import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/analysis_config.dart';
import '../piece/models/recording.dart';
import '../piece/recording_repository.dart';
import 'models/note_event.dart';

class AnalysisRepository {
  AnalysisRepository({RecordingRepository? recordingRepository})
    : _recordingRepository = recordingRepository ?? RecordingRepository();

  final RecordingRepository _recordingRepository;

  SupabaseClient get _client => Supabase.instance.client;

  /// Returns the cached note analysis for a recording if it already ran,
  /// otherwise null.
  Future<List<NoteEvent>?> fetchExisting(String recordingId) async {
    final row = await _client
        .from('recording_analyses')
        .select()
        .eq('recording_id', recordingId)
        .maybeSingle();
    if (row == null) return null;
    return _parseNotes(row['notes']);
  }

  /// Runs the recording through the analysis service (downloading it from
  /// Supabase Storage first) and caches the result. Safe to call again —
  /// re-running just overwrites the cached notes.
  Future<List<NoteEvent>> analyze(Recording recording) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No signed-in user — cannot analyze a recording.');
    }

    final audioUrl = await _recordingRepository.playbackUrl(recording);
    final audioBytes = await http.readBytes(Uri.parse(audioUrl));

    final uri = Uri.parse('$analysisServiceBaseUrl/analyze');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: 'recording.m4a',
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw StateError(
        'Analysis service returned ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final notes = _parseNotes(decoded['notes']);

    await _client.from('recording_analyses').upsert({
      'recording_id': recording.id,
      'owner_id': userId,
      'notes': decoded['notes'],
    }, onConflict: 'recording_id');

    return notes;
  }

  /// Overwrites the cached notes for a recording — used after the user
  /// corrects a reference performance's auto-detected notes by hand.
  Future<void> saveNotes(String recordingId, List<NoteEvent> notes) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No signed-in user — cannot save analysis.');
    }

    await _client.from('recording_analyses').upsert({
      'recording_id': recordingId,
      'owner_id': userId,
      'notes': notes.map((n) => n.toJson()).toList(),
    }, onConflict: 'recording_id');
  }

  List<NoteEvent> _parseNotes(dynamic raw) {
    return (raw as List)
        .map((n) => NoteEvent.fromJson(n as Map<String, dynamic>))
        .toList();
  }
}
