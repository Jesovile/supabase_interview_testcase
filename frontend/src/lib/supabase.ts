import { createClient } from '@supabase/supabase-js'
import type { Database } from './database.types'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    'Missing Supabase env vars. Copy frontend/.env.example to .env.local and fill in VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY.',
  )
}

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey)

// Convenience row types reused across the app.
export type Profile = Database['public']['Tables']['profiles']['Row']
export type Project = Database['public']['Tables']['projects']['Row']
export type ProjectStage = Database['public']['Tables']['project_stages']['Row']
