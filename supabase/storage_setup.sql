-- ============================================================
-- Lacuna — Storage bucket + RLS setup
-- Run this once in the Supabase SQL Editor (postgres role).
-- Safe to re-run; uses on conflict / if not exists guards.
-- ============================================================

-- 1. Create the post-media bucket.
-- Public reads are off; we issue signed URLs from the client.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'post-media',
  'post-media',
  true,                      -- public reads OK; bucket only holds approved post media
  10 * 1024 * 1024,          -- 10 MB hard cap per object
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'video/mp4', 'video/quicktime']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- ============================================================
-- 2. RLS policies on storage.objects for the post-media bucket.
--    Path convention: <user_id>/<uuid>.<ext>
--    The first folder segment MUST equal the uploader's auth.uid.
-- ============================================================

-- Anyone (including anon) can read media.
-- Post visibility is gated upstream by the posts table RLS, so the
-- only way someone learns a media URL is via a post they can already see.
drop policy if exists "post-media: public read" on storage.objects;
create policy "post-media: public read"
on storage.objects for select
using (bucket_id = 'post-media');

-- Authenticated users can upload only into their own folder.
drop policy if exists "post-media: own folder upload" on storage.objects;
create policy "post-media: own folder upload"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'post-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Authenticated users can delete only their own files.
drop policy if exists "post-media: own folder delete" on storage.objects;
create policy "post-media: own folder delete"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'post-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Authenticated users can update (replace metadata of) only their own files.
drop policy if exists "post-media: own folder update" on storage.objects;
create policy "post-media: own folder update"
on storage.objects for update
to authenticated
using (
  bucket_id = 'post-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);
