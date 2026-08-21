enum PieceStatus { started, learning, learned, paused }

extension PieceStatusLabel on PieceStatus {
  String get label => switch (this) {
    PieceStatus.started => 'Started',
    PieceStatus.learning => 'Learning',
    PieceStatus.learned => 'Learned',
    PieceStatus.paused => 'Paused',
  };
}

/// A piece the user is (or has) learned — the central unit of the app.
/// May be a curated public-domain piece or one the user added/composed
/// themselves; both use the same model.
class Piece {
  final String id;
  final String ownerId;
  final String title;
  final String instrument;
  final String? goal;
  final PieceStatus status;

  /// Storage path for the attached sheet music (PDF/image), if any.
  final String? sheetMusicPath;

  /// Storage path for structured note data (MIDI/MusicXML), if any. This is
  /// what unlocks the falling-note tutorial and guided listen-along
  /// analysis — separate from sheet music, which is display-only.
  final String? referenceDataPath;
  final String? referenceDataType;

  /// The recording marked as this piece's reference performance — what new
  /// takes are compared against. Set by recording a correct performance
  /// once and marking it as the reference (see AnalysisRepository).
  final String? referenceRecordingId;

  final bool isCurated;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Piece({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.instrument,
    required this.status,
    required this.isCurated,
    required this.createdAt,
    required this.updatedAt,
    this.goal,
    this.sheetMusicPath,
    this.referenceDataPath,
    this.referenceDataType,
    this.referenceRecordingId,
  });

  /// True once a piece has structured note data attached — the falling-note
  /// tutorial and note-level guided listen-along only work for these.
  /// Pieces without it still get sheet music display, recording, and
  /// rhythm-only feedback.
  bool get hasTutorialData => referenceDataPath != null;

  /// A rough stand-in for "% mastered", used to drive the progress rings in
  /// the UI. This is NOT a real measurement — actual mastery scoring
  /// requires Milestone 6 (performance analysis) and doesn't exist yet.
  /// Swap this out once real per-piece analysis scores exist.
  double get approximateProgress => switch (status) {
    PieceStatus.started => 0.1,
    PieceStatus.learning => 0.5,
    PieceStatus.learned => 1.0,
    PieceStatus.paused => 0.3,
  };

  factory Piece.fromJson(Map<String, dynamic> json) {
    return Piece(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      instrument: json['instrument'] as String,
      goal: json['goal'] as String?,
      status: PieceStatus.values.byName(json['status'] as String),
      sheetMusicPath: json['sheet_music_path'] as String?,
      referenceDataPath: json['reference_data_path'] as String?,
      referenceDataType: json['reference_data_type'] as String?,
      referenceRecordingId: json['reference_recording_id'] as String?,
      isCurated: json['is_curated'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
