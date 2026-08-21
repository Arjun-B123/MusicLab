/// A single detected note, as returned by the analysis service.
class NoteEvent {
  const NoteEvent({
    required this.startTime,
    required this.endTime,
    required this.pitch,
    required this.amplitude,
  });

  /// Seconds from the start of the recording.
  final double startTime;
  final double endTime;

  /// MIDI note number (60 = middle C).
  final int pitch;

  /// Loudness, 0.0-1.0.
  final double amplitude;

  factory NoteEvent.fromJson(Map<String, dynamic> json) {
    return NoteEvent(
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
      pitch: json['pitch'] as int,
      amplitude: (json['amplitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'startTime': startTime,
    'endTime': endTime,
    'pitch': pitch,
    'amplitude': amplitude,
  };
}
