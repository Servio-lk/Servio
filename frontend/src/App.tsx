import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { Toaster } from '@/components/ui/sonner'
import { AuthProvider } from '@/contexts/AuthContext'
import { AuthGuard, GuestGuard } from '@/components/AuthGuard'
import { AdminGuard } from '@/components/AdminGuard'

// Auth pages
import Login from './pages/Login'
import Signup from './pages/Signup'
import AuthCallback from './pages/AuthCallback'
import AdminSetup from './pages/AdminSetup'

// Main app pages (responsive - works on both mobile and desktop)
import HomePage from './pages/HomePage'
import ServicesPage from './pages/ServicesPage'
import ServiceDetailPage from './pages/ServiceDetailPage'
import ActivityPage from './pages/ActivityPage'
import BookingPage from './pages/BookingPage'
import ConfirmationPage from './pages/ConfirmationPage'
import AppointmentStatusPage from './pages/AppointmentStatusPage'

// Admin pages
import { AdminAppLayout } from './components/layouts/AdminAppLayout'
import { AdminDashboard } from './pages/admin/Dashboard'
import { AdminServices } from './pages/admin/Services'
import { AdminOffers } from './pages/admin/Offers'
import { AdminAppointments } from './pages/admin/Appointments'
import { AdminCustomers } from './pages/admin/Customers'

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
            element={
              <GuestGuard>
                <Signup />
              </GuestGuard>
            }
          />

          {/* OAuth callback route */}
          <Route path="/auth/callback" element={<AuthCallback />} />

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

          {/* Account page placeholder */}
          <Route
            path="/account"
            element={
              <AuthGuard>
                <HomePage />
              </AuthGuard>
            }
          />

          {/* Admin routes - protected by AdminGuard */}
          <Route
            path="/admin"
            element={
              <AdminGuard>
                <AdminAppLayout />
              </AdminGuard>
            }
          >
            <Route index element={<AdminDashboard />} />
            <Route path="services" element={<AdminServices />} />
            <Route path="offers" element={<AdminOffers />} />
            <Route path="appointments" element={<AdminAppointments />} />
            <Route path="customers" element={<AdminCustomers />} />
          </Route>

          {/* Redirect old mobile routes to new unified routes */}
          <Route path="/mobile/home" element={<Navigate to="/home" replace />} />
          <Route path="/mobile/services" element={<Navigate to="/services" replace />} />
          <Route path="/mobile/activity" element={<Navigate to="/activity" replace />} />
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
