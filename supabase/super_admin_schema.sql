-- Roles table linking to auth.users
create table if not exists public.roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('superadmin','admin','user')),
  created_at timestamptz default now()
);

alter table public.roles enable row level security;
drop policy if exists roles_read_all on public.roles;
create policy roles_read_all on public.roles for select using (auth.uid() is not null);
drop policy if exists roles_insert_self on public.roles;
create policy roles_insert_self on public.roles for insert with check (auth.uid() = user_id);
drop policy if exists roles_update_self on public.roles;
create policy roles_update_self on public.roles for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Groups table
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz default now()
);
alter table public.groups enable row level security;
drop policy if exists groups_select_all on public.groups;
create policy groups_select_all on public.groups for select using (auth.uid() is not null);
-- Only superadmins can mutate groups via a secured function, provide helper policies if needed

-- Group admins assignment
create table if not exists public.group_admins (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('admin')),
  created_at timestamptz default now(),
  unique (group_id, user_id, role)
);
alter table public.group_admins enable row level security;
drop policy if exists group_admins_select_all on public.group_admins;
create policy group_admins_select_all on public.group_admins for select using (auth.uid() is not null);

-- Explore content (map locations/items for user explore screen)
create table if not exists public.explore_items (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  latitude double precision,
  longitude double precision,
  category text,
  image_url text,
  created_at timestamptz default now(),
  updated_at timestamptz
);
alter table public.explore_items enable row level security;
drop policy if exists explore_select_all on public.explore_items;
create policy explore_select_all on public.explore_items for select using (auth.uid() is not null);

-- Homescreen info (Umrah/Hajj)
create table if not exists public.home_info (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in ('umrah','hajj')),
  title text not null,
  description text not null,
  image_url text,
  created_at timestamptz default now(),
  updated_at timestamptz
);
alter table public.home_info enable row level security;
drop policy if exists home_info_select_all on public.home_info;
create policy home_info_select_all on public.home_info for select using (auth.uid() is not null);

-- Secured RPCs for superadmin operations
create or replace function public.is_superadmin() returns boolean as $$
  select exists (
    select 1 from public.roles r where r.user_id = auth.uid() and r.role = 'superadmin'
  );
$$ language sql stable security definer;

-- Secure bootstrap: allow assigning superadmin if a secret code matches
create or replace function public.superadmin_promote_with_code(p_code text) returns void as $$
declare
  expected_code text;
begin
  -- Read a custom setting 'app.superadmin_code'; set it via: SELECT set_config('app.superadmin_code', '<YOUR_CODE>', true);
  -- In production, manage this through Supabase config/Secrets or a secure table.
  expected_code := current_setting('app.superadmin_code', true);
  if expected_code is null then
    raise exception 'missing_superadmin_code_setting';
  end if;
  if p_code <> expected_code then
    raise exception 'invalid_code';
  end if;
  insert into public.roles(user_id, role)
  values (auth.uid(), 'superadmin')
  on conflict (user_id) do update set role = excluded.role;
end;
$$ language plpgsql security definer;

create or replace function public.super_group_create(p_name text) returns uuid as $$
  declare new_id uuid;
begin
  if not public.is_superadmin() then
    raise exception 'not authorized';
  end if;
  insert into public.groups(name) values (p_name) returning id into new_id;
  return new_id;
end;
$$ language plpgsql security definer;

create or replace function public.super_group_update(p_group_id uuid, p_name text) returns void as $$
begin
  if not public.is_superadmin() then
    raise exception 'not authorized';
  end if;
  update public.groups set name = p_name, created_at = created_at where id = p_group_id;
end;
$$ language plpgsql security definer;

create or replace function public.super_group_delete(p_group_id uuid) returns void as $$
begin
  if not public.is_superadmin() then
    raise exception 'not authorized';
  end if;
  delete from public.groups where id = p_group_id;
end;
$$ language plpgsql security definer;

create or replace function public.super_assign_admin(p_group_id uuid, p_user_id uuid, p_role text) returns void as $$
begin
  if not public.is_superadmin() then
    raise exception 'not authorized';
  end if;
  insert into public.group_admins(group_id, user_id, role)
  values (p_group_id, p_user_id, p_role)
  on conflict (group_id, user_id, role) do nothing;
end;
$$ language plpgsql security definer;

create or replace function public.super_remove_admin(p_group_id uuid, p_user_id uuid, p_role text) returns void as $$
begin
  if not public.is_superadmin() then
    raise exception 'not authorized';
  end if;
  delete from public.group_admins where group_id = p_group_id and user_id = p_user_id and role = p_role;
end;
$$ language plpgsql security definer;

create or replace function public.super_explore_upsert(p_id uuid, p_title text, p_description text, p_latitude double precision, p_longitude double precision, p_category text, p_image_url text) returns uuid as $$
  declare new_id uuid;
begin
  if not public.is_superadmin() then
    raise exception 'not authorized';
  end if;
  if p_id is null then
    insert into public.explore_items(title, description, latitude, longitude, category, image_url) 
    values (p_title, p_description, p_latitude, p_longitude, p_category, nullif(p_image_url, '')) returning id into new_id;
    return new_id;
  else
    update public.explore_items 
    set title = p_title, description = p_description, latitude = p_latitude, longitude = p_longitude, 
        category = p_category, image_url = nullif(p_image_url, ''), updated_at = now() 
    where id = p_id;
    return p_id;
  end if;
end;
$$ language plpgsql security definer;

create or replace function public.super_explore_delete(p_id uuid) returns void as $$
begin
  if not public.is_superadmin() then
    raise exception 'not authorized';
  end if;
  delete from public.explore_items where id = p_id;
end;
$$ language plpgsql security definer;

create or replace function public.super_homeinfo_upsert(p_id uuid, p_category text, p_title text, p_description text, p_image_url text) returns uuid as $$
  declare new_id uuid;
begin
  if not public.is_superadmin() then
    raise exception 'not authorized';
  end if;
  if p_id is null then
    insert into public.home_info(category, title, description, image_url) values (p_category, p_title, p_description, coalesce(p_image_url,'')) returning id into new_id;
    return new_id;
  else
    update public.home_info set category = p_category, title = p_title, description = p_description, image_url = p_image_url, updated_at = now() where id = p_id;
    return p_id;
  end if;
end;
$$ language plpgsql security definer;

create or replace function public.super_homeinfo_delete(p_id uuid) returns void as $$
begin
  if not public.is_superadmin() then
    raise exception 'not authorized';
  end if;
  delete from public.home_info where id = p_id;
end;
$$ language plpgsql security definer;

-- Function to create a default role for a new user
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.roles (user_id, role)
  values (new.id, 'user');
  return new;
end;
$$ language plpgsql security definer;

-- Trigger to run the function after a new user is created
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
