-- Ofrivo Step 2: database, storage, RLS, and transactional foundation.
-- This migration is intended for a Supabase project. It does not connect to
-- Supabase Cloud by itself; apply it through the Supabase CLI in a later step.

begin;

create extension if not exists pgcrypto;

do $$
begin
  create type public.account_status as enum ('active', 'suspended', 'deleted');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.provider_verification_status as enum ('not_applied', 'pending', 'approved', 'rejected', 'suspended');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.job_status as enum ('draft', 'open', 'assigned', 'in_progress', 'completed', 'cancelled', 'expired');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.bid_status as enum ('pending', 'accepted', 'rejected', 'withdrawn', 'expired');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.report_status as enum ('open', 'reviewing', 'resolved', 'dismissed');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.urgency_level as enum ('normal', 'urgent');
exception when duplicate_object then null;
end $$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.path_job_id(object_name text)
returns uuid
language plpgsql
immutable
as $$
begin
  return split_part(object_name, '/', 1)::uuid;
exception when invalid_text_representation then
  return null;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  display_name text,
  phone text,
  whatsapp text,
  avatar_path text,
  account_status public.account_status not null default 'active',
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_full_name_length check (full_name is null or char_length(trim(full_name)) between 1 and 120),
  constraint profiles_display_name_length check (display_name is null or char_length(trim(display_name)) between 1 and 80)
);

create table if not exists public.provider_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  bio text,
  verification_status public.provider_verification_status not null default 'not_applied',
  rating_average numeric(3,2) not null default 0 check (rating_average between 0 and 5),
  rating_count integer not null default 0 check (rating_count >= 0),
  completed_jobs integer not null default 0 check (completed_jobs >= 0),
  is_available boolean not null default false,
  approved_at timestamptz,
  suspended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.service_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name_en text not null,
  name_ms text not null,
  name_zh text not null,
  icon_name text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  constraint service_categories_slug_format check (slug ~ '^[a-z0-9-]+$')
);

create table if not exists public.areas (
  id uuid primary key default gen_random_uuid(),
  state text not null,
  city text not null,
  area_name text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  unique (city, area_name)
);

create table if not exists public.provider_categories (
  provider_id uuid not null references public.provider_profiles(user_id) on delete cascade,
  category_id uuid not null references public.service_categories(id) on delete restrict,
  primary key (provider_id, category_id)
);

create table if not exists public.provider_areas (
  provider_id uuid not null references public.provider_profiles(user_id) on delete cascade,
  area_id uuid not null references public.areas(id) on delete restrict,
  primary key (provider_id, area_id)
);

create table if not exists public.provider_verifications (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.provider_profiles(user_id) on delete cascade,
  ic_front_path text,
  ic_back_path text,
  selfie_path text,
  ssm_path text,
  certificate_paths jsonb not null default '[]'::jsonb,
  status public.provider_verification_status not null default 'pending',
  admin_note text,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id) on delete set null,
  constraint provider_verifications_certificate_array check (jsonb_typeof(certificate_paths) = 'array')
);

create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete restrict,
  category_id uuid not null references public.service_categories(id) on delete restrict,
  area_id uuid not null references public.areas(id) on delete restrict,
  title text not null,
  description text not null,
  public_location_text text not null,
  full_address text not null,
  budget_amount numeric(12,2) not null check (budget_amount > 0),
  scheduled_at timestamptz,
  time_window text,
  urgency public.urgency_level not null default 'normal',
  status public.job_status not null default 'draft',
  accepted_bid_id uuid,
  contact_phone text,
  contact_whatsapp text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  expires_at timestamptz,
  constraint jobs_title_length check (char_length(trim(title)) between 3 and 160),
  constraint jobs_description_length check (char_length(trim(description)) between 1 and 5000),
  constraint jobs_public_location_length check (char_length(trim(public_location_text)) between 1 and 160)
);

create table if not exists public.job_photos (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  storage_path text not null,
  sort_order integer not null default 0 check (sort_order between 0 and 4),
  created_at timestamptz not null default now(),
  unique (job_id, sort_order)
);

create table if not exists public.bids (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  provider_id uuid not null references public.provider_profiles(user_id) on delete restrict,
  amount numeric(12,2) not null check (amount > 0),
  available_at timestamptz not null,
  inclusions text not null,
  exclusions text,
  materials_note text,
  message text,
  status public.bid_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bids_inclusions_length check (char_length(trim(inclusions)) between 1 and 2000)
);

