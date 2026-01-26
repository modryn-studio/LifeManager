-- LifeManager Database Schema
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";

-- =====================================================
-- TABLES
-- =====================================================

-- Couples table (shared household)
CREATE TABLE couples (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  household_name TEXT NOT NULL,
  timezone TEXT DEFAULT 'America/Chicago'
);

-- Profiles table (individual users in a couple)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  couple_id UUID REFERENCES couples(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  avatar_url TEXT,
  pending_partner_email TEXT, -- For "We'll link you when [email] joins"
  notification_preferences JSONB DEFAULT '{"morning_digest": true, "follow_ups": true}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tasks table (shared between couple)
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  couple_id UUID REFERENCES couples(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT CHECK (category IN ('household', 'pet', 'health', 'personal', 'sentimental')),
  due_date DATE, -- NULL for "clean when needed" tasks
  recurrence_pattern TEXT CHECK (recurrence_pattern IN ('daily', 'weekly', 'monthly', 'custom')),
  recurrence_interval INTEGER, -- e.g., every 24 days for Heartgard
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Task completions (tracks who did what, when)
CREATE TABLE task_completions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  completed_by UUID REFERENCES profiles(id),
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  notes TEXT
);

-- Task patterns (ML learning storage)
CREATE TABLE task_patterns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  couple_id UUID REFERENCES couples(id) ON DELETE CASCADE NOT NULL,
  task_description TEXT NOT NULL,
  detected_pattern TEXT NOT NULL, -- JSON: {"frequency": "monthly", "day_of_month": 24}
  embedding vector(1536), -- For similarity search
  confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1), -- 0.00 to 1.00
  suggested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  accepted BOOLEAN DEFAULT NULL -- NULL = pending, true = accepted, false = rejected
);

-- Reminders log (for accountability agent)
CREATE TABLE reminders_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  couple_id UUID REFERENCES couples(id) ON DELETE CASCADE,
  sent_to UUID REFERENCES profiles(id),
  message TEXT,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reminder_type TEXT CHECK (reminder_type IN ('morning_digest', 'follow_up', 'urgent')),
  acknowledged_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- RECURRING TASK AUTO-GENERATION TRIGGER
-- =====================================================

CREATE OR REPLACE FUNCTION create_next_recurring_task()
RETURNS TRIGGER AS $$
DECLARE
  completed_task tasks%ROWTYPE;
  next_due_date DATE;
