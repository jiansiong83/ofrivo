begin;

-- Version 1.1 records a participant-reported no-show without changing the
-- job status. The event is private to the job participants/admins through the
-- existing job_events RLS policy.
create or replace function public.mark_no_show(
  p_job_id uuid,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_job public.jobs;
  v_provider_id uuid;
  v_reported_user_id uuid;
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
  v_event public.job_events;
begin
  if auth.uid() is null or not public.is_active_account() then
    raise exception 'authentication and an active account are required';
  end if;
  if char_length(coalesce(v_reason, '')) > 500 then
    raise exception 'no-show reason must be 500 characters or fewer';
  end if;

  select * into v_job from public.jobs where id = p_job_id for update;
  if not found then
    raise exception 'job not found';
  end if;
  if v_job.status not in ('assigned', 'in_progress') then
    raise exception 'a no-show can only be marked on an assigned or in-progress job';
  end if;

  select provider_id into v_provider_id
  from public.bids
  where id = v_job.accepted_bid_id and status = 'accepted';
  if v_provider_id is null then
    raise exception 'this job has no accepted provider';
  end if;
  if auth.uid() = v_job.customer_id then
    v_reported_user_id := v_provider_id;
  elsif auth.uid() = v_provider_id then
    v_reported_user_id := v_job.customer_id;
  else
    raise exception 'only the customer or accepted provider can mark a no-show';
  end if;

  if exists (
    select 1 from public.job_events
    where job_id = p_job_id
      and event_type = 'no_show_marked'
      and metadata ->> 'reported_user_id' = v_reported_user_id::text
  ) then
    raise exception 'a no-show has already been marked for this participant';
  end if;

  insert into public.job_events (job_id, actor_id, event_type, metadata)
  values (
    p_job_id,
    auth.uid(),
    'no_show_marked',
    jsonb_build_object(
      'reported_user_id', v_reported_user_id,
      'reason', coalesce(v_reason, 'No-show reported by a job participant.')
    )
  )
  returning * into v_event;

  insert into public.notifications (user_id, type, title, body, reference_type, reference_id)
  values (
    v_reported_user_id,
    'no_show',
    'No-show reported',
    'A job participant reported a no-show event. Please contact support if this is incorrect.',
    'job',
    p_job_id
  );

  return jsonb_build_object(
    'event_id', v_event.id,
    'job_id', p_job_id,
    'event_type', v_event.event_type,
    'actor_id', v_event.actor_id,
    'created_at', v_event.created_at,
    'metadata', v_event.metadata
  );
end;
$$;

revoke all on function public.mark_no_show(uuid, text) from public;
grant execute on function public.mark_no_show(uuid, text) to authenticated;

commit;
