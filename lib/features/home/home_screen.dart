import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/dashed_underline.dart';
import '../../core/theme/progress_ring.dart';
import '../piece/models/piece.dart';
import '../piece/models/recording.dart';
import '../piece/piece_repository.dart';
import '../piece/recording_repository.dart';
import '../piece/screens/piece_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeDashboardData {
  final List<Piece> pieces;
  final List<Recording> recentRecordings;

  _HomeDashboardData(this.pieces, this.recentRecordings);
}

class _HomeScreenState extends State<HomeScreen> {
  final _pieceRepository = PieceRepository();
  final _recordingRepository = RecordingRepository();
  late Future<_HomeDashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_HomeDashboardData> _load() async {
    final pieces = await _pieceRepository.fetchPieces();
    final recordingLists = await Future.wait(
      pieces.map((p) => _recordingRepository.fetchRecordings(p.id)),
    );
    final allRecordings = recordingLists.expand((r) => r).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _HomeDashboardData(pieces, allRecordings);
  }

  void _refresh() {
    setState(() {
      _dataFuture = _load();
    });
  }

  Piece? _pieceFor(List<Piece> pieces, String pieceId) {
    for (final p in pieces) {
      if (p.id == pieceId) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<_HomeDashboardData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    "Couldn't load your dashboard: ${snapshot.error}",
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final pieces = data.pieces;
            // Hero = most recently active piece that isn't finished yet.
            final heroCandidates =
                pieces.where((p) => p.status != PieceStatus.learned).toList()
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            final hero = heroCandidates.isNotEmpty
                ? heroCandidates.first
                : null;

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _Header(colors: colors),
                  if (hero != null)
                    _HeroCard(
                      piece: hero,
                      recordings: data.recentRecordings
                          .where((r) => r.pieceId == hero.id)
                          .toList(),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PieceDetailScreen(piece: hero),
                          ),
                        );
                        _refresh();
                      },
                    ),
                  if (pieces.isNotEmpty)
                    _YourPieces(pieces: pieces, onChanged: _refresh),
                  _WeekStrip(recordings: data.recentRecordings),
                  _RecentMoments(
                    recordings: data.recentRecordings.take(2).toList(),
                    pieceFor: (id) => _pieceFor(pieces, id),
                  ),
                  if (pieces.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                      child: Text(
                        "No pieces yet — head to Library to add the one you're learning.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onBackgroundSoft),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMMM d').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: colors.sage,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ready to practice?',
            style: AppTheme.handwritten(size: 27, color: colors.onBackground),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.piece,
    required this.recordings,
    required this.onTap,
  });

  final Piece piece;
  final List<Recording> recordings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lastPracticed = recordings.isNotEmpty
        ? _relativeDate(recordings.first.createdAt)
        : 'not yet';

    // No real per-section breakdown exists yet (needs Milestone 6 analysis)
    // — this bar uses recording count as an honest, real-but-rough proxy
    // for "how much you've engaged with this piece" instead of a fabricated
    // per-section score.
    const segmentCount = 5;
    final filledSegments = recordings.length.clamp(0, segmentCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.surfaceBorder, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTINUE PRACTICING',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 1.1,
                  color: colors.accentOnSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                piece.title,
                style: AppTheme.handwritten(size: 23, color: colors.ink),
              ),
              const SizedBox(height: 2),
              DashedUnderline(color: colors.accentOnSurface, width: 60),
              const SizedBox(height: 8),
              Text(
                '${piece.instrument} · last practiced $lastPracticed',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: colors.inkSoft,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(segmentCount, (i) {
                        final filled = i < filledSegments;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: i == segmentCount - 1 ? 0 : 5,
                            ),
                            height: 6,
                            decoration: BoxDecoration(
                              color: filled
                                  ? colors.accentOnSurface
                                  : colors.surfaceBorder,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${recordings.length} recording${recordings.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: colors.inkFaint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onTap, child: const Text('Keep going')),
            ],
          ),
        ),
      ),
    );
  }
}

class _YourPieces extends StatelessWidget {
  const _YourPieces({required this.pieces, required this.onChanged});

  final List<Piece> pieces;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Your pieces',
              style: AppTheme.handwritten(size: 17, color: colors.onBackground),
            ),
          ),
          SizedBox(
            height: 148,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              scrollDirection: Axis.horizontal,
              itemCount: pieces.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final piece = pieces[index];
                final pct = (piece.approximateProgress * 100).round();
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PieceDetailScreen(piece: piece),
                      ),
                    );
                    onChanged();
                  },
                  child: Container(
                    width: 168,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.surfaceBorder, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ProgressRing(
                              progress: piece.approximateProgress,
                              size: 38,
                              strokeWidth: 4,
                              trackColor: colors.surfaceBorder,
                              progressColor: colors.accentOnSurface,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: colors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          piece.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.handwritten(
                            size: 16,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${piece.instrument} · started ${_relativeDate(piece.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: colors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.recordings});
  final List<Recording> recordings;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));

    final practicedDays = List.generate(7, (i) {
      final day = startOfWeek.add(Duration(days: i));
      return recordings.any((r) {
        final d = DateTime(
          r.createdAt.year,
          r.createdAt.month,
          r.createdAt.day,
        );
        return d == day;
      });
    });

    final daysPracticed = practicedDays.where((p) => p).length;
    final totalSeconds = recordings
        .where((r) {
          final d = DateTime(
            r.createdAt.year,
            r.createdAt.month,
            r.createdAt.day,
          );
          return !d.isBefore(startOfWeek);
        })
        .fold<int>(0, (sum, r) => sum + (r.durationSeconds ?? 0));
    final minutes = (totalSeconds / 60).round();

    const initials = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.surfaceBorder, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final practiced = practicedDays[i];
                return Column(
                  children: [
                    Text(
                      initials[i],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: colors.inkFaint,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: practiced
                            ? colors.accentOnSurface
                            : Colors.transparent,
                        border: Border.all(
                          color: practiced
                              ? colors.accentOnSurface
                              : colors.surfaceBorder,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 14),
            Text(
              '$daysPracticed day${daysPracticed == 1 ? '' : 's'} this week · $minutes minutes',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: colors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentMoments extends StatelessWidget {
  const _RecentMoments({required this.recordings, required this.pieceFor});

  final List<Recording> recordings;
  final Piece? Function(String pieceId) pieceFor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (recordings.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent moments',
            style: AppTheme.handwritten(size: 17, color: colors.onBackground),
          ),
          const SizedBox(height: 6),
          for (final recording in recordings)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New recording of ${pieceFor(recording.pieceId)?.title ?? 'a piece'}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: colors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pieceFor(recording.pieceId)?.title ?? ''}  ·  ${_relativeDate(recording.createdAt)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: colors.onBackgroundFaint,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _relativeDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays >= 1) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
  if (diff.inHours >= 1) {
    return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  }
  if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
  return 'just now';
}
