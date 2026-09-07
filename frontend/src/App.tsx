import { Suspense, lazy } from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { Toaster } from '@/components/ui/sonner'
import { AuthProvider } from '@/contexts/AuthContext'
import { AuthGuard, GuestGuard } from '@/components/AuthGuard'
import { AdminGuard } from '@/components/AdminGuard'
import { useAuth } from '@/contexts/AuthContext'

// Auth pages
import Login from './pages/Login'
import Signup from './pages/Signup'
import AuthCallback from './pages/AuthCallback'
import AdminSetup from './pages/AdminSetup'
import ForgotPassword from './pages/ForgotPassword'
import ResetPassword from './pages/ResetPassword'

// Main app pages (responsive - works on both mobile and desktop)
import HomePage from './pages/HomePage'
import ServicesPage from './pages/ServicesPage'
import ServiceDetailPage from './pages/ServiceDetailPage'
import ActivityPage from './pages/ActivityPage'
import MessagesPage from './pages/MessagesPage'
import BookingPage from './pages/BookingPage'
import ConfirmationPage from './pages/ConfirmationPage'
import AppointmentStatusPage from './pages/AppointmentStatusPage'
import AccountPage from './pages/AccountPage'
import AssistantPage from './pages/AssistantPage'

// Lazy-loaded Admin Layout & Pages
const AdminAppLayout = lazy(() => import('@/components/layouts/AdminAppLayout'))
const AdminDashboard = lazy(() => import('@/pages/admin/Dashboard'))
const AdminServices = lazy(() => import('@/pages/admin/Services'))
const AdminOffers = lazy(() => import('@/pages/admin/Offers'))
const AdminAppointments = lazy(() => import('@/pages/admin/Appointments'))
const AdminCustomers = lazy(() => import('@/pages/admin/Customers'))
const AdminCalendar = lazy(() => import('@/pages/admin/AdminCalendar'))
const AdminInventory = lazy(() => import('@/pages/admin/Inventory'))
const AdminBilling = lazy(() => import('@/pages/admin/Billing'))
const AdminMechanics = lazy(() => import('@/pages/admin/Mechanics'))
const AdminJobCards = lazy(() => import('@/pages/admin/JobCards'))
const AdminServiceBays = lazy(() => import('@/pages/admin/ServiceBays'))
const AdminWalkInCustomers = lazy(() => import('@/pages/admin/WalkInCustomers'))

import './App.css'

