-- Manually delete the user by email to clean up the failed registration state
-- Run this in Supabase SQL Editor

delete from auth.users where email = 'wficmmarikinachapter@gmail.com';
