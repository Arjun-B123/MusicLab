import 'models/comparison_result.dart';
import 'models/note_event.dart';
import 'tempo_estimator.dart';

class _AlignedNote {
  const _AlignedNote({
    required this.reference,
    required this.status,
    this.practice,
  });

  final NoteEvent reference;
  final NoteEvent? practice;
  final NoteDiffStatus status;
}

/// Compares a practice take against a reference take (an earlier take of
/// the same piece, or one the user marks as their best) and finds where
/// the practice take diverged.
///
/// Matching is based on note *sequence* (pitch order), not absolute
/// timestamps — so it doesn't matter if the practice take started late,
/// or was played slower or faster than the reference throughout. That's
/// what a fixed time-shift can't handle: a real tempo difference drifts
/// every note by a growing amount, not a constant one. Sequence alignment
/// (a Needleman-Wunsch style edit-distance) sidesteps that by only asking
/// "was the right note played, in the right place in the sequence" —
/// timing is only used afterward, to estimate tempo/offset for display.
class TakeComparator {
  const TakeComparator({
    this.windowSeconds = 2.0,
    this.pitchTolerance = 1,
    this.weakSpotThreshold = 0.6,
  });

  /// How reference-note time is bucketed for reporting weak spots.
  final double windowSeconds;

  /// Semitones a matched note is allowed to differ by.
  final int pitchTolerance;

  /// Windows scoring below this become weak spots.
  final double weakSpotThreshold;

  ComparisonResult compare({
    required List<NoteEvent> reference,
    required List<NoteEvent> practice,
  }) {
    if (reference.isEmpty) {
      return const ComparisonResult(overallScore: 0, weakSpots: []);
    }

    final sortedReference = [...reference]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final sortedPractice = [...practice]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final aligned = _align(sortedReference, sortedPractice);
    final (offset, tempoRatio) = _estimateTiming(aligned);

    final windowScores = <double>[];
    final rawWeakSpots = <WeakSpot>[];

    final duration = sortedReference
        .map((n) => n.endTime)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final windowCount = (duration / windowSeconds).ceil().clamp(1, 1 << 20);

    for (var i = 0; i < windowCount; i++) {
      final windowStart = i * windowSeconds;
      final windowEnd = windowStart + windowSeconds;

      final windowNotes = aligned.where(
        (a) =>
            a.reference.startTime >= windowStart &&
            a.reference.startTime < windowEnd,
      );
      if (windowNotes.isEmpty) continue;

      final matchedCount = windowNotes
          .where((a) => a.status == NoteDiffStatus.matched)
          .length;
      final windowScore = matchedCount / windowNotes.length;
      windowScores.add(windowScore);

      if (windowScore < weakSpotThreshold) {
        rawWeakSpots.add(
          WeakSpot(
            startTime: windowStart,
            endTime: windowEnd,
            score: windowScore,
            noteDiffs: windowNotes
                .where((a) => a.status != NoteDiffStatus.matched)
                .map(
                  (a) => NoteDiff(
                    time: a.reference.startTime,
                    expectedPitch: a.reference.pitch,
                    playedPitch: a.practice?.pitch,
                    status: a.status,
                  ),
                )
                .toList(),
          ),
        );
      }
    }

    final overallScore = windowScores.isEmpty
        ? 0.0
        : windowScores.reduce((a, b) => a + b) / windowScores.length;

    return ComparisonResult(
      overallScore: overallScore,
      weakSpots: _mergeAdjacent(rawWeakSpots),
      appliedOffsetSeconds: offset,
      tempoRatio: tempoRatio,
      referenceBpm: estimateBpm(sortedReference),
      practiceBpm: estimateBpm(sortedPractice),
    );
  }

