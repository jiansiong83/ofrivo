begin;

-- Step 6 keeps the feed safe by returning public labels and signed-photo
-- source paths while continuing to omit full_address and contact fields.
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
  count(b.id)::integer as bid_count,
  (select c.name_en from public.service_categories c where c.id = j.category_id) as category_name,
  (select a.area_name from public.areas a where a.id = j.area_id) as area_name,
  j.expires_at,
  coalesce(
    (
      select jsonb_agg(
        jsonb_build_object('path', jp.storage_path, 'sort_order', jp.sort_order)
        order by jp.sort_order
      )
      from public.job_photos jp
      where jp.job_id = j.id
    ),
    '[]'::jsonb
  ) as photo_paths
from public.jobs j
left join public.bids b on b.job_id = j.id and b.status in ('pending', 'accepted')
where j.status = 'open'
  and public.is_active_account()
  and public.is_approved_provider()
  and exists (select 1 from public.provider_categories pc where pc.provider_id = auth.uid() and pc.category_id = j.category_id)
  and exists (select 1 from public.provider_areas pa where pa.provider_id = auth.uid() and pa.area_id = j.area_id)
group by j.id;

grant select on public.public_job_feed to authenticated;

create index if not exists jobs_provider_feed_sort_idx
  on public.jobs (status, urgency, created_at desc, budget_amount desc);

commit;
