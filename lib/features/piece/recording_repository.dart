import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/recording.dart';

class RecordingRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Recording>> fetchRecordings(String pieceId) async {
    final rows = await _client
        .from('recordings')
        .select()
        .eq('piece_id', pieceId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => Recording.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Recording> fetchById(String recordingId) async {
    final row = await _client
        .from('recordings')
        .select()
        .eq('id', recordingId)
        .single();
    return Recording.fromJson(row);
  }

  Future<Recording> uploadRecording({
    required String pieceId,
    required File audioFile,
    int? durationSeconds,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No signed-in user — cannot upload a recording.');
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
    final storagePath = '$userId/$pieceId/$fileName';

    await _client.storage.from('recordings').upload(storagePath, audioFile);

    final row = await _client
        .from('recordings')
        .insert({
          'piece_id': pieceId,
          'owner_id': userId,
          'storage_path': storagePath,
          'duration_seconds': durationSeconds,
        })
        .select()
        .single();

    return Recording.fromJson(row);
  }

  /// Recordings are stored privately, so playback needs a short-lived signed
  /// URL rather than a public one.
  Future<String> playbackUrl(Recording recording) async {
    return _client.storage
        .from('recordings')
        .createSignedUrl(recording.storagePath, 3600);
  }

  Future<void> deleteRecording(Recording recording) async {
    await _client.storage.from('recordings').remove([recording.storagePath]);
    await _client.from('recordings').delete().eq('id', recording.id);
  }
}
