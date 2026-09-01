import { type ReactNode } from 'react';
import { Link, Navigate, useLocation, Outlet } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';

interface AdminGuardProps {
  children?: ReactNode;
}

export function AdminGuard({ children }: AdminGuardProps) {
  const { isAuthenticated, isAdmin, isLoading, isBackendTokenReady } = useAuth();
  const location = useLocation();

  if (isLoading || (isAuthenticated && !isBackendTokenReady)) {
    return (
      <div className="flex items-center justify-center h-screen w-full bg-[#fff7f5]">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-[#ff5d2e] border-t-transparent rounded-full animate-spin" />
          <p className="text-base font-medium text-black/70">Loading Admin Module...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (!isAdmin) {
    return (
      <div className="flex flex-col items-center justify-center h-screen w-full bg-[#fff7f5] gap-4 p-6 text-center">
        <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-2">
          <svg className="w-8 h-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <h1 className="text-2xl font-bold text-gray-900">Access Denied</h1>
        <p className="text-gray-600 max-w-md">You do not have administrative privileges to access the Servio Admin Portal.</p>
        <Link
          to="/home"
          className="mt-2 inline-flex items-center justify-center px-5 py-2.5 bg-[#ff5d2e] hover:bg-[#e04d22] text-white font-medium rounded-lg transition-colors shadow-sm"
        >
          Return to Customer Portal
        </Link>
      </div>
    );
  }

  return children ? <>{children}</> : <Outlet />;
}

export default AdminGuard;
