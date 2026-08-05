begin;

-- Local Admin Web integration uses the public anon key plus Supabase Auth. The
-- service role remains reserved for server workers and test fixture cleanup.
create table if not exists public.admin_audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references public.profiles(id) on delete restrict default auth.uid(),
  action text not null,
  target_type text not null,
  target_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint admin_audit_action_length check (char_length(trim(action)) between 2 and 120),
  constraint admin_audit_target_type_length check (char_length(trim(target_type)) between 2 and 80),
  constraint admin_audit_metadata_object check (jsonb_typeof(metadata) = 'object')
);

create index if not exists admin_audit_events_created_at_idx
  on public.admin_audit_events (created_at desc);

create index if not exists admin_audit_events_target_idx
  on public.admin_audit_events (target_type, target_id, created_at desc);

alter table public.admin_audit_events enable row level security;

create policy admin_audit_events_select_admin on public.admin_audit_events
for select to authenticated
using (public.is_admin());

create policy admin_audit_events_insert_admin on public.admin_audit_events
for insert to authenticated
with check (public.is_admin() and actor_id = auth.uid());

grant select, insert on public.admin_audit_events to authenticated;
grant select, insert, update, delete on public.admin_audit_events to service_role;

-- The browser cannot query auth.users directly. This function exposes only the
-- minimum directory fields after an authenticated admin check.
create or replace function public.admin_list_users()
returns table (
  id uuid,
  email text,
  full_name text,
  display_name text,
  account_status public.account_status,
  is_admin boolean,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public, auth
as $$
  select
    p.id,
    u.email,
    p.full_name,
    p.display_name,
    p.account_status,
    p.is_admin,
    p.created_at
  from public.profiles p
  join auth.users u on u.id = p.id
  where public.is_admin();
$$;

-- Keep moderation transitions atomic with their audit event. The provider
-- verification trigger also queues the existing user-scoped notification.
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
  if auth.uid() is null or not public.is_admin() then
    raise exception 'an authenticated admin is required';
  end if;
  if p_status not in ('pending', 'approved', 'rejected', 'suspended') then
    raise exception 'unsupported provider review status';
  end if;
  if not exists (select 1 from public.provider_profiles where user_id = p_provider_id) then
    raise exception 'provider profile not found';
  end if;

  update public.provider_profiles
  set verification_status = p_status,
      approved_at = case when p_status = 'approved' then v_now else null end,
      suspended_at = case when p_status = 'suspended' then v_now else null end,
      is_available = p_status = 'approved',
      updated_at = v_now
  where user_id = p_provider_id;

  update public.provider_verifications
  set status = p_status,
      reviewed_at = case when p_status = 'pending' then null else v_now end,
      reviewed_by = case when p_status = 'pending' then null else auth.uid() end,
      admin_note = v_note
  where id = (
    select pv.id
    from public.provider_verifications pv
    where pv.provider_id = p_provider_id
    order by pv.submitted_at desc
    limit 1
  );

  insert into public.admin_audit_events (actor_id, action, target_type, target_id, metadata)
  values (
    auth.uid(),
    'provider_review_' || p_status::text,
    'provider',
    p_provider_id,
    jsonb_build_object('status', p_status, 'admin_note', v_note)
  );

  return jsonb_build_object('provider_id', p_provider_id, 'status', p_status, 'reviewed_at', v_now);
end;
$$;

create or replace function public.admin_update_account_status(
  p_user_id uuid,
  p_status public.account_status
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_now timestamptz := now();
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'an authenticated admin is required';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'an admin cannot suspend its own account';
  end if;
  if p_status not in ('active', 'suspended') then
    raise exception 'unsupported account status';
  end if;
  update public.profiles
  set account_status = p_status, updated_at = v_now
  where id = p_user_id;
  if not found then
    raise exception 'profile not found';
  end if;

  insert into public.admin_audit_events (actor_id, action, target_type, target_id, metadata)
  values (auth.uid(), 'account_' || p_status::text, 'user', p_user_id, jsonb_build_object('status', p_status));

  return jsonb_build_object('user_id', p_user_id, 'status', p_status, 'updated_at', v_now);
end;
$$;

create or replace function public.admin_review_report(
  p_report_id uuid,
  p_status public.report_status,
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
  if auth.uid() is null or not public.is_admin() then
    raise exception 'an authenticated admin is required';
  end if;
  update public.reports
  set status = p_status,
      admin_note = v_note,
      resolved_at = case when p_status in ('resolved', 'dismissed') then v_now else null end
  where id = p_report_id;
  if not found then
    raise exception 'report not found';
  end if;

  insert into public.admin_audit_events (actor_id, action, target_type, target_id, metadata)
  values (
    auth.uid(),
    'report_' || p_status::text,
    'report',
    p_report_id,
    jsonb_build_object('status', p_status, 'admin_note', v_note)
  );

  return jsonb_build_object('report_id', p_report_id, 'status', p_status, 'updated_at', v_now);
end;
$$;

revoke all on function public.admin_list_users() from public;
revoke all on function public.admin_review_provider(uuid, public.provider_verification_status, text) from public;
revoke all on function public.admin_update_account_status(uuid, public.account_status) from public;
revoke all on function public.admin_review_report(uuid, public.report_status, text) from public;
grant execute on function public.admin_list_users() to authenticated;
grant execute on function public.admin_review_provider(uuid, public.provider_verification_status, text) to authenticated;
grant execute on function public.admin_update_account_status(uuid, public.account_status) to authenticated;
grant execute on function public.admin_review_report(uuid, public.report_status, text) to authenticated;

commit;
