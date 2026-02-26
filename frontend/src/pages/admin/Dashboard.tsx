import { useEffect, useState } from 'react';
import { adminApi } from '../../services/adminApi';
import { Package, Calendar, Users, Clock, ArrowUpRight, ArrowDownRight, DollarSign } from 'lucide-react';
import { Link } from 'react-router-dom';

export function AdminDashboard() {
  const [stats, setStats] = useState({
    totalServices: 0,
    activeServices: 0,
    totalOffers: 0,
    pendingAppointments: 0,
    totalCustomers: 0,
    totalRevenue: 0,
  });
  const [upcomingAppointments, setUpcomingAppointments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      const dashboardRes = await adminApi.getDashboardStats();
      if (dashboardRes?.success) {
        const data = dashboardRes.data;
        setStats({
          // The backend gives us totalCustomers, totalAppointments, totalRevenue
          // and upcomingAppointments. We'll map them appropriately:
          totalServices: 0, // Not provided by the new endpoint, defaulting to 0 or fetch separately
          activeServices: 0,
          totalOffers: 0,
          pendingAppointments: data.totalAppointments || 0, // Reusing field for display
          totalCustomers: data.totalCustomers || 0,
          totalRevenue: data.totalRevenue || 0,
        });

        if (data.upcomingAppointments) {
          setUpcomingAppointments(data.upcomingAppointments);
        }

        // Let's still fetch active services to keep the "Active Services" card valid
        const services = await adminApi.getAllServices();
        setStats(prev => ({
          ...prev,
          totalServices: services?.data?.length || 0,
          activeServices: services?.data?.filter((s: any) => s.isActive).length || 0
        }));
      }
    } catch (error) {
      console.error('Failed to load dashboard stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const statCards = [
    {
      name: 'Total Revenue',
      value: `Rs. ${stats.totalRevenue.toLocaleString()}`,
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
          <h1 className="text-2xl font-bold text-black">Dashboard Overview</h1>
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
          return (
            <div key={stat.name} className="bg-white p-6 rounded-xl border border-black/5 hover:border-[#ff5d2e]/20 transition-all shadow-sm hover:shadow-md">
              <div className="flex items-start justify-between mb-4">
                <div className={`p-3 rounded-lg ${stat.bg}`}>
                  <Icon className={`w-6 h-6 ${stat.color}`} />
                </div>
                {stat.trend !== 'neutral' && (
                  <div className={`flex items-center gap-1 text-xs font-medium px-2 py-1 rounded-full ${stat.trend === 'up' ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'
                    }`}>
                    {stat.trend === 'up' ? <ArrowUpRight className="w-3 h-3" /> : <ArrowDownRight className="w-3 h-3" />}
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
    </div>
  );
}
