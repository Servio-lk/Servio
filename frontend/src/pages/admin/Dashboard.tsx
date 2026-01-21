import { useEffect, useState } from 'react';
import { adminApi } from '../../services/adminApi';
import { Package, Tag, Calendar, Users, TrendingUp, Clock } from 'lucide-react';

export function AdminDashboard() {
  const [stats, setStats] = useState({
    totalServices: 0,
    activeServices: 0,
    totalOffers: 0,
    pendingAppointments: 0,
    totalCustomers: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      const [services, offers, appointments, customers] = await Promise.all([
        adminApi.getAllServices(),
        adminApi.getAllOffers(),
        adminApi.getAllAppointments(),
        adminApi.getAllCustomers(),
      ]);

      setStats({
        totalServices: services.data?.length || 0,
        activeServices: services.data?.filter((s: any) => s.isActive).length || 0,
        totalOffers: offers.data?.length || 0,
        pendingAppointments: appointments.data?.filter((a: any) => a.status === 'PENDING').length || 0,
        totalCustomers: customers.data?.length || 0,
      });
    } catch (error) {
      console.error('Failed to load stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const statCards = [
    {
      name: 'Total Services',
      value: stats.totalServices,
      subtitle: `${stats.activeServices} active`,
      icon: Package,
      color: 'bg-blue-500',
    },
    {
      name: 'Active Offers',
      value: stats.totalOffers,
      subtitle: 'Promotions running',
      icon: Tag,
      color: 'bg-green-500',
    },
    {
      name: 'Pending Appointments',
      value: stats.pendingAppointments,
      subtitle: 'Awaiting confirmation',
      icon: Clock,
      color: 'bg-yellow-500',
    },
    {
      name: 'Total Customers',
      value: stats.totalCustomers,
      subtitle: 'Registered users',
      icon: Users,
      color: 'bg-purple-500',
    },
  ];

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gray-900"></div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-600 mt-2">Welcome to Servio Admin Panel</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {statCards.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.name} className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">{stat.name}</p>
                  <p className="text-3xl font-bold text-gray-900 mt-2">{stat.value}</p>
                  <p className="text-xs text-gray-500 mt-1">{stat.subtitle}</p>
                </div>
                <div className={`${stat.color} p-3 rounded-lg`}>
                  <Icon className="h-6 w-6 text-white" />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Quick Actions</h2>
          <div className="space-y-3">
            <a
              href="/admin/services"
              className="block p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <div className="flex items-center">
                <Package className="h-5 w-5 text-blue-600 mr-3" />
                <div>
                  <div className="font-medium">Manage Services</div>
                  <div className="text-sm text-gray-600">Add, edit, or toggle services</div>
                </div>
              </div>
            </a>
            <a
              href="/admin/appointments"
              className="block p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <div className="flex items-center">
                <Calendar className="h-5 w-5 text-green-600 mr-3" />
                <div>
                  <div className="font-medium">View Appointments</div>
                  <div className="text-sm text-gray-600">Manage customer bookings</div>
                </div>
              </div>
            </a>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Recent Activity</h2>
          <div className="text-center py-8 text-gray-500">
            <TrendingUp className="h-12 w-12 mx-auto mb-2 text-gray-400" />
            <p>Activity tracking coming soon</p>
          </div>
        </div>
      </div>
    </div>
  );
}
