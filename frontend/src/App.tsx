import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { Toaster } from '@/components/ui/sonner'
import { AuthProvider } from '@/contexts/AuthContext'
import { AuthGuard, GuestGuard } from '@/components/AuthGuard'

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

// Admin pages removed from this frontend
import './App.css'

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

          {/* Admin routes removed */}

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

          {/* Default: redirect root and unknown routes to login */}
          <Route path="/" element={<Navigate to="/login" replace />} />
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  )
}

export default App
