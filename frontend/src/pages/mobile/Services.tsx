import { Search, ChevronRight, Home, List, FileText, User } from 'lucide-react';

export default function Services() {
  const serviceCategories = [
    {
      title: 'Periodic Maintenance',
      services: [
        'Washing Packages',
        'Lube Services',
        'Exterior & Interior Detailing',
        'Engine Tune ups',
        'Inspection Reports',
        'Tyre Services',
        'Waxing',
        'Undercarriage Degreasing',
        'Windscreen Treatments',
        'Battery Services',
      ],
    },
    {
      title: 'Nano Coating',
      services: ['Packages', 'Treatments'],
    },
    {
      title: 'Collision Repairs',
      services: ['Insurance Claims', 'Wheel Alignment', 'Full Paints', 'Part Replacements'],
    },
  ];

  return (
    <div className="flex flex-col h-screen w-full bg-[#fff7f5]">
      {/* Status Bar */}
      <div className="flex items-center justify-between px-4 pt-5 pb-5">
        <div className="font-semibold text-[17px]">9:41</div>
        <div className="flex items-center gap-2">
          <div className="w-5 h-3" />
          <div className="w-4 h-3" />
          <div className="w-7 h-3" />
        </div>
      </div>

      {/* Header */}
      <div className="flex flex-col gap-1 px-4 pb-2">
        <div className="flex items-center pb-2">
          <h1 className="text-[28px] font-semibold text-black">Services</h1>
        </div>
        <div className="bg-[#ffe7df] border border-white rounded-2xl h-12 p-2 flex items-center gap-2">
          <Search className="w-6 h-6" />
          <p className="flex-1 text-base font-semibold text-black/80">Search services</p>
        </div>
      </div>

      {/* Services List */}
      <div className="flex-1 flex flex-col gap-4 px-4 py-2 overflow-y-auto">
        {serviceCategories.map((category, idx) => (
          <div key={idx} className="flex flex-col gap-3 overflow-hidden py-3">
            <p className="text-base font-semibold text-black">{category.title}</p>
            <div className="flex flex-col gap-2">
              {category.services.map((service, i) => (
                <div
                  key={i}
                  className="bg-white rounded-lg shadow-sm min-h-[56px] px-2 py-1 flex items-center gap-3"
                >
                  <div className="w-10 h-10 rounded bg-gray-200" />
                  <p className="flex-1 text-base font-medium text-black">{service}</p>
                  <ChevronRight className="w-6 h-6" />
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* Tab Bar */}
      <div className="bg-white border-t border-black/20 flex items-center justify-center gap-4 px-6 py-0">
        <div className="flex flex-col items-center gap-2 h-[59px] py-2 px-2 w-[75.75px]">
          <Home className="w-6 h-6 text-black/50" />
          <p className="text-xs font-medium text-black/50 text-center">Home</p>
        </div>
        <div className="flex flex-col items-center gap-2 py-2 px-2 w-[75.75px]">
          <List className="w-6 h-6" />
          <p className="text-xs font-semibold text-black text-center">Services</p>
          <div className="w-4 h-0.5 bg-[#ff5d2e] rounded-lg" />
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
