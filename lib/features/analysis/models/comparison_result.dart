enum NoteDiffStatus {
  /// Played at (close to) the right pitch, in the right place in the
  /// sequence.
  matched,

  /// A practice note was found in the right place in the sequence, but at
  /// the wrong pitch.
  wrongPitch,

  /// No corresponding practice note was found anywhere in the sequence.
  missed,
}

/// One reference note compared against what was actually played at that
/// point in the sequence, if anything.
class NoteDiff {
  const NoteDiff({
    required this.time,
    required this.expectedPitch,
    required this.status,
    this.playedPitch,
  });

  final double time;
  final int expectedPitch;

  /// Null when the note was missed entirely.
  final int? playedPitch;

  final NoteDiffStatus status;
}

/// A stretch of the practice take that diverged from the reference take —
/// wrong notes, or notes that were dropped entirely.
class WeakSpot {
  const WeakSpot({
    required this.startTime,
    required this.endTime,
    required this.score,
    this.noteDiffs = const [],
  });

  final double startTime;
  final double endTime;

  /// 0.0 (badly off) to 1.0 (fine) — spots below the weak-spot threshold
  /// are the ones that get surfaced.
  final double score;

  /// Expected-vs-played breakdown for the reference notes in this window.
  final List<NoteDiff> noteDiffs;
}

class ComparisonResult {
  const ComparisonResult({
    required this.overallScore,
    required this.weakSpots,
    this.appliedOffsetSeconds = 0,
    this.tempoRatio = 1.0,
    this.referenceBpm,
    this.practiceBpm,
  });

  /// 0.0-1.0 across the whole take.
  final double overallScore;

  final List<WeakSpot> weakSpots;

  /// Estimated tempo of each take, in beats per minute. Null when there
  /// weren't enough notes to estimate from.
  final double? referenceBpm;
  final double? practiceBpm;

  /// How many seconds later (positive) or earlier (negative) the practice
  /// take started, estimated from matched notes — shown for context, not
  /// used to score matching (matching is tempo/offset-independent).
  final double appliedOffsetSeconds;

  /// How the practice take's pace compares to the reference's, estimated
  /// from matched notes: 1.0 = same tempo, 1.15 = played 15% slower,
  /// 0.9 = played 10% faster.
  final double tempoRatio;
}