alter table public.bids
  add constraint bids_id_job_id_key unique (id, job_id);

alter table public.jobs
  add constraint jobs_accepted_bid_fk
  foreign key (accepted_bid_id, id)
  references public.bids (id, job_id)
  deferrable initially immediate;

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id) on delete restrict,
  reviewee_id uuid not null references public.profiles(id) on delete restrict,
  rating integer not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique (job_id, reviewer_id),
  constraint reviews_different_users check (reviewer_id <> reviewee_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete restrict,
  reported_user_id uuid not null references public.profiles(id) on delete restrict,
  reason_code text not null,
  description text not null,
  evidence_paths jsonb not null default '[]'::jsonb,
  status public.report_status not null default 'open',
  admin_note text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  constraint reports_evidence_array check (jsonb_typeof(evidence_paths) = 'array'),
  constraint reports_different_users check (reporter_id <> reported_user_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  reference_type text,
  reference_id uuid,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android', 'ios', 'web')),
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.job_events (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  event_type text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists bids_one_active_per_provider_job
  on public.bids (job_id, provider_id)
  where status in ('pending', 'accepted');

create unique index if not exists bids_one_accepted_per_job
  on public.bids (job_id)
  where status = 'accepted';

create index if not exists jobs_status_created_at_idx on public.jobs (status, created_at desc);
create index if not exists jobs_category_area_status_idx on public.jobs (category_id, area_id, status);
create index if not exists jobs_customer_created_at_idx on public.jobs (customer_id, created_at desc);
create index if not exists bids_job_status_idx on public.bids (job_id, status);
create index if not exists bids_provider_created_at_idx on public.bids (provider_id, created_at desc);
create index if not exists provider_profiles_verification_status_idx on public.provider_profiles (verification_status);
create index if not exists notifications_user_read_created_idx on public.notifications (user_id, is_read, created_at desc);
create index if not exists reports_status_created_at_idx on public.reports (status, created_at desc);
create index if not exists job_events_job_created_at_idx on public.job_events (job_id, created_at desc);
create index if not exists job_photos_job_sort_order_idx on public.job_photos (job_id, sort_order);

create or replace function public.is_admin(p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select p.is_admin from public.profiles p where p.id = p_user_id), false);
$$;

create or replace function public.is_active_account(p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select p.account_status = 'active' from public.profiles p where p.id = p_user_id), false);
$$;

create or replace function public.is_approved_provider(p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    join public.provider_profiles pp on pp.user_id = p.id
    where p.id = p_user_id
      and p.account_status = 'active'
      and pp.verification_status = 'approved'
  );
$$;

create or replace function public.is_customer_job(p_job_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.jobs j
    where j.id = p_job_id
      and j.customer_id = p_user_id
  );
$$;

create or replace function public.is_open_job(p_job_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.jobs j
    where j.id = p_job_id
      and j.status = 'open'
  );
$$;

create or replace function public.is_accepted_job_provider(p_job_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.jobs j
    join public.bids b on b.id = j.accepted_bid_id
    where j.id = p_job_id
      and b.provider_id = p_user_id
      and j.status in ('assigned', 'in_progress', 'completed', 'cancelled')
  );
$$;

create or replace function public.can_read_job(p_job_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.jobs j
    where j.id = p_job_id
      and (
        j.customer_id = p_user_id
        or public.is_admin(p_user_id)
        or public.is_accepted_job_provider(p_job_id, p_user_id)
        or (
          j.status = 'open'
          and public.is_approved_provider(p_user_id)
          and exists (
            select 1
            from public.provider_categories pc
            where pc.provider_id = p_user_id
              and pc.category_id = j.category_id
          )
          and exists (
            select 1
            from public.provider_areas pa
            where pa.provider_id = p_user_id
              and pa.area_id = j.area_id
          )
        )
      )
  );
$$;

create or replace function public.prevent_profile_privilege_escalation()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if new.account_status is distinct from old.account_status
       or new.is_admin is distinct from old.is_admin then
      raise exception 'account status and admin flag are server-managed';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.prevent_provider_privilege_escalation()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if new.verification_status is distinct from old.verification_status
       or new.approved_at is distinct from old.approved_at
       or new.suspended_at is distinct from old.suspended_at then
      raise exception 'provider verification fields are server-managed';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.enforce_bid_eligibility()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_job_status public.job_status;
begin
  if new.status in ('pending', 'accepted') and not public.is_approved_provider(new.provider_id) then
    raise exception 'only an active approved provider can submit a bid';
  end if;

  if (tg_op = 'INSERT' and new.status = 'pending')
     or (tg_op = 'UPDATE' and new.status = 'pending' and old.status is distinct from new.status) then
    select status into v_job_status from public.jobs where id = new.job_id;
    if v_job_status is distinct from 'open' then
      raise exception 'bids can only be submitted to open jobs';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.prevent_verification_privilege_escalation()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if new.status is distinct from old.status
       or new.reviewed_at is distinct from old.reviewed_at
       or new.reviewed_by is distinct from old.reviewed_by
       or new.admin_note is distinct from old.admin_note then
      raise exception 'verification review fields are server-managed';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.validate_review_participants()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_customer_id uuid;
  v_provider_id uuid;
begin
  select j.customer_id, b.provider_id
    into v_customer_id, v_provider_id
  from public.jobs j
  left join public.bids b on b.id = j.accepted_bid_id
  where j.id = new.job_id and j.status = 'completed';

  if v_customer_id is null or v_provider_id is null then
    raise exception 'reviews require a completed job with an accepted provider';
  end if;
  if not ((new.reviewer_id = v_customer_id and new.reviewee_id = v_provider_id)
      or (new.reviewer_id = v_provider_id and new.reviewee_id = v_customer_id)) then
    raise exception 'review participants must be the customer and accepted provider';
  end if;
  return new;
end;
$$;

create or replace function public.validate_report_participants()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_customer_id uuid;
  v_provider_id uuid;
begin
  select j.customer_id, b.provider_id
    into v_customer_id, v_provider_id
  from public.jobs j
  left join public.bids b on b.id = j.accepted_bid_id
  where j.id = new.job_id;

  if v_customer_id is null or v_provider_id is null then
    raise exception 'reports require a job with an accepted provider';
  end if;
  if not ((new.reporter_id = v_customer_id and new.reported_user_id = v_provider_id)
      or (new.reporter_id = v_provider_id and new.reported_user_id = v_customer_id)) then
    raise exception 'report participants must be the customer and accepted provider';
  end if;
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
create trigger provider_profiles_set_updated_at before update on public.provider_profiles
for each row execute function public.set_updated_at();
create trigger jobs_set_updated_at before update on public.jobs
for each row execute function public.set_updated_at();
create trigger bids_set_updated_at before update on public.bids
for each row execute function public.set_updated_at();
create trigger profiles_protected_fields before update on public.profiles
for each row execute function public.prevent_profile_privilege_escalation();
create trigger provider_profiles_protected_fields before update on public.provider_profiles
for each row execute function public.prevent_provider_privilege_escalation();
create trigger provider_verifications_protected_fields before update on public.provider_verifications
for each row execute function public.prevent_verification_privilege_escalation();
create trigger bids_validate_eligibility before insert or update on public.bids
for each row execute function public.enforce_bid_eligibility();
create trigger reviews_validate_participants before insert on public.reviews
for each row execute function public.validate_review_participants();
create trigger reports_validate_participants before insert on public.reports
for each row execute function public.validate_report_participants();

create or replace view public.public_provider_directory as
select
  p.id,
  coalesce(p.display_name, p.full_name) as display_name,
  p.avatar_path,
  pp.bio,
  pp.rating_average,
  pp.rating_count,
  pp.completed_jobs,
  pp.is_available
from public.profiles p
join public.provider_profiles pp on pp.user_id = p.id
where p.account_status = 'active'
  and pp.verification_status = 'approved';

create or replace view public.public_job_feed as
select
  j.id,
  j.category_id,
  j.area_id,
  j.title,
  j.description,
  j.public_location_text,
  j.budget_amount,
  j.scheduled_at,
  j.time_window,
  j.urgency,
  j.created_at,
  count(b.id)::integer as bid_count
from public.jobs j
left join public.bids b on b.job_id = j.id and b.status in ('pending', 'accepted')
where j.status = 'open'
  and public.is_active_account()
  and public.is_approved_provider()
  and exists (select 1 from public.provider_categories pc where pc.provider_id = auth.uid() and pc.category_id = j.category_id)
  and exists (select 1 from public.provider_areas pa where pa.provider_id = auth.uid() and pa.area_id = j.area_id)
group by j.id;

grant select on public.public_provider_directory to authenticated;
grant select on public.public_job_feed to authenticated;

alter table public.profiles enable row level security;
alter table public.provider_profiles enable row level security;
alter table public.service_categories enable row level security;
alter table public.areas enable row level security;
alter table public.provider_categories enable row level security;
alter table public.provider_areas enable row level security;
alter table public.provider_verifications enable row level security;
alter table public.jobs enable row level security;
alter table public.job_photos enable row level security;
alter table public.bids enable row level security;
alter table public.reviews enable row level security;
alter table public.reports enable row level security;
alter table public.notifications enable row level security;
alter table public.device_tokens enable row level security;
alter table public.job_events enable row level security;

create policy profiles_select_self_or_admin on public.profiles
for select to authenticated
using (id = auth.uid() or public.is_admin());

create policy profiles_insert_self on public.profiles
for insert to authenticated
with check (id = auth.uid());

create policy profiles_update_self_or_admin on public.profiles
for update to authenticated
using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

create policy provider_profiles_select_safe on public.provider_profiles
for select to authenticated
using (
  user_id = auth.uid()
  or public.is_admin()
  or (
    verification_status = 'approved'
    and public.is_active_account()
    and exists (select 1 from public.profiles p where p.id = provider_profiles.user_id and p.account_status = 'active')
  )
);

create policy provider_profiles_insert_self on public.provider_profiles
for insert to authenticated
with check (user_id = auth.uid() and public.is_active_account());

create policy provider_profiles_update_self_or_admin on public.provider_profiles
for update to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

create policy service_categories_read_active on public.service_categories
for select to authenticated
using (is_active or public.is_admin());

create policy service_categories_admin_write on public.service_categories
for all to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy areas_read_active on public.areas
for select to authenticated
using (is_active or public.is_admin());

create policy areas_admin_write on public.areas
for all to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy provider_categories_self_or_admin on public.provider_categories
for all to authenticated
using (provider_id = auth.uid() or public.is_admin())
with check (provider_id = auth.uid() or public.is_admin());

create policy provider_areas_self_or_admin on public.provider_areas
for all to authenticated
using (provider_id = auth.uid() or public.is_admin())
with check (provider_id = auth.uid() or public.is_admin());

create policy provider_verifications_self_or_admin on public.provider_verifications
for select to authenticated
using (provider_id = auth.uid() or public.is_admin());

create policy provider_verifications_insert_self on public.provider_verifications
for insert to authenticated
with check (provider_id = auth.uid() and public.is_active_account());

create policy provider_verifications_update_self_or_admin on public.provider_verifications
for update to authenticated
using (provider_id = auth.uid() or public.is_admin())
with check (provider_id = auth.uid() or public.is_admin());

create policy jobs_select_owner_admin_assigned on public.jobs
for select to authenticated
using (
  customer_id = auth.uid()
  or public.is_admin()
  or public.is_accepted_job_provider(id)
);

create policy jobs_insert_customer on public.jobs
for insert to authenticated
with check (customer_id = auth.uid() and status = 'draft' and public.is_active_account());

create policy jobs_update_owner_or_admin on public.jobs
for update to authenticated
using ((customer_id = auth.uid() and status in ('draft', 'open')) or public.is_admin())
with check ((customer_id = auth.uid() and status in ('draft', 'open')) or public.is_admin());

create policy jobs_delete_draft_owner on public.jobs
for delete to authenticated
using (customer_id = auth.uid() and status = 'draft');

create policy job_photos_select_participant on public.job_photos
for select to authenticated
using (
  public.can_read_job(job_id)
);

create policy job_photos_insert_owner on public.job_photos
for insert to authenticated
with check (public.is_customer_job(job_id));

create policy job_photos_delete_owner_or_admin on public.job_photos
for delete to authenticated
using (public.is_customer_job(job_id) or public.is_admin());

create policy bids_select_owner_or_self on public.bids
for select to authenticated
using (
  provider_id = auth.uid()
  or public.is_admin()
  or public.is_customer_job(job_id)
);

create policy bids_insert_approved_provider on public.bids
for insert to authenticated
with check (
  provider_id = auth.uid()
  and status = 'pending'
  and public.is_approved_provider(auth.uid())
  and public.is_open_job(job_id)
);

create policy bids_update_pending_self_or_admin on public.bids
for update to authenticated
using ((provider_id = auth.uid() and status = 'pending') or public.is_admin())
with check ((provider_id = auth.uid() and status in ('pending', 'withdrawn')) or public.is_admin());

create policy reviews_select_participants_or_admin on public.reviews
for select to authenticated
using (reviewer_id = auth.uid() or reviewee_id = auth.uid() or public.is_admin());

create policy reviews_insert_participant on public.reviews
for insert to authenticated
with check (reviewer_id = auth.uid());

create policy reports_select_participants_or_admin on public.reports
for select to authenticated
using (reporter_id = auth.uid() or reported_user_id = auth.uid() or public.is_admin());

create policy reports_insert_reporter on public.reports
for insert to authenticated
with check (reporter_id = auth.uid() and public.is_active_account());

create policy reports_update_admin on public.reports
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy notifications_select_self_or_admin on public.notifications
for select to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy notifications_update_self on public.notifications
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy device_tokens_self on public.device_tokens
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy job_events_select_participants_or_admin on public.job_events
for select to authenticated
using (
  public.is_admin()
  or actor_id = auth.uid()
  or public.is_customer_job(job_id)
  or public.is_accepted_job_provider(job_id)
);

grant select, insert, update, delete on
  public.profiles,
  public.provider_profiles,
  public.service_categories,
  public.areas,
  public.provider_categories,
  public.provider_areas,
  public.provider_verifications,
  public.jobs,
  public.job_photos,
  public.bids,
  public.reviews,
  public.reports,
  public.notifications,
  public.device_tokens,
  public.job_events
to authenticated;

-- The service role is server-only and bypasses RLS. Grant it the table and
-- sequence privileges required by server workers and local integration tests.
grant select, insert, update, delete on
  public.profiles,
  public.provider_profiles,
  public.service_categories,
  public.areas,
  public.provider_categories,
  public.provider_areas,
  public.provider_verifications,
  public.jobs,
  public.job_photos,
  public.bids,
  public.reviews,
  public.reports,
  public.notifications,
  public.device_tokens,
  public.job_events
to service_role;

grant usage, select on all sequences in schema public to authenticated;
grant usage, select on all sequences in schema public to service_role;

revoke all on function public.is_admin(uuid) from public;
revoke all on function public.is_active_account(uuid) from public;
revoke all on function public.is_approved_provider(uuid) from public;
revoke all on function public.is_customer_job(uuid, uuid) from public;
revoke all on function public.is_open_job(uuid) from public;
revoke all on function public.is_accepted_job_provider(uuid, uuid) from public;
revoke all on function public.can_read_job(uuid, uuid) from public;
revoke all on function public.path_job_id(text) from public;
revoke all on function public.set_updated_at() from public;
revoke all on function public.prevent_profile_privilege_escalation() from public;
revoke all on function public.prevent_provider_privilege_escalation() from public;
revoke all on function public.prevent_verification_privilege_escalation() from public;
revoke all on function public.enforce_bid_eligibility() from public;
revoke all on function public.validate_review_participants() from public;
revoke all on function public.validate_report_participants() from public;
grant execute on function public.is_admin(uuid) to authenticated;
grant execute on function public.is_active_account(uuid) to authenticated;
grant execute on function public.is_approved_provider(uuid) to authenticated;
grant execute on function public.is_customer_job(uuid, uuid) to authenticated;
grant execute on function public.is_open_job(uuid) to authenticated;
grant execute on function public.is_accepted_job_provider(uuid, uuid) to authenticated;
grant execute on function public.can_read_job(uuid, uuid) to authenticated;
grant execute on function public.path_job_id(text) to authenticated;

-- Storage buckets are private except for avatars. Sensitive objects are only
-- accessible through RLS and short-lived signed URLs.
insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('job-photos', 'job-photos', false),
  ('provider-verifications', 'provider-verifications', false),
  ('report-evidence', 'report-evidence', false)
on conflict (id) do update set public = excluded.public;

create policy avatars_public_read on storage.objects
for select to public
using (bucket_id = 'avatars');

create policy avatars_owner_insert on storage.objects
for insert to authenticated
with check (bucket_id = 'avatars' and owner_id = auth.uid()::text);

create policy avatars_owner_update on storage.objects
for update to authenticated
using (bucket_id = 'avatars' and owner_id = auth.uid()::text)
with check (bucket_id = 'avatars' and owner_id = auth.uid()::text);

create policy avatars_owner_delete on storage.objects
for delete to authenticated
using (bucket_id = 'avatars' and owner_id = auth.uid()::text);

create policy job_photos_read_authorized on storage.objects
for select to authenticated
using (
  bucket_id = 'job-photos'
  and public.can_read_job(public.path_job_id(name))
);

create policy job_photos_owner_write on storage.objects
for all to authenticated
using (
  bucket_id = 'job-photos'
  and (public.is_customer_job(public.path_job_id(name)) or public.is_admin())
)
with check (
  bucket_id = 'job-photos'
  and (public.is_customer_job(public.path_job_id(name)) or public.is_admin())
);

create policy provider_verifications_owner_admin on storage.objects
for all to authenticated
using (
  bucket_id = 'provider-verifications'
  and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)
)
with check (
  bucket_id = 'provider-verifications'
  and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)
);

