import { useEffect, useState } from 'react';
import { useNavigate, Link, useParams, useLocation} from 'react-router-dom';
import { Car, Phone, Coins, AlertTriangle, Calendar, Download, Share2, Home } from 'lucide-react';
import { ChatCircleDots } from '@phosphor-icons/react';
import { QRCodeSVG } from 'qrcode.react';
import { AppLayout } from '@/components/layouts/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import { apiService } from '@/services/api';
import type { AppointmentDto } from '@/services/api';
import { toast } from 'sonner';

function formatPaymentMethod(method?: string | null) {
  if (!method) return 'Cash';
  const value = method.toLowerCase();
  if (value === 'cash') return 'Cash';
  if (value === 'payhere' || value === 'card' || value.includes('card')) return 'Card';
  return method.replaceAll('_', ' ');
}

function appointmentEnd(start: Date, notes?: string | null) {
  const match = notes?.match(/(\d{1,2}):(\d{2})\s*(AM|PM)\s*-\s*(\d{1,2}):(\d{2})\s*(AM|PM)/i);
  if (!match) {
    return new Date(start.getTime() + 30 * 60 * 1000);
  }

  let hour = Number(match[4]) % 12;
  if (match[6].toUpperCase() === 'PM') hour += 12;
  const end = new Date(start);
  end.setHours(hour, Number(match[5]), 0, 0);
  if (end.getTime() <= start.getTime()) {
    end.setDate(end.getDate() + 1);
  }
  return end;
}

