-- TolongApp Phase 4: account backup / sync for household data.
-- One generic table of JSON documents keyed by (user, entity, record). The app keeps the
-- authoritative copy on-device (encrypted) and pushes changes here when online.
--
-- Conflict rule ("newer change wins"): a record is only overwritten by a copy whose
-- client_modified_at is the same or later. The app applies the same rule when pulling.

create table public.sync_records (
  user_id uuid not null references auth.users (id) on delete cascade,
  entity text not null check (entity in ('profile', 'household', 'contact', 'supply', 'checklist')),
  record_id text not null check (char_length(record_id) between 1 and 100),
  data jsonb,
  deleted boolean not null default false,
  client_modified_at timestamptz not null,
  server_updated_at timestamptz not null default now(),
  primary key (user_id, entity, record_id),
  -- Keep documents small; these are household records, not files.
  check (data is null or pg_column_size(data) <= 32768)
);

create index sync_records_pull_idx on public.sync_records (user_id, server_updated_at);

alter table public.sync_records enable row level security;

create policy "sync_select_own" on public.sync_records
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "sync_insert_own" on public.sync_records
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "sync_update_own" on public.sync_records
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- No delete policy: deletions are tombstones (deleted = true) so other devices learn about them.

-- Batch upsert used by the app. Runs as the caller, so the RLS policies above still apply.
create function public.sync_push(records jsonb)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  r jsonb;
begin
  if (select auth.uid()) is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if jsonb_typeof(records) <> 'array' or jsonb_array_length(records) > 500 then
    raise exception 'records must be an array of at most 500 items' using errcode = '22023';
  end if;

  for r in select * from jsonb_array_elements(records) loop
    insert into public.sync_records as s (user_id, entity, record_id, data, deleted, client_modified_at)
    values (
      (select auth.uid()),
      r ->> 'entity',
      r ->> 'record_id',
      case when coalesce((r ->> 'deleted')::boolean, false) then null else r -> 'data' end,
      coalesce((r ->> 'deleted')::boolean, false),
      (r ->> 'client_modified_at')::timestamptz
    )
    on conflict (user_id, entity, record_id) do update
      set data = excluded.data,
          deleted = excluded.deleted,
          client_modified_at = excluded.client_modified_at,
          server_updated_at = now()
      where s.client_modified_at <= excluded.client_modified_at;
  end loop;
end;
$$;

revoke execute on function public.sync_push(jsonb) from public, anon;
grant execute on function public.sync_push(jsonb) to authenticated;
