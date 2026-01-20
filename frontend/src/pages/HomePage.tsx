import { Link } from 'react-router-dom';
import { Search, Calendar, Warehouse, ChevronRight, Clock, Star, TrendingUp } from 'lucide-react';
import { AppLayout } from '@/components/layouts/AppLayout';
import { useAuth } from '@/contexts/AuthContext';

export default function HomePage() {
  const { user } = useAuth();
  const firstName = user?.fullName?.split(' ')[0] || 'there';

  const suggestions = [
    { id: 1, name: 'Lube Services', image: null },
    { id: 2, name: 'Washing Packages', image: null },
    { id: 3, name: 'Exterior & Interior Detailing', image: null },
    { id: 4, name: 'Engine Tune ups', image: null },
  ];

  const offers = [
    { id: 1, title: 'Enjoy 10% off on', subtitle: 'Mechanical Repair', discount: '10%' },
    { id: 2, title: 'Free inspection with', subtitle: 'Any Lube Service', discount: 'FREE' },
  ];

  const recentServices = [
    { id: 1, name: 'Lubricant Service', date: 'Oct 15, 2025', vehicle: 'Toyota Premio' },
    { id: 2, name: 'Washing Package', date: 'Sep 28, 2025', vehicle: 'Toyota Premio' },
  ];

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

        {/* Last Service */}
        <div className="bg-white border border-[#ffe7df] rounded-lg p-3 lg:p-4 flex items-center gap-3">
          <div className="bg-[#ffeae3] p-2 lg:p-3 rounded">
            <Warehouse className="w-6 h-6" />
          </div>
          <div className="flex-1 flex flex-col gap-1">
            <p className="text-xs font-semibold text-black/70">Last service location</p>
            <p className="text-base font-medium text-black">Auto Miraj-Panadura</p>
          </div>
          <ChevronRight className="w-5 h-5 text-black/50" />
        </div>

        {/* Main content grid - responsive */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left column - Suggestions */}
          <div className="lg:col-span-2 flex flex-col gap-4">
            {/* Suggestions Header */}
            <div className="flex items-center justify-between">
              <p className="text-base lg:text-lg font-semibold text-black">Popular Services</p>
              <Link to="/services" className="text-sm font-semibold text-[#ff5d2e] hover:underline">
                See all
              </Link>
            </div>

            {/* Suggestions Grid - responsive */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {suggestions.map((service) => (
                <Link
                  key={service.id}
                  to={`/services/${service.id}`}
                  className="bg-white rounded-lg shadow-sm p-3 flex items-center gap-3 hover:shadow-md transition-shadow"
                >
                  <div className="w-12 h-12 rounded bg-[#ffe7df] flex items-center justify-center">
                    <Warehouse className="w-6 h-6 text-[#ff5d2e]" />
                  </div>
                  <p className="flex-1 text-base font-medium text-black">{service.name}</p>
                  <ChevronRight className="w-5 h-5 text-black/50" />
                </Link>
              ))}
            </div>

            {/* Recent Services - Desktop only */}
            <div className="hidden lg:flex flex-col gap-4 mt-4">
              <div className="flex items-center justify-between">
                <p className="text-lg font-semibold text-black">Recent Services</p>
                <Link to="/activity" className="text-sm font-semibold text-[#ff5d2e] hover:underline">
                  View all
                </Link>
              </div>
              <div className="bg-white rounded-lg shadow-sm overflow-hidden">
                {recentServices.map((service, idx) => (
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
                      <p className="text-sm text-black/50">{service.vehicle} • {service.date}</p>
                    </div>
                    <button className="px-4 py-2 bg-[#ff5d2e] text-white rounded-lg text-sm font-medium hover:bg-[#e54d1e] transition-colors">
                      Rebook
                    </button>
                  </div>
                ))}
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

            {/* Offers */}
            <div className="flex flex-col gap-3">
              <p className="text-base lg:text-lg font-semibold text-black">Special Offers</p>
              <div className="flex lg:flex-col gap-3 overflow-x-auto lg:overflow-x-visible pb-2 lg:pb-0 -mx-4 px-4 lg:mx-0 lg:px-0">
                {offers.map((offer) => (
                  <div
                    key={offer.id}
                    className="bg-white rounded-2xl shadow-md p-4 min-w-[280px] lg:min-w-0 flex flex-col gap-3 relative overflow-hidden"
                  >
                    <div className="flex items-center gap-2">
                      <span className="bg-[#ff5d2e] text-white text-xs font-bold px-2 py-1 rounded">
                        {offer.discount}
                      </span>
                    </div>
                    <div className="text-base font-medium text-black">
                      <p>{offer.title}</p>
                      <p className="font-semibold">{offer.subtitle}</p>
                    </div>
                    <button className="bg-[#ff5d2e] text-white py-2 px-4 rounded-lg font-semibold text-sm shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] hover:bg-[#e54d1e] transition-colors self-start">
                      Book now
                    </button>
                    <div className="absolute right-[-20px] top-[-20px] w-32 h-32 opacity-10">
                      <div className="w-full h-full rounded-full bg-[#ff5d2e]" />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
