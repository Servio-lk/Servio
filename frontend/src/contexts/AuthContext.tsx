import { createContext, useContext, useState, useEffect, type ReactNode } from 'react';
import { supabaseAuth } from '@/services/supabaseAuth';
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
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [supabaseUser, setSupabaseUser] = useState<SupabaseUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isBackendTokenReady, setIsBackendTokenReady] = useState(false);

  useEffect(() => {
    // Initialize auth state from Supabase
    const initializeAuth = async () => {
      try {
        const currentSession = await supabaseAuth.getCurrentSession();

        if (currentSession) {
          setSession(currentSession);
          setSupabaseUser(currentSession.user);

          // Map Supabase user to our User interface
          const userData: User = {
            id: currentSession.user.id,
            fullName: currentSession.user.user_metadata?.full_name || currentSession.user.email?.split('@')[0] || 'User',
            email: currentSession.user.email || '',
            phone: currentSession.user.user_metadata?.phone || null,
            role: currentSession.user.user_metadata?.role?.toUpperCase() || (currentSession.user.email === 'admin@servio.lk' ? 'ADMIN' : 'USER'),
          };
          setUser(userData);
        }
      } catch (error) {
        console.error('Error initializing auth:', error);
      } finally {
        setIsLoading(false);
      }
    };

    initializeAuth();

    // Listen to auth state changes
    const { data: authListener } = supabaseAuth.onAuthStateChange((newSession) => {
      setSession(newSession);

      if (newSession) {
        setSupabaseUser(newSession.user);
        const userData: User = {
          id: newSession.user.id,
          fullName: newSession.user.user_metadata?.full_name || newSession.user.email?.split('@')[0] || 'User',
          email: newSession.user.email || '',
          phone: newSession.user.user_metadata?.phone || null,
          role: newSession.user.user_metadata?.role?.toUpperCase() || (newSession.user.email === 'admin@servio.lk' ? 'ADMIN' : 'USER'),
        };
        setUser(userData);
      } else {
        setUser(null);
        setSupabaseUser(null);
        setIsBackendTokenReady(false);
      }
    });

    return () => {
      authListener?.subscription.unsubscribe();
    };
  }, []);

  // Exchange Supabase token for Backend Spring Boot token
  useEffect(() => {
    const syncBackendToken = async () => {
      if (session && user && !isBackendTokenReady) {
        try {
          const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';
          console.log('[Auth] Exchanging Supabase token for backend token...');
          const response = await fetch(`${API_URL}/auth/supabase-login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              accessToken: session.access_token,
              email: user.email,
              fullName: user.fullName,
              phone: user.phone || '',
              role: user.role || 'USER'
            })
          });
          console.log('[Auth] supabase-login response status:', response.status);
          const text = await response.text();
          console.log('[Auth] supabase-login raw response:', text);
          try {
            const data = JSON.parse(text);
            if (data.success && data.data?.token) {
              localStorage.setItem('token', data.data.token);
              if (data.data.user) {
                localStorage.setItem('user', JSON.stringify(data.data.user));
              }
              console.log('[Auth] Backend token stored successfully');
              setIsBackendTokenReady(true);
            } else {
              console.warn('[Auth] supabase-login did not return a token:', data);
              setIsBackendTokenReady(true); // unblock UI even on non-success
            }
          } catch {
            console.warn('[Auth] Could not parse supabase-login response:', text);
            setIsBackendTokenReady(true); // unblock UI
          }
        } catch (error) {
          console.error('[Auth] Backend token exchange network error:', error);
          setIsBackendTokenReady(true); // unblock UI even on network failure
        }
      } else if (!session) {
        localStorage.removeItem('token');
        setIsBackendTokenReady(false);
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