  /// Global sequence alignment between the reference and practice pitch
  /// sequences (a Needleman-Wunsch edit-distance): finds the
  /// lowest-cost way to line the two up, allowing notes on either side to
  /// be skipped (a missed reference note, or an extra/spurious practice
  /// note), without relying on timestamps at all.
  List<_AlignedNote> _align(
    List<NoteEvent> reference,
    List<NoteEvent> practice,
  ) {
    final n = reference.length;
    final m = practice.length;
    const gapCost = 1;

    int substitutionCost(NoteEvent a, NoteEvent b) {
      final diff = (a.pitch - b.pitch).abs();
      return diff <= pitchTolerance ? 0 : 2;
    }

    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = 1; i <= n; i++) {
      dp[i][0] = i * gapCost;
    }
    for (var j = 1; j <= m; j++) {
      dp[0][j] = j * gapCost;
    }
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final sub =
            dp[i - 1][j - 1] +
            substitutionCost(reference[i - 1], practice[j - 1]);
        final del = dp[i - 1][j] + gapCost;
        final ins = dp[i][j - 1] + gapCost;
        dp[i][j] = [sub, del, ins].reduce((a, b) => a < b ? a : b);
      }
    }

    final result = <_AlignedNote>[];
    var i = n;
    var j = m;
    while (i > 0 || j > 0) {
      if (i > 0 &&
          j > 0 &&
          dp[i][j] ==
              dp[i - 1][j - 1] +
                  substitutionCost(reference[i - 1], practice[j - 1])) {
        final refNote = reference[i - 1];
        final pracNote = practice[j - 1];
        final matched =
            (refNote.pitch - pracNote.pitch).abs() <= pitchTolerance;
        result.add(
          _AlignedNote(
            reference: refNote,
            practice: pracNote,
            status: matched
                ? NoteDiffStatus.matched
                : NoteDiffStatus.wrongPitch,
          ),
        );
        i--;
        j--;
      } else if (i > 0 && dp[i][j] == dp[i - 1][j] + gapCost) {
        result.add(
          _AlignedNote(
            reference: reference[i - 1],
            status: NoteDiffStatus.missed,
          ),
        );
        i--;
      } else {
        // An extra practice note with no reference counterpart — not
        // tracked as a diff against the reference sequence.
        j--;
      }
    }

    return result.reversed.toList();
  }

  /// Estimates start offset and tempo ratio from matched notes via a
  /// simple least-squares fit of practiceTime = tempoRatio * refTime +
  /// offset — purely for display, not used in matching.
  (double, double) _estimateTiming(List<_AlignedNote> aligned) {
    final matched = aligned
        .where((a) => a.status == NoteDiffStatus.matched)
        .toList();
    if (matched.length < 2) {
      if (matched.length == 1) {
        return (
          matched.first.practice!.startTime - matched.first.reference.startTime,
          1.0,
        );
      }
      return (0.0, 1.0);
    }

    final n = matched.length;
    var sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumXX = 0.0;
    for (final a in matched) {
      final x = a.reference.startTime;
      final y = a.practice!.startTime;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }

    final denominator = (n * sumXX) - (sumX * sumX);
    if (denominator.abs() < 1e-9) {
      return ((sumY / n) - (sumX / n), 1.0);
    }

    final slope = ((n * sumXY) - (sumX * sumY)) / denominator;
    final intercept = (sumY - (slope * sumX)) / n;
    return (intercept, slope);
  }

  /// Merges back-to-back weak windows into single ranges, so "bars 3, 4, 5
  /// are weak" reads as one spot instead of three.
  List<WeakSpot> _mergeAdjacent(List<WeakSpot> spots) {
    if (spots.isEmpty) return spots;

    final merged = <WeakSpot>[];
    var current = spots.first;

    for (final next in spots.skip(1)) {
      if ((next.startTime - current.endTime).abs() < 0.001) {
        current = WeakSpot(
          startTime: current.startTime,
          endTime: next.endTime,
          score: (current.score + next.score) / 2,
          noteDiffs: [...current.noteDiffs, ...next.noteDiffs],
        );
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);

    return merged;
  }
}
