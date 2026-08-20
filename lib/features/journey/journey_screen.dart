import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../piece/models/piece.dart';
import '../piece/piece_repository.dart';
import '../piece/recording_repository.dart';

enum _MomentType { pieceStarted, recording }

class _Moment {
  final _MomentType type;
  final DateTime date;
  final Piece piece;
  final String title;
  final String? body;

  _Moment({
    required this.type,
    required this.date,
    required this.piece,
    required this.title,
    this.body,
  });
}

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  final _pieceRepository = PieceRepository();
  final _recordingRepository = RecordingRepository();
  late Future<List<_Moment>> _momentsFuture;

  @override
  void initState() {
    super.initState();
    _momentsFuture = _loadMoments();
  }

  Future<List<_Moment>> _loadMoments() async {
    final pieces = await _pieceRepository.fetchPieces();
    final moments = <_Moment>[];

    for (final piece in pieces) {
      moments.add(
        _Moment(
          type: _MomentType.pieceStarted,
          date: piece.createdAt,
          piece: piece,
          title: 'Started ${piece.title}',
          body: piece.goal,
        ),
      );

      final recordings = await _recordingRepository.fetchRecordings(piece.id);
      for (final recording in recordings) {
        moments.add(
          _Moment(
            type: _MomentType.recording,
            date: recording.createdAt,
            piece: piece,
            title: 'Recorded ${piece.title}',
            body: recording.note,
          ),
        );
      }
    }

    moments.sort((a, b) => b.date.compareTo(a.date));
    return moments;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<_Moment>>(
          future: _momentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text("Couldn't load your journey: ${snapshot.error}"),
                ),
              );
            }

            final moments = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JOURNEY',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: colors.sage,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your musical story',
                        style: AppTheme.handwritten(
                          size: 27,
                          color: colors.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
                if (moments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 40, 22, 20),
                    child: Text(
                      'Nothing here yet — add a piece and record yourself to start your story.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onBackgroundSoft),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(42, 22, 22, 20),
                    child: Stack(
                      children: [
                        Positioned(
                          left: -19,
                          top: 8,
                          bottom: 8,
                          child: Container(
                            width: 3,
                            color: colors.surfaceBorder,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final moment in moments)
                              _TimelineEntry(moment: moment, colors: colors),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.moment, required this.colors});

  final _Moment moment;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final isRecording = moment.type == _MomentType.recording;
    final dotColor = isRecording ? colors.accent : colors.surface;
    final dotBorder = isRecording ? colors.accent : colors.surfaceBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -42,
            top: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                border: Border.all(
                  color: dotBorder,
                  width: isRecording ? 0 : 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecording ? colors.onAccent : colors.surfaceBorder,
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM d').format(moment.date).toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.4,
                  color: colors.tabInactive,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.surfaceBorder, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moment.title,
                      style: AppTheme.handwritten(size: 15, color: colors.ink),
                    ),
                    if (moment.body != null && moment.body!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        moment.body!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: colors.inkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
