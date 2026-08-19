create extension if not exists pgcrypto;

create type public.user_role as enum ('customer','barber','manager','owner','admin');
create type public.appointment_status as enum ('pending','confirmed','checked_in','in_progress','completed','cancelled','no_show');
create type public.booking_source as enum ('website','mobile','telegram','barber','admin');

create table public.shops (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  logo_path text,
  phone text,
  address text,
  timezone text not null default 'Asia/Tashkent',
  currency text not null default 'UZS',
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  avatar_path text,
  role public.user_role not null default 'customer',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.shop_members (
  shop_id uuid not null references public.shops(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role public.user_role not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (shop_id, profile_id)
);

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  profile_id uuid references public.profiles(id) on delete set null,
  name text not null,
  phone text,
  email text,
  telegram_id text,
  preferences jsonb not null default '{}'::jsonb,
  total_visits integer not null default 0,
  total_spent numeric(12,2) not null default 0,
  last_visit_at timestamptz,
  created_at timestamptz not null default now(),
  unique(shop_id, phone)
);

create table public.barbers (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  bio text,
  avatar_path text,
  active boolean not null default true,
  unique(shop_id, profile_id)
);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  name text not null,
  description text,
  duration_minutes integer not null check (duration_minutes > 0),
  price numeric(12,2) not null check (price >= 0),
  category text,
  image_path text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.barber_services (
  barber_id uuid not null references public.barbers(id) on delete cascade,
  service_id uuid not null references public.services(id) on delete cascade,
  custom_price numeric(12,2) check (custom_price >= 0),
  custom_duration_minutes integer check (custom_duration_minutes > 0),
  primary key (barber_id, service_id)
);

create table public.working_hours (
  id uuid primary key default gen_random_uuid(),
  barber_id uuid not null references public.barbers(id) on delete cascade,
  weekday smallint not null check (weekday between 0 and 6),
  start_time time not null,
  end_time time not null,
  unique(barber_id, weekday, start_time)
);

create table public.time_off (
  id uuid primary key default gen_random_uuid(),
  barber_id uuid not null references public.barbers(id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  reason text,
  check (ends_at > starts_at)
);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete restrict,
  barber_id uuid not null references public.barbers(id) on delete restrict,
  status public.appointment_status not null default 'confirmed',
  start_at timestamptz not null,
  end_at timestamptz not null,
  total_price numeric(12,2) not null default 0,
  source public.booking_source not null default 'website',
  notes text,
  created_at timestamptz not null default now(),
  check (end_at > start_at)
);

create table public.appointment_services (
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  service_id uuid not null references public.services(id) on delete restrict,
  price numeric(12,2) not null check (price >= 0),
  duration_minutes integer not null check (duration_minutes > 0),
  primary key (appointment_id, service_id)
);

create table public.customer_notes (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  appointment_id uuid references public.appointments(id) on delete set null,
  author_id uuid references public.profiles(id) on delete set null,
  note text not null,
  ai_summary text,
  created_at timestamptz not null default now()
);

create table public.customer_photos (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  appointment_id uuid references public.appointments(id) on delete set null,
  storage_path text not null,
  kind text not null default 'after' check (kind in ('before','after','reference','other')),
  caption text,
  created_at timestamptz not null default now()
);

create table public.notification_jobs (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  appointment_id uuid references public.appointments(id) on delete cascade,
  channel text not null check (channel in ('telegram','sms','push','email')),
  template_key text not null,
  scheduled_for timestamptz not null,
  sent_at timestamptz,
  status text not null default 'pending' check (status in ('pending','processing','sent','failed','cancelled')),
  attempts integer not null default 0,
  last_error text,
  created_at timestamptz not null default now()
);

create index appointments_barber_start_idx on public.appointments(barber_id, start_at);
create index appointments_customer_start_idx on public.appointments(customer_id, start_at desc);
create index notification_jobs_due_idx on public.notification_jobs(status, scheduled_for);
create index customer_notes_customer_idx on public.customer_notes(customer_id, created_at desc);
create index customer_photos_customer_idx on public.customer_photos(customer_id, created_at desc);

alter table public.shops enable row level security;
alter table public.profiles enable row level security;
alter table public.shop_members enable row level security;
alter table public.customers enable row level security;
alter table public.barbers enable row level security;
alter table public.services enable row level security;
alter table public.barber_services enable row level security;
alter table public.working_hours enable row level security;
alter table public.time_off enable row level security;
alter table public.appointments enable row level security;
alter table public.appointment_services enable row level security;
alter table public.customer_notes enable row level security;
alter table public.customer_photos enable row level security;
alter table public.notification_jobs enable row level security;

create or replace function public.is_shop_member(target_shop uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.shop_members sm
    where sm.shop_id = target_shop and sm.profile_id = auth.uid() and sm.active
  );
$$;

create policy "members can read shops" on public.shops for select using (public.is_shop_member(id));
create policy "users can read own profile" on public.profiles for select using (id = auth.uid());
create policy "members can read membership" on public.shop_members for select using (profile_id = auth.uid() or public.is_shop_member(shop_id));
create policy "members can read customers" on public.customers for select using (public.is_shop_member(shop_id));
create policy "members can read barbers" on public.barbers for select using (public.is_shop_member(shop_id));
create policy "members can read services" on public.services for select using (public.is_shop_member(shop_id));
create policy "members can read barber services" on public.barber_services for select using (exists (select 1 from public.barbers b where b.id = barber_id and public.is_shop_member(b.shop_id)));
create policy "members can read working hours" on public.working_hours for select using (exists (select 1 from public.barbers b where b.id = barber_id and public.is_shop_member(b.shop_id)));
create policy "members can read time off" on public.time_off for select using (exists (select 1 from public.barbers b where b.id = barber_id and public.is_shop_member(b.shop_id)));
create policy "members can read appointments" on public.appointments for select using (public.is_shop_member(shop_id));
create policy "members can read appointment services" on public.appointment_services for select using (exists (select 1 from public.appointments a where a.id = appointment_id and public.is_shop_member(a.shop_id)));
create policy "members can read customer notes" on public.customer_notes for select using (public.is_shop_member(shop_id));
create policy "members can read customer photos" on public.customer_photos for select using (public.is_shop_member(shop_id));

-- Writes will be added with role-aware policies as the booking API is implemented.
