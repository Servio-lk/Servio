import { supabase } from '@/lib/supabase'
import type { User, Session, AuthError } from '@supabase/supabase-js'

export interface SupabaseAuthResponse {
  user: User | null
  session: Session | null
  error: AuthError | null
}

export interface SignUpData {
  email: string
  password: string
  fullName: string
  phone?: string
}

export interface SignInData {
  email: string
  password: string
}

class SupabaseAuthService {
  // Get current user
  async getCurrentUser(): Promise<User | null> {
    const { data } = await supabase.auth.getUser();
    return data.user;
  }

  // Get current session
  async getCurrentSession(): Promise<Session | null> {
    const { data } = await supabase.auth.getSession()
    return data.session
  }

  // Check if user is authenticated
  async isAuthenticated(): Promise<boolean> {
    const session = await this.getCurrentSession()
    return !!session
  }

  // Sign up with email and password
  async signUp(data: SignUpData): Promise<SupabaseAuthResponse> {
    const { email, password, fullName, phone } = data

    const { data: authData, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          phone: phone || null,
        },
      },
    })

    return {
      user: authData.user,
      session: authData.session,
      error,
    }
  }

  // Sign in with email and password
  async signIn(data: SignInData): Promise<SupabaseAuthResponse> {
    const { email, password } = data

    const { data: authData, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    return {
      user: authData.user,
      session: authData.session,
      error,
    }
  }

  // Sign in with Google
  async signInWithGoogle(): Promise<{ error: AuthError | null }> {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    })
    return { error }
  }

  // Sign in with Facebook
  async signInWithFacebook(): Promise<{ error: AuthError | null }> {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'facebook',
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    })
    return { error }
  }

  // Sign out
  async signOut(): Promise<{ error: AuthError | null }> {
    const { error } = await supabase.auth.signOut()
    return { error }
  }

  // Reset password
  async resetPassword(email: string): Promise<{ error: AuthError | null }> {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    })
    return { error }
  }

  // Update password
  async updatePassword(newPassword: string): Promise<SupabaseAuthResponse> {
    const { data, error } = await supabase.auth.updateUser({
      password: newPassword,
    })

    return {
      user: data.user,
      session: null,
      error,
    }
  }

  // Listen to auth state changes (receives both the event type and session)
  onAuthStateChange(callback: (session: Session | null, event: string) => void) {
    return supabase.auth.onAuthStateChange((event, session) => {
      callback(session, event)
    })
  }

  // Get access token
  async getAccessToken(): Promise<string | null> {
    const session = await this.getCurrentSession()
    return session?.access_token || null
  }

  // Refresh session
  async refreshSession(): Promise<SupabaseAuthResponse> {
    const { data, error } = await supabase.auth.refreshSession()
    return {
      user: data.user,
      session: data.session,
      error,
    }
  }
}

export const supabaseAuth = new SupabaseAuthService()




