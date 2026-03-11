import { useEffect, useState } from 'react';
import { adminApi } from '../../services/adminApi';
import {
  Calendar, Filter, Clock, CreditCard, Banknote,
  CheckCircle, ChevronDown, X, AlertCircle, RefreshCw,
} from 'lucide-react';
import { toast } from 'sonner';

// Valid status transitions per current status
const STATUS_TRANSITIONS: Record<string, Array<{ value: string; label: string }>> = {
  PENDING: [
    { value: 'CONFIRMED', label: 'Confirm Booking' },
    { value: 'CANCELLED', label: 'Cancel' },
  ],
  CONFIRMED: [
    { value: 'IN_PROGRESS', label: 'Start Service' },
    { value: 'CANCELLED', label: 'Cancel' },
  ],
  IN_PROGRESS: [
    { value: 'COMPLETED', label: 'Mark Complete' },
    { value: 'CANCELLED', label: 'Cancel' },
  ],
  COMPLETED: [],
  CANCELLED: [],
  PENDING_PAYMENT: [{ value: 'CANCELLED', label: 'Cancel' }],
};

const STATUS_STYLES: Record<string, string> = {
  PENDING: 'bg-yellow-50 text-yellow-700 border-yellow-200',
  PENDING_PAYMENT: 'bg-yellow-50 text-yellow-700 border-yellow-200',
  CONFIRMED: 'bg-blue-50 text-blue-700 border-blue-200',
  IN_PROGRESS: 'bg-purple-50 text-purple-700 border-purple-200',
  COMPLETED: 'bg-green-50 text-green-700 border-green-200',
  CANCELLED: 'bg-red-50 text-red-700 border-red-200',
};

const TRANSITION_DOT: Record<string, string> = {
  CONFIRMED: 'bg-blue-500',
  IN_PROGRESS: 'bg-purple-500',
  COMPLETED: 'bg-green-500',
  CANCELLED: 'bg-red-500',
  PENDING: 'bg-yellow-400',
};

function getPaymentInfo(appt: any) {
  const paid = appt.paidAmount && Number(appt.paidAmount) > 0;
  const method: string | null = appt.paymentMethod ?? null;
  const status: string = appt.status;

  if (paid && method && method !== 'CASH') {
    return { label: 'Paid by Card', icon: 'card' as const, color: 'bg-green-50 text-green-700 border-green-200', canCollect: false };
  }
  if (paid && method === 'CASH') {
    return { label: 'Paid by Cash', icon: 'cash' as const, color: 'bg-green-50 text-green-700 border-green-200', canCollect: false };
  }
  if (['CONFIRMED', 'IN_PROGRESS', 'COMPLETED'].includes(status)) {
    return { label: 'Cash Pending', icon: 'alert' as const, color: 'bg-orange-50 text-orange-700 border-orange-200', canCollect: true };
  }
  return { label: '—', icon: 'none' as const, color: 'bg-gray-50 text-gray-300 border-gray-200', canCollect: false };
}

