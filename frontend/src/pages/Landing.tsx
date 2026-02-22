import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { LogOut, LogIn, LayoutDashboard } from 'lucide-react';

export default function Landing() {
  const navigate = useNavigate();
  const { isAuthenticated, logout, isAdmin } = useAuth();

  const handleSignIn = async () => {
    // Sign out first if authenticated
    if (isAuthenticated) {
      await logout();
    }
    navigate('/login');
  };

  const handleContinueToAdmin = () => {
    if (isAdmin) {
      navigate('/admin/customers');
    } else {
      navigate('/home');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-b from-[#fff7f5] to-[#fbfbfb] px-4">
      <div className="max-w-md w-full">
        {/* Logo / Branding */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-[#ff5d2e] mb-2">Servio</h1>
          <p className="text-gray-600">Vehicle Service Management</p>
        </div>

        {/* Card */}
        <div className="bg-white rounded-lg shadow-lg p-8">
          {isAuthenticated ? (
            <>
              {/* Authenticated State */}
              <div className="text-center mb-8">
                <div className="inline-flex items-center justify-center w-12 h-12 bg-[#ff5d2e]/10 rounded-full mb-4">
                  <LayoutDashboard className="w-6 h-6 text-[#ff5d2e]" />
                </div>
                <h2 className="text-2xl font-bold text-black mb-2">Welcome Back!</h2>
                <p className="text-gray-600 text-sm">You're already signed in</p>
              </div>

              {/* Buttons */}
              <div className="space-y-3">
                <button
                  onClick={handleContinueToAdmin}
                  className="w-full bg-[#ff5d2e] text-white py-3 rounded-lg font-semibold hover:bg-[#ff4a1a] transition-colors flex items-center justify-center gap-2"
                >
                  <LayoutDashboard className="w-5 h-5" />
                  Continue to {isAdmin ? 'Admin Panel' : 'Dashboard'}
                </button>

                <button
                  onClick={handleSignIn}
                  className="w-full bg-gray-100 text-gray-700 py-3 rounded-lg font-semibold hover:bg-gray-200 transition-colors flex items-center justify-center gap-2"
                >
                  <LogOut className="w-5 h-5" />
                  Sign In as Different User
                </button>
              </div>
            </>
          ) : (
            <>
              {/* Unauthenticated State */}
              <div className="text-center mb-8">
                <div className="inline-flex items-center justify-center w-12 h-12 bg-[#ff5d2e]/10 rounded-full mb-4">
                  <LogIn className="w-6 h-6 text-[#ff5d2e]" />
                </div>
                <h2 className="text-2xl font-bold text-black mb-2">Get Started</h2>
                <p className="text-gray-600 text-sm">Sign in to manage your vehicles and services</p>
              </div>

              {/* Buttons */}
              <div className="space-y-3">
                <button
                  onClick={() => navigate('/login')}
                  className="w-full bg-[#ff5d2e] text-white py-3 rounded-lg font-semibold hover:bg-[#ff4a1a] transition-colors flex items-center justify-center gap-2"
                >
                  <LogIn className="w-5 h-5" />
                  Sign In
                </button>

                <button
                  onClick={() => navigate('/signup')}
                  className="w-full bg-gray-100 text-gray-700 py-3 rounded-lg font-semibold hover:bg-gray-200 transition-colors"
                >
                  Create Account
                </button>
              </div>

              {/* Footer text */}
              <p className="text-center text-gray-500 text-xs mt-6">
                Already have an account? <a href="/login" className="text-[#ff5d2e] font-semibold">Sign in</a>
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
