BEGIN;

-- Create enums
CREATE TYPE IF NOT EXISTS vision_status AS ENUM ('active','achieved','archived');
CREATE TYPE IF NOT EXISTS goal_status AS ENUM ('in_progress','completed','paused');
CREATE TYPE IF NOT EXISTS task_status AS ENUM ('todo','doing','done');
CREATE TYPE IF NOT EXISTS task_priority AS ENUM ('low','medium','high');

-- Create visions
CREATE TABLE IF NOT EXISTS public.visions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  description text,
  color text,
  status vision_status DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Create goals
CREATE TABLE IF NOT EXISTS public.goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  vision_id uuid REFERENCES public.visions(id) ON DELETE SET NULL,
  title text NOT NULL,
  description text,
  start_date date,
  end_date date,
  progress integer DEFAULT 0,
  status goal_status DEFAULT 'in_progress',
  ai_generated boolean DEFAULT false,
  custom_schema jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT progress_range CHECK (progress >= 0 AND progress <= 100)
);

-- Create tasks
CREATE TABLE IF NOT EXISTS public.tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  goal_id uuid REFERENCES public.goals(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  status task_status DEFAULT 'todo',
  priority task_priority DEFAULT 'medium',
  due_date timestamptz,
  custom_properties jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Create events
CREATE TABLE IF NOT EXISTS public.events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  goal_id uuid REFERENCES public.goals(id) ON DELETE CASCADE,
  title text NOT NULL,
  start_time timestamptz NOT NULL,
  end_time timestamptz NOT NULL,
  is_all_day boolean DEFAULT false,
  recurrence_rule text,
  parent_event_id uuid REFERENCES public.events(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT event_times_valid CHECK (is_all_day OR end_time > start_time)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_visions_user ON public.visions(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_user ON public.goals(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_vision ON public.goals(vision_id);
CREATE INDEX IF NOT EXISTS idx_tasks_user ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_goal ON public.tasks(goal_id);
CREATE INDEX IF NOT EXISTS idx_events_user ON public.events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_goal ON public.events(goal_id);
CREATE INDEX IF NOT EXISTS idx_goals_user_status ON public.goals(user_id, status);
CREATE INDEX IF NOT EXISTS idx_tasks_user_status ON public.tasks(user_id, status);

-- GIN indexes for JSONB
CREATE INDEX IF NOT EXISTS idx_goals_custom_schema_gin ON public.goals USING gin (custom_schema);
CREATE INDEX IF NOT EXISTS idx_tasks_custom_properties_gin ON public.tasks USING gin (custom_properties);

-- Enable RLS and create owner-only policies
ALTER TABLE public.visions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS visions_owner ON public.visions
  FOR ALL
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY IF NOT EXISTS goals_owner ON public.goals
  FOR ALL
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY IF NOT EXISTS tasks_owner ON public.tasks
  FOR ALL
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY IF NOT EXISTS events_owner ON public.events
  FOR ALL
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

COMMIT;