# Shelter submissions and role-based access control

Community-submitted shelters, moderated by government reviewers, with three account roles.

## Why

The shelter ranking ([`SHELTER_RANKING_ML.md`](SHELTER_RANKING_ML.md)) scores the bundled
centre list. This feature lets the community *grow* that list safely: a signed-in user can
suggest a shelter, and a government reviewer confirms or rejects it before it appears in the
ranked list. The ranking engine is untouched — an approved shelter is simply *measured* by
the same pipeline (exposure from hazard bands at its coordinates, travel time from routes,
wheelchair accessibility) and scored with the same global weights (30 / 58.19 / 11.81).
Weights are **never** retrained per shelter; they are a single global policy.

## Roles

| Role | Granted by | Can |
|---|---|---|
| `user` | default on signup | Submit, edit, and withdraw their own pending submissions |
| `government` | an admin, in-app | Review the pending queue; correct fields; approve (publish) or reject (with a reason) |
| `admin` | project owner, in the Supabase dashboard | Everything a reviewer can, plus grant/revoke the `government` role |

Roles live in `profiles.role`. Users can never write the column — the update grant on
`profiles` lists only `full_name, age, barangay, preferred_language`. Granting a role always
goes through a `security definer` RPC that checks `is_admin()`, so no signup path can
self-assign. **Bootstrap:** the first admin is seeded by the owner with a one-line dashboard
statement (see the migration header). Admin + government both count as `is_government()`
(admins cover reviews when officials are unavailable).

## The two gates

A submission is only trusted because it passes **two** independent gates:

1. **Machine gate** (server-side, unavoidable by a crafted request): QC-bounds CHECK on
   lat/lng, barangay foreign key against the PSGC list, facility-type enum, capacity range,
   5-pending-per-user cap, and a 100 m straight-line dedupe trigger against both approved
   shelters and other pending submissions.
2. **Human gate**: a reviewer's decision through `review_submission`, which may correct any
   field before approving; corrections are re-validated by the same table CHECKs and the
   dedupe trigger.

Client-side validation mirrors the machine gate (`validateShelterSubmission`) so obvious
failures surface in the form, not after a round trip — the server is still the authority.

## Database

- `20261029000000_roles.sql` — `profiles.role`, `own_role()`, `is_government()`, `is_admin()`,
  `set_role()`, `admin_directory()`.
- `20261029000100_shelter_submissions.sql` — `qc_barangays` (seeded from
  `assets/data/qc_barangays.json`), `shelters` (approved, anon-readable), `shelter_submissions`
  (pending → approved/rejected), `shelter_distance_m`, `enforce_shelter_dedupe`,
  `pending_submission_count`, `review_submission`.

RLS highlights: `shelters` is read-only and public (locations are not personal data);
`shelter_submissions` lets a submitter see/insert/edit/delete only their own *pending* rows
(column grants exclude `status`, `reviewed_by`, `shelter_id`), while reviewers reach
everything through the `review_submission` RPC and the `is_government()` select policy.

## App flow

- **Submit / edit:** `SubmitShelterScreen` (also used in edit mode via the `/submit-shelter`
  route `extra`). A pin preview reuses the swappable map builder; coordinates are authoritative
  and editable, so the preview never invents a position. `SubmitShelterService` runs
  `validateShelterSubmission` and the pending-cap check locally, then calls the repository.
- **Status:** `MySubmissionsScreen` lists the caller's own submissions with status and, for
  rejections, the reviewer's note. Pending rows can be edited or withdrawn.
- **Review:** `ReviewSheltersScreen` (government/admin) shows the pending queue with each
  submission's hazard-exposure preview — neutral 0.5 with an explicit "not measured here"
  disclosure when the pin is outside the sampled hazard-band radius — plus corrections,
  approve, and reject. Every decision goes through the server RPC.
- **Admin:** `AdminAccountsScreen` searches accounts by email and promotes/demotes
  reviewers through `set_role`.