BEGIN
  -- Get the completed task
  SELECT * INTO completed_task FROM tasks WHERE id = NEW.task_id;
  
  -- Only process if task has recurrence pattern
  IF completed_task.recurrence_pattern IS NOT NULL THEN
    -- Calculate next due date based on pattern
    CASE completed_task.recurrence_pattern
      WHEN 'daily' THEN
        next_due_date := COALESCE(completed_task.due_date, CURRENT_DATE) + INTERVAL '1 day';
      WHEN 'weekly' THEN
        next_due_date := COALESCE(completed_task.due_date, CURRENT_DATE) + INTERVAL '7 days';
      WHEN 'monthly' THEN
        next_due_date := COALESCE(completed_task.due_date, CURRENT_DATE) + INTERVAL '1 month';
      WHEN 'custom' THEN
        next_due_date := COALESCE(completed_task.due_date, CURRENT_DATE) + (completed_task.recurrence_interval || ' days')::INTERVAL;
      ELSE
        next_due_date := NULL;
    END CASE;
    
    -- Mark current task as inactive
    UPDATE tasks SET is_active = false, updated_at = NOW() WHERE id = NEW.task_id;
    
    -- Create next instance of the task
    INSERT INTO tasks (
      couple_id,
      title,
      description,
      category,
      due_date,
      recurrence_pattern,
      recurrence_interval,
      is_active,
      created_by
    ) VALUES (
      completed_task.couple_id,
      completed_task.title,
      completed_task.description,
      completed_task.category,
      next_due_date,
      completed_task.recurrence_pattern,
      completed_task.recurrence_interval,
      true,
      completed_task.created_by
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach trigger to task_completions
CREATE TRIGGER after_task_completion
  AFTER INSERT ON task_completions
  FOR EACH ROW
  EXECUTE FUNCTION create_next_recurring_task();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

ALTER TABLE couples ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders_log ENABLE ROW LEVEL SECURITY;

-- Couples: Users can only see their own couple
CREATE POLICY "Users can view their own couple" ON couples
  FOR SELECT USING (id IN (SELECT couple_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update their own couple" ON couples
  FOR UPDATE USING (id IN (SELECT couple_id FROM profiles WHERE id = auth.uid()));

-- Allow creating couples during signup
CREATE POLICY "Users can create couples" ON couples
  FOR INSERT WITH CHECK (true);

-- Profiles: Users can view profiles in their couple
CREATE POLICY "Users can view profiles in their couple" ON profiles
  FOR SELECT USING (
    couple_id IN (SELECT couple_id FROM profiles WHERE id = auth.uid())
    OR id = auth.uid()
  );

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (id = auth.uid());

-- Tasks: Users can CRUD tasks in their couple
CREATE POLICY "Users can manage tasks in their couple" ON tasks
  FOR ALL USING (couple_id IN (SELECT couple_id FROM profiles WHERE id = auth.uid()));

-- Completions: Users can manage completions in their couple
CREATE POLICY "Users can manage completions in their couple" ON task_completions
  FOR ALL USING (task_id IN (
    SELECT id FROM tasks WHERE couple_id IN (
      SELECT couple_id FROM profiles WHERE id = auth.uid()
    )
  ));

-- Patterns: Users can view/manage patterns in their couple
CREATE POLICY "Users can manage patterns in their couple" ON task_patterns
  FOR ALL USING (couple_id IN (SELECT couple_id FROM profiles WHERE id = auth.uid()));

-- Reminders: Users can view their own reminders
CREATE POLICY "Users can view their reminders" ON reminders_log
  FOR SELECT USING (sent_to = auth.uid() OR couple_id IN (SELECT couple_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update their reminders" ON reminders_log
  FOR UPDATE USING (sent_to = auth.uid());

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX idx_profiles_couple_id ON profiles(couple_id);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_pending_partner ON profiles(pending_partner_email) WHERE pending_partner_email IS NOT NULL;

CREATE INDEX idx_tasks_couple_id ON tasks(couple_id);
CREATE INDEX idx_tasks_due_date ON tasks(due_date) WHERE is_active = true;
CREATE INDEX idx_tasks_active ON tasks(couple_id, is_active) WHERE is_active = true;

CREATE INDEX idx_completions_task_id ON task_completions(task_id);
CREATE INDEX idx_completions_completed_at ON task_completions(completed_at);
CREATE INDEX idx_completions_completed_by ON task_completions(completed_by);

CREATE INDEX idx_patterns_couple_id ON task_patterns(couple_id);
CREATE INDEX idx_patterns_pending ON task_patterns(couple_id) WHERE accepted IS NULL;

-- Vector similarity index for pattern matching (create after data exists)
-- CREATE INDEX idx_patterns_embedding ON task_patterns USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

CREATE INDEX idx_reminders_sent_to ON reminders_log(sent_to);
CREATE INDEX idx_reminders_unacknowledged ON reminders_log(sent_to, sent_at) WHERE acknowledged_at IS NULL;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to link partners when second person joins
CREATE OR REPLACE FUNCTION link_pending_partner()
RETURNS TRIGGER AS $$
DECLARE
  pending_profile profiles%ROWTYPE;
BEGIN
  -- Check if anyone is waiting for this email
  SELECT * INTO pending_profile 
  FROM profiles 
  WHERE pending_partner_email = NEW.email 
  AND couple_id IS NOT NULL
  LIMIT 1;
  
  IF FOUND THEN
    -- Link the new user to the existing couple
    NEW.couple_id := pending_profile.couple_id;
    
    -- Clear the pending email from the other profile
    UPDATE profiles 
    SET pending_partner_email = NULL 
    WHERE id = pending_profile.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-link partners on profile creation
CREATE TRIGGER on_profile_created
  BEFORE INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION link_pending_partner();
