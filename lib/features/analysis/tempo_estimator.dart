import 'models/note_event.dart';

/// Rough BPM estimate from a take's note onsets — takes the median gap
/// between consecutive notes as the beat length, then folds it into a
/// typical practice-tempo range (doubling/halving) since a raw median can
/// easily land on a half or double-time reading. Not true beat-tracking
/// (it doesn't know the time signature or which notes are on-beat), but
/// close enough to compare two takes of the same piece against each other.
double? estimateBpm(List<NoteEvent> notes) {
  if (notes.length < 4) return null;

  final onsets = (notes.map((n) => n.startTime).toList()..sort());
  final gaps = <double>[];
  for (var i = 1; i < onsets.length; i++) {
    final gap = onsets[i] - onsets[i - 1];
    if (gap > 0.05) gaps.add(gap);
  }
  if (gaps.isEmpty) return null;

  gaps.sort();
  final medianGap = gaps[gaps.length ~/ 2];
  if (medianGap <= 0) return null;

  var bpm = 60 / medianGap;
  while (bpm < 60) {
    bpm *= 2;
  }
  while (bpm > 200) {
    bpm /= 2;
  }

  return bpm;
}

/// Which bar (1-indexed) a moment in the take falls in, assuming a
/// standard 4/4 time signature — the app has no way to know the real
/// time signature, so this is an approximation based on the estimated
/// tempo.
int barNumberForTime(double seconds, double bpm, {int beatsPerBar = 4}) {
  final barLength = (60 / bpm) * beatsPerBar;
  if (barLength <= 0) return 1;
  return (seconds / barLength).floor() + 1;
}

/// The traditional Italian tempo marking closest to a BPM value.
String tempoMarking(double bpm) {
  if (bpm < 60) return 'Largo';
  if (bpm < 66) return 'Larghetto';
  if (bpm < 76) return 'Adagio';
  if (bpm < 108) return 'Andante';
  if (bpm < 120) return 'Moderato';
  if (bpm < 156) return 'Allegro';
  if (bpm < 176) return 'Vivace';
  if (bpm < 200) return 'Presto';
  return 'Prestissimo';
}
