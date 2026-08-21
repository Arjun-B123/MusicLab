const _noteNames = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

/// e.g. 60 -> "C4"
String midiToNoteName(int midi) {
  final octave = (midi ~/ 12) - 1;
  final name = _noteNames[midi % 12];
  return '$name$octave';
}
