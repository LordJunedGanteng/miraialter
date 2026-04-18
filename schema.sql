-- =====================================================
--  Mirai Atelier — Task Management System
--  Jalankan di: Supabase Dashboard → SQL Editor
-- =====================================================

-- UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── PROFILES ──────────────────────────────────────────
CREATE TABLE public.profiles (
  id          UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name   TEXT NOT NULL DEFAULT 'Developer',
  username    TEXT UNIQUE,
  role        TEXT NOT NULL DEFAULT 'programmer'
                CHECK (role IN ('produser','director','modeller','programmer','animator','ui_designer','admin')),
  avatar_url  TEXT,
  bio         TEXT,
  points      INTEGER NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── TASKS ─────────────────────────────────────────────
CREATE TABLE public.tasks (
  id            UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title         TEXT NOT NULL,
  description   TEXT,
  assigned_to   UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  assigned_by   UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  role_target   TEXT DEFAULT 'all'
                  CHECK (role_target IN ('produser','director','modeller','programmer','animator','ui_designer','all')),
  status        TEXT NOT NULL DEFAULT 'ongoing'
                  CHECK (status IN ('ongoing','on_review','processed','revision')),
  priority      TEXT NOT NULL DEFAULT 'medium'
                  CHECK (priority IN ('low','medium','high','urgent')),
  points_reward INTEGER NOT NULL DEFAULT 10,
  due_date      TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── TASK SUBMISSIONS ──────────────────────────────────
CREATE TABLE public.task_submissions (
  id           UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  task_id      UUID REFERENCES public.tasks(id) ON DELETE CASCADE NOT NULL,
  submitted_by UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  file_url     TEXT,
  file_name    TEXT,
  note         TEXT,
  submitted_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── NOTIFICATIONS ─────────────────────────────────────
CREATE TABLE public.notifications (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title      TEXT NOT NULL,
  message    TEXT,
  type       TEXT DEFAULT 'info' CHECK (type IN ('info','success','warning','error')),
  is_read    BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── ROW LEVEL SECURITY ────────────────────────────────
ALTER TABLE public.profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications   ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "profiles_read_all"    ON public.profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert_own"  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update_own"  ON public.profiles FOR UPDATE USING (
  auth.uid() = id OR
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Tasks
CREATE POLICY "tasks_read"          ON public.tasks FOR SELECT TO authenticated USING (true);
CREATE POLICY "tasks_insert_admin"  ON public.tasks FOR INSERT TO authenticated WITH CHECK (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','director'))
);
CREATE POLICY "tasks_update_admin"  ON public.tasks FOR UPDATE TO authenticated USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  OR assigned_to = auth.uid()
);
CREATE POLICY "tasks_delete_admin"  ON public.tasks FOR DELETE TO authenticated USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Submissions
CREATE POLICY "subs_read"    ON public.task_submissions FOR SELECT TO authenticated USING (true);
CREATE POLICY "subs_insert"  ON public.task_submissions FOR INSERT TO authenticated WITH CHECK (auth.uid() = submitted_by);

-- Notifications
CREATE POLICY "notif_read"   ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notif_insert" ON public.notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "notif_update" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- ── AUTO-CREATE PROFILE ON SIGNUP ─────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, username, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Developer'),
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || LEFT(NEW.id::TEXT, 8)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'programmer')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── AWARD POINTS WHEN TASK PROCESSED ─────────────────
CREATE OR REPLACE FUNCTION public.award_task_points()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'processed' AND OLD.status <> 'processed' AND NEW.assigned_to IS NOT NULL THEN
    UPDATE public.profiles
      SET points = points + COALESCE(NEW.points_reward, 10)
      WHERE id = NEW.assigned_to;

    INSERT INTO public.notifications (user_id, title, message, type)
    VALUES (
      NEW.assigned_to,
      '🏆 Task Selesai!',
      'Kamu mendapat ' || COALESCE(NEW.points_reward, 10) || ' poin untuk task: ' || NEW.title,
      'success'
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_task_processed ON public.tasks;
CREATE TRIGGER on_task_processed
  AFTER UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.award_task_points();

-- ── AUTO-UPDATE updated_at ────────────────────────────
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER profiles_touch BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER tasks_touch    BEFORE UPDATE ON public.tasks    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- ── STORAGE BUCKET ────────────────────────────────────
-- Jalankan ini terpisah jika tabel storage sudah ada:
INSERT INTO storage.buckets (id, name, public)
  VALUES ('task-submissions', 'task-submissions', false)
  ON CONFLICT DO NOTHING;

CREATE POLICY "upload_authenticated" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'task-submissions');

CREATE POLICY "read_authenticated" ON storage.objects
  FOR SELECT TO authenticated USING (bucket_id = 'task-submissions');

-- ── FIRST ADMIN ACCOUNT ───────────────────────────────
-- Setelah signup pertama, jalankan ini untuk jadikan admin:
-- UPDATE public.profiles SET role = 'admin' WHERE username = 'your_username';
