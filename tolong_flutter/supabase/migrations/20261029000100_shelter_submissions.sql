-- TolongApp: community-submitted shelters, moderated by government reviewers.
-- Approved submissions are promoted into `shelters`, which the app merges with the bundled
-- dataset before ranking. The reviewer is the human gate; the checks below are the machine
-- gate a submitter cannot bypass even with a crafted request.
--
-- Role helpers (own_role / is_government / is_admin) come from 20261029000000_roles.sql;
-- touch_updated_at() from 20261018000000_profiles.sql.

-- ---- Reference data: official barangay names (PSGC-crosschecked) --------------
create table public.qc_barangays (
  name text primary key
);

insert into public.qc_barangays (name) values
  ('Alicia'),
  ('Amihan'),
  ('Apolonio Samson'),
  ('Baesa'),
  ('Bagbag'),
  ('Bagong Lipunan Ng Crame'),
  ('Bagong Pag-asa'),
  ('Bagong Silangan'),
  ('Bagumbayan'),
  ('Bagumbuhay'),
  ('Bahay Toro'),
  ('Balingasa'),
  ('Balong Bato'),
  ('Batasan Hills'),
  ('Bayanihan'),
  ('Blue Ridge A'),
  ('Blue Ridge B'),
  ('Botocan'),
  ('Bungad'),
  ('Camp Aguinaldo'),
  ('Capri'),
  ('Central'),
  ('Claro'),
  ('Commonwealth'),
  ('Culiat'),
  ('Damar'),
  ('Damayan'),
  ('Damayang Lagi'),
  ('Del Monte'),
  ('Dioquino Zobel'),
  ('Don Manuel'),
  ('Aurora'),
  ('Doña Imelda'),
  ('Doña Josefa'),
  ('Duyan-duyan'),
  ('E. Rodriguez'),
  ('East Kamias'),
  ('Escopa I'),
  ('Escopa II'),
  ('Escopa III'),
  ('Escopa IV'),
  ('Fairview'),
  ('Greater Lagro'),
  ('Gulod'),
  ('Holy Spirit'),
  ('Horseshoe'),
  ('Immaculate Concepcion'),
  ('Kaligayahan'),
  ('Kalusugan'),
  ('Kamuning'),
  ('Katipunan'),
  ('Kaunlaran'),
  ('Kristong Hari'),
  ('Krus Na Ligas'),
  ('Laging Handa'),
  ('Libis'),
  ('Lourdes'),
  ('Loyola Heights'),
  ('Maharlika'),
  ('Malaya'),
  ('Mangga'),
  ('Manresa'),
  ('Mariana'),
  ('Mariblo'),
  ('Marilag'),
  ('Masagana'),
  ('Masambong'),
  ('Matandang Balara'),
  ('Milagrosa'),
  ('N.S. Amoranto'),
  ('Nagkaisang Nayon'),
  ('Nayong Kanluran'),
  ('New Era'),
  ('North Fairview'),
  ('Novaliches Proper'),
  ('Obrero'),
  ('Old Capitol Site'),
  ('Paang Bundok'),
  ('Pag-ibig Sa Nayon'),
  ('Paligsahan'),
  ('Paltok'),
  ('Pansol'),
  ('Paraiso'),
  ('Pasong Putik Proper'),
  ('Pasong Tamo'),
  ('Payatas'),
  ('Phil-Am'),
  ('Pinagkaisahan'),
  ('Pinyahan'),
  ('Project 6'),
  ('Quirino 2-A'),
  ('Quirino 2-B'),
  ('Quirino 2-C'),
  ('Quirino 3-A'),
  ('Ramon Magsaysay'),
  ('Roxas'),
  ('Sacred Heart'),
  ('Saint Ignatius'),
  ('Saint Peter'),
  ('Salvacion'),
  ('San Agustin'),
  ('San Antonio'),
  ('San Bartolome'),
  ('San Isidro'),
  ('San Isidro Labrador'),
  ('San Jose'),
  ('San Martin De Porres'),
  ('San Roque'),
  ('San Vicente'),
  ('Sangandaan'),
  ('Santa Cruz'),
  ('Santa Lucia'),
  ('Santa Monica'),
  ('Santa Teresita'),
  ('Santo Cristo'),
  ('Santo Domingo'),
  ('Santo Niño'),
  ('Santol'),
  ('Sauyo'),
  ('Sienna'),
  ('Sikatuna Village'),
  ('Silangan'),
  ('Socorro'),
  ('South Triangle'),
  ('Tagumpay'),
  ('Talayan'),
  ('Talipapa'),
  ('Tandang Sora'),
  ('Tatalon'),
  ('Teachers Village East'),
  ('Teachers Village West'),
  ('U.P. Campus'),
  ('U.P. Village'),
  ('Ugong Norte'),
  ('Unang Sigaw'),
  ('Valencia'),
  ('Vasra'),
  ('Veterans Village'),
  ('Villa Maria Clara'),
  ('West Kamias'),
  ('West Triangle'),
  ('White Plains');

