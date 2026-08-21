/// A stretch of the practice take that diverged from the reference take —
/// wrong notes, mistimed notes, or notes that were dropped entirely.
class WeakSpot {
  const WeakSpot({
    required this.startTime,
    required this.endTime,
    required this.score,
  });

  final double startTime;
  final double endTime;

  /// 0.0 (badly off) to 1.0 (fine) — spots below the weak-spot threshold
  /// are the ones that get surfaced.
  final double score;
}

class ComparisonResult {
  const ComparisonResult({required this.overallScore, required this.weakSpots});

  /// 0.0-1.0 across the whole take.
  final double overallScore;

  final List<WeakSpot> weakSpots;
}
