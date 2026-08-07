begin;

alter table public.jobs
  drop constraint if exists jobs_schedule_end_after_start;

alter table public.jobs
  add constraint jobs_schedule_end_after_start
  check (
    scheduled_end_at is null
    or (
      scheduled_at is not null
      and scheduled_end_at > scheduled_at
      and (scheduled_end_at at time zone 'Asia/Kuala_Lumpur')::date =
          (scheduled_at at time zone 'Asia/Kuala_Lumpur')::date
    )
  );

commit;
