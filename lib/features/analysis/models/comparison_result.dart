enum NoteDiffStatus {
  /// Played at (close to) the right pitch and time.
  matched,

  /// A practice note was found nearby but at the wrong pitch.
  wrongPitch,

  /// No practice note was found near this reference note at all.
  missed,
}

/// One reference note compared against what was actually played at that
/// moment, if anything.
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
/// wrong notes, mistimed notes, or notes that were dropped entirely.
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
  const ComparisonResult({required this.overallScore, required this.weakSpots});

  /// 0.0-1.0 across the whole take.
  final double overallScore;

  final List<WeakSpot> weakSpots;
}