create policy report_evidence_reporter_admin on storage.objects
for all to authenticated
using (
  bucket_id = 'report-evidence'
  and (
    public.is_admin()
    or exists (select 1 from public.reports r where r.id = public.path_job_id(name) and r.reporter_id = auth.uid())
  )
)
with check (
  bucket_id = 'report-evidence'
  and (
    public.is_admin()
    or exists (select 1 from public.reports r where r.id = public.path_job_id(name) and r.reporter_id = auth.uid())
  )
);

create or replace function public.accept_bid(p_job_id uuid, p_bid_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_job public.jobs;
  v_bid public.bids;
begin
  if auth.uid() is null or not public.is_active_account() then
    raise exception 'authentication and an active account are required';
  end if;

  select * into v_job from public.jobs where id = p_job_id for update;
  if not found or v_job.customer_id <> auth.uid() then
    raise exception 'only the job owner can accept a bid';
  end if;
  if v_job.status <> 'open' then
    raise exception 'only open jobs can accept a bid';
  end if;

  select * into v_bid
  from public.bids
  where id = p_bid_id and job_id = p_job_id
  for update;
  if not found or v_bid.status <> 'pending' then
    raise exception 'the selected bid is no longer pending';
  end if;
  if not public.is_approved_provider(v_bid.provider_id) then
    raise exception 'the provider is no longer eligible';
  end if;

  update public.bids
  set status = 'accepted', updated_at = now()
  where id = v_bid.id;

  update public.bids
  set status = 'rejected', updated_at = now()
  where job_id = p_job_id and id <> v_bid.id and status = 'pending';

  update public.jobs
  set status = 'assigned', accepted_bid_id = v_bid.id, updated_at = now()
  where id = p_job_id;

  insert into public.job_events (job_id, actor_id, event_type, metadata)
  values (p_job_id, auth.uid(), 'bid_accepted', jsonb_build_object('bid_id', v_bid.id, 'provider_id', v_bid.provider_id));

  insert into public.notifications (user_id, type, title, body, reference_type, reference_id)
  values
    (v_bid.provider_id, 'bid_accepted', 'Your offer has been accepted', 'The customer address and contact details are now available.', 'job', p_job_id),
    (auth.uid(), 'job_assigned', 'Provider selected', 'Your job is now assigned.', 'job', p_job_id);

  return jsonb_build_object('job_id', p_job_id, 'bid_id', v_bid.id, 'provider_id', v_bid.provider_id, 'job_status', 'assigned');
end;
$$;

create or replace function public.start_job(p_job_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_job public.jobs;
begin
  if auth.uid() is null or not public.is_active_account() then
    raise exception 'authentication and an active account are required';
  end if;

  select * into v_job from public.jobs where id = p_job_id for update;
  if not found or v_job.status <> 'assigned' then
    raise exception 'only assigned jobs can be started';
  end if;
  if not exists (select 1 from public.bids b where b.id = v_job.accepted_bid_id and b.provider_id = auth.uid() and b.status = 'accepted') then
    raise exception 'only the accepted provider can start this job';
  end if;

  update public.jobs set status = 'in_progress', updated_at = now() where id = p_job_id;
  insert into public.job_events (job_id, actor_id, event_type) values (p_job_id, auth.uid(), 'job_started');
  insert into public.notifications (user_id, type, title, body, reference_type, reference_id)
  values (v_job.customer_id, 'job_started', 'Job started', 'Your provider marked the job as started.', 'job', p_job_id);

  return jsonb_build_object('job_id', p_job_id, 'job_status', 'in_progress');
end;
$$;

create or replace function public.complete_job(p_job_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_job public.jobs;
  v_provider_id uuid;
begin
  if auth.uid() is null or not public.is_active_account() then
    raise exception 'authentication and an active account are required';
  end if;

  select * into v_job from public.jobs where id = p_job_id for update;
  if not found or v_job.status <> 'in_progress' then
    raise exception 'only in-progress jobs can be completed';
  end if;
  select provider_id into v_provider_id from public.bids where id = v_job.accepted_bid_id and status = 'accepted';
  if v_provider_id is null or (auth.uid() <> v_job.customer_id and auth.uid() <> v_provider_id) then
    raise exception 'only the customer or accepted provider can complete this job';
  end if;

  update public.jobs set status = 'completed', updated_at = now() where id = p_job_id;
  update public.provider_profiles set completed_jobs = completed_jobs + 1 where user_id = v_provider_id;
  insert into public.job_events (job_id, actor_id, event_type) values (p_job_id, auth.uid(), 'job_completed');
  insert into public.notifications (user_id, type, title, body, reference_type, reference_id)
  values (
    case when auth.uid() = v_job.customer_id then v_provider_id else v_job.customer_id end,
    'job_completed', 'Job completed', 'The job is ready for review.', 'job', p_job_id
  );

  return jsonb_build_object('job_id', p_job_id, 'job_status', 'completed', 'provider_id', v_provider_id);
end;
$$;

create or replace function public.cancel_job(p_job_id uuid, p_reason text default null)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_job public.jobs;
  v_provider_id uuid;
  v_previous_status public.job_status;
  v_is_customer boolean;
  v_is_provider boolean;
begin
  if auth.uid() is null or not public.is_active_account() then
    raise exception 'authentication and an active account are required';
  end if;

  select * into v_job from public.jobs where id = p_job_id for update;
  if not found then raise exception 'job not found'; end if;
  select provider_id into v_provider_id from public.bids where id = v_job.accepted_bid_id;
  v_is_customer := v_job.customer_id = auth.uid();
  v_is_provider := v_provider_id = auth.uid();

  if not (v_is_customer or v_is_provider or public.is_admin()) then
    raise exception 'only a job participant or admin can cancel this job';
  end if;
  if v_job.status not in ('open', 'assigned', 'in_progress') then
    raise exception 'this job cannot be cancelled in its current state';
  end if;
  if v_job.status = 'in_progress' and not (v_is_customer or public.is_admin()) then
    raise exception 'an in-progress job requires the customer or admin to cancel';
  end if;

  v_previous_status := v_job.status;
  update public.jobs set status = 'cancelled', updated_at = now() where id = p_job_id;
  insert into public.job_events (job_id, actor_id, event_type, metadata)
  values (p_job_id, auth.uid(), 'job_cancelled', jsonb_build_object('previous_status', v_previous_status, 'reason', p_reason));

  if v_is_customer and v_provider_id is not null then
    insert into public.notifications (user_id, type, title, body, reference_type, reference_id)
    values (v_provider_id, 'job_cancelled', 'Job cancelled', 'A customer cancelled the job.', 'job', p_job_id);
  elsif v_provider_id is not null and v_is_provider then
    insert into public.notifications (user_id, type, title, body, reference_type, reference_id)
    values (v_job.customer_id, 'job_cancelled', 'Job cancelled', 'The accepted provider cancelled the job.', 'job', p_job_id);
  end if;

  return jsonb_build_object('job_id', p_job_id, 'job_status', 'cancelled', 'previous_status', v_previous_status);
end;
$$;

revoke all on function public.accept_bid(uuid, uuid) from public;
revoke all on function public.start_job(uuid) from public;
revoke all on function public.complete_job(uuid) from public;
revoke all on function public.cancel_job(uuid, text) from public;
grant execute on function public.accept_bid(uuid, uuid) to authenticated;
grant execute on function public.start_job(uuid) to authenticated;
grant execute on function public.complete_job(uuid) to authenticated;
grant execute on function public.cancel_job(uuid, text) to authenticated;

commit;
