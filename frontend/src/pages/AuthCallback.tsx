import { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabaseAuth } from '@/services/supabaseAuth';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';

export default function AuthCallback() {
  const navigate = useNavigate();
  const { login, refreshBackendToken } = useAuth();
  const processedRef = useRef(false);

  useEffect(() => {
    if (processedRef.current) return;
    processedRef.current = true;

    let isMounted = true;

    const handleCallback = async () => {
      try {
        // Give Supabase time to parse the OAuth hash fragments if not immediate
        let session = await supabaseAuth.getCurrentSession();
        if (!session) {
          for (let i = 0; i < 5; i++) {
            await new Promise(resolve => setTimeout(resolve, 200));
            session = await supabaseAuth.getCurrentSession();
            if (session) break;
          }
        }

        if (session && session.user && isMounted) {
          // Map Supabase user to our User interface with safe fallback for Facebook accounts without email
          const userMeta = session.user.user_metadata || {};
          const email = session.user.email ||
                       userMeta.email ||
                       `${session.user.id}@oauth.servio.local`;

          const fullName = userMeta.full_name ||
                          userMeta.name ||
                          session.user.email?.split('@')[0] ||
                          'User';

          const userData = {
            id: session.user.id,
            fullName,
            email,
            phone: userMeta.phone || null,
            role: 'USER',
          };

          login(userData, session);

          // Attempt backend token exchange with the established session
          const backendSuccess = await refreshBackendToken();

          if (isMounted) {
            let userRole = 'USER';
            try {
              const storedUserJson = localStorage.getItem('user');
              if (storedUserJson) {
                const parsed = JSON.parse(storedUserJson);
                userRole = (parsed.role || 'USER').toUpperCase();
              }
            } catch {}

            if (backendSuccess) {
              toast.success('Welcome to Servio!');
            }

            if (userRole === 'ADMIN') {
              const host = window.location.hostname;
              const port = window.location.port;
              const isCustomerPortOnEc2 = (port === '80' || port === '') && host !== 'localhost' && host !== '127.0.0.1';

              if (isCustomerPortOnEc2) {
                window.location.href = `${window.location.protocol}//${host}:8081/admin`;
              } else {
                navigate('/admin', { replace: true });
              }
            } else {
              navigate('/home', { replace: true });
            }
          }
        } else if (isMounted) {
          toast.error('Authentication failed');
          navigate('/login', { replace: true });
        }
      } catch (error) {
        console.error('Auth callback error:', error);
        if (isMounted) {
          toast.error('Authentication failed');
          navigate('/login', { replace: true });
        }
      }
    };

    handleCallback();

    return () => {
      isMounted = false;
    };
  }, [navigate, login, refreshBackendToken]);

  return (
    <div className="flex items-center justify-center min-h-screen bg-white">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#FF5D2E] mx-auto mb-4"></div>
        <p className="text-gray-600">Completing sign in...</p>
      </div>
    </div>
  );
}

