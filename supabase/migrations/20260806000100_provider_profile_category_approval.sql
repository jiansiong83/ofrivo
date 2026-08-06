begin;

-- Provider category requests are deliberately separate from provider identity
-- verification. Existing rows are approved for backwards compatibility; every
-- newly selected category must pass an Admin review before it can match jobs.
do $$
begin
  create type public.provider_category_status as enum ('pending', 'approved', 'rejected');
exception when duplicate_object then null;
end $$;

alter table public.provider_categories
  add column if not exists status public.provider_category_status not null default 'approved',
  add column if not exists submitted_at timestamptz not null default now(),
  add column if not exists reviewed_at timestamptz,
  add column if not exists reviewed_by uuid references public.profiles(id) on delete set null,
  add column if not exists admin_note text;

create index if not exists provider_categories_provider_status_idx
  on public.provider_categories (provider_id, status);
create index if not exists provider_categories_category_status_idx
  on public.provider_categories (category_id, status);

create or replace function public.prevent_provider_category_privilege_escalation()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is not null
     and not public.is_admin()
     and coalesce(current_setting('ofrivo.provider_category_submission', true), '') <> 'on' then
    if new.provider_id is distinct from old.provider_id
       or new.category_id is distinct from old.category_id
       or new.status is distinct from old.status
       or new.submitted_at is distinct from old.submitted_at
       or new.reviewed_at is distinct from old.reviewed_at
       or new.reviewed_by is distinct from old.reviewed_by
       or new.admin_note is distinct from old.admin_note then
      raise exception 'provider category review fields are server-managed';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists provider_categories_privilege_escalation on public.provider_categories;
create trigger provider_categories_privilege_escalation
before update on public.provider_categories
for each row execute function public.prevent_provider_category_privilege_escalation();

drop policy if exists provider_categories_self_or_admin on public.provider_categories;
create policy provider_categories_select_self_or_admin on public.provider_categories
for select to authenticated
using (provider_id = auth.uid() or public.is_admin());

create policy provider_categories_insert_self_or_admin on public.provider_categories
for insert to authenticated
with check (
  public.is_admin()
  or (
    provider_id = auth.uid()
    and status = 'pending'
    and reviewed_at is null
    and reviewed_by is null
    and admin_note is null
    and public.is_active_account()
  )
);

create policy provider_categories_update_self_or_admin on public.provider_categories
for update to authenticated
using (provider_id = auth.uid() or public.is_admin())
with check (provider_id = auth.uid() or public.is_admin());

create policy provider_categories_delete_self_or_admin on public.provider_categories
for delete to authenticated
using (provider_id = auth.uid() or public.is_admin());

