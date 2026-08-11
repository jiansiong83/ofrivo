-- Staging reference data only.
--
-- This migration intentionally contains no auth users, passwords, provider
-- profiles, jobs, bids, or other demo records.  Local demo fixtures remain in
-- supabase/seed.sql and must never be pushed to a hosted project.

insert into public.service_categories (
  id, slug, name_en, name_ms, name_zh, icon_name, sort_order
)
values
  ('00000000-0000-0000-0000-000000000201'::uuid, 'plumbing-toilet', 'Plumbing / Toilet', 'Paip / Tandas', 'Plumbing / Toilet', 'water_drop', 1),
  ('00000000-0000-0000-0000-000000000202'::uuid, 'electrical-lighting-fan', 'Electrical / Lighting / Fan', 'Elektrik / Lampu / Kipas', 'Electrical / Lighting / Fan', 'bolt', 2),
  ('00000000-0000-0000-0000-000000000203'::uuid, 'air-conditioning', 'Air Conditioning', 'Penyaman Udara', 'Air Conditioning', 'ac_unit', 3),
  ('00000000-0000-0000-0000-000000000204'::uuid, 'moving-delivery', 'Moving / Delivery', 'Pindah / Penghantaran', 'Moving / Delivery', 'local_shipping', 4),
  ('00000000-0000-0000-0000-000000000205'::uuid, 'cleaning', 'Cleaning', 'Pembersihan', 'Cleaning', 'cleaning_services', 5),
  ('00000000-0000-0000-0000-000000000206'::uuid, 'handyman', 'Handyman', 'Pembaikan Am', 'Handyman', 'handyman', 6)
on conflict (id) do nothing;

insert into public.areas (id, state, city, area_name, sort_order)
values
  ('00000000-0000-0000-0000-000000000251'::uuid, 'Johor', 'Johor Bahru', 'Mount Austin', 1),
  ('00000000-0000-0000-0000-000000000252'::uuid, 'Johor', 'Johor Bahru', 'Taman Molek', 2),
  ('00000000-0000-0000-0000-000000000253'::uuid, 'Johor', 'Johor Bahru', 'Permas Jaya', 3),
  ('00000000-0000-0000-0000-000000000254'::uuid, 'Johor', 'Johor Bahru', 'Skudai', 4)
on conflict (id) do nothing;
