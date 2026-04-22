-- Run in Supabase SQL Editor

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN (
    'produser',
    'director',
    'modeller',
    'programmer',
    'animator',
    'ui_designer',
    'sound_designer',
    'admin'
  ));
