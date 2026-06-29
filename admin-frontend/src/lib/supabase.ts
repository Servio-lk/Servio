import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://szgvnurzdglflmdabjol.supabase.co'
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6Z3ZudXJ6ZGdsZmxtZGFiam9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4OTc3NTgsImV4cCI6MjA4NDQ3Mzc1OH0.MeQsJIGJ-Fy9GLrcHg3M1rM-eEIpmKKsRsrVYPI6U6E'

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
    storage: window.localStorage,
  },
})

