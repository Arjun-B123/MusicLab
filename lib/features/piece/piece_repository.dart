import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/piece.dart';

class PieceRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Pieces visible to the current user: their own, plus any curated ones.
  Future<List<Piece>> fetchPieces() async {
    final rows = await _client
        .from('pieces')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => Piece.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Piece> createPiece({
    required String title,
    required String instrument,
    String? goal,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No signed-in user — cannot create a piece.');
    }

    final row = await _client
        .from('pieces')
        .insert({
          'owner_id': userId,
          'title': title,
          'instrument': instrument,
          'goal': goal,
        })
        .select()
        .single();

    return Piece.fromJson(row);
  }

  Future<void> updateStatus(String pieceId, PieceStatus status) async {
    await _client
        .from('pieces')
        .update({'status': status.name})
        .eq('id', pieceId);
  }

  Future<void> deletePiece(String pieceId) async {
    await _client.from('pieces').delete().eq('id', pieceId);
  }

  /// Uploads a sheet music file (PDF or image) and attaches it to the
  /// piece. Replaces any previously attached sheet music.
  Future<Piece> attachSheetMusic({
    required Piece piece,
    required File file,
    required String extension,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No signed-in user — cannot attach sheet music.');
    }

    final storagePath = '$userId/${piece.id}.$extension';
    await _client.storage
        .from('sheet-music')
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    final row = await _client
        .from('pieces')
        .update({'sheet_music_path': storagePath})
        .eq('id', piece.id)
        .select()
        .single();

    return Piece.fromJson(row);
  }

  /// Sheet music is stored privately, so viewing it needs a short-lived
  /// signed URL rather than a public one.
  Future<String> sheetMusicUrl(String storagePath) async {
    return _client.storage
        .from('sheet-music')
        .createSignedUrl(storagePath, 3600);
  }
}
