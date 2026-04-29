-- ============================================================
-- Lacuna — Storage RLS audit harness
-- Run in Supabase SQL Editor (postgres role).
--
-- Tests storage.objects INSERT policies for the `post-media`
-- bucket:
--   • alice can upload to her own folder (allow)
--   • alice cannot upload to bob's folder (deny — path RLS)
--   • anon cannot upload (deny)
--   • anon CAN read (allow — public bucket)
--
-- ⚠️  What this DOES NOT cover (Supabase platform limits):
--   • UPDATE / DELETE on storage.objects — blocked by a Supabase
--     trigger ("Direct ... not allowed. Use the Storage API")
--     regardless of the RLS policies on the table. The DELETE/
--     UPDATE policies you wrote DO apply when the client goes
--     through `supabase.storage.from(bucket).remove(...)` — but
--     SQL alone can't reach that path.
--   • file_size_limit / allowed_mime_types — enforced by
--     storage-api at upload, not by RLS.
--
-- For DELETE / UPDATE / size / MIME coverage, write a Dart
-- integration test that uses the real Supabase Storage client.
-- See lib/features/post/data/repos/supabase_post_storage_repo.dart
-- for the API surface to exercise.
--
-- Wrapped in begin/rollback. Test users + objects never persist.
-- ============================================================

begin;

create temp table _storage_audit (
  inserted_at timestamptz default clock_timestamp(),
  test text, expected text, actual text, status text
) on commit drop;

grant all on _storage_audit to public;

create or replace function _storage_record(
  _label text, _ok boolean, _expect text
) returns void language plpgsql as $$
declare _matched boolean;
begin
  _matched := (_ok and _expect = 'allow') or (not _ok and _expect = 'deny');
  insert into _storage_audit (test, expected, actual, status)
  values (
    _label, _expect,
    case when _ok then 'allow' else 'deny' end,
    case when _matched then 'OK' else 'UNEXPECTED' end
  );
end; $$;

-- ─── seed users ─────────────────────────────────────────────
do $$
declare _alice uuid := gen_random_uuid();
declare _bob   uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, raw_user_meta_data, aud, role)
  values
    (_alice, 'sa@lacuna.app', '{"username":"sa"}'::jsonb, 'authenticated', 'authenticated'),
    (_bob,   'sb@lacuna.app', '{"username":"sb"}'::jsonb, 'authenticated', 'authenticated');
  perform set_config('audit.alice', _alice::text, false);
  perform set_config('audit.bob',   _bob::text,   false);
end $$;

-- ===== alice uploads to own folder =====
do $$
declare _alice uuid := current_setting('audit.alice')::uuid;
declare _ok boolean;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', _alice::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  begin
    insert into storage.objects (bucket_id, name, owner, metadata)
    values ('post-media', _alice::text || '/own.jpg', _alice, '{}'::jsonb);
    _ok := true;
  exception when others then _ok := false; end;
  perform _storage_record('alice uploads to own folder', _ok, 'allow');
end $$;
reset role;

-- ===== alice tries to upload to bob's folder =====
do $$
declare _alice uuid := current_setting('audit.alice')::uuid;
declare _bob   uuid := current_setting('audit.bob')::uuid;
declare _ok boolean;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', _alice::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  begin
    insert into storage.objects (bucket_id, name, owner, metadata)
    values ('post-media', _bob::text || '/sneaky.jpg', _alice, '{}'::jsonb);
    _ok := true;
  exception when others then _ok := false; end;
  perform _storage_record('alice uploads to bob folder (forbidden)', _ok, 'deny');
end $$;
reset role;

-- DELETE tests intentionally removed:
-- Supabase's storage trigger blocks all direct SQL DELETEs with
-- "Direct deletion from storage tables is not allowed. Use the
-- Storage API instead." This trigger fires regardless of the RLS
-- policies you wrote. To exercise the DELETE RLS, write a Dart
-- integration test that calls supabase.storage.from('post-media')
-- .remove([path]).

-- ===== anon tries to upload =====
do $$
declare _alice uuid := current_setting('audit.alice')::uuid;
declare _ok boolean;
begin
  perform set_config('request.jwt.claims',
    json_build_object('role', 'anon')::text, true);
  set local role anon;

  begin
    insert into storage.objects (bucket_id, name, owner, metadata)
    values ('post-media', _alice::text || '/anon.jpg', null, '{}'::jsonb);
    _ok := true;
  exception when others then _ok := false; end;
  perform _storage_record('anon uploads (forbidden)', _ok, 'deny');
end $$;
reset role;

-- ===== seed a file for the public-read test =====
do $$
declare _alice uuid := current_setting('audit.alice')::uuid;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', _alice::text, 'role', 'authenticated')::text, true);
  set local role authenticated;
  insert into storage.objects (bucket_id, name, owner, metadata)
  values ('post-media', _alice::text || '/public.jpg', _alice, '{}'::jsonb);
end $$;
reset role;

-- ===== anon reads (bucket is public) =====
do $$
declare _ok boolean;
declare _n int;
begin
  perform set_config('request.jwt.claims',
    json_build_object('role', 'anon')::text, true);
  set local role anon;

  begin
    select count(*) into _n from storage.objects where bucket_id = 'post-media';
    _ok := _n > 0;
  exception when others then _ok := false; end;
  perform _storage_record('anon reads post-media (public)', _ok, 'allow');
end $$;
reset role;

-- ─── final result set ──────────────────────────────────────
select test, expected, actual, status
from _storage_audit
order by inserted_at;

rollback;
