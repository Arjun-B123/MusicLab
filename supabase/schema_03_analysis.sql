-- Note-level analysis for a recording, produced by the analysis service
-- (Basic Pitch). One row per recording, holding every detected note as
-- JSON: [{ "startTime": s, "endTime": s, "pitch": midiNumber, "amplitude": 0-1 }, ...]
create table if not exists recording_analyses (
  id uuid primary key default gen_random_uuid(),
  recording_id uuid not null references recordings(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  notes jsonb not null,
  created_at timestamptz not null default now()
);

create unique index if not exists recording_analyses_recording_id_idx
  on recording_analyses(recording_id);

alter table recording_analyses enable row level security;

create policy "Users manage their own recording analyses"
  on recording_analyses
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);
