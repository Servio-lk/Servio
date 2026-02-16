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
            role: currentSession.user.user_metadata?.role || 'USER',
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
          role: newSession.user.user_metadata?.role || 'USER',
        };
        setUser(userData);
      } else {
        setUser(null);
        setSupabaseUser(null);
      }
    });

    return () => {
      authListener?.subscription.unsubscribe();
    };
  }, []);

  const login = (userData: User, userSession: Session) => {
    setUser(userData);
    setSession(userSession);
    setSupabaseUser(userSession.user);
  };

  const logout = async () => {
    await supabaseAuth.signOut();
    setUser(null);
    setSession(null);
    setSupabaseUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        session,
        isAuthenticated: !!session,
        isAdmin: user?.role === 'ADMIN',
        isLoading,
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
