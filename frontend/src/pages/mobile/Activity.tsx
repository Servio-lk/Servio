import { SlidersHorizontal, RotateCw, Home, List, FileText, User } from 'lucide-react';

export default function Activity() {
  const upcomingService = {
    name: 'Lubricant Service',
    vehicle: 'Toyota Premio',
    date: 'Oct 21',
    time: '4:30 P.M.',
    price: 'LKR 4,000',
  };

  const pastServices = [
    {
      name: 'Waxing',
      date: 'Oct 21',
      time: '4:30 P.M.',
      price: 'LKR 4,000',
    },
    {
      name: 'Exterior & Interior Detailing',
      date: 'Oct 21',
      time: '4:30 P.M.',
      price: 'LKR 4,000',
    },
  ];

  return (
    <div className="flex flex-col h-screen w-full bg-gradient-to-b from-[#fff7f5] to-[#fbfbfb]">
      {/* Status Bar */}
      <div className="flex items-center justify-between px-4 pt-5 pb-5">
        <div className="font-semibold text-[17px]">9:41</div>
        <div className="flex items-center gap-2">
          <div className="w-5 h-3" />
          <div className="w-4 h-3" />
          <div className="w-7 h-3" />
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 flex flex-col gap-6 px-4 pb-4">
        {/* Header */}
        <div className="flex flex-col gap-1">
          <div className="flex items-center">
            <h1 className="text-[28px] font-semibold text-black">Activity</h1>
          </div>
        </div>

        {/* Upcoming Service */}
        <div className="flex flex-col gap-4">
          <p className="text-lg font-semibold text-black text-left">Upcoming service</p>
          <div className="border border-[#ffe7df] rounded-2xl p-2 flex flex-col gap-2">
            <div className="h-[185px] rounded-lg bg-gray-200 overflow-hidden">
              {/* Service Image */}
            </div>
            <p className="text-base font-semibold text-black">{upcomingService.name}</p>
            <div className="flex flex-col gap-1">
              <div className="flex items-center gap-1 text-sm font-medium">
                <p className="text-[#4b4b4b]">For:</p>
                <p className="flex-1 text-black">{upcomingService.vehicle}</p>
              </div>
              <div className="flex flex-col gap-1">
                <div className="flex items-center gap-1">
                  <p className="text-sm font-medium text-[#4b4b4b]">{upcomingService.date}</p>
                  <div className="w-1 h-1 rounded-full bg-[#4b4b4b]" />
                  <p className="text-sm font-medium text-[#4b4b4b]">{upcomingService.time}</p>
                </div>
                <p className="text-sm font-medium text-black">{upcomingService.price}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Past Services */}
        <div className="flex flex-col gap-4">
          <div className="flex items-center gap-2">
            <p className="flex-1 text-lg font-semibold text-black">Past</p>
            <SlidersHorizontal className="w-6 h-6" />
          </div>
          <div className="flex flex-col gap-2">
            {pastServices.map((service, idx) => (
              <div key={idx} className="bg-white rounded-lg shadow-sm p-1 flex items-center gap-3">
                <div className="bg-[#ffe7df] p-2 rounded">
                  <div className="w-10 h-10 rounded bg-gray-300" />
                </div>
                <div className="flex-1 flex flex-col gap-1 justify-center">
                  <p className="text-base font-medium text-black">{service.name}</p>
                  <div className="flex items-center gap-1">
                    <p className="text-xs font-medium text-[#4b4b4b]">{service.date}</p>
                    <div className="w-1 h-1 rounded-full bg-[#4b4b4b]" />
                    <p className="text-xs font-medium text-[#4b4b4b]">{service.time}</p>
                  </div>
                  <p className="text-xs font-medium text-black">{service.price}</p>
                </div>
                <button className="bg-[#ff5d2e] text-white py-3 px-3 rounded-lg border border-white shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] flex items-center gap-2">
                  <RotateCw className="w-4 h-4" />
                  <span className="text-base font-medium">Rebook</span>
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Tab Bar */}
      <div className="bg-white border-t border-black/20 flex items-center justify-center gap-4 px-6 py-0">
        <div className="flex flex-col items-center gap-2 h-[59px] py-2 px-2 w-[75.75px]">
          <Home className="w-6 h-6 text-black/50" />
          <p className="text-xs font-medium text-black/50 text-center">Home</p>
        </div>
        <div className="flex flex-col items-center gap-2 h-[59px] py-2 px-2 w-[75.75px]">
          <List className="w-6 h-6 text-black/50" />
          <p className="text-xs font-medium text-black/50 text-center">Services</p>
        </div>
        <div className="flex flex-col items-center gap-2 py-2 px-2 w-[75.75px]">
          <FileText className="w-6 h-6" />
          <p className="text-xs font-semibold text-black text-center">Activity</p>
          <div className="w-4 h-0.5 bg-[#ff5d2e] rounded-lg" />
        </div>
        <div className="flex flex-col items-center gap-2 h-[59px] py-2 px-2 w-[75.75px]">
          <User className="w-6 h-6 text-black/50" />
          <p className="text-xs font-medium text-black/50 text-center">Account</p>
        </div>
      </div>

      {/* Home Indicator */}
      <div className="bg-white h-[34px] flex items-end justify-center pb-2">
        <div className="w-36 h-[5px] bg-black rounded-full" />
      </div>
    </div>
  );
}
