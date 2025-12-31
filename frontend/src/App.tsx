import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { Toaster } from '@/components/ui/sonner'
import Login from './pages/Login'
import Signup from './pages/Signup'
// Mobile pages
import Welcome from './pages/mobile/Welcome'
import Home from './pages/mobile/Home'
import Services from './pages/mobile/Services'
import Activity from './pages/mobile/Activity'
import ServiceDetail from './pages/mobile/ServiceDetail'
import ChooseTime from './pages/mobile/ChooseTime'
import Checkout from './pages/mobile/Checkout'
import AppointmentConfirmed from './pages/mobile/AppointmentConfirmed'
import './App.css'

function App() {
  return (
    <Router>
      <Toaster position="top-center" richColors />
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<Signup />} />
        {/* Mobile routes */}
        <Route path="/mobile/welcome" element={<Welcome />} />
        <Route path="/mobile/home" element={<Home />} />
        <Route path="/mobile/services" element={<Services />} />
        <Route path="/mobile/activity" element={<Activity />} />
        <Route path="/mobile/service/:id" element={<ServiceDetail />} />
        <Route path="/mobile/choose-time" element={<ChooseTime />} />
        <Route path="/mobile/checkout" element={<Checkout />} />
        <Route path="/mobile/confirmed" element={<AppointmentConfirmed />} />
        <Route path="/" element={<Navigate to="/login" replace />} />
      </Routes>
    </Router>
  )
}

export default App
