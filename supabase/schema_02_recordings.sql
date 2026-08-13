-- MusicLab schema addition — Milestone 4: recordings.
-- Run this in the Supabase SQL Editor after schema.sql.

create table if not exists public.recordings (
  id uuid primary key default gen_random_uuid(),
  piece_id uuid not null references public.pieces (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,

  storage_path text not null,
  duration_seconds integer,
  note text,

  created_at timestamptz not null default now()
);

create index if not exists recordings_piece_id_idx on public.recordings (piece_id);
create index if not exists recordings_owner_id_idx on public.recordings (owner_id);

alter table public.recordings enable row level security;

create policy "Users can view their own recordings"
  on public.recordings for select
  using (auth.uid() = owner_id);

create policy "Users can insert their own recordings"
  on public.recordings for insert
  with check (auth.uid() = owner_id);

create policy "Users can delete their own recordings"
  on public.recordings for delete
  using (auth.uid() = owner_id);

insert into storage.buckets (id, name, public)
values ('recordings', 'recordings', false)
on conflict (id) do nothing;

create policy "Users can manage their own recording files"
  on storage.objects for all
  using (bucket_id = 'recordings' and auth.uid()::text = (storage.foldername(name))[1])
  with check (bucket_id = 'recordings' and auth.uid()::text = (storage.foldername(name))[1]);
