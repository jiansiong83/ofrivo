begin;

-- Step 5 adds provider portfolio photos without exposing verification files publicly.
create table if not exists public.provider_work_photos (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.provider_profiles(user_id) on delete cascade,
  storage_path text not null,
  sort_order integer not null default 0 check (sort_order between 0 and 5),
  created_at timestamptz not null default now(),
  unique (provider_id, sort_order)
);

create index if not exists provider_work_photos_provider_sort_idx
  on public.provider_work_photos (provider_id, sort_order);

alter table public.provider_work_photos enable row level security;

create policy provider_work_photos_select_self_or_admin on public.provider_work_photos
for select to authenticated
using (provider_id = auth.uid() or public.is_admin());

create policy provider_work_photos_insert_self on public.provider_work_photos
for insert to authenticated
with check (provider_id = auth.uid() and public.is_active_account());

create policy provider_work_photos_update_self_or_admin on public.provider_work_photos
for update to authenticated
using (provider_id = auth.uid() or public.is_admin())
with check (provider_id = auth.uid() or public.is_admin());

create policy provider_work_photos_delete_self_or_admin on public.provider_work_photos
for delete to authenticated
using (provider_id = auth.uid() or public.is_admin());

-- A provider can create only a not-applied profile directly. Submission and
-- the pending transition happen through the server-owned RPC below.
drop policy if exists provider_profiles_insert_self on public.provider_profiles;
create policy provider_profiles_insert_self on public.provider_profiles
for insert to authenticated
with check (
  user_id = auth.uid()
  and public.is_active_account()
  and verification_status = 'not_applied'
  and approved_at is null
  and suspended_at is null
);

drop policy if exists provider_verifications_insert_self on public.provider_verifications;
create policy provider_verifications_insert_self on public.provider_verifications
for insert to authenticated
with check (
  provider_id = auth.uid()
  and public.is_active_account()
  and status = 'pending'
  and reviewed_at is null
  and reviewed_by is null
  and admin_note is null
);

-- The RPC marks a provider as pending through a transaction-local capability.
-- Clients cannot set this capability through the PostgREST surface.
create or replace function public.prevent_provider_privilege_escalation()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is not null
     and not public.is_admin()
     and coalesce(current_setting('ofrivo.provider_application', true), '') <> 'on' then
    if new.verification_status is distinct from old.verification_status
       or new.approved_at is distinct from old.approved_at
       or new.suspended_at is distinct from old.suspended_at then
      raise exception 'provider verification fields are server-managed';
    end if;
  end if;
  return new;
end;
$$;

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
  if exists (
    select 1 from unnest(p_category_ids) as selected(id)
    where not exists (select 1 from public.service_categories c where c.id = selected.id and c.is_active)
  ) or cardinality(p_category_ids) <> (select count(distinct id) from unnest(p_category_ids) as selected(id)) then
    raise exception 'one or more service categories are invalid';
  end if;
  if exists (
    select 1 from unnest(p_area_ids) as selected(id)
    where not exists (select 1 from public.areas a where a.id = selected.id and a.is_active)
  ) or cardinality(p_area_ids) <> (select count(distinct id) from unnest(p_area_ids) as selected(id)) then
    raise exception 'one or more service areas are invalid';
  end if;

  select verification_status into v_current_status from public.provider_profiles where user_id = auth.uid();
  if v_current_status in ('approved', 'suspended') then
    raise exception 'this provider account cannot submit another application';
  end if;

  perform set_config('ofrivo.provider_application', 'on', true);

  insert into public.profiles (id, display_name)
  values (auth.uid(), trim(p_display_name))
  on conflict (id) do update set display_name = excluded.display_name, updated_at = v_now;

  insert into public.provider_profiles (user_id, bio, verification_status, is_available, approved_at, suspended_at)
  values (auth.uid(), trim(p_bio), 'pending', false, null, null)
  on conflict (user_id) do update set bio = excluded.bio, verification_status = 'pending', is_available = false, approved_at = null, suspended_at = null, updated_at = v_now;

  delete from public.provider_categories where provider_id = auth.uid();
  insert into public.provider_categories (provider_id, category_id)
  select auth.uid(), id from unnest(p_category_ids) as selected(id);

  delete from public.provider_areas where provider_id = auth.uid();
  insert into public.provider_areas (provider_id, area_id)
  select auth.uid(), id from unnest(p_area_ids) as selected(id);

  insert into public.provider_verifications (
    provider_id, ic_front_path, ic_back_path, selfie_path, ssm_path, certificate_paths, status, submitted_at
  ) values (
    auth.uid(), p_ic_front_path, p_ic_back_path, p_selfie_path, p_ssm_path, p_certificate_paths, 'pending', v_now
  );

  delete from public.provider_work_photos where provider_id = auth.uid();
  insert into public.provider_work_photos (provider_id, storage_path, sort_order)
  select auth.uid(), path, ordinality - 1 from unnest(p_work_photo_paths) with ordinality as photos(path, ordinality);

  return jsonb_build_object('provider_id', auth.uid(), 'status', 'pending', 'submitted_at', v_now);
end;
$$;

grant select, insert, update, delete on public.provider_work_photos to authenticated;
revoke all on function public.submit_provider_application(text, text, uuid[], uuid[], text, text, text, text, jsonb, text[]) from public;
grant execute on function public.submit_provider_application(text, text, uuid[], uuid[], text, text, text, text, jsonb, text[]) to authenticated;

commit;
