begin;

-- Device tokens are registered through a server-validated RPC so the caller
-- cannot attach a token to another profile.
create index if not exists device_tokens_user_platform_idx
  on public.device_tokens (user_id, platform, last_seen_at desc);

create or replace function public.register_device_token(
  p_token text,
  p_platform text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_token text := trim(coalesce(p_token, ''));
  v_platform text := lower(trim(coalesce(p_platform, '')));
  v_row public.device_tokens;
begin
  if auth.uid() is null or not public.is_active_account() then
    raise exception 'authentication and an active account are required';
  end if;
  if char_length(v_token) < 8 or char_length(v_token) > 4096 then
    raise exception 'device token length is invalid';
  end if;
  if v_platform not in ('android', 'ios', 'web') then
    raise exception 'device platform is invalid';
  end if;

  insert into public.device_tokens (user_id, token, platform, last_seen_at)
  values (auth.uid(), v_token, v_platform, now())
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        last_seen_at = now()
  returning * into v_row;

  return jsonb_build_object(
    'id', v_row.id,
    'token', v_row.token,
    'platform', v_row.platform,
    'last_seen_at', v_row.last_seen_at
  );
end;
$$;

create or replace function public.unregister_device_token(p_token text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'authentication is required';
  end if;
  delete from public.device_tokens
  where token = trim(coalesce(p_token, ''))
    and user_id = auth.uid();
end;
$$;

-- New published jobs fan out an inbox notification to matching approved
-- providers. The notification row is the durable outbox for a later FCM
-- worker, while RLS keeps the inbox user-scoped.
create or replace function public.notify_new_job_event()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.status <> 'open' then
    return new;
  end if;
  if tg_op = 'UPDATE' then
    if old.status = 'open' then
      return new;
    end if;
  end if;
  insert into public.notifications (user_id, type, title, body, reference_type, reference_id)
  select distinct
    pp.user_id,
    'new_job',
    'New matching job nearby',
    format('%s is open in %s.', new.title, new.public_location_text),
    'job',
    new.id
  from public.provider_profiles pp
  join public.provider_categories pc on pc.provider_id = pp.user_id
  join public.provider_areas pa on pa.provider_id = pp.user_id
  where pp.verification_status = 'approved'
    and pp.is_available
    and pp.user_id <> new.customer_id
    and pc.category_id = new.category_id
    and pa.area_id = new.area_id
    and not exists (
      select 1
      from public.notifications existing
      where existing.user_id = pp.user_id
        and existing.type = 'new_job'
        and existing.reference_type = 'job'
        and existing.reference_id = new.id
    );

  return new;
end;
$$;

create or replace function public.notify_new_bid_event()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_customer_id uuid;
  v_job_title text;
begin
  if new.status <> 'pending' then
    return new;
  end if;

  select customer_id, title into v_customer_id, v_job_title
  from public.jobs
  where id = new.job_id;

  if v_customer_id is not null then
    insert into public.notifications (user_id, type, title, body, reference_type, reference_id)
    values (
      v_customer_id,
      'new_bid',
      'Your job received a new offer',
      format('%s has a new offer.', v_job_title),
      'job',
      new.job_id
    );
  end if;
  return new;
end;
$$;

create or replace function public.notify_provider_verification_event()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_type text;
  v_title text;
  v_body text;
begin
  if new.status is not distinct from old.status
     or new.status not in ('approved', 'rejected', 'suspended') then
    return new;
  end if;

  v_type := case new.status
    when 'approved' then 'provider_approved'
    when 'rejected' then 'provider_rejected'
    else 'provider_suspended'
  end;
  v_title := case new.status
    when 'approved' then 'Provider verification approved'
    when 'rejected' then 'Provider verification needs changes'
    else 'Provider account suspended'
  end;
  v_body := case new.status
    when 'approved' then 'You can now view matching jobs and submit offers.'
    when 'rejected' then 'Review the admin note and update your application before resubmitting.'
    else 'Your provider access is paused. Contact support if you need help.'
  end;

  insert into public.notifications (user_id, type, title, body, reference_type, reference_id)
  values (new.provider_id, v_type, v_title, v_body, 'provider', new.provider_id);
  return new;
end;
$$;

-- This function is intended for a scheduled server job (Supabase Cron or an
-- Edge Function). It is deliberately not executable by browser clients.
create or replace function public.queue_job_expiring_notifications(
  p_horizon interval default interval '24 hours'
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_inserted integer;
begin
  if p_horizon <= interval '0 hours' or p_horizon > interval '7 days' then
    raise exception 'expiry horizon must be between one hour and seven days';
  end if;

  insert into public.notifications (user_id, type, title, body, reference_type, reference_id)
  select
    j.customer_id,
    'job_expiring',
    'Job expiring soon',
    format('%s will stop accepting offers soon.', j.title),
    'job',
    j.id
  from public.jobs j
  where j.status = 'open'
    and j.expires_at > now()
    and j.expires_at <= now() + p_horizon
    and not exists (
      select 1
      from public.notifications existing
      where existing.user_id = j.customer_id
        and existing.type = 'job_expiring'
        and existing.reference_type = 'job'
        and existing.reference_id = j.id
        and existing.created_at >= now() - interval '20 hours'
    );

  get diagnostics v_inserted = row_count;
  return v_inserted;
end;
$$;

drop trigger if exists jobs_notify_new_job on public.jobs;
create trigger jobs_notify_new_job
after insert or update of status, category_id, area_id on public.jobs
for each row execute function public.notify_new_job_event();

drop trigger if exists bids_notify_new_bid on public.bids;
create trigger bids_notify_new_bid
after insert on public.bids
for each row execute function public.notify_new_bid_event();

drop trigger if exists provider_verifications_notify_result on public.provider_verifications;
create trigger provider_verifications_notify_result
after update of status on public.provider_verifications
for each row execute function public.notify_provider_verification_event();

revoke all on function public.register_device_token(text, text) from public;
grant execute on function public.register_device_token(text, text) to authenticated;
revoke all on function public.unregister_device_token(text) from public;
grant execute on function public.unregister_device_token(text) to authenticated;
revoke all on function public.queue_job_expiring_notifications(interval) from public;

commit;
