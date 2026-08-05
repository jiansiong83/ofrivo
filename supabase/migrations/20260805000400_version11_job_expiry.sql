begin;

-- Set a deterministic seven-day offer window whenever a draft is published.
create or replace function public.set_job_expiry_on_publish()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.status = 'open' and new.expires_at is null then
    new.expires_at := now() + interval '7 days';
  end if;
  if new.status = 'open'
     and new.expires_at <= now()
     and (tg_op = 'INSERT' or old.status is distinct from 'open') then
    raise exception 'open jobs must expire in the future';
  end if;
  return new;
end;
$$;

drop trigger if exists jobs_set_expiry_on_publish on public.jobs;
create trigger jobs_set_expiry_on_publish
before insert or update of status, expires_at on public.jobs
for each row execute function public.set_job_expiry_on_publish();

-- Scheduled workers (Supabase Cron or an Edge Function) call this service-only
-- function. It locks each candidate, expires pending bids, writes one event,
-- and queues one user-scoped notification in the same transaction.
create or replace function public.expire_open_jobs(
  p_limit integer default 100
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_job public.jobs;
  v_expired integer := 0;
begin
  if p_limit < 1 or p_limit > 500 then
    raise exception 'expiry batch limit must be between 1 and 500';
  end if;

  for v_job in
    select *
    from public.jobs
    where status = 'open'
      and expires_at is not null
      and expires_at <= now()
    order by expires_at, id
    for update skip locked
    limit p_limit
  loop
    update public.jobs
    set status = 'expired', updated_at = now()
    where id = v_job.id;

    update public.bids
    set status = 'expired', updated_at = now()
    where job_id = v_job.id and status = 'pending';

    insert into public.job_events (job_id, actor_id, event_type, metadata)
    values (
      v_job.id,
      null,
      'job_expired',
      jsonb_build_object('expired_at', now(), 'previous_status', 'open')
    );

    insert into public.notifications (user_id, type, title, body, reference_type, reference_id)
    values (
      v_job.customer_id,
      'job_expired',
      'Job expired',
      format('%s stopped accepting offers after its expiry time.', v_job.title),
      'job',
      v_job.id
    );
    v_expired := v_expired + 1;
  end loop;
  return v_expired;
end;
$$;

revoke all on function public.set_job_expiry_on_publish() from public;
revoke all on function public.expire_open_jobs(integer) from public;
grant execute on function public.expire_open_jobs(integer) to service_role;

commit;