-- ---- Approved shelters --------------------------------------------------------
create table public.shelters (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 120),
  -- Quezon City envelope (qcApproxBounds in the app); a pin elsewhere fails here.
  lat double precision not null check (lat between 14.590 and 14.775),
  lng double precision not null check (lng between 120.985 and 121.135),
  facility_type text not null
    check (facility_type in ('school', 'coveredCourt', 'barangayHall', 'other')),
  barangay text not null references public.qc_barangays (name),
  address text check (char_length(address) <= 200),
  accessibility text check (char_length(accessibility) <= 200),
  capacity integer check (capacity between 1 and 100000),
  facilities text[] not null default '{}',
  source text not null,               -- 'submission:<uuid>' / 'bundled' / 'drrmo'
  status text check (status in ('active', 'closed')),
  submitted_by uuid references auth.users (id) on delete set null,
  approved_by uuid references auth.users (id),
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index shelters_near_idx on public.shelters (lat, lng);
create index shelters_queue_idx on public.shelters (created_at);

alter table public.shelters enable row level security;

-- Shelter locations are public data (not personal), so signed-out guests benefit too.
create policy "shelters_read_public" on public.shelters
  for select using (true);

-- Supabase grants ALL on new tables by default; trim to read-only. Writes happen only
-- through review_submission(), whose definer sees the table as owner.
revoke all on public.shelters from anon, authenticated;
grant select on public.shelters to anon, authenticated;

create trigger shelters_touch_updated_at
  before update on public.shelters
  for each row execute function public.touch_updated_at();

-- ---- Distance helper + dedupe ---------------------------------------------------
create function public.shelter_distance_m(
  a_lat double precision, a_lng double precision,
  b_lat double precision, b_lng double precision)
returns double precision
language sql
immutable
as $$
  select 2 * 6371000 * asin(sqrt(
    pow(sin(radians(b_lat - a_lat) / 2), 2)
    + cos(radians(a_lat)) * cos(radians(b_lat)) * pow(sin(radians(b_lng - a_lng) / 2), 2)))
$$;

