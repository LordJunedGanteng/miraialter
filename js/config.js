// =====================================================
//  Mirai Atelier — Supabase Configuration
//  1. Buat project di https://app.supabase.com
//  2. Masuk ke Settings → API
//  3. Copy Project URL & anon/public key ke sini
// =====================================================

const SUPABASE_URL      = 'YOUR_SUPABASE_URL_HERE';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY_HERE';

const db = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
