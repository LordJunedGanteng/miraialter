const SUPABASE_URL      = 'https://zwoxqbnefnmrnlsmpecv.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3b3hxYm5lZm5tcm5sc21wZWN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1Mjg2NDEsImV4cCI6MjA5MjEwNDY0MX0.tc26YsN0fEwsLvIGxgttKZI4en19dPm-W1gEUGvPBmk';

const db = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);