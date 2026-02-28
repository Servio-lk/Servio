import { useState, useEffect, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { RotateCw, Clock, ChevronRight, Calendar } from 'lucide-react';
import { AppLayout } from '@/components/layouts/AppLayout';
import { apiService } from '@/services/api';
import type { AppointmentDto } from '@/services/api';
import { toast } from 'sonner';
import { useWebSocket } from '@/hooks/useWebSocket';

// Map service type names (from API) to /public/service images/
const serviceImageMap: Record<string, string> = {
  'Washing Packages': '/service images/Washing Packages.jpg',
  'Washing Package': '/service images/Washing Packages.jpg',
  'Lube Services': '/service images/Lubricant Service.jpg',
  'Lubricant Service': '/service images/Lubricant Service.jpg',
  'Lubricant Services': '/service images/Lubricant Service.jpg',
  'Exterior & Interior Detailing': '/service images/Exterior Detailing.jpg',
  'Exterior Detailing': '/service images/Exterior Detailing.jpg',
  'Interior Detailing': '/service images/Interior detailing.jpg',
  'Interior detailing': '/service images/Interior detailing.jpg',
  'Engine Tune ups': '/service images/Mechanical Repair.jpg',
  'Mechanical Repair': '/service images/Mechanical Repair.jpg',
  'Inspection Reports': '/service images/Mulipoint Inspection Report.jpg',
  'Multipoint Inspection Report': '/service images/Mulipoint Inspection Report.jpg',
  'Tyre Services': '/service images/Mechanical Repair.jpg',
  'Waxing': '/service images/Exterior Detailing.jpg',
  'Undercarriage Degreasing': '/service images/Exterior Detailing.jpg',
  'Windscreen Treatments': '/service images/Exterior Detailing.jpg',
  'Battery Services': '/service images/Electrical & Electronic.jpg',
  'Electrical & Electronic': '/service images/Electrical & Electronic.jpg',
  'Nano Coating Packages': '/service images/Exterior Detailing.jpg',
  'Nano Coating Treatments': '/service images/Exterior Detailing.jpg',
  'Insurance Claims': '/service images/General Collision Repair.jpg',
  'General Collision Repair': '/service images/General Collision Repair.jpg',
  'Wheel Alignment': '/service images/Mechanical Repair.jpg',
  'Full Paints': '/service images/Complete Paint.jpg',
  'Complete Paint': '/service images/Complete Paint.jpg',
  'Part Replacements': '/service images/Mechanical Repair.jpg',
  'Periodic Maintenance': '/service images/Periodic Maintenance.jpg',
  'AC Repair and Service': '/service images/AC Repair and Service.jpg',
};

function getServiceImage(serviceType: string): string {
  // Direct match first
  if (serviceImageMap[serviceType]) return serviceImageMap[serviceType];
  // Partial match fallback
  const key = Object.keys(serviceImageMap).find(k =>
    serviceType.toLowerCase().includes(k.toLowerCase()) ||
    k.toLowerCase().includes(serviceType.toLowerCase())
  );
  return key ? serviceImageMap[key] : '/service images/Mechanical Repair.jpg';
}

export default function ActivityPage() {
  const [appointments, setAppointments] = useState<AppointmentDto[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showAllAppointments, setShowAllAppointments] = useState(false);

  const fetchAppointments = useCallback(async () => {
    try {
      setIsLoading(true);
      // Always fetch the current user's own appointments via /appointments/my
      const response = await apiService.getUserAppointments();

      if (response.success && response.data) {
        // Sort by creation time (newest booking first)
        const sorted = response.data.sort((a, b) => {
          const tA = a.createdAt ? new Date(a.createdAt).getTime() : new Date(a.appointmentDate).getTime();
          const tB = b.createdAt ? new Date(b.createdAt).getTime() : new Date(b.appointmentDate).getTime();
          return tB - tA;
        });
        setAppointments(sorted);
      }
    } catch (error: any) {
      console.error('Error fetching appointments:', error);
      toast.error('Failed to load appointments');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAppointments();
  }, [fetchAppointments, showAllAppointments]);

  // Subscribe to real-time appointment updates
  useWebSocket(
    ['/topic/appointments'],
    useCallback(() => { fetchAppointments(); }, [fetchAppointments]),
  );

  // Separate upcoming and past appointments
  const now = new Date();
  const upcomingAppointments = appointments.filter(
    apt => new Date(apt.appointmentDate) >= now && apt.status !== 'CANCELLED' && apt.status !== 'COMPLETED'
  );
  const pastAppointments = appointments.filter(
    apt => new Date(apt.appointmentDate) < now || apt.status === 'COMPLETED'
  );

  // Get the next upcoming appointment
  const nextUpcoming = upcomingAppointments[0];

  // Format date and time
  const formatDate = (isoDate: string) => {
    const date = new Date(isoDate);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const formatTime = (isoDate: string) => {
    const date = new Date(isoDate);
    return date.toLocaleTimeString('en-US', { 
      hour: 'numeric', 
      minute: '2-digit',
      hour12: true 
    });
  };

  // Calculate stats
  const totalServices = appointments.filter(apt => apt.status === 'COMPLETED').length;
  const totalSpent = appointments
    .filter(apt => apt.status === 'COMPLETED')
    .reduce((sum, apt) => sum + (apt.actualCost || apt.estimatedCost || 0), 0);

  // Loading state
  if (isLoading) {
    return (
      <AppLayout>
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#ff5d2e] mx-auto mb-4"></div>
            <p className="text-black/50">Loading your appointments...</p>
          </div>
        </div>
      </AppLayout>
    );
  }

  return (
    <AppLayout>
      <div className="flex flex-col gap-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h1 className="text-2xl lg:text-3xl font-semibold text-black">
            {showAllAppointments ? 'All Appointments' : 'My Activity'}
          </h1>
          <div className="flex items-center gap-2">
            <button 
              onClick={() => setShowAllAppointments(!showAllAppointments)}
              className={`px-4 py-2 rounded-lg transition-colors font-medium text-sm ${
                showAllAppointments 
                  ? 'bg-[#ff5d2e] text-white' 
                  : 'bg-[#ffe7df] text-[#ff5d2e] hover:bg-[#ffd4c7]'
              }`}
            >
              {showAllAppointments ? 'Show My Appointments' : 'Show All Appointments'}
            </button>
          </div>
        </div>

        {/* Main content grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left column - Upcoming */}
          <div className="lg:col-span-2 flex flex-col gap-6">
            {/* Upcoming Service */}
            <div className="flex flex-col gap-4">
              <p className="text-lg font-semibold text-black text-left">Upcoming Service</p>
              
              {nextUpcoming ? (
                <div className="border border-[#ffe7df] rounded-2xl overflow-hidden bg-white">
                  {/* Service Image */}
                  <div className="h-[185px] lg:h-[220px] relative overflow-hidden bg-[#ffe7df]">
                    <img
                      src={getServiceImage(nextUpcoming.serviceType)}
                      alt={nextUpcoming.serviceType}
                      className="w-full h-full object-cover"
                    />
                    <div className={`absolute top-3 right-3 text-white text-xs font-medium px-2 py-1 rounded-full ${
                      nextUpcoming.status === 'CONFIRMED' ? 'bg-green-500' :
                      nextUpcoming.status === 'PENDING' ? 'bg-yellow-500' :
                      'bg-blue-500'
                    }`}>
                      {nextUpcoming.status}
                    </div>
                  </div>
                  
                  {/* Service Details */}
                  <div className="p-4 flex flex-col gap-3">
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex-1">
                        <p className="text-lg font-semibold text-black">{nextUpcoming.serviceType}</p>
                        <div className="flex items-center gap-1 text-sm font-medium mt-1">
                          <span className="text-black/50">For:</span>
                          <span className="text-black">
                            {nextUpcoming.vehicleMake && nextUpcoming.vehicleModel
                              ? `${nextUpcoming.vehicleMake} ${nextUpcoming.vehicleModel}`
                              : 'No vehicle specified'}
                          </span>
                        </div>
                      </div>
                      <p className="text-lg font-semibold text-[#ff5d2e]">
                        LKR {(nextUpcoming.estimatedCost || 0).toLocaleString()}
                      </p>
                    </div>
                    
                    <div className="flex items-center gap-2 text-sm text-black/70">
                      <Clock className="w-4 h-4" />
                      <span>{formatDate(nextUpcoming.appointmentDate)}</span>
                      <span>•</span>
                      <span>{formatTime(nextUpcoming.appointmentDate)}</span>
                    </div>

                    {/* Actions */}
                    <div className="flex gap-3 mt-2">
                      <Link
                        to={`/confirmed/${nextUpcoming.id}`}
                        className="flex-1 bg-[#ff5d2e] text-white py-3 rounded-lg font-medium text-center hover:bg-[#e54d1e] transition-colors shadow-[0px_4px_8px_0px_rgba(255,93,46,0.3)]"
                      >
                        View Details
                      </Link>
                      <button className="px-4 py-3 border border-[#ffe7df] rounded-lg font-medium text-black hover:bg-[#fff7f5] transition-colors">
                        Reschedule
                      </button>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="border border-[#ffe7df] rounded-2xl p-8 bg-white text-center">
                  <Calendar className="w-12 h-12 text-black/30 mx-auto mb-3" />
                  <p className="text-black/50 mb-4">No upcoming services scheduled</p>
                  <Link
                    to="/services"
                    className="inline-block bg-[#ff5d2e] text-white py-2 px-6 rounded-lg font-medium hover:bg-[#e54d1e] transition-colors"
                  >
                    Book a Service
                  </Link>
                </div>
              )}
            </div>

            {/* Past Services */}
            <div className="flex flex-col gap-4">
              <div className="flex items-center justify-between">
                <p className="text-lg font-semibold text-black">Past Services</p>
                {pastAppointments.length > 4 && (
                  <button className="text-sm font-medium text-[#ff5d2e] hover:underline">
                    View all
                  </button>
                )}
              </div>
              
              {pastAppointments.length > 0 ? (
                <div className="flex flex-col gap-2">
                  {pastAppointments.slice(0, 4).map((service) => (
                    <div
                      key={service.id}
                      className="bg-white rounded-lg shadow-sm p-3 lg:p-4 flex items-center gap-3"
                    >
                      <div className="w-16 h-16 rounded-lg overflow-hidden flex-shrink-0">
                        <img
                          src={getServiceImage(service.serviceType)}
                          alt={service.serviceType}
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-base font-medium text-black truncate">{service.serviceType}</p>
                        <div className="flex items-center gap-1 text-xs text-black/50">
                          <span>{formatDate(service.appointmentDate)}</span>
                          <span>•</span>
                          <span>{formatTime(service.appointmentDate)}</span>
                        </div>
                        <p className="text-sm font-medium text-black mt-1">
                          LKR {((service.actualCost || service.estimatedCost || 0)).toLocaleString()}
                        </p>
                      </div>
                      <Link
                        to={`/book/1?notes=Rebook: ${service.serviceType}`}
                        className="bg-[#ff5d2e] text-white py-2 px-3 lg:py-3 lg:px-4 rounded-lg shadow-[0px_4px_8px_0px_rgba(255,93,46,0.3)] flex items-center gap-2 hover:bg-[#e54d1e] transition-colors flex-shrink-0"
                      >
                        <RotateCw className="w-4 h-4" />
                        <span className="text-sm lg:text-base font-medium">Rebook</span>
                      </Link>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="bg-white rounded-lg p-8 text-center">
                  <Clock className="w-12 h-12 text-black/30 mx-auto mb-3" />
                  <p className="text-black/50">No past services yet</p>
                </div>
              )}
            </div>
          </div>

          {/* Right column - Stats & Quick Actions (Desktop only) */}
          <div className="hidden lg:flex flex-col gap-6">
            {/* Stats */}
            <div className="bg-white rounded-lg shadow-sm p-4">
              <p className="text-lg font-semibold text-black mb-4">Service History</p>
              <div className="grid grid-cols-2 gap-4">
                <div className="text-center p-3 bg-[#fff7f5] rounded-lg">
                  <p className="text-2xl font-bold text-[#ff5d2e]">{totalServices}</p>
                  <p className="text-sm text-black/50">Total Services</p>
                </div>
                <div className="text-center p-3 bg-[#fff7f5] rounded-lg">
                  <p className="text-2xl font-bold text-[#ff5d2e]">
                    {totalSpent > 0 ? `LKR ${Math.round(totalSpent / 1000)}K` : 'LKR 0'}
                  </p>
                  <p className="text-sm text-black/50">Total Spent</p>
                </div>
              </div>
            </div>

            {/* Favorite Services */}
            <div className="bg-white rounded-lg shadow-sm p-4">
              <p className="text-lg font-semibold text-black mb-4">Frequent Services</p>
              <div className="flex flex-col gap-2">
                {['Lubricant Service', 'Washing Package', 'Waxing'].map((service, idx) => (
                  <Link
                    key={idx}
                    to="/services"
                    className="flex items-center gap-3 p-2 hover:bg-[#fff7f5] rounded-lg transition-colors"
                  >
                    <div className="w-8 h-8 bg-[#ffe7df] rounded flex items-center justify-center">
                      <Clock className="w-4 h-4 text-[#ff5d2e]" />
                    </div>
                    <span className="flex-1 text-sm font-medium text-black">{service}</span>
                    <ChevronRight className="w-4 h-4 text-black/50" />
                  </Link>
                ))}
              </div>
            </div>

            {/* Service Reminders */}
            <div className="bg-[#ffe7df] rounded-lg p-4">
              <p className="text-base font-semibold text-black mb-2">Service Reminder</p>
              <p className="text-sm text-black/70 mb-3">
                Your vehicle is due for an oil change in 500 km
              </p>
              <Link
                to="/services"
                className="inline-block bg-[#ff5d2e] text-white py-2 px-4 rounded-lg text-sm font-medium hover:bg-[#e54d1e] transition-colors"
              >
                Schedule Now
              </Link>
            </div>
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
