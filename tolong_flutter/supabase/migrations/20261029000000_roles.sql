-- TolongApp: role-based access control (user / government / admin).
-- Accounts are seeded: there is no signup path that writes role. The first admin is
-- granted by the project owner from the Supabase dashboard SQL editor:
--   update public.profiles set role = 'admin' where id = '<uuid>';
-- Government officials are granted in-app by an admin through set_role(), so a new
-- official account always goes through the admin.
--
-- Users can never change their own role: the update grant on profiles (below) lists only
-- profile data columns, a discipline carried over from 20261018000000_profiles.sql.

alter table public.profiles
  add column role text not null default 'user'
    check (role in ('user', 'government', 'admin'));

-- The existing grant touched only profile data columns; spell it out again so adding the
-- role column cannot accidentally make it writable.
revoke update on public.profiles from authenticated;
grant update (full_name, age, barangay, preferred_language) on public.profiles to authenticated;

-- ---- Role helpers --------------------------------------------------------------
-- security definer so RLS policies on other tables can call them without recurring into
-- profiles RLS; explicit schema references only ('' search_path), as the repo does.
create function public.own_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.profiles where id = (select auth.uid())
$$;

-- Government OR admin may review submissions (admins cover when officials are unavailable).
create function public.is_government()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.own_role() in ('government', 'admin'), false)
$$;

create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.own_role() = 'admin', false)
$$;

-- ---- Admin account management ---------------------------------------------------
-- The only way a role changes after the seeded bootstrap. Admins cannot change their own
-- role here, so no admin can strand the instance without admin accounts by accident —
-- account recovery stays a dashboard operation by design.
create function public.set_role(p_target uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'only admins may change roles' using errcode = '42501';
  end if;
  if p_role not in ('user', 'government', 'admin') then
    raise exception 'unknown role' using errcode = '22023';
  end if;
  if p_target = (select auth.uid()) then
    raise exception 'admins cannot change their own role' using errcode = '22023';
  end if;
  update public.profiles set role = p_role where id = p_target;
end;
$$;

revoke execute on function public.set_role(uuid, text) from public, anon;
grant execute on function public.set_role(uuid, text) to authenticated;

-- Account directory for the admin screen: profiles carries no email (it lives in
-- auth.users), and admins must be able to find an official candidate by email.
create function public.admin_directory(p_email_query text)
returns table (id uuid, email text, full_name text, role text)
language sql
stable
security definer
set search_path = ''
as $$
  select u.id, u.email, p.full_name, p.role
  from public.profiles p
  join auth.users u on u.id = p.id
  where public.is_admin()
  and (p_email_query is null or btrim(p_email_query) = ''
       or u.email ilike '%' || btrim(p_email_query) || '%')
  order by p.full_name
  limit 50
$$;

revoke execute on function public.admin_directory(text) from public, anon;
grant execute on function public.admin_directory(text) to authenticated;
