import { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { Calendar, Clock, MapPin, AlertCircle, CheckCircle, XCircle, Loader2 } from 'lucide-react';
import { apiService } from '@/services/api';
import type { AppointmentDto } from '@/services/api';

export default function AppointmentStatusPage() {
  const { id } = useParams<{ id: string }>();
  const [appointment, setAppointment] = useState<AppointmentDto | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchAppointment = async () => {
      if (!id) {
        setError('Invalid appointment ID');
        setIsLoading(false);
        return;
      }

      try {
        setIsLoading(true);
        const response = await apiService.getAppointmentById(parseInt(id));
        
        if (response.success && response.data) {
          setAppointment(response.data);
        } else {
          setError('Appointment not found');
        }
      } catch (error: any) {
        console.error('Error fetching appointment:', error);
        setError('Failed to load appointment details');
      } finally {
        setIsLoading(false);
      }
    };

    fetchAppointment();
  }, [id]);

  const formatDateTime = (isoDate: string) => {
    const date = new Date(isoDate);
    const dateStr = date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      year: 'numeric'
    });
    const timeStr = date.toLocaleTimeString('en-US', { 
      hour: 'numeric', 
      minute: '2-digit',
      hour12: true 
    });
    return { date: dateStr, time: timeStr };
  };

  const getStatusConfig = (status: string) => {
    const configs: Record<string, { icon: any; color: string; bg: string; text: string }> = {
      PENDING: {
        icon: Clock,
        color: 'text-yellow-600',
        bg: 'bg-yellow-50',
        text: 'Pending Confirmation'
      },
      CONFIRMED: {
        icon: CheckCircle,
        color: 'text-green-600',
        bg: 'bg-green-50',
        text: 'Confirmed'
      },
      IN_PROGRESS: {
        icon: Loader2,
        color: 'text-blue-600',
        bg: 'bg-blue-50',
        text: 'In Progress'
      },
      COMPLETED: {
        icon: CheckCircle,
        color: 'text-green-600',
        bg: 'bg-green-50',
        text: 'Completed'
      },
      CANCELLED: {
        icon: XCircle,
        color: 'text-red-600',
        bg: 'bg-red-50',
        text: 'Cancelled'
      }
    };
    return configs[status] || configs.PENDING;
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-[#fff7f5] to-white flex items-center justify-center p-4">
        <div className="text-center">
          <Loader2 className="w-12 h-12 text-[#ff5d2e] animate-spin mx-auto mb-4" />
          <p className="text-black/50">Loading appointment...</p>
        </div>
      </div>
    );
  }

  if (error || !appointment) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-[#fff7f5] to-white flex items-center justify-center p-4">
        <div className="text-center max-w-md">
          <AlertCircle className="w-16 h-16 text-red-500 mx-auto mb-4" />
          <h2 className="text-xl font-bold text-black mb-2">Appointment Not Found</h2>
          <p className="text-black/60 mb-6">{error || 'The appointment you are looking for does not exist.'}</p>
          <Link
            to="/"
            className="inline-block px-6 py-3 bg-[#ff5d2e] text-white rounded-lg font-semibold hover:bg-[#e54d1e] transition-colors"
          >
            Go to Home
          </Link>
        </div>
      </div>
    );
  }

  const { date, time } = formatDateTime(appointment.appointmentDate);
  const statusConfig = getStatusConfig(appointment.status);
  const StatusIcon = statusConfig.icon;

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#fff7f5] to-white py-8 px-4">
      <div className="max-w-2xl mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center gap-2 mb-4">
            <div className="w-12 h-12 bg-[#ff5d2e] rounded-full flex items-center justify-center">
              <span className="text-white font-bold text-xl">S</span>
            </div>
            <h1 className="text-2xl font-bold text-black">Servio</h1>
          </div>
          <p className="text-black/60">Appointment Status</p>
        </div>

        {/* Status Card */}
        <div className="bg-white rounded-2xl shadow-lg overflow-hidden">
          {/* Status Header */}
          <div className={`${statusConfig.bg} p-6 border-b border-black/10`}>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <StatusIcon className={`w-8 h-8 ${statusConfig.color} ${appointment.status === 'IN_PROGRESS' ? 'animate-spin' : ''}`} />
                <div>
                  <p className="text-sm text-black/60">Status</p>
                  <p className={`text-xl font-bold ${statusConfig.color}`}>{statusConfig.text}</p>
                </div>
              </div>
              <div className="text-right">
                <p className="text-sm text-black/60">Appointment ID</p>
                <p className="text-lg font-bold text-black">#{appointment.id}</p>
              </div>
            </div>
          </div>

          {/* Appointment Details */}
          <div className="p-6 space-y-6">
            {/* Service */}
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-[#ffe7df] rounded-lg flex items-center justify-center flex-shrink-0">
                <Calendar className="w-6 h-6 text-[#ff5d2e]" />
              </div>
              <div className="flex-1">
                <p className="text-sm text-black/60 mb-1">Service</p>
                <p className="text-lg font-semibold text-black">{appointment.serviceType}</p>
              </div>
            </div>

            {/* Date & Time */}
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-[#ffe7df] rounded-lg flex items-center justify-center flex-shrink-0">
                <Clock className="w-6 h-6 text-[#ff5d2e]" />
              </div>
              <div className="flex-1">
                <p className="text-sm text-black/60 mb-1">Scheduled For</p>
                <p className="text-lg font-semibold text-black">{date}</p>
                <p className="text-base text-black/70">{time}</p>
              </div>
            </div>

            {/* Location */}
            {appointment.location && (
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 bg-[#ffe7df] rounded-lg flex items-center justify-center flex-shrink-0">
                  <MapPin className="w-6 h-6 text-[#ff5d2e]" />
                </div>
                <div className="flex-1">
                  <p className="text-sm text-black/60 mb-1">Location</p>
                  <p className="text-lg font-semibold text-black">{appointment.location}</p>
                </div>
              </div>
            )}

            {/* Customer Info */}
            <div className="bg-[#fff7f5] rounded-lg p-4">
              <p className="text-sm text-black/60 mb-2">Customer</p>
              <p className="font-semibold text-black">{appointment.user?.fullName || 'Customer'}</p>
              {appointment.user?.phone && (
                <p className="text-sm text-black/70 mt-1">{appointment.user.phone}</p>
              )}
            </div>

            {/* Notes */}
            {appointment.notes && (
              <div className="bg-[#fff7f5] rounded-lg p-4">
                <p className="text-sm text-black/60 mb-2">Notes</p>
                <p className="text-black">{appointment.notes}</p>
              </div>
            )}

            {/* Estimated Cost */}
            {appointment.estimatedCost && (
              <div className="border-t border-black/10 pt-4">
                <div className="flex items-center justify-between">
                  <p className="text-black/60">Estimated Cost</p>
                  <p className="text-2xl font-bold text-[#ff5d2e]">
                    LKR {appointment.estimatedCost.toLocaleString()}
                  </p>
                </div>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="bg-gray-50 px-6 py-4 text-center">
            <p className="text-sm text-black/50">
              Last updated: {new Date(appointment.updatedAt).toLocaleString()}
            </p>
          </div>
        </div>

        {/* Actions */}
        <div className="mt-6 text-center">
          <Link
            to="/"
            className="inline-block px-6 py-3 bg-[#ff5d2e] text-white rounded-lg font-semibold hover:bg-[#e54d1e] transition-colors"
          >
            Book Another Service
          </Link>
        </div>
      </div>
    </div>
  );
}
