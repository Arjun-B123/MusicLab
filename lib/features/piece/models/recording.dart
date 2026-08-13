class Recording {
  final String id;
  final String pieceId;
  final String ownerId;
  final String storagePath;
  final int? durationSeconds;
  final String? note;
  final DateTime createdAt;

  const Recording({
    required this.id,
    required this.pieceId,
    required this.ownerId,
    required this.storagePath,
    required this.createdAt,
    this.durationSeconds,
    this.note,
  });

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] as String,
      pieceId: json['piece_id'] as String,
      ownerId: json['owner_id'] as String,
      storagePath: json['storage_path'] as String,
      durationSeconds: json['duration_seconds'] as int?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
