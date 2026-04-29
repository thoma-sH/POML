-- ============================================================
-- Lacuna — RLS audit harness (v2 — actually works)
-- Run this in the Supabase SQL Editor (postgres role).
--
-- Why it failed before: setting request.jwt.claims alone is not
-- enough. The postgres role bypasses RLS no matter what. To get
-- realistic results you have to `set local role authenticated`
-- (or `anon`) so the policy machinery actually fires.
--
-- Output: at the end this script SELECTs a single result table
-- with one row per test. Look for status='UNEXPECTED' rows —
-- those are real security holes and must be fixed before launch.
--
-- Everything is wrapped in begin/rollback so the test users and
-- any rows they create never persist.
-- ============================================================

begin;

-- collect results here so they show up in the result pane
create temp table _audit (
  inserted_at timestamptz default clock_timestamp(),
  test        text,
  expected    text,
  actual      text,
  status      text
) on commit drop;

-- After we `set local role authenticated`, postgres-owned tables become
-- unwritable. _audit is a private temp table dropped at end of txn, so
-- granting public is harmless and saves us from per-role grants.
grant all on _audit to public;

create or replace function _audit_record(
  _label   text,
  _ok      boolean,
  _expect  text     -- 'allow' | 'deny'
) returns void language plpgsql as $$
declare _matched boolean;
begin
  _matched := (_ok and _expect = 'allow') or (not _ok and _expect = 'deny');
  insert into _audit (test, expected, actual, status)
  values (
    _label,
    _expect,
    case when _ok then 'allow' else 'deny' end,
    case when _matched then 'OK' else 'UNEXPECTED' end
  );
end; $$;

-- ─── seed two test users (postgres role, before role-switching) ─

do $$
declare _alice uuid := gen_random_uuid();
declare _bob   uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, raw_user_meta_data, aud, role)
  values
    (_alice, 'alice@lacuna.app', '{"username":"alice"}'::jsonb, 'authenticated', 'authenticated'),
    (_bob,   'bob@lacuna.app',   '{"username":"bob"}'::jsonb,   'authenticated', 'authenticated');

  perform set_config('audit.alice', _alice::text, false);
  perform set_config('audit.bob',   _bob::text,   false);
end $$;

-- ─── tests ─────────────────────────────────────────────────
-- Each `do $$ ... $$` block:
--   • sets request.jwt.claims (so auth.uid() returns the tester)
--   • set local role authenticated   (so RLS fires)
--   • runs ops in sub-BEGIN..EXCEPTION blocks to capture allow/deny
--   • reset role at the end so the next block starts clean

-- ===== profiles =====
do $$
declare _alice uuid := current_setting('audit.alice')::uuid;
declare _bob   uuid := current_setting('audit.bob')::uuid;
declare _ok boolean;
declare _rows bigint;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', _alice::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  begin perform * from profiles where id = _alice; _ok := true;
  exception when others then _ok := false; end;
  perform _audit_record('alice reads own profile', _ok, 'allow');

  begin perform * from profiles where id = _bob; _ok := true;
  exception when others then _ok := false; end;
  perform _audit_record('alice reads bob profile (public)', _ok, 'allow');

  begin
    update profiles set bio = 'hacked' where id = _bob;
    -- RLS on UPDATE: row count is what matters. update returning 0 rows = denied.
    get diagnostics _rows = row_count;
    _ok := _rows > 0;
  exception when others then _ok := false; end;
  perform _audit_record('alice updates bob profile (forbidden)', _ok, 'deny');

  begin
    update profiles set bio = 'mine' where id = _alice;
    get diagnostics _rows = row_count;
    _ok := _rows > 0;
  exception when others then _ok := false; end;
  perform _audit_record('alice updates own profile', _ok, 'allow');
end $$;
reset role;

