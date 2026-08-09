begin;

-- Customers may edit draft/open job fields, but publishing is one-way and the
-- offer expiry is server-controlled once a job is open. This prevents a browser
-- client from silently unpublishing a job or hiding it with an expired window.
create or replace function public.guard_open_job_mutation()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and current_user <> 'service_role' then
    if not public.is_admin() then
      if old.status = 'open' and new.status = 'draft' then
        raise exception 'an open job cannot be moved back to draft';
      end if;

      if old.status = 'open'
         and new.status = 'open'
         and new.expires_at is distinct from old.expires_at then
        raise exception 'open job expiry is managed by the server';
      end if;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists jobs_guard_open_mutation on public.jobs;
create trigger jobs_guard_open_mutation
before update on public.jobs
for each row execute function public.guard_open_job_mutation();

revoke all on function public.guard_open_job_mutation() from public;

-- Trusted server workers and local integration fixtures may touch rows through
-- RLS-protected tables; helper functions used by those policies must be
-- callable by the service role without becoming browser-callable.
grant execute on function public.is_admin(uuid) to service_role;
grant execute on function public.is_active_account(uuid) to service_role;
grant execute on function public.is_approved_provider(uuid) to service_role;
grant execute on function public.is_customer_job(uuid, uuid) to service_role;
grant execute on function public.is_open_job(uuid) to service_role;
grant execute on function public.is_accepted_job_provider(uuid, uuid) to service_role;
grant execute on function public.can_read_job(uuid, uuid) to service_role;
grant execute on function public.path_job_id(text) to service_role;

commit;
