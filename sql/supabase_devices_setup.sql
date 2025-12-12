-- supabase_devices_setup.sql
-- Setup tables/policies for device registration, group-based access, and secure device data ingestion.
-- Paste this into Supabase SQL editor and run.

-- 1) Enable helpful extensions (if available)
create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";

-- 1a) Profiles table for user information
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  avatar_url text,
  age integer,
  health_condition text,
  role text default 'user',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Enable RLS on profiles
alter table public.profiles enable row level security;

-- Profiles policies: allow all authenticated users to read all profiles (needed for displaying usernames)
drop policy if exists "profiles_select_all" on public.profiles;
create policy "profiles_select_all" on public.profiles for select
  using (auth.uid() is not null);

-- Allow users to insert/update their own profile
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles for insert
  with check (id = auth.uid());

create policy "profiles_update_own" on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

-- 2) Groups and membership
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  admin_user uuid references auth.users(id) on delete set null,
  created_at timestamptz default now()
);

create table if not exists public.group_members (
  group_id uuid references public.groups(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  role text default 'member',
  created_at timestamptz default now(),
  primary key (group_id, user_id)
);

-- 3) Devices table: stores a per-device secret token (device_key) to be used by the device
create table if not exists public.devices (
  id uuid primary key default gen_random_uuid(),
  name text,
  device_key text unique not null, -- long random token you generate per device
  group_id uuid references public.groups(id) on delete set null,
  registered_by uuid references auth.users(id) on delete set null,
  registered_at timestamptz default now(),
  is_active boolean default true
);

-- 4) Device incoming data
create table if not exists public.device_data (
  id bigserial primary key,
  device_id uuid references public.devices(id) on delete cascade,
  payload jsonb,
  created_at timestamptz default now()
);

-- Index for queries
create index if not exists idx_device_data_deviceid_createdat on public.device_data(device_id, created_at desc);
create index if not exists idx_devices_groupid on public.devices(group_id);

-- 5) Enable Row Level Security
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.devices enable row level security;
alter table public.device_data enable row level security;

-- 6) Policies
-- Groups: any authenticated user can view all groups (needed for claiming and joining)
drop policy if exists "groups_select_for_members_and_admin" on public.groups;
drop policy if exists "groups_insert_only_admin" on public.groups;
create policy "groups_select_for_members_and_admin"
  on public.groups
  for select
  using (auth.uid() is not null);

create policy "groups_insert_only_admin" on public.groups for insert
  with check (admin_user = auth.uid());

-- Allow claiming an unassigned group by setting yourself as admin, or unclaiming your own group
drop policy if exists "groups_update_claim_if_unassigned" on public.groups;
create policy "groups_update_claim_if_unassigned" on public.groups for update
  using (
    admin_user is null -- claiming: old row must be unclaimed
    or admin_user = auth.uid() -- unclaiming: must be current admin
  )
  with check (
    admin_user = auth.uid() -- claiming: new value is yourself
    or (admin_user is null and exists (select 1 from public.groups where id = public.groups.id and admin_user = auth.uid())) -- unclaiming: setting to null only if you were admin
  );

-- Group members: allow users to join themselves (insert where user_id = auth.uid()) and allow admins to manage membership
drop policy if exists "group_members_insert_self" on public.group_members;
drop policy if exists "group_members_select_for_member_or_admin" on public.group_members;
drop policy if exists "group_members_delete_self" on public.group_members;
drop policy if exists "group_members_update_self" on public.group_members;

create policy "group_members_insert_self" on public.group_members for insert
  with check (user_id = auth.uid());

create policy "group_members_select_for_member_or_admin" on public.group_members for select
  using (
    auth.uid() is not null -- any authenticated user can view all group members
  );

create policy "group_members_delete_self" on public.group_members for delete
  using (user_id = auth.uid());

create policy "group_members_update_self" on public.group_members for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Devices policies
-- Select: group members or group admin can view devices for that group
drop policy if exists "devices_select_for_group_members_or_admin" on public.devices;
drop policy if exists "devices_insert_for_group_member_or_admin" on public.devices;
drop policy if exists "devices_update_delete_owner_or_admin" on public.devices;
create policy "devices_select_for_group_members_or_admin" on public.devices for select
  using (
    exists (select 1 from public.group_members gm where gm.group_id = public.devices.group_id and gm.user_id = auth.uid())
    or exists (select 1 from public.groups g where g.id = public.devices.group_id and g.admin_user = auth.uid())
    or public.devices.registered_by = auth.uid() -- device owner can also see
  );

-- Insert: authenticated users may register devices for any group (open registration for Groups A-G)
create policy "devices_insert_for_group_member_or_admin" on public.devices for insert
  with check (
    auth.uid() is not null
    and (registered_by = auth.uid())
  );

-- Update/Delete: only group admin or the registering user can modify or delete
create policy "devices_update_delete_owner_or_admin" on public.devices for update using (
    public.devices.registered_by = auth.uid() or
    exists (select 1 from public.groups g where g.id = public.devices.group_id and g.admin_user = auth.uid())
  ) with check (
    public.devices.registered_by = auth.uid() or
    exists (select 1 from public.groups g where g.id = group_id and g.admin_user = auth.uid())
  );

