-- MusicLab core schema — Milestone 2: piece library.
-- Run this in the Supabase SQL Editor (Project → SQL Editor → New query).

create table if not exists public.pieces (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,

  title text not null,
  instrument text not null default 'piano',
  goal text,

  -- started -> learning -> learned -> paused, matches the Journey timeline
  status text not null default 'started'
    check (status in ('started', 'learning', 'learned', 'paused')),

  -- Sheet music (PDF/image) attached for display — separate from the
  -- structured reference data below, per the sheet-music-vs-tutorial split
  -- decided during planning.
  sheet_music_path text,

  -- Structured note data (MIDI/MusicXML) that unlocks the falling-note
  -- tutorial and guided listen-along analysis. Absent for pieces that only
  -- have sheet music or mic-only recordings — those still work, just with
  -- rhythm-only feedback instead of note-level guidance.
  reference_data_path text,
  reference_data_type text
    check (reference_data_type in ('midi', 'musicxml')),

  -- True for the curated public-domain pieces shipped with the app; false
  -- for pieces the user created themselves (including their own
  -- compositions).
  is_curated boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists pieces_owner_id_idx on public.pieces (owner_id);

alter table public.pieces enable row level security;

-- Users can fully manage their own pieces.
create policy "Users can view their own pieces"
  on public.pieces for select
  using (auth.uid() = owner_id);

create policy "Users can insert their own pieces"
  on public.pieces for insert
  with check (auth.uid() = owner_id);

create policy "Users can update their own pieces"
  on public.pieces for update
  using (auth.uid() = owner_id);

create policy "Users can delete their own pieces"
  on public.pieces for delete
  using (auth.uid() = owner_id);

-- Curated pieces (owned by no one in particular) are readable by everyone,
-- signed in or not.
create policy "Anyone can view curated pieces"
  on public.pieces for select
  using (is_curated = true);

-- Keep updated_at current on every change.
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists pieces_set_updated_at on public.pieces;
create trigger pieces_set_updated_at
  before update on public.pieces
  for each row execute function public.set_updated_at();

-- Storage buckets for sheet music and reference data files.
insert into storage.buckets (id, name, public)
values ('sheet-music', 'sheet-music', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('reference-data', 'reference-data', false)
on conflict (id) do nothing;

create policy "Users can manage their own sheet music files"
  on storage.objects for all
  using (bucket_id = 'sheet-music' and auth.uid()::text = (storage.foldername(name))[1])
  with check (bucket_id = 'sheet-music' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users can manage their own reference data files"
  on storage.objects for all
  using (bucket_id = 'reference-data' and auth.uid()::text = (storage.foldername(name))[1])
  with check (bucket_id = 'reference-data' and auth.uid()::text = (storage.foldername(name))[1]);
