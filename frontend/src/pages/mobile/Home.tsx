import { Search, Calendar, Warehouse, ChevronRight, Home as HomeIcon, List, FileText, User } from 'lucide-react';

export default function Home() {
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
      <div className="flex-1 flex flex-col gap-4 px-4 pb-4 overflow-y-auto">
        {/* Greeting */}
        <div className="flex items-center pb-2">
          <h1 className="text-xl font-semibold text-black text-center">
            Hello, Cham!
          </h1>
        </div>

        {/* Search Bar */}
        <div className="flex flex-col gap-4">
          <div className="bg-[#ffe7df] border border-white rounded-2xl p-2 flex items-center gap-2">
            <Search className="w-6 h-6" />
            <p className="flex-1 text-base font-semibold text-black">
              Search services
            </p>
            <div className="h-full w-px bg-black/20" />
            <div className="bg-white rounded-lg px-2 py-1 flex items-center gap-1">
              <Calendar className="w-6 h-6" />
              <span className="text-sm font-semibold text-black">Later</span>
            </div>
          </div>

          {/* Last Service */}
          <div className="bg-white border border-[#ffe7df] rounded-lg p-2 flex items-center gap-2">
            <div className="bg-[#ffeae3] p-2 rounded">
              <Warehouse className="w-6 h-6" />
            </div>
            <div className="flex-1 flex flex-col gap-1">
              <p className="text-xs font-semibold text-black/70">Last service</p>
              <p className="text-base font-medium text-black">Auto Miraj-Panadura</p>
            </div>
          </div>
        </div>

        {/* Suggestions Header */}
        <div className="flex items-center justify-between py-4">
          <p className="flex-1 text-base font-semibold text-black">Suggestions</p>
          <p className="text-sm font-semibold text-black text-center">See all</p>
        </div>

        {/* Suggestions List */}
        <div className="flex flex-col gap-2">
          {['Lube Services', 'Washing Packages', 'Exterior & Interior Detailing', 'Engine Tune ups'].map((service, i) => (
            <div key={i} className="bg-white rounded-lg shadow-sm px-2 py-1 flex items-center gap-3">
              <div className="w-12 h-12 rounded bg-gray-200" />
              <p className="flex-1 text-base font-medium text-black">{service}</p>
              <ChevronRight className="w-6 h-6" />
            </div>
          ))}
        </div>

        {/* Offers */}
        <div className="flex-1 flex gap-4 overflow-x-auto">
          {[1, 2].map((i) => (
            <div key={i} className="bg-white rounded-2xl shadow-md p-2 min-w-[328px] h-full flex flex-col justify-between overflow-hidden relative">
              <div className="flex items-center py-1">
                <div className="text-base font-medium text-black">
                  <p>Enjoy 10% off on</p>
                  <p>Mechanical Repair</p>
                </div>
              </div>
              <button className="bg-[#ff5d2e] text-white py-3 px-4 rounded-lg font-semibold text-base border border-white shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] w-[106px]">
                Book now
              </button>
              <div className="absolute right-[-7px] top-[-7px] w-56 h-56 opacity-20">
                <div className="w-full h-full rounded-full bg-orange-200" />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Tab Bar */}
      <div className="bg-white border-t border-black/20 flex items-center justify-center gap-4 px-6 py-0">
        <div className="flex flex-col items-center gap-2 py-2 px-2 w-[75.75px]">
          <HomeIcon className="w-6 h-6" />
          <p className="text-xs font-semibold text-black text-center">Home</p>
          <div className="w-4 h-0.5 bg-[#ff5d2e] rounded-lg" />
        </div>
        <div className="flex flex-col items-center gap-2 h-[59px] py-2 px-2 w-[75.75px]">
          <List className="w-6 h-6 text-black/50" />
          <p className="text-xs font-medium text-black/50 text-center">Services</p>
        </div>
        <div className="flex flex-col items-center gap-2 h-[59px] py-2 px-2 w-[75.75px]">
          <FileText className="w-6 h-6 text-black/50" />
          <p className="text-xs font-medium text-black/50 text-center">Activity</p>
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