-- Device data (inserts will normally come from the RPC function below; we keep a restrictive policy)
-- Select: allow group members and admin to query device_data for devices in their groups
drop policy if exists "device_data_select_for_group_members_or_admin" on public.device_data;
drop policy if exists "device_data_insert_by_device_owner" on public.device_data;
create policy "device_data_select_for_group_members_or_admin" on public.device_data for select
  using (
    exists (
      select 1 from public.devices d
      join public.group_members gm on gm.group_id = d.group_id
      where d.id = public.device_data.device_id and gm.user_id = auth.uid()
    )
    or exists (
      select 1 from public.devices d
      join public.groups g on g.id = d.group_id
      where d.id = public.device_data.device_id and g.admin_user = auth.uid()
    )
  );

-- Insert from authenticated users: only allow if the authenticated user is the device owner (registered_by)
create policy "device_data_insert_by_device_owner" on public.device_data for insert
  with check (
    exists (select 1 from public.devices d where d.id = device_id and d.registered_by = auth.uid())
  );

-- Note: For non-authenticated devices (Arduino), we will provide a SECURITY DEFINER RPC function
-- that validates a device token and inserts the device data (see below). That function runs
-- with elevated rights and bypasses RLS safely because it validates the device_key.

-- 7) RPC function for devices (Arduino/IoT) to push data using a per-device token
-- The device_key should be a long random secret that you provision on device registration.
create or replace function public.rpc_insert_device_payload(p_device_key text, p_payload jsonb)
  returns jsonb
  language plpgsql security definer
  set search_path = public
as $$
declare
  v_device uuid;
  v_user_id uuid;
  v_group_id uuid;
  v_panic_alert boolean;
begin
  -- Find the active device matching the token
  select id into v_device from public.devices where device_key = p_device_key and is_active limit 1;
  if v_device is null then
    raise exception 'invalid_device_token' using hint = 'check device key or device is deactivated';
  end if;

  -- Get device's user_id and group_id
  select registered_by, group_id into v_user_id, v_group_id from public.devices where id = v_device;

  insert into public.device_data(device_id, payload) values (v_device, p_payload);

  -- Check if panic_alert is true in the payload
  v_panic_alert := (p_payload ->> 'panic_alert')::boolean;
  
  -- If panic alert is triggered, create a panic_alert record
  if v_panic_alert then
    insert into public.panic_alerts (device_id, user_id, group_id, triggered_at)
    values (v_device, v_user_id, v_group_id, NOW());
  end if;

  return jsonb_build_object('status', 'ok', 'device_id', v_device);
end;
$$;

-- Grant execute on the rpc to anon so devices can call the RPC using the anon key
grant execute on function public.rpc_insert_device_payload(text, jsonb) to anon;

-- 8) Helpful views
create or replace view public.my_devices as
  select d.* from public.devices d
  where exists (select 1 from public.group_members gm where gm.group_id = d.group_id and gm.user_id = auth.uid())
  or exists (select 1 from public.groups g where g.id = d.group_id and g.admin_user = auth.uid())
  or d.registered_by = auth.uid();

-- 9) Example seeds (remove or modify for production)
-- create group example
-- insert into public.groups (name, admin_user) values ('Group A', '00000000-0000-0000-0000-000000000000');

-- 9a) Clean up duplicate admin assignments (keep only the first one per user)
do $$
declare
  admin_id uuid;
begin
  for admin_id in (
    select admin_user 
    from public.groups 
    where admin_user is not null 
    group by admin_user 
    having count(*) > 1
  ) loop
    -- Keep only the first group for this admin, unclaim the rest
    update public.groups 
    set admin_user = null 
    where admin_user = admin_id 
    and id not in (
      select id from public.groups 
      where admin_user = admin_id 
      order by created_at 
      limit 1
    );
  end loop;
end;
$$;

-- 9a2) Now create the unique constraint after cleanup
create unique index if not exists groups_admin_user_unique on public.groups (admin_user) where admin_user is not null;

-- 9b) Idempotent seed for Groups A-G (without admin assignments). Assign admins later manually.
do $$
declare
  g text;
begin
  for g in select unnest(array['Group A','Group B','Group C','Group D','Group E','Group F','Group G']) loop
    insert into public.groups(name)
    select g
    where not exists (select 1 from public.groups where name = g);
  end loop;
end;
$$;

-- 10) Usage examples (run in Supabase SQL Editor or via REST)
-- Register a device (as an authenticated user who is a member of group or admin):
-- insert into public.devices (name, device_key, group_id, registered_by) values ('Device 001', 'LONG_RANDOM_TOKEN', '<group_uuid>', auth.uid());

-- Arduino / IoT: POST to Supabase RPC endpoint:
-- curl -X POST \
--  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qem16eG9rd3p3aWNjYmdrdXhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyNDIwMzAsImV4cCI6MjA3NzgxODAzMH0.lVr70zs6t0d7xInKVTbuxQ5R11H3fie__5vsGTpSRkw" \
--  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qem16eG9rd3p3aWNjYmdrdXhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyNDIwMzAsImV4cCI6MjA3NzgxODAzMH0.lVr70zs6t0d7xInKVTbuxQ5R11H3fie__5vsGTpSRkw" \
--  -H "Content-Type: application/json" \
--  -d '{"p_device_key":"LONG_RANDOM_TOKEN","p_payload":{"temp":25.4,"hum":60}}' \
--  https://<project>.supabase.co/rest/v1/rpc/rpc_insert_device_payload

-- Notes:
-- - Using the RPC with SECURITY DEFINER and a device-specific secret token lets bare IoT devices send data
--   without exposing the Supabase service_role key to the device. Make sure to generate a strong random token
--   per device and keep it private.
-- - You can also implement an edge function to accept data and rotate/expire tokens, add additional validation,
--   or integrate with MQTT/broker flows.
-- - On iOS/Android clients, query `select * from public.my_devices` to list devices accessible to the current authenticated user.

-- End of file