-- Initial applications create pending category requests. This replacement is
-- intentionally kept in the same migration so a reset has one deterministic
-- implementation of the application workflow.
create or replace function public.submit_provider_application(
  p_display_name text,
  p_bio text,
  p_category_ids uuid[],
  p_area_ids uuid[],
  p_ic_front_path text,
  p_ic_back_path text,
  p_selfie_path text,
  p_ssm_path text default null,
  p_certificate_paths jsonb default '[]'::jsonb,
  p_work_photo_paths text[] default '{}'::text[]
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_current_status public.provider_verification_status;
  v_now timestamptz := now();
begin
  if auth.uid() is null or not public.is_active_account() then
    raise exception 'authentication and an active account are required';
  end if;
  if char_length(trim(coalesce(p_display_name, ''))) not between 2 and 80 then
    raise exception 'display name must be between 2 and 80 characters';
  end if;
  if char_length(trim(coalesce(p_bio, ''))) not between 10 and 2000 then
    raise exception 'provider bio must be between 10 and 2000 characters';
  end if;
  if p_category_ids is null or cardinality(p_category_ids) < 1 or cardinality(p_category_ids) > 6 then
    raise exception 'choose between 1 and 6 service categories';
  end if;
  if p_area_ids is null or cardinality(p_area_ids) < 1 or cardinality(p_area_ids) > 10 then
    raise exception 'choose between 1 and 10 service areas';
  end if;
  if p_ic_front_path is null or p_ic_back_path is null or p_selfie_path is null then
    raise exception 'identity front, identity back, and selfie are required';
  end if;
  if p_certificate_paths is null or jsonb_typeof(p_certificate_paths) <> 'array' or jsonb_array_length(p_certificate_paths) > 5 then
    raise exception 'certificate evidence must contain no more than 5 files';
  end if;
  if p_work_photo_paths is null or cardinality(p_work_photo_paths) > 6 then
    raise exception 'work photos must contain no more than 6 files';
  end if;
  if exists (
    select 1 from unnest(array[p_ic_front_path, p_ic_back_path, p_selfie_path] || case when p_ssm_path is null then array[]::text[] else array[p_ssm_path] end) as paths(path)
    where path not like auth.uid()::text || '/%'
  ) then
    raise exception 'verification files must belong to the authenticated provider';
  end if;
  if exists (select 1 from jsonb_array_elements_text(p_certificate_paths) as paths(path) where path not like auth.uid()::text || '/%') then
    raise exception 'certificate files must belong to the authenticated provider';
  end if;
  if exists (select 1 from unnest(p_work_photo_paths) as paths(path) where path not like auth.uid()::text || '/%') then
    raise exception 'work photos must belong to the authenticated provider';
  end if;
  if exists (select 1 from unnest(p_category_ids) as selected(id) where not exists (select 1 from public.service_categories c where c.id = selected.id and c.is_active))
     or cardinality(p_category_ids) <> (select count(distinct id) from unnest(p_category_ids) as selected(id)) then
    raise exception 'one or more service categories are invalid';
  end if;
  if exists (select 1 from unnest(p_area_ids) as selected(id) where not exists (select 1 from public.areas a where a.id = selected.id and a.is_active))
     or cardinality(p_area_ids) <> (select count(distinct id) from unnest(p_area_ids) as selected(id)) then
    raise exception 'one or more service areas are invalid';
  end if;

  select verification_status into v_current_status from public.provider_profiles where user_id = auth.uid();
  if v_current_status in ('approved', 'suspended') then
    raise exception 'this provider account cannot submit another application';
  end if;

  perform set_config('ofrivo.provider_application', 'on', true);
  perform set_config('ofrivo.provider_category_submission', 'on', true);

  insert into public.profiles (id, display_name)
  values (auth.uid(), trim(p_display_name))
  on conflict (id) do update set display_name = excluded.display_name, updated_at = v_now;

  insert into public.provider_profiles (user_id, bio, verification_status, is_available, approved_at, suspended_at)
  values (auth.uid(), trim(p_bio), 'pending', false, null, null)
  on conflict (user_id) do update set bio = excluded.bio, verification_status = 'pending', is_available = false, approved_at = null, suspended_at = null, updated_at = v_now;

  delete from public.provider_categories where provider_id = auth.uid();
  insert into public.provider_categories (provider_id, category_id, status, submitted_at)
  select auth.uid(), id, 'pending', v_now from unnest(p_category_ids) as selected(id);

  delete from public.provider_areas where provider_id = auth.uid();
  insert into public.provider_areas (provider_id, area_id)
  select auth.uid(), id from unnest(p_area_ids) as selected(id);

  insert into public.provider_verifications (provider_id, ic_front_path, ic_back_path, selfie_path, ssm_path, certificate_paths, status, submitted_at)
  values (auth.uid(), p_ic_front_path, p_ic_back_path, p_selfie_path, p_ssm_path, p_certificate_paths, 'pending', v_now);

  delete from public.provider_work_photos where provider_id = auth.uid();
  insert into public.provider_work_photos (provider_id, storage_path, sort_order)
  select auth.uid(), path, ordinality - 1 from unnest(p_work_photo_paths) with ordinality as photos(path, ordinality);

  return jsonb_build_object('provider_id', auth.uid(), 'status', 'pending', 'submitted_at', v_now);
end;
$$;

create or replace function public.submit_provider_category_changes(p_category_ids uuid[])
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_now timestamptz := now();
  v_status public.provider_verification_status;
begin
  if auth.uid() is null or not public.is_active_account() then
    raise exception 'authentication and an active account are required';
  end if;
  select verification_status into v_status from public.provider_profiles where user_id = auth.uid();
  if v_status is distinct from 'approved' then
    raise exception 'only an approved provider can update service categories';
  end if;
  if p_category_ids is null or cardinality(p_category_ids) < 1 or cardinality(p_category_ids) > 6 then
    raise exception 'choose between 1 and 6 service categories';
  end if;
  if exists (select 1 from unnest(p_category_ids) selected(id) where not exists (select 1 from public.service_categories c where c.id = selected.id and c.is_active))
     or cardinality(p_category_ids) <> (select count(distinct id) from unnest(p_category_ids) selected(id)) then
    raise exception 'one or more service categories are invalid';
  end if;

  perform set_config('ofrivo.provider_category_submission', 'on', true);
  delete from public.provider_categories pc where pc.provider_id = auth.uid() and not (pc.category_id = any(p_category_ids));

  insert into public.provider_categories (provider_id, category_id, status, submitted_at, reviewed_at, reviewed_by, admin_note)
  select auth.uid(), selected.id, 'pending', v_now, null, null, null
  from unnest(p_category_ids) selected(id)
  where not exists (select 1 from public.provider_categories pc where pc.provider_id = auth.uid() and pc.category_id = selected.id);

  update public.provider_categories pc
  set status = 'pending', submitted_at = v_now, reviewed_at = null, reviewed_by = null, admin_note = null
  where pc.provider_id = auth.uid()
    and pc.category_id = any(p_category_ids)
    and pc.status = 'rejected';

  return jsonb_build_object(
    'provider_id', auth.uid(),
    'approved_count', (select count(*) from public.provider_categories where provider_id = auth.uid() and status = 'approved'),
    'pending_count', (select count(*) from public.provider_categories where provider_id = auth.uid() and status = 'pending')
  );
end;
$$;

create or replace function public.update_provider_profile(
  p_display_name text,
  p_bio text,
  p_phone text default null,
  p_whatsapp text default null,
  p_area_ids uuid[] default '{}'::uuid[],
  p_work_photo_paths text[] default '{}'::text[]
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_now timestamptz := now();
begin
  if auth.uid() is null or not public.is_active_account() then
    raise exception 'authentication and an active account are required';
  end if;
  if char_length(trim(coalesce(p_display_name, ''))) not between 2 and 80 then
    raise exception 'display name must be between 2 and 80 characters';
  end if;
  if char_length(trim(coalesce(p_bio, ''))) not between 10 and 2000 then
    raise exception 'provider bio must be between 10 and 2000 characters';
  end if;
  if p_area_ids is null or cardinality(p_area_ids) < 1 or cardinality(p_area_ids) > 10 then
    raise exception 'choose between 1 and 10 service areas';
  end if;
  if exists (select 1 from unnest(p_area_ids) selected(id) where not exists (select 1 from public.areas a where a.id = selected.id and a.is_active))
     or cardinality(p_area_ids) <> (select count(distinct id) from unnest(p_area_ids) selected(id)) then
    raise exception 'one or more service areas are invalid';
  end if;
  if p_work_photo_paths is null or cardinality(p_work_photo_paths) > 6 then
    raise exception 'work photos must contain no more than 6 files';
  end if;
  if exists (select 1 from unnest(p_work_photo_paths) paths(path) where path not like auth.uid()::text || '/%') then
    raise exception 'work photos must belong to the authenticated provider';
  end if;

  perform set_config('ofrivo.provider_profile_update', 'on', true);
  update public.profiles set display_name = trim(p_display_name), phone = nullif(trim(coalesce(p_phone, '')), ''), whatsapp = nullif(trim(coalesce(p_whatsapp, '')), ''), updated_at = v_now where id = auth.uid();
  update public.provider_profiles set bio = trim(p_bio), updated_at = v_now where user_id = auth.uid();
  if not found then raise exception 'provider profile not found'; end if;

  delete from public.provider_areas where provider_id = auth.uid();
  insert into public.provider_areas (provider_id, area_id) select auth.uid(), id from unnest(p_area_ids) selected(id);
  delete from public.provider_work_photos where provider_id = auth.uid();
  insert into public.provider_work_photos (provider_id, storage_path, sort_order)
  select auth.uid(), path, ordinality - 1 from unnest(p_work_photo_paths) with ordinality as photos(path, ordinality);

  return jsonb_build_object('provider_id', auth.uid(), 'updated_at', v_now);
end;
$$;

create or replace function public.set_provider_availability(p_is_available boolean)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status public.provider_verification_status;
begin
  if auth.uid() is null or not public.is_active_account() then
    raise exception 'authentication and an active account are required';
  end if;
  select verification_status into v_status from public.provider_profiles where user_id = auth.uid();
  if v_status is distinct from 'approved' and p_is_available then
    raise exception 'only an approved provider can receive new jobs';
  end if;
  update public.provider_profiles set is_available = coalesce(p_is_available, false), updated_at = now() where user_id = auth.uid();
  if not found then raise exception 'provider profile not found'; end if;
  return jsonb_build_object('provider_id', auth.uid(), 'is_available', coalesce(p_is_available, false));
end;
$$;

create or replace function public.review_provider_category(
  p_provider_id uuid,
  p_category_id uuid,
  p_status public.provider_category_status,
  p_admin_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_now timestamptz := now();
  v_note text := nullif(trim(coalesce(p_admin_note, '')), '');
  v_name text;
  v_type text;
begin
  if auth.uid() is null or not public.is_admin() then raise exception 'an authenticated admin is required'; end if;
  if p_status not in ('approved', 'rejected') then raise exception 'category review must approve or reject'; end if;
  select name_en into v_name from public.service_categories where id = p_category_id;
  if v_name is null then raise exception 'service category not found'; end if;
  update public.provider_categories
  set status = p_status, reviewed_at = v_now, reviewed_by = auth.uid(), admin_note = v_note
  where provider_id = p_provider_id and category_id = p_category_id and status = 'pending';
  if not found then raise exception 'pending provider category request not found'; end if;

  v_type := case when p_status = 'approved' then 'provider_category_approved' else 'provider_category_rejected' end;
  insert into public.notifications (user_id, type, title, body, reference_type, reference_id)
  values (
    p_provider_id,
    v_type,
    case when p_status = 'approved' then 'Service category approved' else 'Service category needs changes' end,
    format('%s was %s.%s', v_name, p_status::text, case when v_note is null then '' else ' Admin note: ' || v_note end),
    'provider_category', p_category_id
  );
  insert into public.admin_audit_events (actor_id, action, target_type, target_id, metadata)
  values (auth.uid(), 'provider_category_review_' || p_status::text, 'provider_category', p_provider_id, jsonb_build_object('category_id', p_category_id, 'status', p_status, 'admin_note', v_note));
  return jsonb_build_object('provider_id', p_provider_id, 'category_id', p_category_id, 'status', p_status, 'reviewed_at', v_now);
end;
$$;

create or replace function public.admin_review_provider(
  p_provider_id uuid,
  p_status public.provider_verification_status,
  p_admin_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_now timestamptz := now();
  v_note text := nullif(trim(coalesce(p_admin_note, '')), '');
begin
  if auth.uid() is null or not public.is_admin() then raise exception 'an authenticated admin is required'; end if;
  if p_status not in ('pending', 'approved', 'rejected', 'suspended') then raise exception 'unsupported provider review status'; end if;
  if not exists (select 1 from public.provider_profiles where user_id = p_provider_id) then raise exception 'provider profile not found'; end if;
  perform set_config('ofrivo.provider_application', 'on', true);
  perform set_config('ofrivo.provider_category_submission', 'on', true);
  update public.provider_profiles
  set verification_status = p_status, approved_at = case when p_status = 'approved' then v_now else null end, suspended_at = case when p_status = 'suspended' then v_now else null end, is_available = p_status = 'approved', updated_at = v_now
  where user_id = p_provider_id;
  update public.provider_verifications
  set status = p_status, reviewed_at = case when p_status = 'pending' then null else v_now end, reviewed_by = case when p_status = 'pending' then null else auth.uid() end, admin_note = v_note
  where id = (select pv.id from public.provider_verifications pv where pv.provider_id = p_provider_id order by pv.submitted_at desc limit 1);
  if p_status = 'approved' then
    update public.provider_categories set status = 'approved', reviewed_at = v_now, reviewed_by = auth.uid(), admin_note = null where provider_id = p_provider_id and status = 'pending';
  end if;
  insert into public.admin_audit_events (actor_id, action, target_type, target_id, metadata) values (auth.uid(), 'provider_review_' || p_status::text, 'provider', p_provider_id, jsonb_build_object('status', p_status, 'admin_note', v_note));
  return jsonb_build_object('provider_id', p_provider_id, 'status', p_status, 'reviewed_at', v_now);
end;
$$;

create or replace view public.public_job_feed as
select j.id, j.category_id, j.area_id, j.title, j.description, j.public_location_text, j.budget_amount, j.scheduled_at, j.time_window, j.urgency, j.created_at, count(b.id)::integer as bid_count,
  (select c.name_en from public.service_categories c where c.id = j.category_id) as category_name,
  (select a.area_name from public.areas a where a.id = j.area_id) as area_name,
  j.expires_at,
  coalesce((select jsonb_agg(jsonb_build_object('path', jp.storage_path, 'sort_order', jp.sort_order) order by jp.sort_order) from public.job_photos jp where jp.job_id = j.id), '[]'::jsonb) as photo_paths
from public.jobs j
left join public.bids b on b.job_id = j.id and b.status in ('pending', 'accepted')
where j.status = 'open' and public.is_active_account() and public.is_approved_provider()
  and exists (select 1 from public.provider_profiles pp where pp.user_id = auth.uid() and pp.is_available)
  and exists (select 1 from public.provider_categories pc where pc.provider_id = auth.uid() and pc.category_id = j.category_id and pc.status = 'approved')
  and exists (select 1 from public.provider_areas pa where pa.provider_id = auth.uid() and pa.area_id = j.area_id)
group by j.id;

grant execute on function public.submit_provider_category_changes(uuid[]) to authenticated;
grant execute on function public.update_provider_profile(text, text, text, text, uuid[], text[]) to authenticated;
grant execute on function public.set_provider_availability(boolean) to authenticated;
grant execute on function public.review_provider_category(uuid, uuid, public.provider_category_status, text) to authenticated;
revoke all on function public.submit_provider_category_changes(uuid[]) from public;
revoke all on function public.update_provider_profile(text, text, text, text, uuid[], text[]) from public;
revoke all on function public.set_provider_availability(boolean) from public;
revoke all on function public.review_provider_category(uuid, uuid, public.provider_category_status, text) from public;
grant execute on function public.submit_provider_category_changes(uuid[]) to authenticated;
grant execute on function public.update_provider_profile(text, text, text, text, uuid[], text[]) to authenticated;
grant execute on function public.set_provider_availability(boolean) to authenticated;
grant execute on function public.review_provider_category(uuid, uuid, public.provider_category_status, text) to authenticated;

-- Existing bids and assigned jobs remain readable when a provider turns the
-- availability switch off or loses a category. Only the open-feed branch is
-- restricted by availability and approved category status.
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
          and exists (select 1 from public.provider_profiles pp where pp.user_id = p_user_id and pp.is_available)
          and exists (
            select 1 from public.provider_categories pc
            where pc.provider_id = p_user_id and pc.category_id = j.category_id and pc.status = 'approved'
          )
          and exists (select 1 from public.provider_areas pa where pa.provider_id = p_user_id and pa.area_id = j.area_id)
        )
      )
  );
$$;

create or replace function public.notify_new_job_event()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.status <> 'open' then return new; end if;
  if tg_op = 'UPDATE' and old.status = 'open' then return new; end if;
  insert into public.notifications (user_id, type, title, body, reference_type, reference_id)
  select distinct pp.user_id, 'new_job', 'New matching job nearby', format('%s is open in %s.', new.title, new.public_location_text), 'job', new.id
  from public.provider_profiles pp
  join public.provider_categories pc on pc.provider_id = pp.user_id
  join public.provider_areas pa on pa.provider_id = pp.user_id
  where pp.verification_status = 'approved' and pp.is_available and pp.user_id <> new.customer_id
    and pc.category_id = new.category_id and pc.status = 'approved' and pa.area_id = new.area_id
    and not exists (select 1 from public.notifications existing where existing.user_id = pp.user_id and existing.type = 'new_job' and existing.reference_type = 'job' and existing.reference_id = new.id);
  return new;
end;
$$;
commit;
