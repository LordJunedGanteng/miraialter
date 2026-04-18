-- Run this in Supabase SQL Editor
-- Safe to re-run: drops and recreates the notifications table

DROP TABLE IF EXISTS notifications CASCADE;

CREATE TABLE notifications (
  id           uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  recipient_id uuid        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  sender_id    uuid        REFERENCES profiles(id) ON DELETE SET NULL,
  type         text        NOT NULL,
  task_id      uuid        REFERENCES tasks(id) ON DELETE CASCADE,
  title        text        NOT NULL,
  message      text,
  is_read      boolean     NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX notifications_recipient_idx ON notifications(recipient_id, is_read);
CREATE INDEX notifications_created_idx   ON notifications(created_at DESC);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read_own"
  ON notifications FOR SELECT TO authenticated
  USING (auth.uid() = recipient_id);

CREATE POLICY "insert_own"
  ON notifications FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "update_own"
  ON notifications FOR UPDATE TO authenticated
  USING (auth.uid() = recipient_id);
