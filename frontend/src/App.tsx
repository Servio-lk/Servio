import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { Toaster } from '@/components/ui/sonner'
import { AuthProvider } from '@/contexts/AuthContext'
import { AuthGuard, GuestGuard } from '@/components/AuthGuard'

// Auth pages
import Login from './pages/Login'
import Signup from './pages/Signup'

// Main app pages (responsive - works on both mobile and desktop)
import HomePage from './pages/HomePage'
import ServicesPage from './pages/ServicesPage'
import ServiceDetailPage from './pages/ServiceDetailPage'
import ActivityPage from './pages/ActivityPage'
import BookingPage from './pages/BookingPage'
import ConfirmationPage from './pages/ConfirmationPage'

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

          {/* Redirect old mobile routes to new unified routes */}
          <Route path="/mobile/home" element={<Navigate to="/home" replace />} />
          <Route path="/mobile/services" element={<Navigate to="/services" replace />} />
          <Route path="/mobile/activity" element={<Navigate to="/activity" replace />} />
          <Route path="/mobile/service/:id" element={<Navigate to="/services/:id" replace />} />
          <Route path="/mobile/choose-time" element={<Navigate to="/home" replace />} />
          <Route path="/mobile/checkout" element={<Navigate to="/home" replace />} />
          <Route path="/mobile/confirmed" element={<Navigate to="/home" replace />} />
          <Route path="/mobile/welcome" element={<Navigate to="/login" replace />} />

          {/* Default redirect */}
          <Route path="/" element={<Navigate to="/home" replace />} />
          <Route path="*" element={<Navigate to="/home" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  )
}

export default App
