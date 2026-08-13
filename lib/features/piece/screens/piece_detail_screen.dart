import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/piece.dart';
import '../models/recording.dart';
import '../recording_repository.dart';

class PieceDetailScreen extends StatefulWidget {
  const PieceDetailScreen({super.key, required this.piece});

  final Piece piece;

  @override
  State<PieceDetailScreen> createState() => _PieceDetailScreenState();
}

class _PieceDetailScreenState extends State<PieceDetailScreen> {
  final _repository = RecordingRepository();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  late Future<List<Recording>> _recordingsFuture;

  bool _isRecording = false;
  Stopwatch? _stopwatch;
  Timer? _tickTimer;
  Duration _elapsed = Duration.zero;
  String? _playingRecordingId;

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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final piece = widget.piece;

    return Scaffold(
      appBar: AppBar(title: Text(piece.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
                        onPressed:
                            _isRecording ? _stopRecording : _startRecording,
                        backgroundColor: _isRecording
                            ? Theme.of(context).colorScheme.error
                            : null,
                        child: Icon(_isRecording ? Icons.stop : Icons.mic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Recording>>(
              future: _recordingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Couldn't load recordings: ${snapshot.error}"),
                  );
                }

                final recordings = snapshot.data ?? [];
                if (recordings.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No recordings yet — tap the mic to start.'),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: recordings.length,
                  itemBuilder: (context, index) {
                    final recording = recordings[index];
                    final isPlaying = _playingRecordingId == recording.id;
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
                      subtitle: Text(
                        '${recording.createdAt.month}/${recording.createdAt.day}/${recording.createdAt.year}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
