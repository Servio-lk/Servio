import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';

interface AuthGuardProps {
  children: React.ReactNode;
}

export function AuthGuard({ children }: AuthGuardProps) {
  const { isAuthenticated, isLoading, isBackendTokenReady } = useAuth();
  const location = useLocation();

  if (isLoading || (isAuthenticated && !isBackendTokenReady)) {
    // Show loading spinner while checking auth
    return (
      <div className="flex items-center justify-center h-screen w-full bg-gradient-to-b from-[#fff7f5] to-[#fbfbfb]">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-[#ff5d2e] border-t-transparent rounded-full animate-spin" />
          <p className="text-base font-medium text-black/70">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    // Redirect to login with return path
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return <>{children}</>;
}

export function GuestGuard({ children }: AuthGuardProps) {
  const { isAuthenticated, isAdmin, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-screen w-full bg-gradient-to-b from-[#fff7f5] to-[#fbfbfb]">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-[#ff5d2e] border-t-transparent rounded-full animate-spin" />
          <p className="text-base font-medium text-black/70">Loading...</p>
        </div>
      </div>
    );
  }

  if (isAuthenticated) {
    if (isAdmin) {
      const host = window.location.hostname;
      const port = window.location.port;
      const isCustomerPortOnEc2 = (port === '80' || port === '') && host !== 'localhost' && host !== '127.0.0.1';
      if (isCustomerPortOnEc2) {
        window.location.href = `${window.location.protocol}//${host}:8081/admin`;
        return null;
      }
      return <Navigate to="/admin" replace />;
    }
    const from = location.state?.from?.pathname || '/home';
    return <Navigate to={from} replace />;
  }

  return <>{children}</>;
}
