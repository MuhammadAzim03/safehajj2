-- Define a type to structure the returned member data
create type public.group_member as (
  user_id uuid,
  full_name text,
  email text,
  role public.user_role
);

-- RPC to get all members of a specific group
create or replace function public.get_group_members(p_group_id uuid)
returns setof public.group_member
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Security check: Ensure the caller is a super admin
  if not is_super_admin() then
    raise exception 'Only super admins can view group members.';
  end if;

  -- Return the list of members for the given group
  return query
    select
      p.id as user_id,
      p.full_name,
      u.email,
      p.role
    from
      public.profiles as p
    join
      auth.users as u on p.id = u.id
    where
      p.group_id = p_group_id
    order by
      p.role, p.full_name;
end;
$$;

grant execute on function public.get_group_members(uuid) to authenticated;
