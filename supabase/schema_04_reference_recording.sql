-- Each piece can designate one recording as its "reference" — the take
-- every future take gets compared against. This is how a personal
-- composition, a YouTube-learned piece, or a piece with sheet music (which
-- can't be read directly — see recording_analyses) all get a real,
-- note-level comparison target: someone plays it correctly once, Basic
-- Pitch transcribes that performance, and it becomes the standard.
alter table public.pieces
  add column if not exists reference_recording_id uuid
    references public.recordings(id) on delete set null;
