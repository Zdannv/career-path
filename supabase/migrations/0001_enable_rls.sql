-- ============================================================================
-- 0001_enable_rls.sql
--
-- Turns on Row Level Security for every table that exists today.
--
-- Context: this project has been running with RLS off and a service_role key
-- reachable from the browser. Once that key is rotated to an anon key, every
-- query from the frontend arrives as `anon` or `authenticated` and is governed
-- by the policies below. Without them, an RLS-enabled table returns nothing.
--
-- Two shapes of table:
--   * knowledge base  -> readable by everyone, writable only by service_role
--   * user data       -> readable and writable only by the row's owner
--
-- Run in the Supabase SQL Editor, or `supabase db push`.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Knowledge base: public read, no client writes.
--    service_role bypasses RLS entirely, so admin/seed scripts still work.
-- ---------------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array[
    'education_levels',
    'education_majors',
    'skills',
    'careers',
    'career_skills'
  ]
  loop
    if to_regclass('public.' || t) is null then
      raise notice 'skipping %: table does not exist', t;
      continue;
    end if;

    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_read_all', t);
    execute format(
      'create policy %I on public.%I for select to anon, authenticated using (true)',
      t || '_read_all', t
    );
    raise notice 'RLS enabled on % (public read)', t;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 2. user_journeys: legacy table from the old anonymous flow.
--
--    It has no user_id column yet, so ownership cannot be expressed. Until
--    0002 adds accounts, lock it down to service_role only: the FastAPI
--    service already reaches it with the service key, and nothing else should.
--
--    Reads from the public share page (/student/journey/<id>) go through the
--    backend, not through the browser's Supabase client, so this does not
--    break the share link.
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.user_journeys') is null then
    raise notice 'skipping user_journeys: table does not exist';
    return;
  end if;

  alter table public.user_journeys enable row level security;

  -- No policy for anon/authenticated = deny all. Deliberate.
  drop policy if exists user_journeys_read_all on public.user_journeys;
  drop policy if exists user_journeys_insert_all on public.user_journeys;

  raise notice 'RLS enabled on user_journeys (service_role only)';
end $$;

-- ---------------------------------------------------------------------------
-- 3. Reusable owner policy helper.
--
--    Fase 1 adds profiles, user_career_goals, user_roadmaps, user_activities,
--    xp_ledger and friends. Every one of them carries a user_id referencing
--    auth.users. Call this once per table instead of hand-writing four
--    policies each time and getting one of them subtly wrong.
--
--    Example:  select public.apply_owner_rls('user_activities');
-- ---------------------------------------------------------------------------
create or replace function public.apply_owner_rls(
  target_table text,
  owner_column text default 'user_id'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if to_regclass('public.' || target_table) is null then
    raise exception 'table public.% does not exist', target_table;
  end if;

  execute format('alter table public.%I enable row level security', target_table);

  execute format('drop policy if exists %I on public.%I', target_table || '_owner_select', target_table);
  execute format('drop policy if exists %I on public.%I', target_table || '_owner_insert', target_table);
  execute format('drop policy if exists %I on public.%I', target_table || '_owner_update', target_table);
  execute format('drop policy if exists %I on public.%I', target_table || '_owner_delete', target_table);

  execute format(
    'create policy %I on public.%I for select to authenticated using (auth.uid() = %I)',
    target_table || '_owner_select', target_table, owner_column
  );
  execute format(
    'create policy %I on public.%I for insert to authenticated with check (auth.uid() = %I)',
    target_table || '_owner_insert', target_table, owner_column
  );
  execute format(
    'create policy %I on public.%I for update to authenticated using (auth.uid() = %I) with check (auth.uid() = %I)',
    target_table || '_owner_update', target_table, owner_column, owner_column
  );
  execute format(
    'create policy %I on public.%I for delete to authenticated using (auth.uid() = %I)',
    target_table || '_owner_delete', target_table, owner_column
  );
end $$;

comment on function public.apply_owner_rls(text, text) is
  'Enables RLS on a table and grants full access to the row owner only. Call once per user-owned table.';

commit;

-- ============================================================================
-- Verify afterwards:
--
--   select relname, relrowsecurity
--   from pg_class
--   where relnamespace = 'public'::regnamespace and relkind = 'r'
--   order by relname;
--
-- Every row should show relrowsecurity = true.
-- ============================================================================