export default function ConfirmationPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { id } = useParams<{ id: string }>();
  const location = useLocation();
  const breakdown = (location.state ?? null) as {
    originalTotal?: number;
    discount?: number;
    offerName?: string | null;
    paymentMethod?: string | null;
  } | null;
  
  const [appointment, setAppointment] = useState<AppointmentDto | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const downloadQRCode = () => {
    const svg = document.getElementById('appointment-qr-code');
    if (!svg) return;
    
    const svgData = new XMLSerializer().serializeToString(svg);
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    const img = new Image();
    
    img.onload = () => {
      canvas.width = img.width;
      canvas.height = img.height;
      ctx?.drawImage(img, 0, 0);
      const pngFile = canvas.toDataURL('image/png');
      
      const downloadLink = document.createElement('a');
      downloadLink.download = `appointment-${id}-qr.png`;
      downloadLink.href = pngFile;
      downloadLink.click();
    };
    
    img.src = 'data:image/svg+xml;base64,' + btoa(svgData);
  };

  const shareAppointment = async () => {
    const url = `${window.location.origin}/appointment/${id}`;
    
    if (navigator.share) {
      try {
        await navigator.share({
          title: 'My Servio Appointment',
          text: `Check out my appointment - ${appointmentDisplay.service}`,
          url: url,
        });
      } catch (error) {
        console.log('Error sharing:', error);
      }
    } else {
      // Fallback: copy to clipboard
      navigator.clipboard.writeText(url);
      toast.success('Link copied to clipboard!');
    }
  };

  const addToCalendar = () => {
    if (!appointment) return;

    const start = new Date(appointment.appointmentDate);
    if (Number.isNaN(start.getTime())) {
      toast.error('Could not add this appointment to your calendar');
      return;
    }

    const end = appointmentEnd(start, appointment.notes);
    const toGoogleDate = (date: Date) =>
      date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');

    const params = new URLSearchParams({
      action: 'TEMPLATE',
      text: `Servio — ${appointment.serviceType}`,
      dates: `${toGoogleDate(start)}/${toGoogleDate(end)}`,
      details: `Appointment #APT-${appointment.id.toString().padStart(6, '0')}`,
      location: appointment.location || 'Service Center',
    });

    window.open(
      `https://calendar.google.com/calendar/render?${params.toString()}`,
      '_blank',
      'noopener,noreferrer',
    );
  };

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

  // Extract vehicle from notes if not available from vehicle fields
  let vehicleDisplay = 'No vehicle specified';
  if (appointment.vehicleMake && appointment.vehicleModel) {
    vehicleDisplay = `${appointment.vehicleMake} ${appointment.vehicleModel}`;
  } else if (appointment.notes) {
    const match = appointment.notes.match(/Vehicle:\s*([^|]+)/i);
    if (match) vehicleDisplay = match[1].trim();
  }

  const appointmentDisplay = {
    id: `#APT-${appointment.id.toString().padStart(6, '0')}`,
    customerName: user?.fullName || appointment.userName || 'Customer',
    service: appointment.serviceType,
    date: date,
    time: time,
    vehicle: vehicleDisplay,
    phone: user?.phone || appointment.userEmail || 'N/A',
    paymentMethod: formatPaymentMethod(appointment.paymentMethod || breakdown?.paymentMethod),
    total: appointment.estimatedCost || 0,
    status: appointment.status,
    location: appointment.location || 'Service Center',
    notes: appointment.notes,
  };
  const canMessageServiceTeam = ['CONFIRMED', 'IN_PROGRESS'].includes(appointment.status);

  return (
    <AppLayout showNav={false}>
      <div className="min-h-screen flex flex-col">
        {/* Header */}
        <div className="sticky top-0 bg-gradient-to-b from-[#fff7f5] to-transparent z-10 pb-4">
          <div className="flex items-center justify-center gap-4 px-4 py-3 lg:px-0">
            <h1 className="text-xl lg:text-2xl font-semibold text-black text-center">
              {appointment.status === 'PENDING' ? 'Appointment Request Received' : 'Appointment Confirmed!'}
            </h1>
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
                    {appointmentDisplay.status === 'PENDING' ? 'Pending Confirmation' :
                     appointmentDisplay.status === 'CONFIRMED' ? 'Confirmed' :
                     appointmentDisplay.status}
                  </span>
                </div>
                {appointment.status === 'PENDING' && (
                  <p className="mt-3 text-sm text-black/70 max-w-sm mx-auto">
                    Your request has been submitted. We will notify you as soon as your appointment is confirmed.
                  </p>
                )}
              </div>

              {/* QR Code */}
              <div className="w-64 h-64 bg-white border-2 border-black/20 rounded-lg flex items-center justify-center shadow-lg p-4">
                <QRCodeSVG
                  id="appointment-qr-code"
                  value={`${window.location.origin}/appointment/${appointment.id}`}
                  size={224}
                  level="H"
                  includeMargin={false}
                />
              </div>

              <p className="text-xs text-center text-black/50 max-w-[250px]">
                Scan this QR code to view your appointment status anytime
              </p>

              {/* Action buttons - Desktop */}
              <div className="hidden lg:flex gap-3">
                <button 
                  onClick={downloadQRCode}
                  className="flex items-center gap-2 px-4 py-2 bg-white border border-[#ffe7df] rounded-lg hover:bg-[#fff7f5] transition-colors"
                >
                  <Download className="w-4 h-4" />
                  <span className="text-sm font-medium">Download QR</span>
                </button>
                <button 
                  onClick={shareAppointment}
                  className="flex items-center gap-2 px-4 py-2 bg-white border border-[#ffe7df] rounded-lg hover:bg-[#fff7f5] transition-colors"
                >
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
              <div className="flex flex-col gap-2 p-4 bg-[#fff7f5] rounded-lg">
                {breakdown?.discount ? (
                  <>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-black/70">Total</span>
                      <span className="font-medium text-black">LKR {breakdown.originalTotal?.toLocaleString()}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-[#ff5d2e]">{breakdown.offerName} applied</span>
                      <span className="font-medium text-[#ff5d2e]">-LKR {breakdown.discount.toLocaleString()}</span>
                    </div>
                  </>
                ) : null}
                <div className="flex items-center justify-between">
                  <span className="font-semibold text-black">Total Amount</span>
                  <span className="text-xl font-bold text-[#ff5d2e]">LKR {appointmentDisplay.total.toLocaleString()}</span>
                </div>
              </div>

              {/* Desktop buttons */}
              <div className="hidden lg:flex flex-col gap-3">
                {canMessageServiceTeam && (
                  <Link
                    to={`/messages/${appointment.id}`}
                    className="w-full flex items-center justify-center gap-2 py-3 bg-[#ff5d2e] text-white rounded-xl font-medium hover:bg-[#e54d1e] transition-colors shadow-[0px_4px_8px_0px_rgba(255,93,46,0.3)]"
                  >
                    <ChatCircleDots className="w-5 h-5" weight="duotone" />
                    Message your service team
                  </Link>
                )}
                <button
                  type="button"
                  onClick={addToCalendar}
                  className="w-full flex items-center justify-center gap-2 py-3 bg-white border border-[#ffe7df] rounded-xl font-medium text-black hover:bg-[#fff7f5] transition-colors"
                >
                  <Calendar className="w-5 h-5" />
                  Add to Calendar
                </button>
                <Link
                  to="/activity"
                  className="w-full flex items-center justify-center gap-2 py-3 bg-[#ff5d2e] text-white rounded-xl font-medium hover:bg-[#e54d1e] transition-colors shadow-[0px_4px_8px_0px_rgba(255,93,46,0.3)]"
                >
                  View My Bookings
                </Link>
                <Link
                  to="/home"
                  className="w-full flex items-center justify-center gap-2 py-3 bg-white border border-[#ffe7df] text-black rounded-xl font-medium hover:bg-[#fff7f5] transition-colors"
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
          {canMessageServiceTeam && (
            <Link
              to={`/messages/${appointment.id}`}
              className="w-full flex items-center justify-center gap-2 py-3 bg-[#ff5d2e] text-white rounded-xl font-medium shadow-[0px_4px_8px_0px_rgba(255,93,46,0.3)]"
            >
              <ChatCircleDots className="w-5 h-5" weight="duotone" />
              Message your service team
            </Link>
          )}
          <button
            type="button"
            onClick={addToCalendar}
            className="w-full flex items-center justify-center gap-2 py-3 bg-white border border-[#ffe7df] rounded-xl font-medium text-black"
          >
            <Calendar className="w-5 h-5" />
            Add to Calendar
          </button>
          <Link
            to="/activity"
            className="w-full flex items-center justify-center gap-2 py-3 bg-[#ff5d2e] text-white rounded-xl font-medium shadow-[0px_4px_8px_0px_rgba(255,93,46,0.3)]"
          >
            View My Bookings
          </Link>
          <Link
            to="/home"
            className="w-full flex items-center justify-center gap-2 py-3 bg-white border border-[#ffe7df] text-black rounded-xl font-medium"
          >
            <Home className="w-5 h-5" />
            Back to Home
          </Link>
        </div>
      </div>
    </AppLayout>
  );
}
