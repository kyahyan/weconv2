-- Add end_time column to services table
ALTER TABLE services ADD COLUMN end_time timestamptz;

-- Optional: Add a check constraint to ensure end_time > date (start_time)
-- ALTER TABLE services ADD CONSTRAINT check_end_time_after_start_time CHECK (end_time > date);