- **Merge:** `evacuationCentersProvider` now returns the bundled asset merged with
  government-approved shelters (`mergeCenters`), refreshed online and cached in the encrypted
  vault for offline use. Failures never invent centers — they fall back to the cache, then the
  bundled asset alone.

Routes: `/submit-shelter` (authenticated), `/my-submissions` (authenticated),
`/review-shelters` (reviewer), `/admin` (admin). `redirectFor` fails closed: an unverified
role is treated as no privilege, so deep links into review/admin land on `/home`.

## Honesty constraints (unchanged)

Approved shelters carry `verified: true` and their government source + approval date. The
ranking still discloses unknown exposure rather than inventing a number, and the neutral
accessibility precedent (0.5) applies to unmetered shelters exactly as before.

## Seeding the first admin

```sql
update public.profiles set role = 'admin' where id = '<uuid>';
```

Read the account's `uuid` from Supabase **Authentication → Users**, then run the statement in
the SQL editor. There is no in-app path that creates an admin — that bootstrap must stay a
dashboard operation.

## Testing against a live Supabase project

### 1. Apply the migrations, in filename order

In the Supabase Dashboard → SQL Editor (New query), run each file top-to-bottom in this
order — they reference each other:

1. `supabase/migrations/20261018000000_profiles.sql` (pre-existing)
2. `supabase/migrations/20261019000000_delete_own_account.sql` (pre-existing)
3. `supabase/migrations/20261020000000_sync_records.sql` (pre-existing)
4. `supabase/migrations/20261029000000_roles.sql`
5. `supabase/migrations/20261029000100_shelter_submissions.sql`

(Or link the project with the Supabase CLI and run `supabase db push`.)

### 2. Wire the app

- Add the Supabase **URL** and **publishable (anon) key** to `tolong_flutter/env.json` as
  `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` (never commit it), then run the app with
  `flutter run --dart-define-from-file=env.json`.
- In Authentication → URL Configuration, add the redirect URL `io.tolongapp://login-callback`.
- For faster test signups, disable **Confirm email** (Authentication → Providers → Email)
  so new accounts are immediately signed in.

### 3. Bootstrap the first admin

Pick the admin account's UUID from **Authentication → Users**, then run:

```sql
update public.profiles set role = 'admin' where id = '<uuid>';
```

### 4. Walk the happy path

1. Sign up three accounts: `admin@test`, `official@test`, `resident@test` (any passwords).
2. Seed `admin@test` as admin (step 3).
3. As admin in the app: **More → Manage accounts** → search `official@test` → *Make government reviewer*.
4. As `resident@test`: **Safe places → Add a shelter** → fill the form (use *Use my location*
   or enter coordinates inside Quezon City) → *Send for review*.
5. As `official@test`: **More → Review shelter submissions** → confirm the exposure preview →
   correct any field if needed → *Approve and publish*.
6. Everyone: the shelter now appears in the ranked Safe Places list, labelled
   government-verified (with "exposure not measured here" if the pin sits outside the
   hazard-band radius).

### 5. Check the guardrails

- **Duplicate:** a second submission within 100 m of an existing shelter/pending submission is
  rejected with a duplicate message (server trigger, SQLSTATE `23514`).
- **Pending cap:** a user's 6th pending submission is refused (limit 5).
- **Least privilege:** `select role from public.profiles where id = auth.uid()` stays `user`
  even for the reviewer; only the seeded admin can change roles.
- **RPC gating:** calling `review_submission(...)` as a non-reviewer raises `42501`.
- **Barangay list:** `select count(*) from public.qc_barangays;` → `142` (the Doña/Santo Niño
  names match the app dropdown exactly).

### 6. Known caveats

- `admin_directory` reads `auth.users.email`; if the `postgres` role cannot read `auth.users`
  in your project, grant it `select` on `auth.users` (or surface email through a
  `security definer` wrapper owned by `supabase_auth_admin`).