-- ===== posts: direct insert blocked, RPC works =====
do $$
declare _alice uuid := current_setting('audit.alice')::uuid;
declare _post_id uuid;
declare _ok boolean;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', _alice::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  begin
    insert into posts (author_id, media_url, media_type)
    values (_alice, 'https://example.com/x.jpg', 'photo');
    _ok := true;
  exception when others then _ok := false; end;
  perform _audit_record('alice direct-inserts post (should require RPC)', _ok, 'deny');

  begin
    select create_post(
      _media_url := 'https://example.com/x.jpg',
      _media_type := 'photo'::media_type_enum
    ) into _post_id;
    _ok := _post_id is not null;
  exception when others then _ok := false; end;
  perform _audit_record('alice creates post via RPC', _ok, 'allow');

  if _post_id is not null then
    perform set_config('audit.post', _post_id::text, false);
  end if;
end $$;
reset role;

-- ===== posts: bob can't delete alice's =====
do $$
declare _bob uuid := current_setting('audit.bob')::uuid;
declare _post_id uuid := nullif(current_setting('audit.post', true), '')::uuid;
declare _ok boolean;
declare _rows bigint;
begin
  if _post_id is null then return; end if;
  perform set_config('request.jwt.claims',
    json_build_object('sub', _bob::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  begin
    delete from posts where id = _post_id;
    get diagnostics _rows = row_count;
    _ok := _rows > 0;
  exception when others then _ok := false; end;
  perform _audit_record('bob deletes alice post (forbidden)', _ok, 'deny');
end $$;
reset role;

-- ===== votes =====
do $$
declare _alice uuid := current_setting('audit.alice')::uuid;
declare _bob uuid := current_setting('audit.bob')::uuid;
declare _post_id uuid := nullif(current_setting('audit.post', true), '')::uuid;
declare _ok boolean;
begin
  if _post_id is null then return; end if;

  -- bob votes via RPC: allowed
  perform set_config('request.jwt.claims',
    json_build_object('sub', _bob::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  begin perform cast_vote(_post_id := _post_id, _fits := true); _ok := true;
  exception when others then _ok := false; end;
  perform _audit_record('bob votes on alice post via RPC', _ok, 'allow');

  reset role;

  -- alice tries to self-vote: denied
  perform set_config('request.jwt.claims',
    json_build_object('sub', _alice::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  begin perform cast_vote(_post_id := _post_id, _fits := true); _ok := true;
  exception when others then _ok := false; end;
  perform _audit_record('alice self-votes (forbidden)', _ok, 'deny');

  -- alice direct-inserts vote: denied
  begin
    insert into votes (post_id, voter_id, fits) values (_post_id, _alice, true);
    _ok := true;
  exception when others then _ok := false; end;
  perform _audit_record('alice direct-inserts vote (should require RPC)', _ok, 'deny');
end $$;
reset role;

-- ===== blocks =====
do $$
declare _alice uuid := current_setting('audit.alice')::uuid;
declare _bob uuid := current_setting('audit.bob')::uuid;
declare _ok boolean;
declare _seen_count int;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', _alice::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  begin perform block_user(_target_id := _bob); _ok := true;
  exception when others then _ok := false; end;
  perform _audit_record('alice blocks bob via RPC', _ok, 'allow');

  reset role;

  -- bob tries to read alice's block list: should see 0 rows (RLS hides)
  perform set_config('request.jwt.claims',
    json_build_object('sub', _bob::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  select count(*) into _seen_count from blocks where blocker_id = _alice;
  perform _audit_record('bob reads alice blocks (should be hidden)', _seen_count > 0, 'deny');
end $$;
reset role;

-- ===== reports =====
-- Strong version: alice files a report too, so the table contains
-- one row per user. A broken RLS would leak alice's row to bob.
do $$
declare _alice uuid := current_setting('audit.alice')::uuid;
declare _bob uuid := current_setting('audit.bob')::uuid;
declare _post_id uuid := nullif(current_setting('audit.post', true), '')::uuid;
declare _ok boolean;
declare _seen_count int;
declare _own_count int;
begin
  if _post_id is null then return; end if;

  -- bob files a report
  perform set_config('request.jwt.claims',
    json_build_object('sub', _bob::text, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform report_post(_post_id := _post_id, _reason := 'spam'); _ok := true;
  exception when others then _ok := false; end;
  perform _audit_record('bob reports alice post via RPC', _ok, 'allow');
  reset role;

  -- alice files a different report (against bob)
  perform set_config('request.jwt.claims',
    json_build_object('sub', _alice::text, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform report_user(_target_id := _bob, _reason := 'harassment'); _ok := true;
  exception when others then _ok := false; end;
  perform _audit_record('alice reports bob via RPC', _ok, 'allow');
  reset role;

  -- now from bob's POV: he must see only his own row, never alice's
  perform set_config('request.jwt.claims',
    json_build_object('sub', _bob::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  select count(*) into _seen_count from reports;
  select count(*) into _own_count from reports where reporter_id = _bob;

  -- bob should see exactly his own row(s); seeing more means RLS leaked alice's
  perform _audit_record(
    'bob sees only own reports (alice''s hidden)',
    _seen_count = _own_count and _own_count > 0,
    'allow'
  );
end $$;
reset role;

-- ===== rate_limits + audit_log are app-internal =====
do $$
declare _bob uuid := current_setting('audit.bob')::uuid;
declare _ok boolean;
declare _n int;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', _bob::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  -- empty result is fine; the test is whether the read errors or sees rows
  begin
    select count(*) into _n from rate_limits;
    _ok := _n > 0;
  exception when others then _ok := false; end;
  perform _audit_record('bob reads rate_limits (should be hidden)', _ok, 'deny');

  begin
    select count(*) into _n from audit_log;
    _ok := _n > 0;
  exception when others then _ok := false; end;
  perform _audit_record('bob reads audit_log (should be hidden)', _ok, 'deny');
end $$;
reset role;

-- ===== anon role =====
do $$
declare _post_id uuid := nullif(current_setting('audit.post', true), '')::uuid;
declare _ok boolean;
declare _n int;
begin
  perform set_config('request.jwt.claims',
    json_build_object('role', 'anon')::text, true);
  set local role anon;

  begin select count(*) into _n from profiles; _ok := true;
  exception when others then _ok := false; end;
  perform _audit_record('anon reads profiles (public OK)', _ok, 'allow');

  begin select count(*) into _n from posts where deleted_at is null; _ok := true;
  exception when others then _ok := false; end;
  perform _audit_record('anon reads posts (public OK)', _ok, 'allow');

  begin perform create_post(_media_url := 'https://x.com/x.jpg'); _ok := true;
  exception when others then _ok := false; end;
  perform _audit_record('anon creates post (forbidden)', _ok, 'deny');

  if _post_id is not null then
    begin perform cast_vote(_post_id := _post_id, _fits := true); _ok := true;
    exception when others then _ok := false; end;
    perform _audit_record('anon votes (forbidden)', _ok, 'deny');
  end if;
end $$;
reset role;

-- ===== account deletion + cascade =====
do $$
declare _alice uuid := current_setting('audit.alice')::uuid;
declare _ok boolean;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', _alice::text, 'role', 'authenticated')::text, true);
  set local role authenticated;

  begin perform delete_my_account(); _ok := true;
  exception when others then _ok := false; end;
  perform _audit_record('alice deletes own account', _ok, 'allow');
end $$;
reset role;

-- back to postgres for the cascade check
do $$
declare _alice uuid := current_setting('audit.alice')::uuid;
declare _gone boolean;
begin
  _gone := not exists (select 1 from profiles where id = _alice);
  perform _audit_record('alice profile cascade-deleted', _gone, 'allow');
  _gone := not exists (select 1 from auth.users where id = _alice);
  perform _audit_record('alice auth row cascade-deleted', _gone, 'allow');
end $$;

-- ─── final result set: shows in the SQL editor result pane ──
select test, expected, actual, status
from _audit
order by inserted_at;

rollback;
