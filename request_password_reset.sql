-- Run in Supabase SQL Editor

CREATE OR REPLACE FUNCTION public.request_password_reset(p_username text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  SELECT id INTO v_user_id FROM public.profiles WHERE username = p_username LIMIT 1;

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'not_found');
  END IF;

  -- Skip if there's already a pending request
  IF EXISTS (
    SELECT 1 FROM public.password_reset_requests
    WHERE user_id = v_user_id AND status = 'pending'
  ) THEN
    RETURN json_build_object('success', true, 'message', 'already_pending');
  END IF;

  INSERT INTO public.password_reset_requests (user_id, status)
  VALUES (v_user_id, 'pending');

  RETURN json_build_object('success', true);
END;
$$;

-- Allow unauthenticated (anon) users to call this function
GRANT EXECUTE ON FUNCTION public.request_password_reset(text) TO anon, authenticated;
