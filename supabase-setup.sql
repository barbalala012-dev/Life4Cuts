-- Life4Cuts shared frame library
-- Run once in Supabase SQL Editor. Only frame PNGs and their names are stored here.
-- Captured photos are never uploaded by the app.
create table if not exists public.life4cuts_teachers (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.life4cuts_teachers enable row level security;
drop policy if exists "Teachers can read own registration" on public.life4cuts_teachers;
create policy "Teachers can read own registration" on public.life4cuts_teachers for select to authenticated using (user_id = auth.uid());
grant select on public.life4cuts_teachers to authenticated;

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
drop policy if exists "Teachers can delete shared frames" on public.shared_frames;
create policy "Teachers can delete shared frames" on public.shared_frames for delete to authenticated using (exists (select 1 from public.life4cuts_teachers t where t.user_id = auth.uid()));
grant select, insert on public.shared_frames to anon, authenticated;
grant delete on public.shared_frames to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('life4cuts-frames', 'life4cuts-frames', true, 10485760, array['image/png'])
on conflict (id) do update set public = true, file_size_limit = 10485760, allowed_mime_types = array['image/png'];
drop policy if exists "Anyone can view shared frame PNGs" on storage.objects;
create policy "Anyone can view shared frame PNGs" on storage.objects for select to anon, authenticated using (bucket_id = 'life4cuts-frames');
drop policy if exists "Anyone can upload shared frame PNGs" on storage.objects;
create policy "Anyone can upload shared frame PNGs" on storage.objects for insert to anon, authenticated with check (bucket_id = 'life4cuts-frames' and lower(storage.extension(name)) = 'png');
drop policy if exists "Teachers can delete shared frame PNGs" on storage.objects;
create policy "Teachers can delete shared frame PNGs" on storage.objects for delete to authenticated using (bucket_id = 'life4cuts-frames' and exists (select 1 from public.life4cuts_teachers t where t.user_id = auth.uid()));

do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'shared_frames') then
    alter publication supabase_realtime add table public.shared_frames;
  end if;
end $$;
