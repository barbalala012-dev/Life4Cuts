-- Life4Cuts shared frame library
-- Run once in Supabase SQL Editor. This stores frame PNGs and names only;
-- captured photos are never uploaded by the app.
create table if not exists public.shared_frames (
  id uuid primary key,
  name text not null check (char_length(name) between 1 and 100),
  storage_path text not null unique,
  created_at timestamptz not null default now()
);
alter table public.shared_frames enable row level security;
drop policy if exists "Anyone can read shared frames" on public.shared_frames;
create policy "Anyone can read shared frames" on public.shared_frames for select to anon, authenticated using (true);
drop policy if exists "Anyone can add shared frames" on public.shared_frames;
create policy "Anyone can add shared frames" on public.shared_frames for insert to anon, authenticated with check (char_length(name) between 1 and 100);
grant select, insert on public.shared_frames to anon, authenticated;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('life4cuts-frames', 'life4cuts-frames', true, 10485760, array['image/png'])
on conflict (id) do update set public = true, file_size_limit = 10485760, allowed_mime_types = array['image/png'];
drop policy if exists "Anyone can view shared frame PNGs" on storage.objects;
create policy "Anyone can view shared frame PNGs" on storage.objects for select to anon, authenticated using (bucket_id = 'life4cuts-frames');
drop policy if exists "Anyone can upload shared frame PNGs" on storage.objects;
create policy "Anyone can upload shared frame PNGs" on storage.objects for insert to anon, authenticated with check (bucket_id = 'life4cuts-frames' and lower(storage.extension(name)) = 'png');
alter publication supabase_realtime add table public.shared_frames;
