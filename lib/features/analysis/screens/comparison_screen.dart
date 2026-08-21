import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../piece/models/recording.dart';
import '../analysis_repository.dart';
import '../models/comparison_result.dart';
import '../models/note_event.dart';
import '../note_names.dart';
import '../take_comparator.dart';

/// Compares two takes of the same piece and shows where the newer one
/// diverged from the reference — no sheet music needed, just two
/// recordings run through the analysis service.
class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({
    super.key,
    required this.reference,
    required this.practice,
  });

  /// The take being compared against — typically the earlier one.
  final Recording reference;

  /// The newer take being scored.
  final Recording practice;

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final _repository = AnalysisRepository();
  late Future<ComparisonResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _run();
  }

  Future<ComparisonResult> _run() async {
    final referenceNotes = await _analyzeOrFetch(widget.reference);
    final practiceNotes = await _analyzeOrFetch(widget.practice);
    return const TakeComparator().compare(
      reference: referenceNotes,
      practice: practiceNotes,
    );
  }

  Future<List<NoteEvent>> _analyzeOrFetch(Recording recording) async {
    final existing = await _repository.fetchExisting(recording.id);
    if (existing != null) return existing;
    return _repository.analyze(recording);
  }

  String _timingNote(ComparisonResult result) {
    const base = 'How closely this take matched your reference take';

    final refBpm = result.referenceBpm;
    final practiceBpm = result.practiceBpm;
    if (refBpm == null || practiceBpm == null) return '$base.';
    if ((refBpm - practiceBpm).abs() < 3) return '$base.';

    return '$base (reference ≈${refBpm.round()} BPM, this take ≈${practiceBpm.round()} BPM).';
  }

  String _formatTime(double seconds) {
    final duration = Duration(milliseconds: (seconds * 1000).round());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Take comparison')),
      body: FutureBuilder<ComparisonResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Listening to both takes…'),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text("Couldn't run the analysis: ${snapshot.error}"),
              ),
            );
          }

          final result = snapshot.data!;
          final scorePercent = (result.overallScore * 100).round();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Match score',
                  style: AppTheme.handwritten(size: 18, color: colors.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  '$scorePercent%',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: colors.accentOnSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timingNote(result),
                  style: TextStyle(color: colors.onBackgroundSoft),
                ),
                const SizedBox(height: 28),
                Text(
                  result.weakSpots.isEmpty
                      ? 'No weak spots found'
                      : 'Weak spots (${result.weakSpots.length})',
                  style: AppTheme.handwritten(size: 18, color: colors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  result.weakSpots.isEmpty
                      ? "This take matched your reference all the way through."
                      : 'Sections that drifted from your reference take — try practising these.',
                  style: TextStyle(color: colors.onBackgroundSoft),
                ),
                const SizedBox(height: 12),
                ...result.weakSpots.map(
                  (spot) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.surfaceBorder, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: colors.accentOnSurface,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_formatTime(spot.startTime)} – ${_formatTime(spot.endTime)}',
                                style: TextStyle(color: colors.ink),
                              ),
                            ),
                            Text(
                              '${(spot.score * 100).round()}%',
                              style: TextStyle(color: colors.onBackgroundSoft),
                            ),
                          ],
                        ),
                        if (spot.noteDiffs.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...spot.noteDiffs.map(
                            (diff) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                diff.status == NoteDiffStatus.missed
                                    ? 'Expected ${midiToNoteName(diff.expectedPitch)} at ${_formatTime(diff.time)} — not played'
                                    : 'Expected ${midiToNoteName(diff.expectedPitch)}, played ${midiToNoteName(diff.playedPitch!)} at ${_formatTime(diff.time)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.onBackgroundSoft,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
