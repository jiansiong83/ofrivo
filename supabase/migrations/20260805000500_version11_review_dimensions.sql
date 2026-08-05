-- Version 1.1: richer review dimensions.
-- Existing reviews receive a safe legacy default; new inserts must provide all
-- three dimension scores explicitly after the migration is applied.

alter table public.reviews
  add column if not exists punctuality_rating integer not null default 5,
  add column if not exists quality_rating integer not null default 5,
  add column if not exists communication_rating integer not null default 5;

alter table public.reviews
  alter column punctuality_rating drop default,
  alter column quality_rating drop default,
  alter column communication_rating drop default;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'reviews_punctuality_rating_range'
      and conrelid = 'public.reviews'::regclass
  ) then
    alter table public.reviews
      add constraint reviews_punctuality_rating_range
      check (punctuality_rating between 1 and 5);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'reviews_quality_rating_range'
      and conrelid = 'public.reviews'::regclass
  ) then
    alter table public.reviews
      add constraint reviews_quality_rating_range
      check (quality_rating between 1 and 5);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'reviews_communication_rating_range'
      and conrelid = 'public.reviews'::regclass
  ) then
    alter table public.reviews
      add constraint reviews_communication_rating_range
      check (communication_rating between 1 and 5);
  end if;
end;
$$;
