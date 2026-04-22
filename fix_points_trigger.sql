-- Fix trigger award_task_points: wrong column 'user_id' → 'recipient_id'
-- Run this in Supabase SQL Editor

CREATE OR REPLACE FUNCTION public.award_task_points()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'processed' AND OLD.status <> 'processed' AND NEW.assigned_to IS NOT NULL THEN
    -- Add points to user profile
    UPDATE public.profiles
      SET points = points + COALESCE(NEW.points_reward, 10)
      WHERE id = NEW.assigned_to;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_task_processed ON public.tasks;
CREATE TRIGGER on_task_processed
  AFTER UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.award_task_points();