export function AdminAppointments() {
  const [appointments, setAppointments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [updatingId, setUpdatingId] = useState<number | null>(null);
  const [openDropdownId, setOpenDropdownId] = useState<number | null>(null);
  const [cashModal, setCashModal] = useState<{ open: boolean; appointment: any | null }>({ open: false, appointment: null });
  const [cashAmount, setCashAmount] = useState('');
  const [cashLoading, setCashLoading] = useState(false);

  useEffect(() => { loadAppointments(); }, [statusFilter]);

  // Close dropdowns on outside click
  useEffect(() => {
    const handle = (e: MouseEvent) => {
      if (!(e.target as Element).closest('[data-dropdown]')) setOpenDropdownId(null);
    };
    document.addEventListener('mousedown', handle);
    return () => document.removeEventListener('mousedown', handle);
  }, []);

  // Close modal on Escape
  useEffect(() => {
    if (!cashModal.open) return;
    const handle = (e: KeyboardEvent) => { if (e.key === 'Escape') setCashModal({ open: false, appointment: null }); };
    document.addEventListener('keydown', handle);
    return () => document.removeEventListener('keydown', handle);
  }, [cashModal.open]);

  const loadAppointments = async () => {
    try {
      setLoading(true);
      const response = await adminApi.getAllAppointments(statusFilter || undefined);
      setAppointments(response.data || []);
    } catch {
      toast.error('Failed to load appointments');
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (id: number, newStatus: string) => {
    setUpdatingId(id);
    setOpenDropdownId(null);
    try {
      await adminApi.updateAppointmentStatus(id, newStatus);
      toast.success(`Status updated to ${newStatus.replace(/_/g, ' ')}`);
      await loadAppointments();
    } catch {
      toast.error('Failed to update status');
    } finally {
      setUpdatingId(null);
    }
  };

  const openCashModal = (appointment: any) => {
    setCashModal({ open: true, appointment });
    setCashAmount(appointment.estimatedCost ? String(appointment.estimatedCost) : '');
  };

  const handleCollectCash = async () => {
    if (!cashModal.appointment) return;
    const amount = parseFloat(cashAmount);
    if (!cashAmount || isNaN(amount) || amount <= 0) {
      toast.error('Please enter a valid amount');
      return;
    }
    setCashLoading(true);
    try {
      await adminApi.recordPayment(cashModal.appointment.id, amount, 'CASH');
      toast.success('Cash payment recorded successfully');
      setCashModal({ open: false, appointment: null });
      await loadAppointments();
    } catch {
      toast.error('Failed to record payment');
    } finally {
      setCashLoading(false);
    }
  };

  const formatDateTime = (dateString: string) =>
    new Date(dateString).toLocaleString('en-US', {
      month: 'short', day: 'numeric', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    });

  const countByStatus = (s: string) => appointments.filter(a => a.status === s).length;

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
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl text-left font-bold text-black">Appointments Management</h1>
          <p className="text-black/70 mt-1">Manage bookings, update statuses, and collect payments</p>
        </div>
        <button
          onClick={loadAppointments}
          className="flex items-center gap-2 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e54d1e] text-sm font-medium transition-colors self-start sm:self-auto"
        >
          <RefreshCw className="w-4 h-4" />
          Refresh
        </button>
      </div>

      {/* Quick-filter summary cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {(
          [
            { key: 'PENDING', label: 'Pending', bg: 'border-yellow-200 bg-yellow-50', num: 'text-yellow-700' },
            { key: 'CONFIRMED', label: 'Confirmed', bg: 'border-blue-200 bg-blue-50', num: 'text-blue-700' },
            { key: 'IN_PROGRESS', label: 'In Progress', bg: 'border-purple-200 bg-purple-50', num: 'text-purple-700' },
            { key: 'COMPLETED', label: 'Completed', bg: 'border-green-200 bg-green-50', num: 'text-green-700' },
          ] as const
        ).map(({ key, label, bg, num }) => (
          <button
            key={key}
            onClick={() => setStatusFilter(statusFilter === key ? '' : key)}
            className={`p-3 rounded-xl border text-left transition-all ${
              bg
            } ${
              statusFilter === key
                ? 'ring-2 ring-offset-1 ring-[#ff5d2e] shadow-sm'
                : 'hover:shadow-sm'
            }`}
          >
            <p className={`text-2xl font-bold ${num}`}>{countByStatus(key)}</p>
            <p className="text-xs text-black/60 mt-0.5">{label}</p>
          </button>
        ))}
      </div>

      <div className="bg-white rounded-xl border border-black/5 shadow-sm overflow-hidden">
        {/* Toolbar */}
        <div className="p-4 border-b border-black/5 flex items-center justify-between flex-wrap gap-3">
          <div className="flex items-center gap-2">
            <div className="relative">
              <Filter className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="pl-9 pr-4 py-2 bg-gray-50 border border-transparent focus:bg-white focus:border-[#ff5d2e] focus:outline-none rounded-lg text-sm appearance-none cursor-pointer"
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
          <div className="text-sm text-gray-500 flex items-center gap-3">
            <span><span className="font-medium text-black">{appointments.length}</span> appointments</span>
            {statusFilter && (
              <button onClick={() => setStatusFilter('')} className="text-[#ff5d2e] font-medium hover:underline">
                Clear filter
              </button>
            )}
          </div>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50/50 border-b border-black/5">
                <th className="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">ID</th>
                <th className="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Customer</th>
                <th className="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Service</th>
                <th className="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Date &amp; Time</th>
                <th className="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Vehicle</th>
                <th className="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Payment</th>
                <th className="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Cost</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {appointments.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-6 py-16 text-center">
                    <div className="bg-gray-50 rounded-full w-16 h-16 flex items-center justify-center mx-auto mb-4">
                      <Calendar className="h-8 w-8 text-gray-400" />
                    </div>
                    <p className="text-lg font-medium text-black">No appointments found</p>
                    <p className="text-sm text-gray-500 mt-1">Try changing the filter or wait for new bookings.</p>
                  </td>
                </tr>
              ) : (
                appointments.map((appt) => {
                  const transitions = STATUS_TRANSITIONS[appt.status] ?? [];
                  const payInfo = getPaymentInfo(appt);
                  const isUpdating = updatingId === appt.id;

                  return (
                    <tr key={appt.id} className="hover:bg-gray-50/40 transition-colors">
                      {/* ID */}
                      <td className="px-4 py-4 text-sm font-mono text-gray-400">#{appt.id}</td>

                      {/* Customer */}
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-2">
                          <div className="w-8 h-8 rounded-full bg-orange-100 flex items-center justify-center text-[#ff5d2e] font-bold text-xs flex-shrink-0">
                            {(appt.userName || 'U').charAt(0).toUpperCase()}
                          </div>
                          <div className="min-w-0">
                            <p className="text-sm font-medium text-black leading-tight truncate">{appt.userName || 'Unknown'}</p>
                            <p className="text-xs text-gray-400 truncate">{appt.userEmail}</p>
                          </div>
                        </div>
                      </td>

                      {/* Service */}
                      <td className="px-4 py-4 text-sm font-medium text-black">{appt.serviceType}</td>

                      {/* Date */}
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-1.5 text-sm text-gray-600">
                          <Clock className="w-3.5 h-3.5 text-gray-400 flex-shrink-0" />
                          {formatDateTime(appt.appointmentDate)}
                        </div>
                      </td>

                      {/* Vehicle */}
                      <td className="px-4 py-4 text-sm text-gray-600">
                        {appt.vehicleMake && appt.vehicleModel
                          ? `${appt.vehicleMake} ${appt.vehicleModel}`
                          : <span className="text-gray-400">—</span>}
                      </td>

                      {/* Status — clickable dropdown for valid transitions */}
                      <td className="px-4 py-4">
                        {transitions.length > 0 ? (
                          <div className="relative" data-dropdown>
                            <button
                              onClick={() => setOpenDropdownId(openDropdownId === appt.id ? null : appt.id)}
                              disabled={isUpdating}
                              className={`inline-flex items-center gap-1 px-2.5 py-1 text-xs font-medium rounded-full border transition-all hover:shadow-sm disabled:opacity-50 cursor-pointer ${
                                STATUS_STYLES[appt.status] ?? 'bg-gray-50 text-gray-700 border-gray-200'
                              }`}
                            >
                              {isUpdating ? (
                                <span className="animate-pulse">Updating…</span>
                              ) : (
                                <>
                                  {appt.status.replace(/_/g, ' ')}
                                  <ChevronDown className="w-3 h-3 opacity-60" />
                                </>
                              )}
                            </button>

                            {openDropdownId === appt.id && (
                              <div className="absolute left-0 top-full mt-1 bg-white border border-black/10 rounded-xl shadow-xl z-20 min-w-[180px] overflow-hidden">
                                <div className="px-3 py-2 text-xs text-gray-400 font-medium border-b border-gray-100">
                                  Change status to
                                </div>
                                {transitions.map((t) => (
                                  <button
                                    key={t.value}
                                    onClick={() => handleStatusChange(appt.id, t.value)}
                                    className={`w-full text-left px-3 py-2.5 text-sm hover:bg-gray-50 flex items-center gap-2.5 transition-colors ${
                                      t.value === 'CANCELLED' ? 'text-red-600' : 'text-black'
                                    }`}
                                  >
                                    <span className={`w-2 h-2 rounded-full flex-shrink-0 ${TRANSITION_DOT[t.value] ?? 'bg-gray-400'}`} />
                                    {t.label}
                                  </button>
                                ))}
                              </div>
                            )}
                          </div>
                        ) : (
                          <span
                            className={`inline-flex px-2.5 py-1 text-xs font-medium rounded-full border ${
                              STATUS_STYLES[appt.status] ?? 'bg-gray-50 text-gray-700 border-gray-200'
                            }`}
                          >
                            {appt.status.replace(/_/g, ' ')}
                          </span>
                        )}
                      </td>

                      {/* Payment column */}
                      <td className="px-4 py-4">
                        <div className="flex flex-col gap-1">
                          <span
                            className={`inline-flex items-center gap-1 px-2 py-0.5 text-xs font-medium rounded-full border w-fit ${payInfo.color}`}
                          >
                            {payInfo.icon === 'card' && <CreditCard className="w-3 h-3" />}
                            {payInfo.icon === 'cash' && <Banknote className="w-3 h-3" />}
                            {payInfo.icon === 'alert' && <AlertCircle className="w-3 h-3" />}
                            {payInfo.label}
                          </span>
                          {payInfo.canCollect && (
                            <button
                              onClick={() => openCashModal(appt)}
                              className="text-xs text-[#ff5d2e] hover:underline font-medium text-left leading-none"
                            >
                              Collect Cash →
                            </button>
                          )}
                        </div>
                      </td>

                      {/* Cost */}
                      <td className="px-4 py-4 text-sm">
                        {appt.actualCost ? (
                          <span className="font-semibold text-black">Rs. {Number(appt.actualCost).toLocaleString()}</span>
                        ) : appt.estimatedCost ? (
                          <span className="text-gray-500">~Rs. {Number(appt.estimatedCost).toLocaleString()}</span>
                        ) : (
                          <span className="text-gray-400">TBD</span>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-black/5 bg-gray-50/50 text-xs text-gray-500">
          Showing {appointments.length} result{appointments.length !== 1 ? 's' : ''}
        </div>
      </div>

      {/* Cash Collection Modal */}
      {cashModal.open && cashModal.appointment && (
        <div
          className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4"
          onClick={(e) => { if (e.target === e.currentTarget) setCashModal({ open: false, appointment: null }); }}
        >
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
            {/* Modal header */}
            <div className="flex items-center justify-between p-6 border-b border-black/5">
              <div>
                <h2 className="text-lg font-bold text-black">Collect Cash Payment</h2>
                <p className="text-sm text-gray-500 mt-0.5">Record cash received from customer</p>
              </div>
              <button
                onClick={() => setCashModal({ open: false, appointment: null })}
                className="p-2 hover:bg-gray-100 rounded-full transition-colors"
              >
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>

            <div className="p-6 space-y-4">
              {/* Appointment summary */}
              <div className="bg-gray-50 rounded-xl p-4 space-y-2.5">
                {([
                  ['Customer', cashModal.appointment.userName || 'Unknown'],
                  ['Service', cashModal.appointment.serviceType],
                  ['Date', formatDateTime(cashModal.appointment.appointmentDate)],
                  ['Estimated Cost', cashModal.appointment.estimatedCost
                    ? `Rs. ${Number(cashModal.appointment.estimatedCost).toLocaleString()}`
                    : 'Not set'],
                ] as [string, string][]).map(([label, value]) => (
                  <div key={label} className="flex justify-between text-sm">
                    <span className="text-gray-500">{label}</span>
                    <span className="font-medium text-black">{value}</span>
                  </div>
                ))}
              </div>

              {/* Amount input */}
              <div>
                <label className="block text-sm font-medium text-black mb-1.5">
                  Amount Collected (Rs.)
                </label>
                <div className="relative">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm font-medium">Rs.</span>
                  <input
                    type="number"
                    value={cashAmount}
                    onChange={(e) => setCashAmount(e.target.value)}
                    placeholder="0.00"
                    min="0"
                    step="0.01"
                    className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:border-[#ff5d2e] focus:ring-1 focus:ring-[#ff5d2e] text-sm"
                    autoFocus
                  />
                </div>
              </div>

              {/* Actions */}
              <div className="flex gap-3 pt-2">
                <button
                  onClick={() => setCashModal({ open: false, appointment: null })}
                  className="flex-1 px-4 py-3 border border-gray-200 text-black rounded-xl hover:bg-gray-50 text-sm font-medium transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleCollectCash}
                  disabled={cashLoading || !cashAmount}
                  className="flex-1 px-4 py-3 bg-[#ff5d2e] text-white rounded-xl hover:bg-[#e54d1e] text-sm font-medium transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {cashLoading ? (
                    <span className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent" />
                  ) : (
                    <CheckCircle className="w-4 h-4" />
                  )}
                  {cashLoading ? 'Recording…' : 'Confirm Payment'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
