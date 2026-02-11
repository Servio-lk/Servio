import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabaseAuth } from '@/services/supabaseAuth';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';

export default function AuthCallback() {
  const navigate = useNavigate();
  const { login } = useAuth();

  useEffect(() => {
    const handleCallback = async () => {
      try {
        const session = await supabaseAuth.getCurrentSession();

        if (session && session.user) {
          // Map Supabase user to our User interface
          const userData = {
            id: session.user.id,
            fullName: session.user.user_metadata?.full_name ||
                     session.user.user_metadata?.name ||
                     session.user.email?.split('@')[0] || 'User',
            email: session.user.email || '',
            phone: session.user.user_metadata?.phone || null,
            role: session.user.user_metadata?.role || 'USER',
          };

          login(userData, session);
          toast.success('Welcome to Servio!');
          navigate('/home');
        } else {
          toast.error('Authentication failed');
          navigate('/login');
        }
      } catch (error) {
        console.error('Auth callback error:', error);
        toast.error('Authentication failed');
        navigate('/login');
      }
    };

    handleCallback();
  }, [navigate, login]);

  return (
    <div className="flex items-center justify-center min-h-screen bg-white">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#FF5D2E] mx-auto mb-4"></div>
        <p className="text-gray-600">Completing sign in...</p>
      </div>
    </div>
  );
}

