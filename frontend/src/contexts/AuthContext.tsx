import { createContext, useContext, useState, useEffect, useCallback, useRef, type ReactNode } from 'react';
import { supabaseAuth } from '@/services/supabaseAuth';
import { registerAuthHandlers } from '@/services/apiFetch';
import type { User as SupabaseUser, Session } from '@supabase/supabase-js';

const getApiBaseUrl = () => {
  let envApi = import.meta.env.VITE_API_URL;

  // Ignore hardcoded localhost env vars if we are deployed on a real domain
  const isLocalEnvApi = envApi && (envApi.includes('localhost') || envApi.includes('127.0.0.1'));
  const isLocalHost = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
  
  if (isLocalEnvApi && !isLocalHost) {
    envApi = undefined;
  } else if (envApi && envApi.startsWith('http://') && window.location.protocol === 'https:') {
    envApi = undefined;
  }

  if (envApi) {
    return envApi;
  }

  const host = window.location.hostname;
  if (host === 'localhost' || host === '127.0.0.1') {
    return `http://${host}:3001/api`;
  }

  return `${window.location.origin}/api`;
};

async function exchangeSupabaseToken(payload: {
  accessToken: string;
  email: string;
  fullName: string;
  phone: string;
  role: string;
}) {
  const apiBase = getApiBaseUrl();
  try {
    const controller = new AbortController();
    const timeoutId = window.setTimeout(() => controller.abort(), 10000);

    const response = await fetch(`${apiBase}/auth/supabase-login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    window.clearTimeout(timeoutId);

    const data = await response.json();
    if (data?.success && data?.data?.token) {
      return data;
    }
    return null;
  } catch {
    return null;
  }
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

function areUsersEqual(a: User | null, b: User | null): boolean {
  return (
    a?.id === b?.id &&
    a?.email === b?.email &&
    a?.fullName === b?.fullName &&
    a?.phone === b?.phone &&
    a?.role === b?.role
  );
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [supabaseUser, setSupabaseUser] = useState<SupabaseUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isBackendTokenReady, setIsBackendTokenReady] = useState(false);
  const attemptedTokenExchange = useRef<Set<string>>(new Set());
  const sessionRef = useRef<Session | null>(null);
  const userRef = useRef<User | null>(null);
  const backendTokenReadyRef = useRef(false);

  useEffect(() => {
    sessionRef.current = session;
  }, [session]);

  useEffect(() => {
    userRef.current = user;
  }, [user]);

  useEffect(() => {
    backendTokenReadyRef.current = isBackendTokenReady;
  }, [isBackendTokenReady]);

  const applySessionState = useCallback((nextSession: Session, forceUserUpdate = false) => {
    const nextUser = mapSupabaseUser(nextSession.user);

    sessionRef.current = nextSession;
    setSession(prev => (prev?.access_token === nextSession.access_token ? prev : nextSession));
    setSupabaseUser(prev => (prev?.id === nextSession.user.id ? prev : nextSession.user));

    if (forceUserUpdate || !areUsersEqual(userRef.current, nextUser)) {
      userRef.current = nextUser;
      setUser(nextUser);
    }
  }, []);

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
          applySessionState(currentSession);
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
        sessionRef.current = null;
        userRef.current = null;
        setUser(null);
        setSession(null);
        setSupabaseUser(null);
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        setIsBackendTokenReady(false);
        attemptedTokenExchange.current.clear();
        return;
      }

      const previousSession = sessionRef.current;
      const sameUser = previousSession?.user.id === newSession.user.id;

      applySessionState(newSession, authEvent === 'USER_UPDATED');

      // Supabase can emit SIGNED_IN again when a suspended tab wakes up. Treat
      // that as a silent session confirmation for the same user, otherwise the
      // app clears the backend token and the route guards flash a full loader.
      if (authEvent === 'SIGNED_IN' && !sameUser) {
        localStorage.removeItem('token');
        setIsBackendTokenReady(false);
        attemptedTokenExchange.current.clear();
      } else if ((authEvent === 'TOKEN_REFRESHED' || authEvent === 'SIGNED_IN') && backendTokenReadyRef.current) {
        setIsBackendTokenReady(true);
      }
    });

    return () => {
      authListener?.subscription.unsubscribe();
    };
  }, [applySessionState]);

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
              setUser(prev => {
                if (!prev) return prev;
                const nextUser = { ...prev, role: backendRole };
                userRef.current = nextUser;
                return nextUser;
              });
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
    userRef.current = userData;
    sessionRef.current = userSession;
    setUser(userData);
    setSession(userSession);
    setSupabaseUser(userSession.user);
    setIsBackendTokenReady(false);
    attemptedTokenExchange.current.clear();
  };

  const logout = async () => {
    await supabaseAuth.signOut();
    userRef.current = null;
    sessionRef.current = null;
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
