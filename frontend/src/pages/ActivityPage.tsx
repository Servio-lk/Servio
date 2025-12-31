import { Link } from 'react-router-dom';
import { SlidersHorizontal, RotateCw, Clock, ChevronRight, Calendar } from 'lucide-react';
import { AppLayout } from '@/components/layouts/AppLayout';

export default function ActivityPage() {
  const upcomingService = {
    id: 1,
    name: 'Lubricant Service',
    vehicle: 'Toyota Premio',
    date: 'Oct 21',
    time: '4:30 P.M.',
    price: 'LKR 4,000',
    status: 'confirmed',
  };

  const pastServices = [
    {
      id: 2,
      name: 'Waxing',
      date: 'Oct 21',
      time: '4:30 P.M.',
      price: 'LKR 4,000',
    },
    {
      id: 3,
      name: 'Exterior & Interior Detailing',
      date: 'Oct 21',
      time: '4:30 P.M.',
      price: 'LKR 4,000',
    },
    {
      id: 4,
      name: 'Engine Tune up',
      date: 'Oct 15',
      time: '2:00 P.M.',
      price: 'LKR 3,500',
    },
    {
      id: 5,
      name: 'Washing Package',
      date: 'Oct 10',
      time: '10:00 A.M.',
      price: 'LKR 1,200',
    },
  ];

  return (
    <AppLayout>
      <div className="flex flex-col gap-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h1 className="text-2xl lg:text-3xl font-semibold text-black">Activity</h1>
          <button className="p-2 hover:bg-[#ffe7df] rounded-lg transition-colors">
            <SlidersHorizontal className="w-5 h-5" />
          </button>
        </div>

        {/* Main content grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left column - Upcoming */}
          <div className="lg:col-span-2 flex flex-col gap-6">
            {/* Upcoming Service */}
            <div className="flex flex-col gap-4">
              <p className="text-lg font-semibold text-black">Upcoming Service</p>
              <div className="border border-[#ffe7df] rounded-2xl overflow-hidden bg-white">
                {/* Service Image */}
                <div className="h-[185px] lg:h-[220px] bg-gradient-to-br from-[#ffe7df] to-[#fff7f5] relative">
                  <div className="absolute inset-0 flex items-center justify-center">
                    <div className="w-16 h-16 bg-[#ff5d2e]/20 rounded-full flex items-center justify-center">
                      <Calendar className="w-8 h-8 text-[#ff5d2e]" />
                    </div>
                  </div>
                  <div className="absolute top-3 right-3 bg-green-500 text-white text-xs font-medium px-2 py-1 rounded-full">
                    Confirmed
                  </div>
                </div>
                
                {/* Service Details */}
                <div className="p-4 flex flex-col gap-3">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1">
                      <p className="text-lg font-semibold text-black">{upcomingService.name}</p>
                      <div className="flex items-center gap-1 text-sm font-medium mt-1">
                        <span className="text-black/50">For:</span>
                        <span className="text-black">{upcomingService.vehicle}</span>
                      </div>
                    </div>
                    <p className="text-lg font-semibold text-[#ff5d2e]">{upcomingService.price}</p>
                  </div>
                  
                  <div className="flex items-center gap-2 text-sm text-black/70">
                    <Clock className="w-4 h-4" />
                    <span>{upcomingService.date}</span>
                    <span>•</span>
                    <span>{upcomingService.time}</span>
                  </div>

                  {/* Actions */}
                  <div className="flex gap-3 mt-2">
                    <Link
                      to={`/confirmed/${upcomingService.id}`}
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
            </div>

            {/* Past Services */}
            <div className="flex flex-col gap-4">
              <div className="flex items-center justify-between">
                <p className="text-lg font-semibold text-black">Past Services</p>
                <button className="text-sm font-medium text-[#ff5d2e] hover:underline">
                  View all
                </button>
              </div>
              
              <div className="flex flex-col gap-2">
                {pastServices.map((service) => (
                  <div
                    key={service.id}
                    className="bg-white rounded-lg shadow-sm p-3 lg:p-4 flex items-center gap-3"
                  >
                    <div className="bg-[#ffe7df] p-2 lg:p-3 rounded">
                      <div className="w-10 h-10 rounded bg-[#ff5d2e]/20" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-base font-medium text-black truncate">{service.name}</p>
                      <div className="flex items-center gap-1 text-xs text-black/50">
                        <span>{service.date}</span>
                        <span>•</span>
                        <span>{service.time}</span>
                      </div>
                      <p className="text-sm font-medium text-black mt-1">{service.price}</p>
                    </div>
                    <button className="bg-[#ff5d2e] text-white py-2 px-3 lg:py-3 lg:px-4 rounded-lg shadow-[0px_4px_8px_0px_rgba(255,93,46,0.3)] flex items-center gap-2 hover:bg-[#e54d1e] transition-colors flex-shrink-0">
                      <RotateCw className="w-4 h-4" />
                      <span className="text-sm lg:text-base font-medium">Rebook</span>
                    </button>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Right column - Stats & Quick Actions (Desktop only) */}
          <div className="hidden lg:flex flex-col gap-6">
            {/* Stats */}
            <div className="bg-white rounded-lg shadow-sm p-4">
              <p className="text-lg font-semibold text-black mb-4">Service History</p>
              <div className="grid grid-cols-2 gap-4">
                <div className="text-center p-3 bg-[#fff7f5] rounded-lg">
                  <p className="text-2xl font-bold text-[#ff5d2e]">12</p>
                  <p className="text-sm text-black/50">Total Services</p>
                </div>
                <div className="text-center p-3 bg-[#fff7f5] rounded-lg">
                  <p className="text-2xl font-bold text-[#ff5d2e]">LKR 45K</p>
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
