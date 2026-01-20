import { useEffect, useState } from 'react';
import { useNavigate, Link, useParams } from 'react-router-dom';
import { ArrowLeft, Car, Phone, Coins, AlertTriangle, Calendar, Download, Share2, Home } from 'lucide-react';
import { AppLayout } from '@/components/layouts/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import { apiService } from '@/services/api';
import type { AppointmentDto } from '@/services/api';
import { toast } from 'sonner';

export default function ConfirmationPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { id } = useParams<{ id: string }>();
  
  const [appointment, setAppointment] = useState<AppointmentDto | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchAppointment = async () => {
      if (!id) {
        toast.error('Invalid appointment ID');
        navigate('/home');
        return;
      }

      try {
        setIsLoading(true);
        const response = await apiService.getAppointmentById(parseInt(id));
        
        if (response.success && response.data) {
          setAppointment(response.data);
        } else {
          toast.error('Failed to load appointment details');
          navigate('/home');
        }
      } catch (error: any) {
        console.error('Error fetching appointment:', error);
        toast.error('Failed to load appointment details');
        navigate('/home');
      } finally {
        setIsLoading(false);
      }
    };

    fetchAppointment();
  }, [id, navigate]);

  // Format date and time from ISO string
  const formatDateTime = (isoDate: string) => {
    const date = new Date(isoDate);
    const dateStr = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    const timeStr = date.toLocaleTimeString('en-US', { 
      hour: 'numeric', 
      minute: '2-digit',
      hour12: true 
    });
    return { date: dateStr, time: timeStr };
  };

  // Show loading state
  if (isLoading) {
    return (
      <AppLayout showNav={false}>
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#ff5d2e] mx-auto mb-4"></div>
            <p className="text-black/50">Loading appointment details...</p>
          </div>
        </div>
      </AppLayout>
    );
  }

  // Show error if no appointment
  if (!appointment) {
    return (
      <AppLayout showNav={false}>
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <AlertTriangle className="w-12 h-12 text-[#ff5d2e] mx-auto mb-4" />
            <p className="text-black/70">Appointment not found</p>
          </div>
        </div>
      </AppLayout>
    );
  }

  const { date, time } = formatDateTime(appointment.appointmentDate);
  const appointmentDisplay = {
    id: `#APT-${appointment.id.toString().padStart(6, '0')}`,
    customerName: user?.fullName || appointment.user?.fullName || 'Customer',
    service: appointment.serviceType,
    date: date,
    time: time,
    vehicle: appointment.vehicle ? `${appointment.vehicle.make} ${appointment.vehicle.model}` : 'No vehicle specified',
    phone: user?.phone || appointment.user?.phone || 'N/A',
    paymentMethod: 'Cash', // Default for now
    total: appointment.estimatedCost || 0,
    status: appointment.status,
    location: appointment.location || 'Service Center',
    notes: appointment.notes,
  };

  return (
    <AppLayout showNav={false}>
      <div className="min-h-screen flex flex-col">
        {/* Header */}
        <div className="sticky top-0 bg-gradient-to-b from-[#fff7f5] to-transparent z-10 pb-4">
          <div className="flex items-center gap-4 px-4 py-3 lg:px-0">
            <button
              onClick={() => navigate('/home')}
              className="w-10 h-10 bg-white rounded-lg flex items-center justify-center shadow-sm hover:shadow-md transition-shadow"
            >
              <ArrowLeft className="w-5 h-5" />
            </button>
            <h1 className="text-xl lg:text-2xl font-semibold text-black">Appointment Confirmed!</h1>
          </div>
        </div>

        {/* Main content */}
        <div className="flex-1 max-w-4xl mx-auto w-full px-4 lg:px-6 pb-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Left column - QR Code and main info */}
            <div className="flex flex-col items-center gap-6">
              {/* Customer name */}
              <div className="text-center">
                <p className="text-lg font-bold text-black">{appointmentDisplay.customerName}</p>
                <div className="flex items-center justify-center gap-2 mt-2">
                  <span className="text-xs text-black/50">Appointment ID:</span>
                  <span className="text-xs font-medium text-black bg-[#fff7f5] px-2 py-1 rounded-full border border-[#ffe7df]">
                    {appointmentDisplay.id}
                  </span>
                </div>
                <div className="mt-2">
                  <span className={`text-xs font-semibold px-3 py-1 rounded-full ${
                    appointmentDisplay.status === 'CONFIRMED' ? 'bg-green-100 text-green-700' :
                    appointmentDisplay.status === 'PENDING' ? 'bg-yellow-100 text-yellow-700' :
                    appointmentDisplay.status === 'COMPLETED' ? 'bg-blue-100 text-blue-700' :
                    'bg-gray-100 text-gray-700'
                  }`}>
                    {appointmentDisplay.status}
                  </span>
                </div>
              </div>

              {/* QR Code */}
              <div className="w-64 h-64 bg-white border-2 border-black/20 rounded-lg flex items-center justify-center shadow-lg">
                {/* QR Code placeholder - In production, use a QR library */}
                <div className="w-56 h-56 bg-gradient-to-br from-gray-100 to-gray-200 rounded flex items-center justify-center">
                  <div className="grid grid-cols-5 gap-1">
                    {Array.from({ length: 25 }).map((_, i) => (
                      <div
                        key={i}
                        className={`w-4 h-4 rounded-sm ${Math.random() > 0.5 ? 'bg-black' : 'bg-transparent'}`}
                      />
                    ))}
                  </div>
                </div>
              </div>

              {/* Action buttons - Desktop */}
              <div className="hidden lg:flex gap-3">
                <button className="flex items-center gap-2 px-4 py-2 bg-white border border-[#ffe7df] rounded-lg hover:bg-[#fff7f5] transition-colors">
                  <Download className="w-4 h-4" />
                  <span className="text-sm font-medium">Download</span>
                </button>
                <button className="flex items-center gap-2 px-4 py-2 bg-white border border-[#ffe7df] rounded-lg hover:bg-[#fff7f5] transition-colors">
                  <Share2 className="w-4 h-4" />
                  <span className="text-sm font-medium">Share</span>
                </button>
              </div>
            </div>

            {/* Right column - Details */}
            <div className="flex flex-col gap-6">
              {/* Service Details */}
              <div className="flex flex-col gap-3">
                <div className="flex items-start gap-3">
                  <span className="text-sm font-bold text-black/70 w-20">Service:</span>
                  <div className="flex-1">
                    <p className="font-medium text-black">{appointmentDisplay.service}</p>
                    {appointmentDisplay.notes && (
                      <p className="text-sm text-black/50">{appointmentDisplay.notes}</p>
                    )}
                  </div>
                </div>
              </div>

              {/* Date & Time highlight */}
              <div className="bg-[#ffe7df] p-4 rounded-lg flex items-start gap-4">
                <div className="bg-white p-2 rounded-lg">
                  <AlertTriangle className="w-6 h-6 text-[#ff5d2e]" />
                </div>
                <div className="flex-1">
                  <p className="text-xs text-black/70 font-medium">DATE & TIME</p>
                  <p className="text-base font-semibold text-black mt-1">
                    {appointmentDisplay.date} · {appointmentDisplay.time}
                  </p>
                </div>
              </div>

              {/* Additional Details */}
              <div className="flex flex-col gap-2 bg-white rounded-lg overflow-hidden">
                <div className="flex items-center gap-3 p-4 border-b border-black/5">
                  <Car className="w-5 h-5 text-black/70" />
                  <span className="flex-1 text-sm font-medium text-black/70">{appointmentDisplay.vehicle}</span>
                </div>
                <div className="flex items-center gap-3 p-4 border-b border-black/5">
                  <Phone className="w-5 h-5 text-black/70" />
                  <span className="flex-1 text-sm font-medium text-black/70">{appointmentDisplay.phone}</span>
                </div>
                <div className="flex items-center gap-3 p-4">
                  <Coins className="w-5 h-5 text-black/70" />
                  <span className="flex-1 text-sm font-medium text-black/70">Pay by {appointmentDisplay.paymentMethod}</span>
                </div>
              </div>

              {/* Total */}
              <div className="flex items-center justify-between p-4 bg-[#fff7f5] rounded-lg">
                <span className="font-semibold text-black">Total Amount</span>
                <span className="text-xl font-bold text-[#ff5d2e]">LKR {appointmentDisplay.total.toLocaleString()}</span>
              </div>

              {/* Desktop buttons */}
              <div className="hidden lg:flex flex-col gap-3">
                <button className="w-full flex items-center justify-center gap-2 py-3 bg-white border border-[#ffe7df] rounded-xl font-medium text-black hover:bg-[#fff7f5] transition-colors">
                  <Calendar className="w-5 h-5" />
                  Add to Calendar
                </button>
                <Link
                  to="/home"
                  className="w-full flex items-center justify-center gap-2 py-3 bg-[#ff5d2e] text-white rounded-xl font-medium hover:bg-[#e54d1e] transition-colors shadow-[0px_4px_8px_0px_rgba(255,93,46,0.3)]"
                >
                  <Home className="w-5 h-5" />
                  Back to Home
                </Link>
              </div>
            </div>
          </div>
        </div>

        {/* Mobile bottom buttons */}
        <div className="lg:hidden sticky bottom-0 bg-white border-t border-black/10 p-4 safe-area-pb flex flex-col gap-2">
          <button className="w-full flex items-center justify-center gap-2 py-3 bg-white border border-[#ffe7df] rounded-xl font-medium text-black">
            <Calendar className="w-5 h-5" />
            Add to Calendar
          </button>
          <Link
            to="/home"
            className="w-full flex items-center justify-center gap-2 py-3 bg-[#ff5d2e] text-white rounded-xl font-medium shadow-[0px_4px_8px_0px_rgba(255,93,46,0.3)]"
          >
            <Home className="w-5 h-5" />
            Back to Home
          </Link>
        </div>
      </div>
    </AppLayout>
  );
}
