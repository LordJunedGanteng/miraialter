-- Fix: add sound_designer to tasks_role_target_check constraint
-- Step 1: Normalize any NULL or unknown role_target values to 'all'
UPDATE tasks
SET role_target = 'all'
WHERE role_target IS NULL
   OR role_target NOT IN ('all','video_editor','graphic_designer','thumbnail_designer','sound_designer');

-- Step 2: Drop old constraint and recreate with sound_designer included
ALTER TABLE tasks
  DROP CONSTRAINT IF EXISTS tasks_role_target_check;

ALTER TABLE tasks
  ADD CONSTRAINT tasks_role_target_check
  CHECK (role_target IN (
    'all',
    'video_editor',
    'graphic_designer',
    'thumbnail_designer',
    'sound_designer'
  ));
