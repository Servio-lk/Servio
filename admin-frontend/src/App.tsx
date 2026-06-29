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
import ForgotPassword from './pages/ForgotPassword'
import ResetPassword from './pages/ResetPassword'

// Customer pages removed

// Admin pages
import { AdminAppLayout } from './components/layouts/AdminAppLayout'
import { AdminDashboard } from './pages/admin/Dashboard'
import { AdminServices } from './pages/admin/Services'
import { AdminOffers } from './pages/admin/Offers'
import { AdminAppointments } from './pages/admin/Appointments'
import { AdminCustomers } from './pages/admin/Customers'
import AdminCalendar from './pages/admin/AdminCalendar'
import { AdminInventory } from './pages/admin/Inventory'
import { AdminBilling } from './pages/admin/Billing'
import { AdminMechanics } from './pages/admin/Mechanics'

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

          {/* Admin frontend routes */}
          <Route path="/" element={<Navigate to="/admin" replace />} />

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
            <Route path="calendar" element={<AdminCalendar />} />
            <Route path="inventory" element={<AdminInventory />} />
            <Route path="billing" element={<AdminBilling />} />
            <Route path="staff" element={<AdminMechanics />} />
            <Route path="mechanics" element={<AdminMechanics />} />
          </Route>

          {/* Mobile routes removed */}

          {/* Default: redirect root and unknown routes to login */}
          <Route path="/" element={<Navigate to="/login" replace />} />
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  )
}

export default App
