import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Search, Calendar, Warehouse, ChevronRight, Clock, TrendingUp, Star } from 'lucide-react';
import { AppLayout } from '@/components/layouts/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import { ServiceCard } from '@/components/ServiceCard';
import { OfferCard } from '@/components/OfferCard';
import type { ServiceItem, Offer, ServiceProvider, AppointmentDto } from '@/services/api';
import { apiService } from '@/services/api';

interface RecentService {
  id: number;
  name: string;
  date: string;
  vehicle: string;
}

export default function HomePage() {
  const { user, isLoading: authLoading } = useAuth();
  const firstName = user?.fullName?.split(' ')[0] || 'there';

  const [featuredServices, setFeaturedServices] = useState<ServiceItem[]>([]);
  const [offers, setOffers] = useState<Offer[]>([]);
  const [lastServiceProvider, setLastServiceProvider] = useState<ServiceProvider | null>(null);
  const [recentServices, setRecentServices] = useState<RecentService[]>([]);
  const [appointmentsLoading, setAppointmentsLoading] = useState(true);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Wait for auth (including backend token exchange) to fully complete before
    // calling getUserAppointments(), so localStorage.getItem('user') is ready
    if (!authLoading) {
      loadHomeData();
    }
  }, [user, authLoading]);

  const loadHomeData = async () => {
    try {
      setLoading(true);

      // Load featured services (for popular services section)
      const servicesResponse = await apiService.getFeaturedServices();
      if (servicesResponse.success && servicesResponse.data) {
        setFeaturedServices(servicesResponse.data.slice(0, 4)); // Show top 4
      }

      // Load active offers
      const offersResponse = await apiService.getActiveOffers();
      if (offersResponse.success && offersResponse.data) {
        setOffers(offersResponse.data);
      }

      // Load service providers (use first one as last service location)
      const providersResponse = await apiService.getServiceProviders();
      if (providersResponse.success && providersResponse.data && providersResponse.data.length > 0) {
        setLastServiceProvider(providersResponse.data[0]);
      }

      // Load user's recent appointments
      if (user) {
        try {
          setAppointmentsLoading(true);
          const appointmentsResponse = await apiService.getUserAppointments();
          if (appointmentsResponse.success && appointmentsResponse.data) {
            const mappedServices: RecentService[] = (appointmentsResponse.data as AppointmentDto[])
              .sort((a, b) => {
                // Sort by creation time (newest booking first); fall back to appointment date
                const tA = a.createdAt ? new Date(a.createdAt).getTime() : new Date(a.appointmentDate).getTime();
                const tB = b.createdAt ? new Date(b.createdAt).getTime() : new Date(b.appointmentDate).getTime();
                return tB - tA;
              })
              .slice(0, 5)
              .map(app => {
                // Prefer linked vehicle entity; fall back to parsing notes ("Vehicle: Toyota Premio | ...")
                let vehicle = app.vehicleMake ? `${app.vehicleMake} ${app.vehicleModel}`.trim() : '';
                if (!vehicle && app.notes) {
                  const match = app.notes.match(/Vehicle:\s*([^|]+)/i);
                  if (match) vehicle = match[1].trim();
                }
                return {
                  id: app.id,
                  name: app.serviceType,
                  date: new Date(app.appointmentDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
                  vehicle: vehicle || '',
                };
              });
            setRecentServices(mappedServices);
          }
        } catch (err) {
          console.error('[HomePage] Failed to load appointments:', err);
        } finally {
          setAppointmentsLoading(false);
        }
      } else {
        setAppointmentsLoading(false);
      }
    } catch (error) {
      console.error('Error loading home page data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <AppLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#ff5d2e] mx-auto"></div>
            <p className="mt-4 text-black/70">Loading...</p>
          </div>
        </div>
      </AppLayout>
    );
  }

  return (
    <AppLayout>
      <div className="flex flex-col gap-6">
        {/* Greeting - Mobile only (desktop has header) */}
        <div className="lg:hidden">
          <h1 className="text-xl font-semibold text-black">
            Hello, {firstName}!
          </h1>
        </div>

        {/* Desktop greeting */}
        <div className="hidden lg:block">
          <h1 className="text-2xl font-semibold text-black">
            Welcome back, {firstName}!
          </h1>
          <p className="text-base text-black/70 mt-1">
            What service do you need today?
          </p>
        </div>

        {/* Search Bar */}
        <div className="bg-[#ffe7df] mx-auto w-full lg:w-1/2 border border-white rounded-2xl p-2 lg:p-3 flex items-center gap-2 lg:gap-3 cursor-pointer hover:bg-[#ffd9cc] transition-colors">
          <Search className="w-6 h-6" />
          <p className="flex-1 text-base font-semibold text-black">
            Search services
          </p>
          <div className="h-6 w-px bg-black/20 hidden sm:block" />
          <div className="bg-white rounded-lg px-2 lg:px-3 py-1 lg:py-2 flex items-center gap-1 lg:gap-2">
            <Calendar className="w-5 h-5 lg:w-6 lg:h-6" />
            <span className="text-sm font-semibold text-black">Schedule</span>
          </div>
        </div>

        {/* Last Service Location */}
        {lastServiceProvider && (
          <div className="bg-white border border-[#ffe7df] rounded-lg p-3 lg:p-4 flex items-center gap-3">
            <div className="bg-[#ffeae3] p-2 lg:p-3 rounded">
              <Warehouse className="w-6 h-6" />
            </div>
            <div className="flex-1 flex flex-col gap-1">
              <p className="text-xs font-semibold text-black/70">Last service location</p>
              <p className="text-base font-medium text-black">{lastServiceProvider.name}</p>
              {lastServiceProvider.city && (
                <p className="text-xs text-black/50">{lastServiceProvider.city}</p>
              )}
            </div>
            <ChevronRight className="w-5 h-5 text-black/50" />
          </div>
        )}

        {/* Main content grid - responsive */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left column - Popular Services */}
          <div className="lg:col-span-2 flex flex-col gap-4">
            {/* Popular Services Header */}
            <div className="flex items-center justify-between">
              <p className="text-base lg:text-lg font-semibold text-black">Popular Services</p>
              <Link to="/services" className="text-sm font-semibold text-[#ff5d2e] hover:underline">
                See all
              </Link>
            </div>

            {/* Popular Services Grid */}
            {featuredServices.length > 0 ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {featuredServices.map((service) => (
                  <ServiceCard
                    key={service.id}
                    id={service.id}
                    name={service.name}
                    imageUrl={service.imageUrl}
                  />
                ))}
              </div>
            ) : (
              <div className="bg-white rounded-lg p-8 text-center">
                <p className="text-black/50">No featured services available at the moment.</p>
                <Link to="/services" className="text-[#ff5d2e] hover:underline mt-2 inline-block">
                  Browse all services
                </Link>
              </div>
            )}

            {/* Recent Services */}
            <div className="flex flex-col gap-4 mt-4">
              <div className="flex items-center justify-between">
                <p className="text-lg font-semibold text-black">Recent Services</p>
                <Link to="/activity" className="text-sm font-semibold text-[#ff5d2e] hover:underline">
                  View all
                </Link>
              </div>
              <div className="bg-white rounded-lg shadow-sm overflow-hidden">
                {appointmentsLoading ? (
                  <div className="p-6 flex justify-center">
                    <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-[#ff5d2e]"></div>
                  </div>
                ) : recentServices.length > 0 ? (
                  recentServices.map((service, idx) => (
                    <div
                      key={service.id}
                      className={`p-4 flex items-center gap-4 ${
                        idx !== recentServices.length - 1 ? 'border-b border-black/10' : ''
                      }`}
                    >
                      <div className="w-10 h-10 bg-[#ffe7df] rounded-lg flex items-center justify-center">
                        <Clock className="w-5 h-5 text-[#ff5d2e]" />
                      </div>
                      <div className="flex-1">
                        <p className="font-medium text-black">{service.name}</p>
                        <p className="text-sm text-black/50">
                          {service.vehicle ? `${service.vehicle} • ` : ''}{service.date}
                        </p>
                      </div>
                      <button className="px-4 py-2 bg-[#ff5d2e] text-white rounded-lg text-sm font-medium hover:bg-[#e54d1e] transition-colors">
                        Rebook
                      </button>
                    </div>
                  ))
                ) : (
                  <div className="p-6 text-center">
                    <p className="text-black/50">No recent services found.</p>
                    <Link to="/services" className="text-[#ff5d2e] font-medium hover:underline mt-2 inline-block">
                      Book a service
                    </Link>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Right column - Offers & Quick Actions */}
          <div className="flex flex-col gap-4">
            {/* Quick Actions - Desktop only */}
            <div className="hidden lg:flex flex-col gap-3">
              <p className="text-lg font-semibold text-black">Quick Actions</p>
              <div className="flex flex-col gap-2">
                <Link
                  to="/services"
                  className="bg-[#ff5d2e] text-white rounded-lg p-4 flex items-center gap-3 hover:bg-[#e54d1e] transition-colors shadow-[0px_4px_8px_0px_rgba(255,93,46,0.3)]"
                >
                  <TrendingUp className="w-6 h-6" />
                  <span className="font-semibold">Book a Service</span>
                </Link>
                <Link
                  to="/activity"
                  className="bg-white border border-[#ffe7df] rounded-lg p-4 flex items-center gap-3 hover:bg-[#fff7f5] transition-colors"
                >
                  <Star className="w-6 h-6 text-[#ff5d2e]" />
                  <span className="font-medium text-black">View Appointments</span>
                </Link>
              </div>
            </div>

            {/* Special Offers */}
            <div className="flex flex-col gap-3">
              <p className="text-base lg:text-lg font-semibold text-black">Special Offers</p>
              {offers.length > 0 ? (
                <div className="flex lg:flex-col gap-3 overflow-x-auto lg:overflow-x-visible pb-2 lg:pb-0 -mx-4 px-4 lg:mx-0 lg:px-0">
                  {offers.map((offer) => (
                    <OfferCard
                      key={offer.id}
                      id={offer.id}
                      title={offer.title}
                      subtitle={offer.subtitle}
                      discountType={offer.discountType}
                      discountValue={offer.discountValue}
                      imageUrl={offer.imageUrl}
                    />
                  ))}
                </div>
              ) : (
                <div className="bg-white rounded-lg p-6 text-center">
                  <p className="text-black/50">No active offers at the moment.</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
