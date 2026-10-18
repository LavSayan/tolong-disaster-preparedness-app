-- TolongApp Phase 2: self-service account deletion without shipping a service-role key.
-- Store the language chosen at sign-up, and let users delete only their own auth user;
-- public.profiles rows go with it through "on delete cascade".

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, age, barangay, preferred_language, privacy_accepted_at)
  values (
    new.id,
    left(coalesce(new.raw_user_meta_data ->> 'full_name', ''), 120),
    nullif(new.raw_user_meta_data ->> 'age', '')::smallint,
    left(new.raw_user_meta_data ->> 'barangay', 80),
    case when new.raw_user_meta_data ->> 'preferred_language' = 'fil' then 'fil' else 'en' end,
    (new.raw_user_meta_data ->> 'privacy_accepted_at')::timestamptz
  );
  return new;
end;
$$;

create function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  delete from auth.users where id = uid;
end;
$$;

revoke execute on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
