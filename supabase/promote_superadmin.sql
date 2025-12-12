-- Promote a user to superadmin
-- Replace '<USER_EMAIL_OR_ID>' with the actual user email or UUID

-- Option 1: Promote by user email
-- First, find the user ID by email:
-- select id from auth.users where email = 'user@example.com';

-- Option 2: Promote directly by user UUID (replace with actual UUID)
insert into public.roles (user_id, role)
values (
  '<USER_UUID_HERE>',  -- Replace with actual user UUID from auth.users
  'superadmin'
)
on conflict (user_id) 
do update set role = 'superadmin';

-- Example: To promote user by email in one query:
-- insert into public.roles (user_id, role)
-- select id, 'superadmin'
-- from auth.users
-- where email = 'admin@example.com'
-- on conflict (user_id) 
-- do update set role = 'superadmin';

-- Verify the promotion:
-- select u.email, r.role 
-- from public.roles r
-- join auth.users u on u.id = r.user_id
-- where r.role = 'superadmin';
