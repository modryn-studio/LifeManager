-- Schedule Edge Functions using pg_cron
-- Run this after deploying the Edge Functions

-- Enable pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Morning digest: Every day at 7 AM (America/Chicago)
SELECT cron.schedule(
  'morning-digest-7am',
  '0 7 * * *',
  $$
  SELECT
    net.http_post(
      url := 'https://vcbknqnrxzzfrxpjcbcl.supabase.co/functions/v1/morning-digest',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- Accountability agent: Every 2 hours
SELECT cron.schedule(
  'accountability-agent-2h',
  '0 */2 * * *',
  $$
  SELECT
    net.http_post(
      url := 'https://vcbknqnrxzzfrxpjcbcl.supabase.co/functions/v1/accountability-agent',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- Pattern analyzer: Weekly on Sunday at midnight
SELECT cron.schedule(
  'pattern-analyzer-weekly',
  '0 0 * * 0',
  $$
  SELECT
    net.http_post(
      url := 'https://vcbknqnrxzzfrxpjcbcl.supabase.co/functions/v1/pattern-analyzer',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

-- View scheduled jobs
-- SELECT * FROM cron.job;

-- To unschedule (if needed):
-- SELECT cron.unschedule('morning-digest-7am');
-- SELECT cron.unschedule('accountability-agent-2h');
-- SELECT cron.unschedule('pattern-analyzer-weekly');
