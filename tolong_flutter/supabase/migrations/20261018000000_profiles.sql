-- TolongApp Phase 1: account profiles.
-- Household details and emergency contacts stay on-device (encrypted) in Phase 1;
-- they get their own tables with the sync queue in Phase 4.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '' check (char_length(full_name) <= 120),
  age smallint check (age between 1 and 120),
  barangay text check (char_length(barangay) <= 80),
  preferred_language text not null default 'en' check (preferred_language in ('en', 'fil')),
  privacy_accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Each user can read and update only their own row. There is no insert or delete policy:
-- rows are created by the trigger below and removed with the auth user (on delete cascade).
create policy "profiles_select_own" on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);

create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Users may not rewrite when they accepted the privacy notice.
revoke update on public.profiles from authenticated;
grant update (full_name, age, barangay, preferred_language) on public.profiles to authenticated;

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, age, barangay, privacy_accepted_at)
  values (
    new.id,
    left(coalesce(new.raw_user_meta_data ->> 'full_name', ''), 120),
    nullif(new.raw_user_meta_data ->> 'age', '')::smallint,
    left(new.raw_user_meta_data ->> 'barangay', 80),
    (new.raw_user_meta_data ->> 'privacy_accepted_at')::timestamptz
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();
