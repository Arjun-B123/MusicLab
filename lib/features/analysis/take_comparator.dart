import 'models/comparison_result.dart';
import 'models/note_event.dart';

/// Compares a practice take against a reference take (an earlier take of
/// the same piece, or one the user marks as their best) and finds where
/// the practice take diverged.
///
/// Walks the reference take in fixed-length windows ("bars") and, for each
/// window, checks how many reference notes were matched by a practice note
/// at roughly the same pitch and time. Windows with poor matches become
/// weak spots, each carrying an expected-vs-played breakdown per note.
/// This is a heuristic, not ground-truth music analysis — it needs no
/// sheet music, just two recordings.
class TakeComparator {
  const TakeComparator({
    this.windowSeconds = 2.0,
    this.pitchTolerance = 1,
    this.timeTolerance = 0.35,
    this.weakSpotThreshold = 0.6,
  });

  final double windowSeconds;

  /// Semitones a matched note is allowed to differ by.
  final int pitchTolerance;

  /// Seconds a matched note's start time is allowed to differ by.
  final double timeTolerance;

  /// Windows scoring below this become weak spots.
  final double weakSpotThreshold;

  ComparisonResult compare({
    required List<NoteEvent> reference,
    required List<NoteEvent> practice,
  }) {
    if (reference.isEmpty) {
      return const ComparisonResult(overallScore: 0, weakSpots: []);
    }

    final duration = reference
        .map((n) => n.endTime)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final windowCount = (duration / windowSeconds).ceil().clamp(1, 1 << 20);

    final windowScores = <double>[];
    final rawWeakSpots = <WeakSpot>[];

    for (var i = 0; i < windowCount; i++) {
      final windowStart = i * windowSeconds;
      final windowEnd = windowStart + windowSeconds;

      final refNotes = reference.where(
        (n) => n.startTime >= windowStart && n.startTime < windowEnd,
      );
      if (refNotes.isEmpty) continue;

      var matched = 0;
      var timingErrorTotal = 0.0;
      final diffs = <NoteDiff>[];

      for (final refNote in refNotes) {
        final nearest = _nearestByTime(refNote, practice);

        if (nearest == null) {
          diffs.add(
            NoteDiff(
              time: refNote.startTime,
              expectedPitch: refNote.pitch,
              status: NoteDiffStatus.missed,
            ),
          );
          continue;
        }

        final pitchDiff = (nearest.pitch - refNote.pitch).abs();
        if (pitchDiff <= pitchTolerance) {
          matched++;
          timingErrorTotal += (nearest.startTime - refNote.startTime).abs();
          diffs.add(
            NoteDiff(
              time: refNote.startTime,
              expectedPitch: refNote.pitch,
              playedPitch: nearest.pitch,
              status: NoteDiffStatus.matched,
            ),
          );
        } else {
          diffs.add(
            NoteDiff(
              time: refNote.startTime,
              expectedPitch: refNote.pitch,
              playedPitch: nearest.pitch,
              status: NoteDiffStatus.wrongPitch,
            ),
          );
        }
      }

      final refCount = refNotes.length;
      final matchFraction = matched / refCount;
      final avgTimingError = matched == 0
          ? timeTolerance
          : timingErrorTotal / matched;
      final timingAccuracy = (1 - (avgTimingError / timeTolerance)).clamp(
        0.0,
        1.0,
      );

      final windowScore = (matchFraction * 0.7) + (timingAccuracy * 0.3);
      windowScores.add(windowScore);

      if (windowScore < weakSpotThreshold) {
        rawWeakSpots.add(
          WeakSpot(
            startTime: windowStart,
            endTime: windowEnd,
            score: windowScore,
            noteDiffs: diffs
                .where((d) => d.status != NoteDiffStatus.matched)
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
    );
  }

  /// The practice note closest in time to a reference note, within
  /// [timeTolerance], regardless of pitch — used to report what was
  /// actually played even when it was the wrong note.
  NoteEvent? _nearestByTime(NoteEvent refNote, List<NoteEvent> practice) {
    NoteEvent? best;
    double bestError = double.infinity;

    for (final candidate in practice) {
      final timeDiff = (candidate.startTime - refNote.startTime).abs();
      if (timeDiff > timeTolerance) continue;

      if (timeDiff < bestError) {
        bestError = timeDiff;
        best = candidate;
      }
    }

    return best;
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
