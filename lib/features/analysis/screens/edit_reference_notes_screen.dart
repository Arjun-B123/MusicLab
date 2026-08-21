import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../analysis_repository.dart';
import '../models/note_event.dart';
import '../note_names.dart';

/// Lets the user correct what Basic Pitch heard in a reference
/// performance — delete notes it picked up wrongly, or nudge a note's
/// pitch/timing. This recording's notes are what every future take gets
/// scored against, so it's worth getting right.
class EditReferenceNotesScreen extends StatefulWidget {
  const EditReferenceNotesScreen({
    super.key,
    required this.recordingId,
    required this.initialNotes,
  });

  final String recordingId;
  final List<NoteEvent> initialNotes;

  @override
  State<EditReferenceNotesScreen> createState() =>
      _EditReferenceNotesScreenState();
}

class _EditReferenceNotesScreenState extends State<EditReferenceNotesScreen> {
  final _repository = AnalysisRepository();
  late List<NoteEvent> _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notes = [...widget.initialNotes]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _deleteAt(int index) {
    setState(() => _notes.removeAt(index));
  }

  void _shiftPitch(int index, int delta) {
    final note = _notes[index];
    setState(() {
      _notes[index] = NoteEvent(
        startTime: note.startTime,
        endTime: note.endTime,
        pitch: note.pitch + delta,
        amplitude: note.amplitude,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _repository.saveNotes(widget.recordingId, _notes);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't save: $e")));
      setState(() => _saving = false);
    }
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
      appBar: AppBar(
        title: const Text('Edit reference notes'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Remove notes Basic Pitch heard wrong, or nudge the pitch up/down a semitone.',
              style: TextStyle(color: colors.onBackgroundSoft),
            ),
          ),
          Expanded(
            child: _notes.isEmpty
                ? const Center(child: Text('No notes left.'))
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return ListTile(
                        leading: Text(_formatTime(note.startTime)),
                        title: Text(midiToNoteName(note.pitch)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _shiftPitch(index, -1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _shiftPitch(index, 1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteAt(index),
                            ),
                          ],
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
