-- ============================================================
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- Fix 1: Update RLS tasks (pakai DO block biar aman)
DO $$
BEGIN
  DROP POLICY IF EXISTS "tasks_update_admin" ON public.tasks;
  DROP POLICY IF EXISTS "tasks_update"       ON public.tasks;
EXCEPTION WHEN OTHERS THEN NULL;
END;
$$;

CREATE POLICY "tasks_update" ON public.tasks FOR UPDATE TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  OR assigned_to = auth.uid()
  OR (
    assigned_to IS NULL AND (
      role_target = 'all'
      OR role_target = (SELECT role FROM public.profiles WHERE id = auth.uid() LIMIT 1)
    )
  )
);

-- Fix 2: Trigger hanya update poin, notifikasi dihandle frontend
CREATE OR REPLACE FUNCTION public.award_task_points()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'processed' AND OLD.status <> 'processed' AND NEW.assigned_to IS NOT NULL THEN
    UPDATE public.profiles
      SET points = points + COALESCE(NEW.points_reward, 10)
      WHERE id = NEW.assigned_to;
  END IF;
  RETURN NEW;
END;
$$;
