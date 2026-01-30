-- Add couple_id to task_completions for efficient pattern analysis
-- This allows the pattern analyzer to query completions by couple without joining through tasks

ALTER TABLE task_completions 
ADD COLUMN couple_id UUID REFERENCES couples(id) ON DELETE CASCADE;

-- Backfill existing records (get couple_id from their associated task)
UPDATE task_completions tc
SET couple_id = (
  SELECT t.couple_id 
  FROM tasks t 
  WHERE t.id = tc.task_id
);

-- Make couple_id NOT NULL after backfill
ALTER TABLE task_completions 
ALTER COLUMN couple_id SET NOT NULL;

-- Add index for efficient couple-based queries (used by pattern analyzer)
CREATE INDEX idx_task_completions_couple ON task_completions(couple_id, completed_at DESC);
