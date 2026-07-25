-- Supabase SQL instructions to automatically delete URLs older than 30 days
-- Run this in your Supabase SQL Editor

-- Create a function that will delete URLs older than 30 days
CREATE OR REPLACE FUNCTION delete_old_urls()
RETURNS void AS $$
BEGIN
  DELETE FROM urls 
  WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Make sure pg_cron is enabled for your project by executing this extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule the function to run daily at midnight
SELECT cron.schedule(
  'delete-old-urls-daily', -- name of the cron job
  '0 0 * * *',             -- standard cron expression for "every day at midnight"
  'SELECT delete_old_urls()'
);

-- Note: If you want to check if the cron job is scheduled properly, run:
-- SELECT * FROM cron.job;
