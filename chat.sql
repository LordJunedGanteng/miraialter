-- ============================================================
-- Jalankan di Supabase SQL Editor
-- Chat / Messages system untuk Mirai Atelier Hub
-- ============================================================

DROP TABLE IF EXISTS messages CASCADE;

CREATE TABLE messages (
  id            uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id     uuid        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  recipient_id  uuid        REFERENCES profiles(id) ON DELETE SET NULL,
  task_id       uuid        REFERENCES tasks(id) ON DELETE CASCADE,
  content       text        NOT NULL,
  is_read       boolean     NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  CHECK (recipient_id IS NOT NULL OR task_id IS NOT NULL)
);

CREATE INDEX messages_recipient_idx ON messages(recipient_id, is_read, created_at DESC);
CREATE INDEX messages_sender_idx    ON messages(sender_id, created_at DESC);
CREATE INDEX messages_task_idx      ON messages(task_id, created_at);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Siapa yang bisa baca pesan
CREATE POLICY "messages_select" ON messages FOR SELECT TO authenticated
USING (
  sender_id = auth.uid()
  OR recipient_id = auth.uid()
  OR (
    task_id IS NOT NULL AND (
      EXISTS(SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
      OR EXISTS(SELECT 1 FROM public.tasks   WHERE id = task_id AND assigned_to = auth.uid())
    )
  )
);

-- Hanya bisa kirim sebagai diri sendiri
CREATE POLICY "messages_insert" ON messages FOR INSERT TO authenticated
WITH CHECK (sender_id = auth.uid());

-- Hanya penerima (atau admin) yang bisa mark as read
CREATE POLICY "messages_update" ON messages FOR UPDATE TO authenticated
USING (
  recipient_id = auth.uid()
  OR EXISTS(SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Enable Realtime agar frontend bisa subscribe
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
