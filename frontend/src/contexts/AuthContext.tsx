import { createContext, useContext, useState, useEffect, useCallback, useRef, type ReactNode } from 'react';
import { supabaseAuth } from '@/services/supabaseAuth';
import { registerAuthHandlers } from '@/services/apiFetch';
import type { User as SupabaseUser, Session } from '@supabase/supabase-js';

const getApiBaseCandidates = () => {
  const host = window.location.hostname;
  const candidates = [
    import.meta.env.VITE_API_URL,
    `http://${host}:3001/api`,
    'http://localhost:3001/api',
    'http://127.0.0.1:3001/api',
  ].filter((url): url is string => Boolean(url));

  return Array.from(new Set(candidates));
};

async function fetchWithTimeout(input: RequestInfo | URL, init: RequestInit, timeoutMs = 10000) {
  const controller = new AbortController();
  const timeoutId = window.setTimeout(() => controller.abort(), timeoutMs);

  try {
    return await fetch(input, { ...init, signal: controller.signal });
  } finally {
    window.clearTimeout(timeoutId);
  }
}

async function exchangeSupabaseToken(payload: {
  accessToken: string;
  email: string;
  fullName: string;
  phone: string;
  role: string;
}) {
  for (const apiBase of getApiBaseCandidates()) {
    try {
      const response = await fetchWithTimeout(
        `${apiBase}/auth/supabase-login`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        },
        5000,
      );

      const data = await response.json();
      if (data?.success && data?.data?.token) {
        return data;
      }

      // Server responded but did not issue token, do not keep trying other hosts.
      return null;
    } catch {
      // Try next host candidate.
    }
  }

  return null;
}

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
  isBackendTokenReady: boolean;
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
  const attemptedTokenExchange = useRef<Set<string>>(new Set());

  const refreshBackendToken = useCallback(async (): Promise<boolean> => {
    try {
      const { session: freshSession } = await supabaseAuth.refreshSession();
      if (!freshSession?.access_token) return false;

      const data = await exchangeSupabaseToken({
        accessToken: freshSession.access_token,
        email: freshSession.user.email || '',
        fullName: freshSession.user.user_metadata?.full_name || '',
        phone: freshSession.user.user_metadata?.phone || '',
        role: freshSession.user.user_metadata?.role || 'USER',
      });

      if (data?.success && data.data?.token) {
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

  useEffect(() => {
    registerAuthHandlers(
      refreshBackendToken,
      async () => {
        await supabaseAuth.signOut();
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        setUser(null);
        setSession(null);
        setSupabaseUser(null);
        setIsBackendTokenReady(false);
        attemptedTokenExchange.current.clear();
      },
    );
  }, [refreshBackendToken]);

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

    const { data: authListener } = supabaseAuth.onAuthStateChange((newSession, authEvent) => {
      setIsLoading(false);

      if (authEvent === 'SIGNED_OUT' || !newSession) {
        setUser(null);
        setSession(null);
        setSupabaseUser(null);
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        setIsBackendTokenReady(false);
        attemptedTokenExchange.current.clear();
        return;
      }

      setSession(newSession);
      setSupabaseUser(newSession.user);
      setUser(mapSupabaseUser(newSession.user));

      if (authEvent === 'SIGNED_IN') {
        localStorage.removeItem('token');
        setIsBackendTokenReady(false);
        attemptedTokenExchange.current.clear();
      }
    });

    return () => {
      authListener?.subscription.unsubscribe();
    };
  }, []);

  useEffect(() => {
    const syncBackendToken = async () => {
      if (!session || !user || isBackendTokenReady) return;

      const accessToken = session.access_token;
      if (attemptedTokenExchange.current.has(accessToken)) {
        setIsBackendTokenReady(true);
        return;
      }

      attemptedTokenExchange.current.add(accessToken);
      setIsBackendTokenReady(true);

      try {
        console.log('[Auth] Exchanging Supabase token for backend token...');

        const data = await exchangeSupabaseToken({
          accessToken,
          email: user.email,
          fullName: user.fullName,
          phone: user.phone || '',
          role: user.role || 'USER',
        });

        if (data?.success && data.data?.token) {
          localStorage.setItem('token', data.data.token);
          if (data.data.user) {
            localStorage.setItem('user', JSON.stringify(data.data.user));
            // Update the user role from backend response (authoritative source —
            // the backend checks profiles.is_admin / profiles.role in the DB)
            const backendRole = data.data.user.role?.toUpperCase();
            if (backendRole && backendRole !== user.role) {
              setUser(prev => prev ? { ...prev, role: backendRole } : prev);
            }
          }
          console.log('[Auth] Backend token stored successfully');
        } else {
          console.warn('[Auth] supabase-login did not return a token');
        }
      } catch (error) {
        console.error('[Auth] Backend token exchange network error:', error);
      }
    };

    syncBackendToken();
  }, [session, user, isBackendTokenReady]);

  const login = (userData: User, userSession: Session) => {
    setUser(userData);
    setSession(userSession);
    setSupabaseUser(userSession.user);
    setIsBackendTokenReady(false);
    attemptedTokenExchange.current.clear();
  };

  const logout = async () => {
    await supabaseAuth.signOut();
    setUser(null);
    setSession(null);
    setSupabaseUser(null);
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setIsBackendTokenReady(false);
    attemptedTokenExchange.current.clear();
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        session,
        isAuthenticated: !!session,
        isAdmin: user?.role === 'ADMIN' || user?.role === 'admin',
        isLoading,
        login,
        logout,
        supabaseUser,
        refreshBackendToken,
        isBackendTokenReady,
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
