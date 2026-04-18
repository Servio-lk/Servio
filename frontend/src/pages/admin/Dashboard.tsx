import { useCallback, useEffect, useState } from 'react';
import { adminApi } from '../../services/adminApi';
import { useWebSocket } from '@/hooks/useWebSocket';
import {
  Package, Calendar, Users, Clock, ArrowUpRight,
  DollarSign, CreditCard, Banknote, AlertCircle, X, CheckCircle,
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { toast } from 'sonner';

export function AdminDashboard() {
  const [stats, setStats] = useState({
    totalServices: 0,
    activeServices: 0,
    pendingAppointments: 0,
    totalCustomers: 0,
    totalRevenue: 0,
    cardRevenue: 0,
    cashRevenue: 0,
    pendingCashRevenue: 0,
  });
  const [upcomingAppointments, setUpcomingAppointments] = useState<any[]>([]);
  const [pendingCashAppointments, setPendingCashAppointments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [cashModal, setCashModal] = useState<{ open: boolean; appointment: any | null }>({ open: false, appointment: null });
  const [cashAmount, setCashAmount] = useState('');
  const [cashLoading, setCashLoading] = useState(false);

  const loadStats = useCallback(async () => {
    try {
      const dashboardRes = await adminApi.getDashboardStats();
      if (dashboardRes?.success) {
        const data = dashboardRes.data;
        setStats(prev => ({
          ...prev,
          pendingAppointments: data.totalAppointments || 0,
          totalCustomers: data.totalCustomers || 0,
          totalServices: data.totalServices || 0,
          activeServices: data.activeServices || 0,
          totalRevenue: data.totalRevenue || 0,
          cardRevenue: data.cardRevenue || 0,
          cashRevenue: data.cashRevenue || 0,
          pendingCashRevenue: data.pendingCashRevenue || 0,
        }));
        if (data.recentAppointments) setUpcomingAppointments(data.recentAppointments);
        else if (data.upcomingAppointments) setUpcomingAppointments(data.upcomingAppointments);
        if (data.pendingCashAppointments) setPendingCashAppointments(data.pendingCashAppointments);
      }
    } catch (error) {
      console.error('Failed to load dashboard stats:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadStats();
  }, [loadStats]);

  // Keep dashboard cards and recent activity fresh as soon as bookings change.
  useWebSocket(
    ['/topic/appointments'],
    useCallback(() => {
      loadStats();
    }, [loadStats]),
  );

  const statCards = [
    {
      name: 'Total Revenue',
      value: `Rs. ${Number(stats.totalRevenue).toLocaleString()}`,
      change: '+12.5%',
      trend: 'up',
      icon: DollarSign,
      color: 'text-[#ff5d2e]',
      bg: 'bg-[#ffe7df]',
    },
    {
      name: 'Pending Bookings',
      value: stats.pendingAppointments,
      change: '+4',
      trend: 'up',
      icon: Calendar,
      color: 'text-blue-600',
      bg: 'bg-blue-50',
    },
    {
      name: 'Active Services',
      value: stats.activeServices,
      change: `${stats.totalServices} total`,
      trend: 'neutral',
      icon: Package,
      color: 'text-purple-600',
      bg: 'bg-purple-50',
    },
    {
      name: 'Total Customers',
      value: stats.totalCustomers,
      change: '+2.4%',
      trend: 'up',
      icon: Users,
      color: 'text-emerald-600',
      bg: 'bg-emerald-50',
    },
  ];

  const formatDateTime = (dateString: string) =>
    new Date(dateString).toLocaleString('en-US', {
      month: 'short', day: 'numeric', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    });

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
      await loadStats();
    } catch {
      toast.error('Failed to record payment');
    } finally {
      setCashLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#ff5d2e] mx-auto"></div>
          <p className="mt-4 text-black/70">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl text-left font-bold text-black">Dashboard Overview</h1>
          <p className="text-black/70 mt-1">Welcome back, here's what's happening today.</p>
        </div>
        <div className="flex gap-3">
          <Link
            to="/admin/appointments"
            className="flex items-center gap-2 px-4 py-2 bg-black text-white rounded-lg hover:bg-gray-800 transition-colors"
          >
            <Clock className="w-4 h-4" />
            <span>View Schedule</span>
          </Link>
          <Link
            to="/admin/services"
            className="flex items-center gap-2 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e54d1e] transition-colors shadow-lg shadow-[#ff5d2e]/20"
          >
            <Package className="w-4 h-4" />
            <span>Add Service</span>
          </Link>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {statCards.map((stat) => {
          const Icon = stat.icon;
          const isRevenue = stat.name === 'Total Revenue';
          return (
            <div key={stat.name} className="bg-white p-6 rounded-xl border border-black/5 hover:border-[#ff5d2e]/20 transition-all shadow-sm hover:shadow-md">
              <div className="flex items-start justify-between mb-4">
                <div className={`p-3 rounded-lg ${stat.bg}`}>
                  <Icon className={`w-6 h-6 ${stat.color}`} />
                </div>
                {stat.trend !== 'neutral' && (
                  <div className="flex items-center gap-1 text-xs font-medium px-2 py-1 rounded-full bg-green-50 text-green-700">
                    <ArrowUpRight className="w-3 h-3" />
                    {stat.change}
                  </div>
                )}
                {stat.trend === 'neutral' && (
                  <div className="flex items-center gap-1 text-xs font-medium px-2 py-1 rounded-full bg-gray-50 text-gray-600">
                    {stat.change}
                  </div>
                )}
              </div>
              <h3 className="text-black/50 text-sm font-medium">{stat.name}</h3>
              <p className="text-2xl font-bold text-black mt-1">{stat.value}</p>
              {/* Revenue breakdown sub-lines */}
              {isRevenue && (
                <div className="mt-3 pt-3 border-t border-gray-100 space-y-1.5">
                  <div className="flex items-center justify-between text-xs">
                    <span className="flex items-center gap-1 text-gray-500">
                      <CreditCard className="w-3 h-3" /> Card
                    </span>
                    <span className="font-semibold text-black">Rs. {Number(stats.cardRevenue).toLocaleString()}</span>
                  </div>
                  <div className="flex items-center justify-between text-xs">
                    <span className="flex items-center gap-1 text-gray-500">
                      <Banknote className="w-3 h-3" /> Cash
                    </span>
                    <span className="font-semibold text-black">Rs. {Number(stats.cashRevenue).toLocaleString()}</span>
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Recent Activity & Quick Actions Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Activity Section */}
        <div className="lg:col-span-2 bg-white rounded-xl border border-black/5 shadow-sm p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-bold text-black">Recent Activity</h2>
            <button className="text-sm font-semibold text-[#ff5d2e] hover:underline">View All</button>
          </div>

          <div className="flex flex-col gap-4">
            {upcomingAppointments && upcomingAppointments.length > 0 ? (
              upcomingAppointments.map((appt, i) => (
                <div key={i} className="flex items-center gap-4 p-4 rounded-lg bg-gray-50/50 hover:bg-gray-50 transition-colors">
                  <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold text-xs uppercase">
                    {(appt.userName || 'U').substring(0, 2)}
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-medium text-black">
                      {appt.userName || 'Unknown'} booked <span className="font-bold">{appt.serviceType}</span>
                    </p>
                    <p className="text-xs text-black/50">
                      {new Date(appt.appointmentDate).toLocaleString()} - {appt.vehicleMake} {appt.vehicleModel}
                    </p>
                  </div>
                  <span className={`px-2 py-1 text-xs font-medium rounded ${appt.status === 'PENDING' ? 'bg-yellow-100 text-yellow-700' :
                      appt.status === 'CONFIRMED' ? 'bg-blue-100 text-blue-700' :
                        'bg-green-100 text-green-700'
                    }`}>
                    {appt.status}
                  </span>
                </div>
              ))
            ) : (
              <div className="text-center py-6 text-black/50 text-sm">
                No upcoming appointments found.
              </div>
            )}
          </div>
        </div>

        {/* Quick Actions / Notifications */}
        <div className="bg-white rounded-xl border border-black/5 shadow-sm p-6">
          <h2 className="text-lg font-bold text-black mb-6">System Status</h2>

          <div className="space-y-6">
            <div>
              <div className="flex justify-between text-sm mb-2">
                <span className="text-black/70">Database Usage</span>
                <span className="font-medium text-black">24%</span>
              </div>
              <div className="w-full bg-gray-100 rounded-full h-2">
                <div className="bg-green-500 h-2 rounded-full w-1/4"></div>
              </div>
            </div>

            <div>
              <div className="flex justify-between text-sm mb-2">
                <span className="text-black/70">Daily Booking Goal</span>
                <span className="font-medium text-black">8/12</span>
              </div>
              <div className="w-full bg-gray-100 rounded-full h-2">
                <div className="bg-[#ff5d2e] h-2 rounded-full w-2/3"></div>
              </div>
            </div>

            <div className="p-4 bg-[#fff7f5] rounded-lg border border-[#ff5d2e]/10 mt-6">
              <h3 className="text-[#ff5d2e] font-semibold text-sm mb-1">Backup Scheduled</h3>
              <p className="text-xs text-black/60">Next system backup scheduled for tonight at 02:00 AM.</p>
            </div>
          </div>
        </div>
      </div>

      {/* Pending Cash Collections */}
      <div className="bg-white rounded-xl border border-orange-200 shadow-sm overflow-hidden">
        <div className="p-5 border-b border-orange-100 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-orange-50 rounded-lg">
              <AlertCircle className="w-5 h-5 text-orange-500" />
            </div>
            <div>
              <h2 className="text-base font-bold text-black">Pending Cash Collections</h2>
              <p className="text-xs text-gray-500 mt-0.5">
                {pendingCashAppointments.length} appointment{pendingCashAppointments.length !== 1 ? 's' : ''} awaiting payment
                {stats.pendingCashRevenue > 0 && (
                  <> · Est. <span className="font-semibold text-orange-600">Rs. {Number(stats.pendingCashRevenue).toLocaleString()}</span> pending</>
                )}
              </p>
            </div>
          </div>
          <Link
            to="/admin/appointments"
            className="text-sm text-[#ff5d2e] font-semibold hover:underline hidden sm:block"
          >
            View All →
          </Link>
        </div>

        {pendingCashAppointments.length === 0 ? (
          <div className="py-12 text-center">
            <div className="w-12 h-12 rounded-full bg-green-50 flex items-center justify-center mx-auto mb-3">
              <CheckCircle className="w-6 h-6 text-green-500" />
            </div>
            <p className="text-sm font-medium text-black">All caught up!</p>
            <p className="text-xs text-gray-500 mt-1">No pending cash collections right now.</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {pendingCashAppointments.map((appt) => (
              <div key={appt.id} className="flex items-center gap-4 px-5 py-4 hover:bg-orange-50/30 transition-colors">
                <div className="w-9 h-9 rounded-full bg-orange-100 flex items-center justify-center text-orange-600 font-bold text-xs flex-shrink-0">
                  {(appt.userName || 'U').charAt(0).toUpperCase()}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-black truncate">{appt.userName || 'Unknown'}</p>
                  <p className="text-xs text-gray-500 truncate">
                    {appt.serviceType}
                    {appt.vehicleMake && appt.vehicleModel && <> · {appt.vehicleMake} {appt.vehicleModel}</>}
                    {' · '}{formatDateTime(appt.appointmentDate)}
                  </p>
                </div>
                <div className="flex items-center gap-3 flex-shrink-0">
                  <div className="text-right">
                    <p className="text-sm font-semibold text-black">
                      {appt.estimatedCost
                        ? `Rs. ${Number(appt.estimatedCost).toLocaleString()}`
                        : 'TBD'}
                    </p>
                    <span className="text-xs px-1.5 py-0.5 bg-blue-50 text-blue-700 rounded font-medium">
                      {appt.status.replace(/_/g, ' ')}
                    </span>
                  </div>
                  <button
                    onClick={() => openCashModal(appt)}
                    className="px-3 py-1.5 bg-[#ff5d2e] text-white text-xs font-semibold rounded-lg hover:bg-[#e54d1e] transition-colors whitespace-nowrap"
                  >
                    Collect Cash
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Cash Collection Modal */}
      {cashModal.open && cashModal.appointment && (
        <div
          className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4"
          onClick={(e) => { if (e.target === e.currentTarget) setCashModal({ open: false, appointment: null }); }}
        >
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
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
              <div>
                <label className="block text-sm font-medium text-black mb-1.5">Amount Collected (Rs.)</label>
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
