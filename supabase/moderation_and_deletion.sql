-- ============================================================
-- Lacuna — moderation + account deletion
-- Run AFTER the main schema. Safe to re-run; uses guards.
--
-- Provides the server side of:
--   • blocks UI         → block_user / unblock_user RPC + blocks table
--   • report sheet      → report_post / report_user RPC + reports table
--   • account deletion  → delete_my_account RPC (App Store Guideline 5.1.1(v))
-- ============================================================

create extension if not exists "pgcrypto";

-- ─── clean slate (safe to re-run pre-launch) ────────────────
-- Drops dependent objects first. Order matters: indexes are
-- killed implicitly by `drop table cascade`. Functions are
-- replaced by `create or replace` further down, but we drop
-- them too so signature changes don't fail silently.

drop table if exists reports cascade;
drop table if exists blocks  cascade;

drop function if exists block_user(uuid)               cascade;
drop function if exists unblock_user(uuid)             cascade;
drop function if exists report_post(uuid, text, text)  cascade;
drop function if exists report_user(uuid, text, text)  cascade;
drop function if exists delete_my_account()            cascade;

-- ─── tables ─────────────────────────────────────────────────

create table blocks (
  blocker_id uuid        not null references profiles(id) on delete cascade,
  blocked_id uuid        not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create index blocks_blocker_idx on blocks (blocker_id, created_at desc);
create index blocks_blocked_idx on blocks (blocked_id);

create table reports (
  id           uuid        primary key default gen_random_uuid(),
  reporter_id  uuid        not null references profiles(id) on delete cascade,
  post_id      uuid        references posts(id) on delete cascade,
  reported_user_id uuid    references profiles(id) on delete cascade,
  reason       text        not null,
  note         text        check (note is null or char_length(note) <= 1000),
  status       text        not null default 'pending'
                           check (status in ('pending', 'reviewing', 'actioned', 'dismissed')),
  created_at   timestamptz not null default now(),
  reviewed_at  timestamptz,
  reviewed_by  uuid,
  -- a report must target either a post or a user, not both, not neither
  check ((post_id is null) <> (reported_user_id is null))
);

create index reports_status_idx   on reports (status, created_at desc);
create index reports_post_idx     on reports (post_id);
create index reports_user_idx     on reports (reported_user_id);
create index reports_reporter_idx on reports (reporter_id, created_at desc);

-- ─── RLS ────────────────────────────────────────────────────

alter table blocks  enable row level security;
alter table reports enable row level security;

-- blocks: a user can only see their own block list
drop policy if exists "blocks: read own" on blocks;
create policy "blocks: read own"
  on blocks for select
  using (auth.uid() = blocker_id);

-- writes go through RPCs only
drop policy if exists "blocks: no direct writes" on blocks;
create policy "blocks: no direct writes"
  on blocks for all using (false) with check (false);

-- reports: a user can only see reports they themselves filed
drop policy if exists "reports: read own" on reports;
create policy "reports: read own"
  on reports for select
  using (auth.uid() = reporter_id);

drop policy if exists "reports: no direct writes" on reports;
create policy "reports: no direct writes"
  on reports for all using (false) with check (false);

-- ─── RPCs: blocking ────────────────────────────────────────

create or replace function block_user(_target_id uuid)
  returns void language plpgsql
  security definer set search_path = public as $$
declare _uid uuid := auth.uid(); begin
  if _uid is null then raise exception 'not_authenticated'; end if;
  if _uid = _target_id then raise exception 'self_block'; end if;

  if not check_rate_limit(_uid, 'block', 3600, 50) then
    raise exception 'rate_limited' using hint = 'Too many block actions in one hour';
  end if;

  -- block implies unfollow in both directions
  delete from follows
    where (follower_id = _uid and following_id = _target_id)
       or (follower_id = _target_id and following_id = _uid);

  insert into blocks (blocker_id, blocked_id) values (_uid, _target_id)
  on conflict do nothing;
end; $$;

create or replace function unblock_user(_target_id uuid)
  returns void language plpgsql
  security definer set search_path = public as $$
declare _uid uuid := auth.uid(); begin
  if _uid is null then raise exception 'not_authenticated'; end if;
  delete from blocks where blocker_id = _uid and blocked_id = _target_id;
end; $$;

-- ─── RPCs: reporting ───────────────────────────────────────

create or replace function report_post(
  _post_id uuid,
  _reason  text,
  _note    text default null
) returns void language plpgsql
  security definer set search_path = public as $$
declare _uid uuid := auth.uid(); begin
  if _uid is null then raise exception 'not_authenticated'; end if;

  if not check_rate_limit(_uid, 'report', 3600, 30) then
    raise exception 'rate_limited' using hint = 'Too many reports in one hour';
  end if;

  if not exists (select 1 from posts where id = _post_id) then
    raise exception 'not_found';
  end if;

  insert into reports (reporter_id, post_id, reason, note)
  values (_uid, _post_id, _reason, _note);
end; $$;

create or replace function report_user(
  _target_id uuid,
  _reason    text,
  _note      text default null
) returns void language plpgsql
  security definer set search_path = public as $$
declare _uid uuid := auth.uid(); begin
  if _uid is null then raise exception 'not_authenticated'; end if;
  if _uid = _target_id then raise exception 'self_report'; end if;

  if not check_rate_limit(_uid, 'report', 3600, 30) then
    raise exception 'rate_limited' using hint = 'Too many reports in one hour';
  end if;

  if not exists (select 1 from profiles where id = _target_id) then
    raise exception 'not_found';
  end if;

  insert into reports (reporter_id, reported_user_id, reason, note)
  values (_uid, _target_id, _reason, _note);
end; $$;

-- ─── RPC: account deletion (App Store Guideline 5.1.1(v)) ──
-- Removes the auth.users row. Cascades through profiles.id
-- (which references auth.users(id) on delete cascade) and from
-- there to every other table that references profiles(id) on
-- delete cascade — posts, votes, saves, follows, blocks, reports
-- where the user is the reporter, etc.
--
-- SECURITY: this is security definer because end users cannot
-- normally write to the auth schema. The function only deletes
-- the row matching auth.uid(); never accept a parameter that
-- selects which user to delete.
create or replace function delete_my_account()
  returns void language plpgsql
  security definer set search_path = public, auth as $$
declare _uid uuid := auth.uid(); begin
  if _uid is null then raise exception 'not_authenticated'; end if;
  delete from auth.users where id = _uid;
end; $$;

-- ─── grant execute (so authenticated role can call) ────────

grant execute on function block_user(uuid) to authenticated;
grant execute on function unblock_user(uuid) to authenticated;
grant execute on function report_post(uuid, text, text) to authenticated;
grant execute on function report_user(uuid, text, text) to authenticated;
grant execute on function delete_my_account() to authenticated;

-- ============================================================
-- IMPORTANT: feed RPC must filter blocked users
--
-- Whatever your `get_following_feed` (or equivalent) RPC looks
-- like, it MUST exclude posts where the author is in the
-- viewer's `blocks` list. Add this clause to its SELECT:
--
--   and not exists (
--     select 1 from blocks b
--     where b.blocker_id = auth.uid()
--       and b.blocked_id = posts.author_id
--   )
--
-- Same for any "search users" or "explore" RPC that returns
-- profiles — filter out blocked profiles from the viewer's POV.
-- ============================================================
