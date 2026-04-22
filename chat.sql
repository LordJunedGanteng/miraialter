-- ============================================================
--  Mirai Atelier — Chat / Channel System
--  Run in: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── CHANNELS ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.chat_channels (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name        TEXT NOT NULL,
  category    TEXT NOT NULL DEFAULT 'UMUM',
  description TEXT,
  position    INTEGER NOT NULL DEFAULT 0,
  type        TEXT NOT NULL DEFAULT 'text'
                CHECK (type IN ('text', 'announcement')),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── MESSAGES ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.chat_messages (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  channel_id  UUID NOT NULL REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content     TEXT NOT NULL DEFAULT '',
  reply_to_id UUID REFERENCES public.chat_messages(id) ON DELETE SET NULL,
  is_edited   BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  edited_at   TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS chat_messages_channel_time_idx
  ON public.chat_messages (channel_id, created_at);

-- ── ATTACHMENTS ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.chat_attachments (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  message_id  UUID NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
  file_url    TEXT NOT NULL,
  file_name   TEXT NOT NULL,
  file_type   TEXT NOT NULL DEFAULT 'application/octet-stream',
  file_size   BIGINT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── ROW LEVEL SECURITY ───────────────────────────────────────

ALTER TABLE public.chat_channels    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_attachments ENABLE ROW LEVEL SECURITY;

-- chat_channels policies
CREATE POLICY "chat_channels_read" ON public.chat_channels
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "chat_channels_admin_insert" ON public.chat_channels
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "chat_channels_admin_update" ON public.chat_channels
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "chat_channels_admin_delete" ON public.chat_channels
  FOR DELETE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- chat_messages policies
CREATE POLICY "chat_messages_read" ON public.chat_messages
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "chat_messages_insert_own" ON public.chat_messages
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "chat_messages_update_own" ON public.chat_messages
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "chat_messages_delete_own_or_admin" ON public.chat_messages
  FOR DELETE TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- chat_attachments policies
CREATE POLICY "chat_attachments_read" ON public.chat_attachments
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "chat_attachments_insert_own" ON public.chat_attachments
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.chat_messages
      WHERE id = message_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "chat_attachments_delete_own_or_admin" ON public.chat_attachments
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.chat_messages
      WHERE id = message_id AND user_id = auth.uid()
    )
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ── REALTIME ─────────────────────────────────────────────────

ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_attachments;

-- ── SEED DEFAULT CHANNELS ────────────────────────────────────

INSERT INTO public.chat_channels (name, category, description, position, type) VALUES
  -- UMUM
  ('general',       'UMUM',    'Obrolan umum untuk semua anggota',         1, 'text'),
  ('pengumuman',    'UMUM',    'Pengumuman penting dari admin',             2, 'announcement'),
  -- DIVISI
  ('programmer',    'DIVISI',  'Diskusi khusus tim programmer',             3, 'text'),
  ('3d-artist',     'DIVISI',  'Diskusi khusus tim 3D artist',              4, 'text'),
  ('animator',      'DIVISI',  'Diskusi khusus tim animator',               5, 'text'),
  ('ui-designer',   'DIVISI',  'Diskusi khusus tim UI/UX designer',         6, 'text'),
  ('sound-designer','DIVISI',  'Diskusi khusus tim sound designer',         7, 'text'),
  -- PROJECT
  ('show-off',      'PROJECT', 'Pameran karya dan progress project',        8, 'text'),
  ('feedback',      'PROJECT', 'Berikan dan terima feedback untuk project', 9, 'text'),
  ('bugs-issues',   'PROJECT', 'Laporan bug dan issue teknis',             10, 'text')
ON CONFLICT DO NOTHING;
