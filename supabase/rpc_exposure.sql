-- ============================================================
-- Lacuna — RPC exposure surface
--
-- Lists every public-schema function and which Supabase role
-- (anon / authenticated / service_role) can EXECUTE it.
--
-- How to use:
--   1. Run the query.
--   2. Look at the `anon` column. Anything with YES is callable
--      by anyone holding your bundled anon key — including
--      attackers who pull it out of the IPA.
--   3. For every YES, ask: is this *intentionally* public?
--      • Sign-up / sign-in helpers — yes
--      • Public read-only RPCs (e.g. trending posts) — maybe
--      • Anything that mutates state, reads private data, or
--        relies on auth.uid() — must be NO
--   4. To revoke anon access on a function:
--        revoke execute on function name(arg_types) from anon;
--        revoke execute on function name(arg_types) from public;
--
-- The `security` column shows DEFINER vs INVOKER. DEFINER funcs
-- run as the function owner (postgres) and bypass RLS. Audit
-- those manually for `auth.uid()` checks at the top.
-- ============================================================

select
  p.proname                                                  as function,
  pg_get_function_identity_arguments(p.oid)                  as args,
  case when has_function_privilege('anon',          p.oid, 'EXECUTE') then 'YES' else '-' end as anon,
  case when has_function_privilege('authenticated', p.oid, 'EXECUTE') then 'YES' else '-' end as authenticated,
  case when has_function_privilege('service_role',  p.oid, 'EXECUTE') then 'YES' else '-' end as service_role,
  case when p.prosecdef then 'DEFINER' else 'INVOKER' end    as security,
  pg_get_userbyid(p.proowner)                                as owner
from pg_proc p
where p.pronamespace = 'public'::regnamespace
  -- audit-harness helpers start with `_`
  and p.proname not like '\_%' escape '\'
order by
  has_function_privilege('anon', p.oid, 'EXECUTE') desc,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') desc,
  p.proname;

-- Optional: look only at SECURITY DEFINER functions (the ones
-- that bypass RLS) to manually verify each starts with an
-- `if auth.uid() is null then raise exception 'not_authenticated'`
-- guard. Uncomment to run.
--
-- select
--   p.proname,
--   pg_get_function_identity_arguments(p.oid) as args,
--   pg_get_functiondef(p.oid) as definition
-- from pg_proc p
-- where p.pronamespace = 'public'::regnamespace
--   and p.prosecdef = true
--   and p.proname not like '\_%' escape '\'
-- order by p.proname;
