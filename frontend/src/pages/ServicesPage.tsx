import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Search, ChevronRight, Filter, Grid, List as ListIcon } from 'lucide-react';
import { AppLayout } from '@/components/layouts/AppLayout';

export default function ServicesPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [viewMode, setViewMode] = useState<'list' | 'grid'>('list');

  // Icon mapping - maps service names to icon filenames
  const serviceIcons: Record<string, string> = {
    'Washing Packages': '/service icons/Washing Packages.png',
    'Lube Services': '/service icons/Lube Services.png',
    'Exterior & Interior Detailing': '/service icons/Exterior & Interior Detailing.png',
    'Engine Tune ups': '/service icons/Engine Tune ups.png',
    'Inspection Reports': '/service icons/Inspection Reports.png',
    'Tyre Services': '/service icons/Tyre Services.png',
    'Waxing': '/service icons/Waxing.png',
    'Undercarriage Degreasing': '/service icons/Undercarriage Degreasing.png',
    'Windscreen Treatments': '/service icons/Windscreen Treatments.png',
    'Battery Services': '/service icons/Battery Services.png',
    'Packages': '/service icons/Nano Coating Packages.png',
    'Treatments': '/service icons/Nano Coating Treatments.png',
    'Insurance Claims': '/service icons/Insurance Claims.png',
    'Wheel Alignment': '/service icons/Wheel Alignment.png',
    'Full Paints': '/service icons/Full Paints.png',
    'Part Replacements': '/service icons/Part Replacements.png',
  };

  const serviceCategories = [
    {
      id: 'periodic',
      title: 'Periodic Maintenance',
      description: 'Regular maintenance to keep your vehicle running smoothly',
      services: [
        { id: 1, name: 'Washing Packages', price: 'from LKR 500' },
        { id: 2, name: 'Lube Services', price: 'from LKR 1,500' },
        { id: 3, name: 'Exterior & Interior Detailing', price: 'from LKR 3,000' },
        { id: 4, name: 'Engine Tune ups', price: 'from LKR 2,500' },
        { id: 5, name: 'Inspection Reports', price: 'from LKR 1,000' },
        { id: 6, name: 'Tyre Services', price: 'from LKR 800' },
        { id: 7, name: 'Waxing', price: 'from LKR 1,200' },
        { id: 8, name: 'Undercarriage Degreasing', price: 'from LKR 2,000' },
        { id: 9, name: 'Windscreen Treatments', price: 'from LKR 1,500' },
        { id: 10, name: 'Battery Services', price: 'from LKR 500' },
      ],
    },
    {
      id: 'nano',
      title: 'Nano Coating',
      description: 'Premium protection for your vehicle\'s exterior',
      services: [
        { id: 11, name: 'Packages', price: 'from LKR 15,000' },
        { id: 12, name: 'Treatments', price: 'from LKR 8,000' },
      ],
    },
    {
      id: 'collision',
      title: 'Collision Repairs',
      description: 'Expert repair services for vehicle damage',
      services: [
        { id: 13, name: 'Insurance Claims', price: 'Quote required' },
        { id: 14, name: 'Wheel Alignment', price: 'from LKR 2,000' },
        { id: 15, name: 'Full Paints', price: 'from LKR 50,000' },
        { id: 16, name: 'Part Replacements', price: 'Quote required' },
      ],
    },
  ];

  const filteredCategories = serviceCategories.map((category) => ({
    ...category,
    services: category.services.filter((service) =>
      service.name.toLowerCase().includes(searchQuery.toLowerCase())
    ),
  })).filter((category) => category.services.length > 0);

  return (
    <AppLayout>
      <div className="flex flex-col gap-4 lg:gap-6">
        {/* Mobile Header - Figma Design */}
        <div className="lg:hidden flex flex-col gap-1">
          {/* Mobile Search */}
          <div className="bg-[#ffe7df] border border-white rounded-2xl p-2 flex items-center gap-2">
            <Search className="w-6 h-6 text-black/80" />
            <input
              type="text"
              placeholder="Search services"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="flex-1 bg-transparent text-base font-semibold text-black/80 outline-none placeholder:text-black/80"
            />
          </div>
        </div>

        {/* Desktop Header */}
        <div className="hidden lg:flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl lg:text-3xl font-semibold text-black">Services</h1>
            {/* View toggle - Desktop only */}
            <div className="flex items-center gap-2 bg-white rounded-lg p-1 border border-black/10">
              <button
                onClick={() => setViewMode('list')}
                className={`p-2 rounded ${viewMode === 'list' ? 'bg-[#ffe7df] text-[#ff5d2e]' : 'text-black/50 hover:text-black'}`}
              >
                <ListIcon className="w-5 h-5" />
              </button>
              <button
                onClick={() => setViewMode('grid')}
                className={`p-2 rounded ${viewMode === 'grid' ? 'bg-[#ffe7df] text-[#ff5d2e]' : 'text-black/50 hover:text-black'}`}
              >
                <Grid className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* Desktop Search and Filter */}
          <div className="flex gap-3">
            <div className="flex-1 bg-[#ffe7df] border border-white rounded-2xl p-3 flex items-center gap-2">
              <Search className="w-6 h-6" />
              <input
                type="text"
                placeholder="Search services"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="flex-1 bg-transparent text-base font-medium text-black outline-none placeholder:text-black/50"
              />
            </div>
            <button className="bg-white border border-[#ffe7df] rounded-2xl p-3 hover:bg-[#fff7f5] transition-colors">
              <Filter className="w-6 h-6" />
            </button>
          </div>
        </div>

        {/* Services List - Mobile uses Figma design, Desktop uses grid/list */}
        <div className="flex flex-col gap-4 lg:gap-6">
          {filteredCategories.map((category) => (
            <div key={category.id} className="flex flex-col gap-3 lg:gap-4">
              {/* Category Header */}
              <h2 className="text-base lg:text-lg font-semibold text-black text-left">
                {category.title}
              </h2>

              {/* Mobile Services List */}
              <div className="lg:hidden flex flex-col gap-2">
                {category.services.map((service) => (
                  <Link
                    key={service.id}
                    to={`/services/${service.id}`}
                    className="bg-white min-h-[56px] relative rounded-[8px] shadow-[0px_2px_8px_0px_rgba(0,0,0,0.04)] shrink-0 w-full"
                  >
                    <div className="flex flex-row items-center min-h-[inherit] size-full">
                      <div className="content-stretch flex gap-[12px] items-center min-h-[inherit] px-[8px] py-[4px] relative w-full">
                        <div className="relative shrink-0 size-[40px]">
                          {serviceIcons[service.name] ? (
                            <img
                              alt={service.name}
                              src={serviceIcons[service.name]}
                              className="absolute inset-0 max-w-none object-cover pointer-events-none size-full"
                            />
                          ) : (
                            <div className="absolute inset-0 rounded bg-[#ffe7df] flex items-center justify-center">
                              <div className="w-6 h-6 rounded bg-[#ff5d2e]/20" />
                            </div>
                          )}
                        </div>
                        <p className="flex-[1_0_0] font-medium leading-[normal] w-full min-h-px min-w-px relative text-[16px] text-black text-left">
                          {service.name}
                        </p>
                        <ChevronRight className="w-6 h-6 text-black/50 shrink-0" />
                      </div>
                    </div>
                  </Link>
                ))}
              </div>

              {/* Desktop Services - Grid/List View */}
              <div className={
                viewMode === 'grid' 
                  ? 'hidden lg:grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3'
                  : 'hidden lg:flex flex-col gap-2'
              }>
                {category.services.map((service) => (
                  <Link
                    key={service.id}
                    to={`/services/${service.id}`}
                    className={`bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow ${
                      viewMode === 'grid' 
                        ? 'p-4 flex flex-col gap-3'
                        : 'px-4 py-3 flex items-center gap-3'
                    }`}
                  >
                    <div className={`${viewMode === 'grid' ? 'w-12 h-12' : 'w-10 h-10'} rounded bg-[#ffe7df] flex items-center justify-center shrink-0 p-2`}>
                      {serviceIcons[service.name] ? (
                        <img
                          src={serviceIcons[service.name]}
                          alt={service.name}
                          className="w-full h-full object-contain"
                        />
                      ) : (
                        <div className="w-6 h-6 rounded bg-[#ff5d2e]/20" />
                      )}
                    </div>
                    <div className={`flex-1 ${viewMode === 'grid' ? '' : 'min-w-0'}`}>
                      <p className="text-base font-medium text-black truncate">{service.name}</p>
                      <p className="text-sm text-black/50">{service.price}</p>
                    </div>
                    {viewMode === 'list' && <ChevronRight className="w-5 h-5 text-black/50 shrink-0" />}
                    {viewMode === 'grid' && (
                      <button className="w-full bg-[#ff5d2e] text-white py-2 rounded-lg text-sm font-medium hover:bg-[#e54d1e] transition-colors">
                        Book Now
                      </button>
                    )}
                  </Link>
                ))}
              </div>
            </div>
          ))}
        </div>

        {/* No results */}
        {filteredCategories.length === 0 && (
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <Search className="w-12 h-12 text-black/20 mb-4" />
            <p className="text-lg font-medium text-black">No services found</p>
            <p className="text-sm text-black/50">Try adjusting your search terms</p>
          </div>
        )}
      </div>
    </AppLayout>
  );
}
