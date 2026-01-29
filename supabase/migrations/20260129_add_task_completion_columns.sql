-- Add completion tracking columns to tasks table
-- The code expects these columns directly on tasks, not in a separate completions table

ALTER TABLE tasks 
ADD COLUMN is_completed BOOLEAN DEFAULT false,
ADD COLUMN completed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN completed_by UUID REFERENCES profiles(id),
ADD COLUMN assigned_to UUID REFERENCES profiles(id);

-- Add index for quick filtering of incomplete tasks
CREATE INDEX idx_tasks_incomplete ON tasks(couple_id, is_completed) WHERE is_completed = false;

-- Add index for completion tracking
CREATE INDEX idx_tasks_completed ON tasks(completed_at DESC) WHERE is_completed = true;