<<<<<<< HEAD
// Smart redirect component: routes authenticated users to their appropriate dashboard
function RootRedirect() {
  const { isAuthenticated, isAdmin, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-screen w-full bg-[#fff7f5]">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-[#ff5d2e] border-t-transparent rounded-full animate-spin" />
          <p className="text-base font-medium text-black/70">Loading...</p>
        </div>
      </div>
    );
  }

  // If not authenticated, go to login
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  // If authenticated and admin, go to admin dashboard
  if (isAdmin) {
    return <Navigate to="/admin" replace />;
  }

  // If authenticated and regular user, go to home
  return <Navigate to="/home" replace />;
=======
function AdminLoadingFallback() {
  return (
    <div className="flex items-center justify-center min-h-[50vh] w-full">
      <div className="flex flex-col items-center gap-3">
        <div className="w-10 h-10 border-4 border-[#ff5d2e] border-t-transparent rounded-full animate-spin" />
        <p className="text-sm font-medium text-black/60">Loading Admin Module...</p>
      </div>
    </div>
  )
>>>>>>> 1ccc2b6040efed7e3791fe659e47d80b5c2a31b5
}

function App() {
  return (
    <AuthProvider>
      <Router>
        <Toaster position="top-center" richColors />
        <Routes>
          {/* Public routes - redirect to home if authenticated */}
          <Route
            path="/login"
            element={
              <GuestGuard>
                <Login />
              </GuestGuard>
            }
          />
          <Route
            path="/signup"
            element={<Signup />}
          />

          <Route path="/forgot-password" element={<ForgotPassword />} />

          {/* OAuth callback route */}
          <Route path="/auth/callback" element={<AuthCallback />} />

          {/* Password reset route - public because Supabase recovery links create a temporary session */}
          <Route path="/reset-password" element={<ResetPassword />} />

          {/* Admin setup page - for creating admin users */}
          <Route path="/admin-setup" element={<AdminSetup />} />

          {/* Public appointment status page - accessible via QR code */}
          <Route path="/appointment/:id" element={<AppointmentStatusPage />} />

          {/* Protected routes - redirect to login if not authenticated */}
          <Route
            path="/home"
            element={
              <AuthGuard>
                <HomePage />
              </AuthGuard>
            }
          />
          <Route
            path="/services"
            element={
              <AuthGuard>
                <ServicesPage />
              </AuthGuard>
            }
          />
          <Route
            path="/services/:id"
            element={
              <AuthGuard>
                <ServiceDetailPage />
              </AuthGuard>
            }
          />
          <Route
            path="/activity"
            element={
              <AuthGuard>
                <ActivityPage />
              </AuthGuard>
            }
          />
          <Route
            path="/messages"
            element={
              <AuthGuard>
                <MessagesPage />
              </AuthGuard>
            }
          />
          <Route
            path="/assistant"
            element={
              <AuthGuard>
                <AssistantPage />
              </AuthGuard>
            }
          />
          <Route
            path="/messages/:appointmentId"
            element={
              <AuthGuard>
                <MessagesPage />
              </AuthGuard>
            }
          />
          <Route
            path="/book/:id"
            element={
              <AuthGuard>
                <BookingPage />
              </AuthGuard>
            }
          />
          <Route
            path="/confirmed/:id"
            element={
              <AuthGuard>
                <ConfirmationPage />
              </AuthGuard>
            }
          />

          {/* Account page */}
          <Route
            path="/account"
            element={
              <AuthGuard>
                <AccountPage />
              </AuthGuard>
            }
          />

          {/* Protected lazy-loaded Admin routes */}
          <Route
            path="/admin"
            element={
              <AdminGuard>
                <Suspense fallback={<AdminLoadingFallback />}>
                  <AdminAppLayout />
                </Suspense>
              </AdminGuard>
            }
          >
            <Route index element={<Suspense fallback={<AdminLoadingFallback />}><AdminDashboard /></Suspense>} />
            <Route path="services" element={<Suspense fallback={<AdminLoadingFallback />}><AdminServices /></Suspense>} />
            <Route path="offers" element={<Suspense fallback={<AdminLoadingFallback />}><AdminOffers /></Suspense>} />
            <Route path="appointments" element={<Suspense fallback={<AdminLoadingFallback />}><AdminAppointments /></Suspense>} />
            <Route path="customers" element={<Suspense fallback={<AdminLoadingFallback />}><AdminCustomers /></Suspense>} />
            <Route path="calendar" element={<Suspense fallback={<AdminLoadingFallback />}><AdminCalendar /></Suspense>} />
            <Route path="inventory" element={<Suspense fallback={<AdminLoadingFallback />}><AdminInventory /></Suspense>} />
            <Route path="billing" element={<Suspense fallback={<AdminLoadingFallback />}><AdminBilling /></Suspense>} />
            <Route path="staff" element={<Suspense fallback={<AdminLoadingFallback />}><AdminMechanics /></Suspense>} />
            <Route path="mechanics" element={<Suspense fallback={<AdminLoadingFallback />}><AdminMechanics /></Suspense>} />
            <Route path="job-cards" element={<Suspense fallback={<AdminLoadingFallback />}><AdminJobCards /></Suspense>} />
            <Route path="service-bays" element={<Suspense fallback={<AdminLoadingFallback />}><AdminServiceBays /></Suspense>} />
            <Route path="walk-in" element={<Suspense fallback={<AdminLoadingFallback />}><AdminWalkInCustomers /></Suspense>} />
          </Route>

          {/* Redirect old mobile routes to new unified routes */}
          <Route path="/mobile/home" element={<Navigate to="/home" replace />} />
          <Route path="/mobile/services" element={<Navigate to="/services" replace />} />
          <Route path="/mobile/activity" element={<Navigate to="/activity" replace />} />
          <Route path="/mobile/messages" element={<Navigate to="/messages" replace />} />
          <Route path="/mobile/service/:id" element={<Navigate to="/services/:id" replace />} />
          <Route path="/mobile/choose-time" element={<Navigate to="/home" replace />} />
          <Route path="/mobile/checkout" element={<Navigate to="/home" replace />} />
          <Route path="/mobile/confirmed" element={<Navigate to="/home" replace />} />
          <Route path="/mobile/welcome" element={<Navigate to="/login" replace />} />

          {/* Smart root redirect: routes authenticated users to their appropriate dashboard */}
          <Route path="/" element={<RootRedirect />} />
          
          {/* Default: redirect unknown routes based on auth status (via root redirect) */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  )
}

export default App
