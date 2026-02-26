import { useEffect, useState } from 'react';
import { adminApi } from '../../services/adminApi';
import { Calendar, Filter, Clock, CreditCard, MoreVertical } from 'lucide-react';
import { toast } from 'sonner';

export function AdminAppointments() {
  const [appointments, setAppointments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>('');

  useEffect(() => {
    loadAppointments();
  }, [statusFilter]);

  const loadAppointments = async () => {
    try {
      setLoading(true);
      const response = await adminApi.getAllAppointments(statusFilter || undefined);
      setAppointments(response.data || []);
    } catch (error) {
      console.error('Failed to load appointments:', error);
      toast.error('Failed to load appointments');
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (appointmentId: number, newStatus: string) => {
    try {
      await adminApi.updateAppointmentStatus(appointmentId, newStatus);
      toast.success('Appointment status updated successfully');
      // Update the local state
      setAppointments(prev =>
        prev.map(apt =>
          apt.id === appointmentId ? { ...apt, status: newStatus } : apt
        )
      );
    } catch (error) {
      console.error('Failed to update appointment status:', error);
      toast.error('Failed to update appointment status');
    }
  };

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      PENDING: 'bg-yellow-50 text-yellow-700 border-yellow-200',
      CONFIRMED: 'bg-blue-50 text-blue-700 border-blue-200',
      IN_PROGRESS: 'bg-purple-50 text-purple-700 border-purple-200',
      COMPLETED: 'bg-green-50 text-green-700 border-green-200',
      CANCELLED: 'bg-red-50 text-red-700 border-red-200',
    };
    return colors[status] || 'bg-gray-50 text-gray-700 border-gray-200';
  };

  const formatDateTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#ff5d2e] mx-auto"></div>
          <p className="mt-4 text-black/70">Loading appointments...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-black">Appointments Management</h1>
          <p className="text-black/70 mt-1">Track and manage customer bookings</p>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-black/5 shadow-sm overflow-hidden">
        {/* Toolbar */}
        <div className="p-4 border-b border-black/5 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="relative">
              <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="pl-9 pr-4 py-2 bg-gray-50 border-transparent focus:bg-white focus:border-[#ff5d2e] focus:ring-0 rounded-lg transition-all text-sm appearance-none cursor-pointer"
              >
                <option value="">All Status</option>
                <option value="PENDING">Pending</option>
                <option value="CONFIRMED">Confirmed</option>
                <option value="IN_PROGRESS">In Progress</option>
                <option value="COMPLETED">Completed</option>
                <option value="CANCELLED">Cancelled</option>
              </select>
            </div>
          </div>
          <div className="text-sm text-gray-500">
            <span className="font-medium text-black">{appointments.length}</span> appointments found
          </div>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50/50 border-b border-black/5">
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">ID</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Customer</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Service</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Date & Time</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Cost</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {appointments.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-gray-500">
                    <div className="bg-gray-50 rounded-full w-16 h-16 flex items-center justify-center mx-auto mb-4">
                      <Calendar className="h-8 w-8 text-gray-400" />
                    </div>
                    <p className="text-lg font-medium text-black">No appointments found</p>
                    <p className="text-sm text-gray-500">Try changing the filter or wait for new bookings.</p>
                  </td>
                </tr>
              ) : (
                appointments.map((appointment) => (
                  <tr key={appointment.id} className="hover:bg-gray-50/50 transition-colors group">
                    <td className="px-6 py-4 text-sm font-mono text-gray-400">
                      #{appointment.id}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-orange-100 flex items-center justify-center text-[#ff5d2e] font-bold text-xs">
                          {(appointment.userName || 'U').charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <p className="text-sm font-medium text-black">{appointment.userName || 'Unknown User'}</p>
                          <p className="text-xs text-gray-500">{appointment.userEmail}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-black font-medium">
                      {appointment.serviceType}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2 text-sm text-gray-600">
                        <Clock className="w-4 h-4 text-gray-400" />
                        {formatDateTime(appointment.appointmentDate)}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <select
                        value={appointment.status}
                        onChange={(e) => handleStatusChange(appointment.id, e.target.value)}
                        className={`px-2.5 py-1 text-xs font-medium rounded-lg border cursor-pointer focus:outline-none focus:ring-2 focus:ring-[#ff5d2e] focus:ring-offset-1 transition-all ${getStatusColor(
                          appointment.status
                        )}`}
                      >
                        <option value="PENDING">Pending</option>
                        <option value="CONFIRMED">Confirmed</option>
                        <option value="IN_PROGRESS">In Progress</option>
                        <option value="COMPLETED">Completed</option>
                        <option value="CANCELLED">Cancelled</option>
                      </select>
                    </td>
                    <td className="px-6 py-4 text-sm font-medium text-black">
                      <div className="flex items-center gap-1">
                        <CreditCard className="w-3 h-3 text-gray-400" />
                        {appointment.actualCost
                          ? `Rs. ${appointment.actualCost.toLocaleString()}`
                          : appointment.estimatedCost
                            ? `~Rs. ${appointment.estimatedCost.toLocaleString()}`
                            : 'TBD'}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button className="text-gray-400 hover:text-black transition-colors p-1 rounded-full hover:bg-gray-100">
                        <MoreVertical className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Footer / Pagination Placeholder */}
        <div className="p-4 border-t border-black/5 bg-gray-50/50 flex items-center justify-between text-xs text-gray-500">
          <span>Showing {appointments.length} results</span>
          <div className="flex gap-2">
            <button className="px-3 py-1 border rounded hover:bg-white disabled:opacity-50" disabled>Previous</button>
            <button className="px-3 py-1 border rounded hover:bg-white disabled:opacity-50" disabled>Next</button>
          </div>
        </div>
      </div>
    </div>
  );
}