-- ---- Pending submissions ---------------------------------------------------------
create table public.shelter_submissions (
  id uuid primary key default gen_random_uuid(),
  submitted_by uuid not null references auth.users (id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  lat double precision not null check (lat between 14.590 and 14.775),
  lng double precision not null check (lng between 120.985 and 121.135),
  facility_type text not null
    check (facility_type in ('school', 'coveredCourt', 'barangayHall', 'other')),
  barangay text not null references public.qc_barangays (name),
  address text check (char_length(address) <= 200),
  accessibility text check (char_length(accessibility) <= 200),
  capacity integer check (capacity between 1 and 100000),
  facilities text[] not null default '{}',
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  rejection_reason text
    check (status <> 'rejected' or (rejection_reason is not null
      and char_length(btrim(rejection_reason)) between 1 and 300)),
  reviewed_by uuid references auth.users (id),
  reviewed_at timestamptz,
  shelter_id uuid references public.shelters (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index submissions_own_idx on public.shelter_submissions (submitted_by, status);
create index submissions_queue_idx on public.shelter_submissions (status, created_at);

-- ---- Dedupe trigger function ------------------------------------------------------
-- Rejects rows duplicating an approved shelter (and duplicate *pending* submissions)
-- within 100 m straight-line. The bbox prefilter keeps the scan cheap; large campuses
-- can host distinct facilities closer together than a tight radius would like, which is
-- the case the reviewer corrects (or splits) by hand. security definer avoids recursing
-- into the submissions table's own RLS policies mid-trigger.
create function public.enforce_shelter_dedupe()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_dup text;
  v_radius constant double precision := 100;    -- meters, the tunable constant
  v_box constant double precision := 0.0012;    -- ~133 m of latitude in degrees
begin
  if tg_table_name = 'shelters' then
    select btrim(name) into v_dup from public.shelters
    where id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
      and lat between new.lat - v_box and new.lat + v_box
      and lng between new.lng - v_box and new.lng + v_box
      and public.shelter_distance_m(new.lat, new.lng, lat, lng) <= v_radius
    limit 1;
    if v_dup is not null then
      raise exception 'shelter "%" already exists within % m of this location',
        v_dup, v_radius using errcode = '23514';
    end if;
    return new;
  end if;

  -- Submissions table: an approved or rejected row was validated as pending already,
  -- and the approval UPDATE touches lat/lng but must not block on itself.
  if new.status <> 'pending' then
    return new;
  end if;

  select name into v_dup from public.shelters
  where lat between new.lat - v_box and new.lat + v_box
    and lng between new.lng - v_box and new.lng + v_box
    and public.shelter_distance_m(new.lat, new.lng, lat, lng) <= v_radius
  limit 1;
  if v_dup is null then
    select name into v_dup from public.shelter_submissions
    where id <> new.id and status = 'pending'
      and lat between new.lat - v_box and new.lat + v_box
      and lng between new.lng - v_box and new.lng + v_box
      and public.shelter_distance_m(new.lat, new.lng, lat, lng) <= v_radius
    limit 1;
  end if;
  if v_dup is not null then
    raise exception 'duplicate within % m of "%"', v_radius, v_dup
      using errcode = '23514';
  end if;
  return new;
end;
$$;

-- ---- Rate limit helper (pending cap per submitter) -------------------------------
-- Must exist before the insert policy that calls it (policy expressions are resolved
-- when the policy is created). security definer bypasses submissions RLS, avoiding the
-- self-referencing-policy trap.
create function public.pending_submission_count()
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::int from public.shelter_submissions
  where submitted_by = (select auth.uid()) and status = 'pending'
$$;

alter table public.shelter_submissions enable row level security;

create policy "submissions_select_own_or_gov" on public.shelter_submissions
  for select to authenticated
  using ((select auth.uid()) = submitted_by or public.is_government());

create policy "submissions_insert_own" on public.shelter_submissions
  for insert to authenticated
  with check (submitted_by = (select auth.uid())
              and status = 'pending'
              and public.pending_submission_count() < 5);

create policy "submissions_update_own_pending" on public.shelter_submissions
  for update to authenticated
  using ((select auth.uid()) = submitted_by and status = 'pending')
  with check ((select auth.uid()) = submitted_by and status = 'pending');
-- Status/reviewed_by/shelter_id are not in the update grant (below), so a submitter can
-- edit the fields of their own pending row but never transition it themselves.

create policy "submissions_delete_own_pending_or_gov" on public.shelter_submissions
  for delete to authenticated
  using (((select auth.uid()) = submitted_by and status = 'pending')
         or public.is_government());

-- Trim Supabase's default grants; hand out only what each action needs.
revoke all on public.shelter_submissions from anon, authenticated;
grant select on public.shelter_submissions to authenticated;
grant insert (submitted_by, name, lat, lng, facility_type, barangay,
              address, accessibility, capacity, facilities)
  on public.shelter_submissions to authenticated;
grant update (name, lat, lng, facility_type, barangay,
              address, accessibility, capacity, facilities)
  on public.shelter_submissions to authenticated;
grant delete on public.shelter_submissions to authenticated;

create trigger submissions_touch_updated_at
  before update on public.shelter_submissions
  for each row execute function public.touch_updated_at();

create trigger submissions_dedupe
  before insert or update of lat, lng on public.shelter_submissions
  for each row execute function public.enforce_shelter_dedupe();

create trigger shelters_dedupe
  before insert or update of lat, lng on public.shelters
  for each row execute function public.enforce_shelter_dedupe();

-- ---- Government review RPC ---------------------------------------------------------
-- The only way a submission becomes approved or rejected. Corrections are applied first;
-- the shelters table's own CHECKs and its dedupe trigger re-validate the corrected data,
-- so a reviewer cannot publish values the table itself would refuse. Users never call it;
-- is_government() is the gate even for a crafted request.
create function public.review_submission(
  p_id uuid,
  p_action text,                       -- 'approve' | 'edit' | 'reject'
  p_edits jsonb default null,          -- keys: name, lat, lng, facility_type, barangay,
                                       -- address, accessibility, capacity, facilities
  p_rejection_reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  s public.shelter_submissions;
  c public.shelter_submissions;
  v_shelter_id uuid;
begin
  if not public.is_government() then
    raise exception 'only government reviewers may act on submissions' using errcode = '42501';
  end if;

  select * into s from public.shelter_submissions where id = p_id and status = 'pending';
  if not found then
    raise exception 'submission not found or already reviewed' using errcode = '22023';
  end if;

  if p_action = 'reject' then
    if p_rejection_reason is null or btrim(p_rejection_reason) = ''
       or char_length(btrim(p_rejection_reason)) > 300 then
      raise exception 'a rejection needs a reason of at most 300 characters' using errcode = '22023';
    end if;
    update public.shelter_submissions
    set status = 'rejected',
        rejection_reason = btrim(p_rejection_reason),
        reviewed_by = (select auth.uid()),
        reviewed_at = now()
    where id = s.id;
    return;
  end if;

  -- 'edit' persists reviewer corrections on the pending row without deciding yet.
  if p_action = 'edit' then
    update public.shelter_submissions
    set name = coalesce(p_edits ->> 'name', s.name),
        lat = coalesce((p_edits ->> 'lat')::double precision, s.lat),
        lng = coalesce((p_edits ->> 'lng')::double precision, s.lng),
        facility_type = coalesce(p_edits ->> 'facility_type', s.facility_type),
        barangay = coalesce(p_edits ->> 'barangay', s.barangay),
        address = coalesce(p_edits ->> 'address', s.address),
        accessibility = coalesce(p_edits ->> 'accessibility', s.accessibility),
        capacity = coalesce((p_edits ->> 'capacity')::int, s.capacity),
        facilities = coalesce(
          (select array_agg(x #>> '{}') from jsonb_array_elements(p_edits -> 'facilities') x),
          s.facilities)
    where id = s.id;
    return;
  end if;

  if p_action <> 'approve' then
    raise exception 'action must be approve, edit or reject' using errcode = '22023';
  end if;

  -- Approve: overlay corrections onto a copy, then certify it through the real table.
  c := s;
  if p_edits is not null then
    c.name := coalesce(p_edits ->> 'name', s.name);
    c.lat := coalesce((p_edits ->> 'lat')::double precision, s.lat);
    c.lng := coalesce((p_edits ->> 'lng')::double precision, s.lng);
    c.facility_type := coalesce(p_edits ->> 'facility_type', s.facility_type);
    c.barangay := coalesce(p_edits ->> 'barangay', s.barangay);
    c.address := coalesce(p_edits ->> 'address', s.address);
    c.accessibility := coalesce(p_edits ->> 'accessibility', s.accessibility);
    c.capacity := coalesce((p_edits ->> 'capacity')::int, s.capacity);
    c.facilities := coalesce(
      (select array_agg(x #>> '{}') from jsonb_array_elements(p_edits -> 'facilities') x),
      s.facilities);
  end if;

  insert into public.shelters
    (name, lat, lng, facility_type, barangay, address, accessibility,
     capacity, facilities, source, submitted_by, approved_by, approved_at)
  values
    (c.name, c.lat, c.lng, c.facility_type, c.barangay, c.address,
     c.accessibility, c.capacity, c.facilities,
     'submission:' || s.submitted_by, s.submitted_by, (select auth.uid()), now())
  returning id into v_shelter_id;

  update public.shelter_submissions
  set status = 'approved',
      reviewed_by = (select auth.uid()),
      reviewed_at = now(),
      shelter_id = v_shelter_id,
      name = c.name, lat = c.lat, lng = c.lng, facility_type = c.facility_type,
      barangay = c.barangay, address = c.address, accessibility = c.accessibility,
      capacity = c.capacity, facilities = c.facilities
  where id = s.id;
end;
$$;

revoke execute on function public.review_submission(uuid, text, jsonb, text) from public, anon;
grant execute on function public.review_submission(uuid, text, jsonb, text) to authenticated;
