begin;

-- Keep a customer's personal identity on profiles while storing the
-- provider-facing business name on the provider profile.
alter table public.provider_profiles
  add column if not exists display_name text;

do $$
begin
  alter table public.provider_profiles
    add constraint provider_profiles_display_name_length
    check (display_name is null or char_length(trim(display_name)) between 2 and 80);
exception when duplicate_object then null;
end $$;

-- Existing fixtures used profiles.display_name for both roles. Preserve that
-- value as the initial provider label, then let future edits diverge safely.
update public.provider_profiles pp
set display_name = coalesce(nullif(trim(pp.display_name), ''), nullif(trim(p.display_name), ''), nullif(trim(p.full_name), ''))
from public.profiles p
where p.id = pp.user_id
  and pp.display_name is null;

create or replace view public.public_provider_directory as
select
  p.id,
  coalesce(pp.display_name, p.display_name, p.full_name) as display_name,
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

-- The original functions remain useful as private implementation helpers.
-- Their public signatures are wrapped so provider edits cannot overwrite the
-- customer-facing profiles.display_name field.
alter function public.submit_provider_application(text, text, uuid[], uuid[], text, text, text, text, jsonb, text[])
  rename to submit_provider_application_legacy;
revoke all on function public.submit_provider_application_legacy(text, text, uuid[], uuid[], text, text, text, text, jsonb, text[]) from public, authenticated;

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
  v_profile_exists boolean;
  v_customer_display_name text;
  v_result jsonb;
begin
  select exists (select 1 from public.profiles where id = auth.uid()),
         (select display_name from public.profiles where id = auth.uid())
    into v_profile_exists, v_customer_display_name;

  v_result := public.submit_provider_application_legacy(
    p_display_name, p_bio, p_category_ids, p_area_ids, p_ic_front_path,
    p_ic_back_path, p_selfie_path, p_ssm_path, p_certificate_paths,
    p_work_photo_paths
  );

  update public.provider_profiles
  set display_name = trim(p_display_name), updated_at = now()
  where user_id = auth.uid();

  if v_profile_exists then
    update public.profiles
    set display_name = v_customer_display_name, updated_at = now()
    where id = auth.uid();
  end if;

  return v_result;
end;
$$;

revoke all on function public.submit_provider_application(text, text, uuid[], uuid[], text, text, text, text, jsonb, text[]) from public;
grant execute on function public.submit_provider_application(text, text, uuid[], uuid[], text, text, text, text, jsonb, text[]) to authenticated;

alter function public.update_provider_profile(text, text, text, text, uuid[], text[])
  rename to update_provider_profile_legacy;
revoke all on function public.update_provider_profile_legacy(text, text, text, text, uuid[], text[]) from public, authenticated;

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
  v_profile_exists boolean;
  v_customer_display_name text;
  v_result jsonb;
begin
  select exists (select 1 from public.profiles where id = auth.uid()),
         (select display_name from public.profiles where id = auth.uid())
    into v_profile_exists, v_customer_display_name;

  v_result := public.update_provider_profile_legacy(
    p_display_name, p_bio, p_phone, p_whatsapp, p_area_ids, p_work_photo_paths
  );

  update public.provider_profiles
  set display_name = trim(p_display_name), updated_at = now()
  where user_id = auth.uid();

  if v_profile_exists then
    update public.profiles
    set display_name = v_customer_display_name, updated_at = now()
    where id = auth.uid();
  end if;

  return v_result;
end;
$$;

revoke all on function public.update_provider_profile(text, text, text, text, uuid[], text[]) from public;
grant execute on function public.update_provider_profile(text, text, text, text, uuid[], text[]) to authenticated;

commit;
