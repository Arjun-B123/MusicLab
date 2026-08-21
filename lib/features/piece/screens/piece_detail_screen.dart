import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../analysis/analysis_repository.dart';
import '../../analysis/screens/comparison_screen.dart';
import '../../analysis/screens/edit_reference_notes_screen.dart';
import '../models/piece.dart';
import '../models/recording.dart';
import '../piece_repository.dart';
import '../recording_repository.dart';
import '../widgets/sheet_music_section.dart';

class PieceDetailScreen extends StatefulWidget {
  const PieceDetailScreen({super.key, required this.piece});

  final Piece piece;

  @override
  State<PieceDetailScreen> createState() => _PieceDetailScreenState();
}

class _PieceDetailScreenState extends State<PieceDetailScreen> {
  final _repository = RecordingRepository();
  final _pieceRepository = PieceRepository();
  final _analysisRepository = AnalysisRepository();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  late Piece _piece = widget.piece;
  late Future<List<Recording>> _recordingsFuture;

  bool _isRecording = false;
  Stopwatch? _stopwatch;
  Timer? _tickTimer;
  Duration _elapsed = Duration.zero;
  String? _playingRecordingId;
  String? _busyRecordingId;

  @override
  void initState() {
    super.initState();
    _recordingsFuture = _repository.fetchRecordings(widget.piece.id);
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _tickTimer?.cancel();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _recordingsFuture = _repository.fetchRecordings(widget.piece.id);
    });
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is needed to record.'),
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/musiclab_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    _stopwatch = Stopwatch()..start();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() => _elapsed = _stopwatch!.elapsed);
    });

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _tickTimer?.cancel();
    final duration = _stopwatch?.elapsed ?? Duration.zero;
    _stopwatch = null;

    setState(() {
      _isRecording = false;
      _elapsed = Duration.zero;
    });

    if (path == null) return;

    try {
      await _repository.uploadRecording(
        pieceId: widget.piece.id,
        audioFile: File(path),
        durationSeconds: duration.inSeconds,
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save that recording: $e")),
      );
    }
  }

  Future<void> _togglePlayback(Recording recording) async {
    if (_playingRecordingId == recording.id) {
      await _player.stop();
      setState(() => _playingRecordingId = null);
      return;
    }

    final url = await _repository.playbackUrl(recording);
    await _player.play(UrlSource(url));
    setState(() => _playingRecordingId = recording.id);
    _player.onPlayerComplete.first.then((_) {
      if (mounted) setState(() => _playingRecordingId = null);
    });
  }

  Future<void> _setAsReference(Recording recording) async {
    setState(() => _busyRecordingId = recording.id);
    try {
      var notes = await _analysisRepository.fetchExisting(recording.id);
      notes ??= await _analysisRepository.analyze(recording);

      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EditReferenceNotesScreen(
            recordingId: recording.id,
            initialNotes: notes!,
          ),
        ),
      );

      if (saved != true) return;

      final updated = await _pieceRepository.setReferenceRecording(
        _piece.id,
        recording.id,
      );
      if (!mounted) return;
      setState(() => _piece = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set as this piece\'s reference.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't set reference: $e")));
    } finally {
      if (mounted) setState(() => _busyRecordingId = null);
    }
  }

  Future<void> _compareToReference() async {
    final referenceId = _piece.referenceRecordingId;
    if (referenceId == null) return;

    final recordings = await _recordingsFuture;
    final practice = recordings.firstWhere(
      (r) => r.id != referenceId,
      orElse: () => recordings.first,
    );

    final reference = recordings.firstWhere(
      (r) => r.id == referenceId,
      orElse: () => throw StateError('Reference recording not found'),
    );

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ComparisonScreen(reference: reference, practice: practice),
      ),
    );
  }

  Future<void> _deletePiece() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this piece?'),
        content: Text(
          'This deletes "${_piece.title}" and all its recordings and sheet music. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _pieceRepository.deletePiece(_piece.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't delete: $e")));
    }
  }

  Future<void> _deleteRecording(Recording recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this take?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.deleteRecording(recording);
      if (recording.id == _piece.referenceRecordingId) {
        final updated = await _pieceRepository.clearReferenceRecording(
          _piece.id,
        );
        if (mounted) setState(() => _piece = updated);
      }
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't delete: $e")));
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final piece = _piece;

    return Scaffold(
      appBar: AppBar(
        title: Text(piece.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete piece',
            onPressed: _deletePiece,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [piece.instrument, piece.status.label].join(' · '),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (piece.goal != null) ...[
                    const SizedBox(height: 4),
                    Text(piece.goal!),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        if (_isRecording)
                          Text(
                            _formatDuration(_elapsed),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        const SizedBox(height: 8),
                        FloatingActionButton.large(
                          onPressed: _isRecording
                              ? _stopRecording
                              : _startRecording,
                          backgroundColor: _isRecording
                              ? Theme.of(context).colorScheme.error
                              : null,
                          child: Icon(_isRecording ? Icons.stop : Icons.mic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SheetMusicSection(
              piece: piece,
              onPieceUpdated: (updated) => setState(() => _piece = updated),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          FutureBuilder<List<Recording>>(
            future: _recordingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text("Couldn't load recordings: ${snapshot.error}"),
                  ),
                );
              }

              final recordings = snapshot.data ?? [];
              if (recordings.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No recordings yet — tap the mic to start.'),
                    ),
                  ),
                );
              }

              final referenceId = _piece.referenceRecordingId;
              final hasUsableReference =
                  referenceId != null &&
                  recordings.any((r) => r.id == referenceId) &&
                  recordings.length >= 2;
              final showCompareButton =
                  hasUsableReference || recordings.length >= 2;

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == recordings.length) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: OutlinedButton.icon(
                        onPressed: hasUsableReference
                            ? _compareToReference
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ComparisonScreen(
                                    reference: recordings[1],
                                    practice: recordings[0],
                                  ),
                                ),
                              ),
                        icon: const Icon(Icons.compare_arrows),
                        label: Text(
                          hasUsableReference
                              ? 'Compare to reference take'
                              : 'Compare latest two takes',
                        ),
                      ),
                    );
                  }
                  final recording = recordings[index];
                  final isPlaying = _playingRecordingId == recording.id;
                  final isReference = recording.id == referenceId;
                  final isBusy = _busyRecordingId == recording.id;
                  return ListTile(
                    leading: IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                      ),
                      onPressed: () => _togglePlayback(recording),
                    ),
                    title: Text(
                      recording.durationSeconds != null
                          ? _formatDuration(
                              Duration(seconds: recording.durationSeconds!),
                            )
                          : 'Recording',
                    ),
                    trailing: isBusy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isReference ? Icons.star : Icons.star_border,
                                ),
                                tooltip: isReference
                                    ? 'Reference take — tap to edit its notes'
                                    : 'Set as reference take',
                                onPressed: () => _setAsReference(recording),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Delete take',
                                onPressed: () => _deleteRecording(recording),
                              ),
                            ],
                          ),
                    subtitle: Text(
                      '${recording.createdAt.month}/${recording.createdAt.day}/${recording.createdAt.year}',
                    ),
                  );
                }, childCount: recordings.length + (showCompareButton ? 1 : 0)),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
