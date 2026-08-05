begin;

-- Version 1.1 separates public portfolio images from private verification files.
insert into storage.buckets (id, name, public)
values ('provider-portfolio', 'provider-portfolio', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists provider_portfolio_public_read on storage.objects;
create policy provider_portfolio_public_read on storage.objects
for select to public
using (bucket_id = 'provider-portfolio');

drop policy if exists provider_portfolio_owner_write on storage.objects;
create policy provider_portfolio_owner_write on storage.objects
for all to authenticated
using (
  bucket_id = 'provider-portfolio'
  and (
    public.is_admin()
    or (storage.foldername(name))[1] = auth.uid()::text
  )
)
with check (
  bucket_id = 'provider-portfolio'
  and (
    public.is_admin()
    or ((storage.foldername(name))[1] = auth.uid()::text and public.is_active_account())
  )
);

-- Only approved providers with active accounts appear in this public portfolio
-- view. It exposes storage paths, not private verification or contact fields.
create or replace view public.public_provider_portfolio as
select
  pp.user_id as provider_id,
  coalesce(
    array_agg(wp.storage_path order by wp.sort_order)
      filter (where wp.storage_path is not null),
    '{}'::text[]
  ) as photo_paths
from public.provider_profiles pp
join public.profiles p on p.id = pp.user_id
left join public.provider_work_photos wp on wp.provider_id = pp.user_id
where pp.verification_status = 'approved'
  and p.account_status = 'active'
group by pp.user_id;

grant select on public.public_provider_portfolio to authenticated, service_role;

commit;
