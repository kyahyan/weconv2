-- Add team_name column to service_assignments
ALTER TABLE service_assignments 
ADD COLUMN team_name text NOT NULL DEFAULT 'General';
