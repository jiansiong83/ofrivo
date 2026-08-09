-- Ofrivo Step 2 local seed data.
-- This is deliberately fake data for local development only. The passwords
-- are generated into auth.users as bcrypt hashes and are not production creds.

begin;

do $$
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data
  )
  select
    '00000000-0000-0000-0000-000000000101'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated', 'customer@example.test',
    crypt('local-dev-only', gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Alex Tan"}'::jsonb
  where not exists (select 1 from auth.users where id = '00000000-0000-0000-0000-000000000101'::uuid);

  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data
  )
  select
    '00000000-0000-0000-0000-000000000102'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated', 'provider@example.test',
    crypt('local-dev-only', gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Ahmad Plumbing"}'::jsonb
  where not exists (select 1 from auth.users where id = '00000000-0000-0000-0000-000000000102'::uuid);

  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data
  )
  select
    '00000000-0000-0000-0000-000000000103'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated', 'pending-provider@example.test',
    crypt('local-dev-only', gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Pending Provider"}'::jsonb
  where not exists (select 1 from auth.users where id = '00000000-0000-0000-0000-000000000103'::uuid);

  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data
  )
  select
    '00000000-0000-0000-0000-000000000104'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated', 'provider-b@example.test',
    crypt('local-dev-only', gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"JB Home Fix"}'::jsonb
  where not exists (select 1 from auth.users where id = '00000000-0000-0000-0000-000000000104'::uuid);

  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data
  )
  select
    '00000000-0000-0000-0000-000000000199'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated', 'authenticated', 'admin@example.test',
    crypt('local-dev-only', gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Ofrivo Admin"}'::jsonb
  where not exists (select 1 from auth.users where id = '00000000-0000-0000-0000-000000000199'::uuid);
end $$;

-- GoTrue expects token fields to be non-null when reading password-login
-- fixtures. Keep these local demo identities compatible across GoTrue versions.
update auth.users
set created_at = coalesce(created_at, now()),
    updated_at = coalesce(updated_at, now()),
    confirmation_token = coalesce(confirmation_token, ''),
    recovery_token = coalesce(recovery_token, ''),
    email_change = coalesce(email_change, ''),
    email_change_token_new = coalesce(email_change_token_new, ''),
    phone_change = coalesce(phone_change, ''),
    phone_change_token = coalesce(phone_change_token, ''),
    email_change_token_current = coalesce(email_change_token_current, ''),
    reauthentication_token = coalesce(reauthentication_token, '')
where email like '%@example.test';

insert into public.profiles (id, full_name, display_name, phone, whatsapp, account_status, is_admin)
values
  ('00000000-0000-0000-0000-000000000101', 'Alex Tan', 'Alex', '+60 12 000 0101', '+60 12 000 0101', 'active', false),
  ('00000000-0000-0000-0000-000000000102', 'Ahmad Plumbing', 'Ahmad Plumbing', '+60 12 000 0102', '+60 12 000 0102', 'active', false),
  ('00000000-0000-0000-0000-000000000103', 'Pending Provider', 'Pending Provider', '+60 12 000 0103', '+60 12 000 0103', 'active', false),
  ('00000000-0000-0000-0000-000000000104', 'JB Home Fix', 'JB Home Fix', '+60 12 000 0104', '+60 12 000 0104', 'active', false),
  ('00000000-0000-0000-0000-000000000199', 'Ofrivo Admin', 'Ofrivo Admin', null, null, 'active', true)
on conflict (id) do nothing;

insert into public.provider_profiles (user_id, display_name, bio, verification_status, rating_average, rating_count, completed_jobs, is_available, approved_at)
values
  ('00000000-0000-0000-0000-000000000102', 'Ahmad Plumbing', 'Friendly local plumbing service for homes and small shops.', 'approved', 4.90, 27, 86, true, now()),
  ('00000000-0000-0000-0000-000000000103', 'Pending Provider', 'General home repair provider awaiting verification.', 'pending', 0, 0, 0, false, null),
  ('00000000-0000-0000-0000-000000000104', 'JB Home Fix', 'Reliable home repair and handyman service.', 'approved', 4.70, 18, 42, true, now())
on conflict (user_id) do nothing;

insert into public.service_categories (id, slug, name_en, name_ms, name_zh, icon_name, sort_order)
values
  ('00000000-0000-0000-0000-000000000201', 'plumbing-toilet', 'Plumbing / Toilet', 'Paip / Tandas', '水喉 / 厕所', 'water_drop', 1),
  ('00000000-0000-0000-0000-000000000202', 'electrical-lighting-fan', 'Electrical / Lighting / Fan', 'Elektrik / Lampu / Kipas', '电工 / 灯 / 风扇', 'bolt', 2),
  ('00000000-0000-0000-0000-000000000203', 'air-conditioning', 'Air Conditioning', 'Penyaman Udara', '冷气', 'ac_unit', 3),
  ('00000000-0000-0000-0000-000000000204', 'moving-delivery', 'Moving / Delivery', 'Pindah / Penghantaran', '搬运 / 送货', 'local_shipping', 4),
  ('00000000-0000-0000-0000-000000000205', 'cleaning', 'Cleaning', 'Pembersihan', '清洁', 'cleaning_services', 5),
  ('00000000-0000-0000-0000-000000000206', 'handyman', 'Handyman', 'Pembaikan Am', '杂工 / 小维修', 'handyman', 6)
on conflict (id) do nothing;

insert into public.areas (id, state, city, area_name, sort_order)
values
  ('00000000-0000-0000-0000-000000000251', 'Johor', 'Johor Bahru', 'Mount Austin', 1),
  ('00000000-0000-0000-0000-000000000252', 'Johor', 'Johor Bahru', 'Taman Molek', 2),
  ('00000000-0000-0000-0000-000000000253', 'Johor', 'Johor Bahru', 'Permas Jaya', 3),
  ('00000000-0000-0000-0000-000000000254', 'Johor', 'Johor Bahru', 'Skudai', 4)
on conflict (id) do nothing;

insert into public.provider_categories (provider_id, category_id)
values
  ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000201'),
  ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000206'),
  ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000205'),
  ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000206')
on conflict do nothing;

insert into public.provider_areas (provider_id, area_id)
values
  ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000251'),
  ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000252'),
  ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000253'),
  ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000252')
on conflict do nothing;

insert into public.provider_verifications (id, provider_id, ic_front_path, ic_back_path, selfie_path, status, submitted_at, reviewed_at, reviewed_by, admin_note)
values
  ('00000000-0000-0000-0000-000000000271', '00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000102/ic-front.jpg', '00000000-0000-0000-0000-000000000102/ic-back.jpg', '00000000-0000-0000-0000-000000000102/selfie.jpg', 'approved', now() - interval '14 days', now() - interval '13 days', '00000000-0000-0000-0000-000000000199', 'Local fixture approved by admin.'),
  ('00000000-0000-0000-0000-000000000272', '00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000103/ic-front.jpg', '00000000-0000-0000-0000-000000000103/ic-back.jpg', '00000000-0000-0000-0000-000000000103/selfie.jpg', 'pending', now() - interval '2 days', null, null, null),
  ('00000000-0000-0000-0000-000000000273', '00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000104/ic-front.jpg', '00000000-0000-0000-0000-000000000104/ic-back.jpg', '00000000-0000-0000-0000-000000000104/selfie.jpg', 'approved', now() - interval '30 days', now() - interval '29 days', '00000000-0000-0000-0000-000000000199', 'Local fixture approved by admin.')
on conflict (id) do nothing;

insert into public.jobs (id, customer_id, category_id, area_id, title, description, public_location_text, full_address, budget_amount, scheduled_at, time_window, urgency, status, contact_phone, contact_whatsapp, expires_at)
values
  ('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000251', 'Toilet blockage', 'Water is draining slowly and the toilet is close to overflowing.', 'Mount Austin', '12 Example Street, Mount Austin, Johor Bahru', 100, now() + interval '4 hours', '2pm–6pm', 'urgent', 'open', '+60 12 000 0101', '+60 12 000 0101', now() + interval '2 days'),
  ('00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000252', 'Install ceiling fan', 'Install one new ceiling fan. Existing power point is available.', 'Taman Molek', '18 Example Street, Taman Molek, Johor Bahru', 160, now() + interval '1 day', '10am–1pm', 'normal', 'open', '+60 12 000 0101', '+60 12 000 0101', now() + interval '3 days'),
  ('00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000204', '00000000-0000-0000-0000-000000000253', 'Move a washing machine', 'Move one washing machine from a landed house to a nearby apartment.', 'Permas Jaya', '22 Example Street, Permas Jaya, Johor Bahru', 80, now() + interval '3 days', '9am–12pm', 'normal', 'assigned', '+60 12 000 0101', '+60 12 000 0101', now() + interval '5 days')
on conflict (id) do nothing;

insert into public.jobs (id, customer_id, category_id, area_id, title, description, public_location_text, full_address, budget_amount, scheduled_at, time_window, urgency, status, contact_phone, contact_whatsapp, expires_at)
values
  ('00000000-0000-0000-0000-000000000304', '00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000206', '00000000-0000-0000-0000-000000000252', 'Repair kitchen sink pipe', 'Repair a leaking kitchen sink pipe and check the shutoff valve.', 'Taman Molek', '8 Example Street, Taman Molek, Johor Bahru', 140, now() - interval '2 days', '10am-2pm', 'normal', 'completed', '+60 12 000 0101', '+60 12 000 0101', now() - interval '1 day')
on conflict (id) do nothing;

insert into public.bids (id, job_id, provider_id, amount, available_at, inclusions, exclusions, materials_note, message, status)
values
  ('00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000102', 120, now() + interval '7 hours', 'Inspection and labour', 'Materials and wall hacking', 'Parts charged only after confirmation.', 'I can inspect and explain the repair before work starts.', 'pending'),
  ('00000000-0000-0000-0000-000000000402', '00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000104', 95, now() + interval '5 hours', 'Inspection and basic unclogging', 'Replacement parts', null, 'Available nearby.', 'pending'),
  ('00000000-0000-0000-0000-000000000403', '00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000102', 90, now() + interval '3 days', 'Two movers and trolley', 'Staircase surcharge', null, 'Ready for the scheduled window.', 'accepted')
on conflict (id) do nothing;

insert into public.bids (id, job_id, provider_id, amount, available_at, inclusions, exclusions, materials_note, message, status)
values
  ('00000000-0000-0000-0000-000000000404', '00000000-0000-0000-0000-000000000304', '00000000-0000-0000-0000-000000000104', 125, now() - interval '2 days', 'Inspection and pipe repair', 'Replacement parts', 'Parts charged after confirmation.', 'The repair was completed during the scheduled visit.', 'accepted')
on conflict (id) do nothing;

update public.jobs
set accepted_bid_id = '00000000-0000-0000-0000-000000000403'
where id = '00000000-0000-0000-0000-000000000303';

update public.jobs
set accepted_bid_id = '00000000-0000-0000-0000-000000000404'
where id = '00000000-0000-0000-0000-000000000304';

insert into public.reports (id, job_id, reporter_id, reported_user_id, reason_code, description, status)
values (
  '00000000-0000-0000-0000-000000000501',
  '00000000-0000-0000-0000-000000000304',
  '00000000-0000-0000-0000-000000000101',
  '00000000-0000-0000-0000-000000000104',
  'work_quality',
  'The leak returned after the first visit and the provider stopped replying.',
  'open'
)
on conflict (id) do nothing;

insert into public.job_events (id, job_id, actor_id, event_type, metadata)
values
  ('00000000-0000-0000-0000-000000000501', '00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000101', 'job_published', '{"fixture":true}'::jsonb),
  ('00000000-0000-0000-0000-000000000502', '00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000101', 'bid_accepted', '{"bid_id":"00000000-0000-0000-0000-000000000403","fixture":true}'::jsonb)
on conflict (id) do nothing;

insert into public.notifications (id, user_id, type, title, body, reference_type, reference_id)
values
  ('00000000-0000-0000-0000-000000000601', '00000000-0000-0000-0000-000000000101', 'new_bid', 'Your job received a new offer', 'Toilet blockage has a new offer.', 'job', '00000000-0000-0000-0000-000000000301'),
  ('00000000-0000-0000-0000-000000000602', '00000000-0000-0000-0000-000000000102', 'provider_approved', 'Provider verification approved', 'You can now view matching jobs.', 'provider', '00000000-0000-0000-0000-000000000102')
on conflict (id) do nothing;

insert into public.admin_audit_events (id, actor_id, action, target_type, target_id, metadata, created_at)
values
  ('00000000-0000-0000-0000-000000000801', '00000000-0000-0000-0000-000000000199', 'provider_review_approved', 'provider', '00000000-0000-0000-0000-000000000102', '{"status":"approved","fixture":true}'::jsonb, now() - interval '13 days'),
  ('00000000-0000-0000-0000-000000000802', '00000000-0000-0000-0000-000000000199', 'report_fixture_created', 'report', '00000000-0000-0000-0000-000000000501', '{"status":"open","fixture":true}'::jsonb, now() - interval '2 days')
on conflict (id) do nothing;

insert into public.device_tokens (id, user_id, token, platform)
values
  ('00000000-0000-0000-0000-000000000701', '00000000-0000-0000-0000-000000000101', 'local-demo-device-token-android', 'android')
on conflict (id) do nothing;

commit;
