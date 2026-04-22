-- Run in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS public.submission_comments (
  id           uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  submission_id uuid       NOT NULL REFERENCES task_submissions(id) ON DELETE CASCADE,
  user_id      uuid        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content      text        NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.submission_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read_all"    ON submission_comments FOR SELECT TO authenticated USING (true);
CREATE POLICY "own_insert"  ON submission_comments FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "own_delete"  ON submission_comments FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Index for fast lookup by submission
CREATE INDEX IF NOT EXISTS submission_comments_submission_id_idx ON submission_comments(submission_id);
