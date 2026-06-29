import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';

interface AdminGuardProps {
  children: React.ReactNode;
}

export function AdminGuard({ children }: AdminGuardProps) {
  const { isAuthenticated, isAdmin, isLoading, isBackendTokenReady } = useAuth();
  const location = useLocation();

  if (isLoading || (isAuthenticated && !isBackendTokenReady)) {
    return (
      <div className="flex items-center justify-center h-screen w-full bg-[#fff7f5]">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-[#ff5d2e] border-t-transparent rounded-full animate-spin" />
          <p className="text-base font-medium text-black/70">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (!isAdmin) {
    return (
      <div className="flex flex-col items-center justify-center h-screen w-full bg-[#fff7f5] gap-4">
        <h1 className="text-2xl font-bold text-red-600">Access Denied</h1>
        <p className="text-gray-700">You do not have permission to access the admin portal.</p>
        <p className="text-sm text-gray-500">Please use the customer app instead.</p>
      </div>
    );
  }

  return <>{children}</>;
}