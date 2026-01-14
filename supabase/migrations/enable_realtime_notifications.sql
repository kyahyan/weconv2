-- Enable Realtime for notifications table
-- This allows the flutter client to listen to changes via .stream()
alter publication supabase_realtime add table notifications;
