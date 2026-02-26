import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from 'react';
import { supabaseAuth } from '@/services/supabaseAuth';
import { registerAuthHandlers } from '@/services/apiFetch';
import type { User as SupabaseUser, Session } from '@supabase/supabase-js';

interface User {
  id: string;
  fullName: string;
  email: string;
  phone: string | null;
  role?: string;
}

interface AuthContextType {
  user: User | null;
  session: Session | null;
  isAuthenticated: boolean;
  isAdmin: boolean;
  isLoading: boolean;
  login: (user: User, session: Session) => void;
  logout: () => Promise<void>;
  supabaseUser: SupabaseUser | null;
  refreshBackendToken: () => Promise<boolean>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

function mapSupabaseUser(supabaseUser: SupabaseUser): User {
  return {
    id: supabaseUser.id,
    fullName: supabaseUser.user_metadata?.full_name || supabaseUser.email?.split('@')[0] || 'User',
    email: supabaseUser.email || '',
    phone: supabaseUser.user_metadata?.phone || null,
    role:
      supabaseUser.user_metadata?.role?.toUpperCase() ||
      (supabaseUser.email === 'admin@servio.lk' ? 'ADMIN' : 'USER'),
  };
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [supabaseUser, setSupabaseUser] = useState<SupabaseUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isBackendTokenReady, setIsBackendTokenReady] = useState(false);

  // ---------------------------------------------------------------------------
  // refreshBackendToken
  // Refreshes the Supabase session and exchanges it for a new backend JWT.
  // Returns true on success, false on failure.
  // Also called automatically by apiFetch whenever a 401 is received.
  // ---------------------------------------------------------------------------
  const refreshBackendToken = useCallback(async (): Promise<boolean> => {
    try {
      const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';
      const { session: freshSession } = await supabaseAuth.refreshSession();
      if (!freshSession?.access_token) return false;

      const response = await fetch(`${API_URL}/auth/supabase-login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          accessToken: freshSession.access_token,
          email: freshSession.user.email,
          fullName: freshSession.user.user_metadata?.full_name || '',
          phone: freshSession.user.user_metadata?.phone || '',
          role: freshSession.user.user_metadata?.role || 'USER',
        }),
      });

      const data = await response.json();
      if (data.success && data.data?.token) {
        localStorage.setItem('token', data.data.token);
        if (data.data.user) {
          localStorage.setItem('user', JSON.stringify(data.data.user));
        }
        console.log('[Auth] Backend token refreshed successfully');
        return true;
      }
      return false;
    } catch {
      return false;
    }
  }, []);

  // ---------------------------------------------------------------------------
  // Register refreshBackendToken + force-logout with apiFetch.
  // Any fetch() call in api.ts / adminApi.ts that uses apiFetch() will
  // automatically call this if it receives a 401.
  // ---------------------------------------------------------------------------
  useEffect(() => {
    registerAuthHandlers(
      refreshBackendToken,
      async () => {
        await supabaseAuth.signOut();
        localStorage.removeItem('token');
        setUser(null);
        setSession(null);
        setSupabaseUser(null);
        setIsBackendTokenReady(false);
      }
    );
  }, [refreshBackendToken]);

  // ---------------------------------------------------------------------------
  // Initialise auth state from the stored Supabase session.
  // ---------------------------------------------------------------------------
  useEffect(() => {
    const initializeAuth = async () => {
      try {
        const currentSession = await supabaseAuth.getCurrentSession();
        if (currentSession) {
          setSession(currentSession);
          setSupabaseUser(currentSession.user);
          setUser(mapSupabaseUser(currentSession.user));
        }
      } catch (error) {
        console.error('Error initializing auth:', error);
      } finally {
        setIsLoading(false);
      }
    };

    initializeAuth();

    // SIGNED_IN  → real login; clear old backend token so we get a fresh one
    // TOKEN_REFRESHED → Supabase silently rotated access_token; keep backend token
    // SIGNED_OUT → clear everything
    const { data: authListener } = supabaseAuth.onAuthStateChange((newSession, authEvent) => {
      if (authEvent === 'SIGNED_OUT' || !newSession) {
        setUser(null);
        setSession(null);
        setSupabaseUser(null);
        localStorage.removeItem('token');
        setIsBackendTokenReady(false);
      } else {
        setSession(newSession);
        setSupabaseUser(newSession.user);
        setUser(mapSupabaseUser(newSession.user));

        if (authEvent === 'SIGNED_IN') {
          localStorage.removeItem('token');
          setIsBackendTokenReady(false);
        }
      }
    });

    return () => {
      authListener?.subscription.unsubscribe();
    };
  }, []);

  // ---------------------------------------------------------------------------
  // Exchange the Supabase access_token for a backend JWT once per session.
  // ---------------------------------------------------------------------------
  useEffect(() => {
    const syncBackendToken = async () => {
      if (!session || !user || isBackendTokenReady) return;

      try {
        const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

        // Refresh Supabase session to guarantee a fresh access_token.
        // TOKEN_REFRESHED won't re-trigger this effect because isBackendTokenReady
        // is set to true in the finally block before any state update fires.
        let accessToken = session.access_token;
        try {
          const { session: freshSession } = await supabaseAuth.refreshSession();
          if (freshSession?.access_token) {
            accessToken = freshSession.access_token;
          }
        } catch {
          // proceed with existing token if refresh fails
        }

        console.log('[Auth] Exchanging Supabase token for backend token...');

        const response = await fetch(`${API_URL}/auth/supabase-login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            accessToken,
            email: user.email,
            fullName: user.fullName,
            phone: user.phone || '',
            role: user.role || 'USER',
          }),
        });

        const text = await response.text();
        try {
          const data = JSON.parse(text);
          if (data.success && data.data?.token) {
            localStorage.setItem('token', data.data.token);
            if (data.data.user) {
              localStorage.setItem('user', JSON.stringify(data.data.user));
            }
            console.log('[Auth] Backend token stored successfully');
          } else {
            console.warn('[Auth] supabase-login did not return a token:', data);
          }
        } catch {
          console.warn('[Auth] Could not parse supabase-login response:', text);
        }
      } catch (error) {
        console.error('[Auth] Backend token exchange network error:', error);
      } finally {
        setIsBackendTokenReady(true);
      }
    };

    syncBackendToken();
  }, [session, user, isBackendTokenReady]);

  const login = (userData: User, userSession: Session) => {
    setUser(userData);
    setSession(userSession);
    setSupabaseUser(userSession.user);
    setIsBackendTokenReady(false);
  };

  const logout = async () => {
    await supabaseAuth.signOut();
    setUser(null);
    setSession(null);
    setSupabaseUser(null);
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setIsBackendTokenReady(false);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        session,
        isAuthenticated: !!session,
        isAdmin: user?.role === 'ADMIN',
        isLoading: isLoading || (!!session && !!user && !isBackendTokenReady),
        login,
        logout,
        supabaseUser,
        refreshBackendToken,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
