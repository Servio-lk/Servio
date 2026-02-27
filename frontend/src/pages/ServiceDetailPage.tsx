import { useState } from 'react';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { ArrowLeft, Car, Check, Clock, Star, Shield } from 'lucide-react';
import { AppLayout } from '@/components/layouts/AppLayout';

export default function ServiceDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [selectedOil, setSelectedOil] = useState('standard');
  const [specialInstructions, setSpecialInstructions] = useState('');
  const [vehicleName, setVehicleName] = useState('');

  // Map service IDs to images in /public/service images/
  const serviceImages: { [key: string]: string } = {
    '1': '/service images/Washing Packages.jpg',
    '2': '/service images/Lubricant Service.jpg',
    '3': '/service images/Exterior Detailing.jpg',
    '4': '/service images/Mechanical Repair.jpg',
    '5': '/service images/Mulipoint Inspection Report.jpg',
    '6': '/service images/Mechanical Repair.jpg',
    '7': '/service images/Exterior Detailing.jpg',
    '8': '/service images/Exterior Detailing.jpg',
    '9': '/service images/Exterior Detailing.jpg',
    '10': '/service images/Electrical & Electronic.jpg',
    '11': '/service images/Exterior Detailing.jpg',
    '12': '/service images/Exterior Detailing.jpg',
    '13': '/service images/General Collision Repair.jpg',
    '14': '/service images/Mechanical Repair.jpg',
    '15': '/service images/Complete Paint.jpg',
    '16': '/service images/Mechanical Repair.jpg',
  };

  // Service catalog with all services
  const servicesCatalog: { [key: string]: any } = {
    '1': {
      id: '1',
      name: 'Washing Packages',
      basePrice: 500,
      description: 'Professional car washing service to keep your vehicle looking pristine. We use eco-friendly products and techniques to ensure the best results.',
      duration: '20-30 min',
      rating: 4.9,
      reviews: 432,
      features: [
        'Exterior wash',
        'Interior vacuuming',
        'Windscreen cleaning',
        'Door jamb cleaning',
      ],
    },
    '2': {
      id: '2',
      name: 'Lube Services',
      basePrice: 1500,
      description: 'Professional oil change with premium lubricants to protect your engine. Our certified technicians use only high-quality filters.',
      duration: '30-45 min',
      rating: 4.8,
      reviews: 234,
      features: [
        'Premium quality oil',
        'Oil filter replacement',
        'Multi-point inspection',
        'Fluid level check',
      ],
    },
    '3': {
      id: '3',
      name: 'Exterior & Interior Detailing',
      basePrice: 3000,
      description: 'Complete detailing service for your vehicle\'s exterior and interior. Our experts use professional-grade products for a showroom finish.',
      duration: '2-3 hours',
      rating: 4.9,
      reviews: 567,
      features: [
        'Full exterior detail',
        'Interior deep clean',
        'Leather conditioning',
        'Dashboard treatment',
      ],
    },
    '4': {
      id: '4',
      name: 'Engine Tune ups',
      basePrice: 2500,
      description: 'Keep your engine running at peak performance with our professional tune-up service. We inspect and adjust all critical components.',
      duration: '1-2 hours',
      rating: 4.7,
      reviews: 189,
      features: [
        'Spark plug check',
        'Air filter replacement',
        'Fuel injector cleaning',
        'Performance diagnostics',
      ],
    },
    '5': {
      id: '5',
      name: 'Inspection Reports',
      basePrice: 1000,
      description: 'Comprehensive vehicle inspection with detailed report. Perfect before buying or for regular maintenance tracking.',
      duration: '45-60 min',
      rating: 4.8,
      reviews: 145,
      features: [
        'Full system check',
        'Detailed report',
        'Photo documentation',
        'Recommendations included',
      ],
    },
    '6': {
      id: '6',
      name: 'Tyre Services',
      basePrice: 800,
      description: 'Professional tyre maintenance and replacement services. We offer balancing, rotation, and puncture repair.',
      duration: '30-45 min',
      rating: 4.9,
      reviews: 356,
      features: [
        'Tyre rotation',
        'Balancing',
        'Pressure check',
        'Puncture repair',
      ],
    },
    '7': {
      id: '7',
      name: 'Waxing',
      basePrice: 1200,
      description: 'Premium waxing service to protect and enhance your vehicle\'s paint finish. UV protection included.',
      duration: '45-60 min',
      rating: 4.8,
      reviews: 234,
      features: [
        'Clay bar treatment',
        'Premium wax application',
        'UV protection',
        '3-month warranty',
      ],
    },
    '8': {
      id: '8',
      name: 'Undercarriage Degreasing',
      basePrice: 2000,
      description: 'Deep cleaning of your vehicle\'s undercarriage to remove dirt, salt, and debris. Rust prevention treatment included.',
      duration: '1-1.5 hours',
      rating: 4.7,
      reviews: 123,
      features: [
        'High-pressure wash',
        'Rust prevention',
        'Anti-corrosion spray',
        'Oil-based sealant',
      ],
    },
    '9': {
      id: '9',
      name: 'Windscreen Treatments',
      basePrice: 1500,
      description: 'Professional windscreen treatment for water resistance and enhanced visibility. Protects against weather and UV damage.',
      duration: '20-30 min',
      rating: 4.9,
      reviews: 201,
      features: [
        'Water repellent coating',
        'UV protection',
        'Scratch resistance',
        '6-month durability',
      ],
    },
    '10': {
      id: '10',
      name: 'Battery Services',
      basePrice: 500,
      description: 'Battery testing, charging, and replacement services. Reliable power for your vehicle guaranteed.',
      duration: '15-20 min',
      rating: 4.8,
      reviews: 278,
      features: [
        'Battery testing',
        'Terminal cleaning',
        'Safe disposal',
        'Installation included',
      ],
    },
    '11': {
      id: '11',
      name: 'Nano Coating Packages',
      basePrice: 15000,
      description: 'Premium nano coating for ultimate paint protection. Provides long-lasting gloss and protection against environmental elements.',
      duration: '3-4 hours',
      rating: 4.9,
      reviews: 89,
      features: [
        'Surface preparation',
        'Nano coating application',
        'Curing process',
        '2-year warranty',
      ],
    },
    '12': {
      id: '12',
      name: 'Nano Coating Treatments',
      basePrice: 8000,
      description: 'Professional nano treatment for enhanced protection and stunning gloss. Quick application with long-lasting results.',
      duration: '2-3 hours',
      rating: 4.8,
      reviews: 67,
      features: [
        'Paint protection',
        'Hydrophobic properties',
        'High gloss finish',
        '1-year warranty',
      ],
    },
    '13': {
      id: '13',
      name: 'Insurance Claims',
      basePrice: 0,
      description: 'Expert handling of insurance claims for collision damage. We work directly with insurance companies for hassle-free service.',
      duration: 'Varies',
      rating: 4.7,
      reviews: 156,
      features: [
        'Claim assessment',
        'Documentation support',
        'Direct insurance billing',
        'Quality repairs',
      ],
    },
    '14': {
      id: '14',
      name: 'Wheel Alignment',
      basePrice: 2000,
      description: 'Professional wheel alignment service to ensure proper handling and tire wear. State-of-the-art alignment equipment used.',
      duration: '45-60 min',
      rating: 4.8,
      reviews: 234,
      features: [
        'Computer alignment',
        'All wheels checked',
        'Performance verification',
        'Warranty included',
      ],
    },
    '15': {
      id: '15',
      name: 'Full Paints',
      basePrice: 50000,
      description: 'Complete vehicle repaint service with premium quality paint. Perfect for collision damage or aesthetic upgrades.',
      duration: '2-3 days',
      rating: 4.9,
      reviews: 112,
      features: [
        'Professional prep',
        'Multi-coat application',
        'Premium paint',
        '2-year warranty',
      ],
    },
    '16': {
      id: '16',
      name: 'Part Replacements',
      basePrice: 0,
      description: 'Expert part replacement for all vehicle components. We use OEM and quality aftermarket parts.',
      duration: 'Varies',
      rating: 4.8,
      reviews: 189,
      features: [
        'Quality parts',
        'Professional installation',
        'Warranty coverage',
        'Competitive pricing',
      ],
    },
  };

  const service = servicesCatalog[id || '1'] || servicesCatalog['1'];

  const oilOptions = [
    { id: 'standard', name: 'Standard/Conventional Oil', price: 4000, description: 'Basic protection for everyday driving' },
    { id: 'synthetic-blend', name: 'Synthetic Blend Oil', price: 5500, description: 'Enhanced protection and performance' },
    { id: 'full-synthetic', name: 'Full Synthetic Oil', price: 7000, description: 'Maximum protection for high-performance engines' },
  ];

  const selectedOilOption = oilOptions.find(o => o.id === selectedOil);
  const totalPrice = service.basePrice + (selectedOilOption?.price || 0);

  return (
    <AppLayout showNav={false}>
      <div className="min-h-screen flex flex-col">
        {/* Header with back button */}
        <div className="sticky top-0 bg-gradient-to-b from-[#fff7f5] to-transparent z-10 pb-4">
          <div className="flex items-center gap-4 px-4 py-3 lg:px-0">
            <button
              onClick={() => navigate(-1)}
              className="w-10 h-10 bg-white rounded-lg flex items-center justify-center shadow-sm hover:shadow-md transition-shadow"
            >
              <ArrowLeft className="w-5 h-5" />
            </button>
            <span className="text-lg font-semibold text-black lg:hidden">Service Details</span>
          </div>
        </div>

        {/* Main content */}
        <div className="flex-1 max-w-5xl mx-auto w-full px-4 lg:px-6 pb-32 lg:pb-8">
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-6 lg:gap-8">
            {/* Left column - Service details */}
            <div className="lg:col-span-3 flex flex-col gap-6">
              {/* Service Image */}
              <div className="w-full aspect-[16/9] lg:aspect-[16/7] bg-gradient-to-br from-[#ffe7df] to-[#fff7f5] rounded-2xl overflow-hidden relative">
                <img
                  src={serviceImages[id || '1'] || serviceImages['1']}
                  alt={service.name}
                  className="w-full h-full object-cover"
                />
              </div>

              {/* Service Info */}
              <div className="flex flex-col gap-4">
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <h1 className="text-xl lg:text-2xl font-semibold text-black">{service.name}</h1>
                    <p className="text-lg font-semibold text-[#ff5d2e] mt-1">
                      from LKR {service.basePrice.toLocaleString()}
                    </p>
                  </div>
                  <div className="flex items-center gap-1 bg-[#fff7f5] px-3 py-2 rounded-lg">
                    <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                    <span className="font-semibold text-black">{service.rating}</span>
                    <span className="text-sm text-black/50">({service.reviews})</span>
                  </div>
                </div>

                <div className="flex items-center gap-4 text-sm text-black/70">
                  <div className="flex items-center gap-1">
                    <Clock className="w-4 h-4" />
                    <span>{service.duration}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Shield className="w-4 h-4" />
                    <span>Warranty included</span>
                  </div>
                </div>

                <p className="text-base text-black/70 leading-relaxed">
                  {service.description}
                </p>

                <button className="text-[#ff5d2e] text-sm font-medium hover:underline self-start">
                  Show more
                </button>
              </div>

              {/* Features - Desktop */}
              <div className="hidden lg:block">
                <h3 className="text-lg font-semibold text-black mb-3">What's Included</h3>
                <div className="grid grid-cols-2 gap-3">
                  {service.features.map((feature: string, idx: number) => (
                    <div key={idx} className="flex items-center gap-2 p-3 bg-white rounded-lg">
                      <Check className="w-5 h-5 text-green-500" />
                      <span className="text-sm font-medium text-black">{feature}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Divider */}
              <div className="h-px bg-black/10" />

              {/* Oil Selection - Only for Lube Services (ID 2) */}
              {id === '2' && (
                <div className="flex flex-col gap-4">
                  <h3 className="text-base lg:text-lg font-semibold text-black">
                    Pricing and Oil Selection
                  </h3>
                  <div className="flex flex-col gap-2">
                    {oilOptions.map((option) => (
                      <button
                        key={option.id}
                        onClick={() => setSelectedOil(option.id)}
                        className={`w-full text-left p-4 rounded-lg transition-all ${
                          selectedOil === option.id
                            ? 'bg-[#ffe7df] border-2 border-[#ff5d2e]'
                            : 'bg-white border border-black/10 hover:border-[#ff5d2e]/50'
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                            selectedOil === option.id ? 'border-[#ff5d2e]' : 'border-black/30'
                          }`}>
                            {selectedOil === option.id && (
                              <div className="w-3 h-3 rounded-full bg-[#ff5d2e]" />
                            )}
                          </div>
                          <div className="flex-1">
                            <p className="font-medium text-black">{option.name}</p>
                            <p className="text-sm text-black/50 hidden lg:block">{option.description}</p>
                          </div>
                          <p className="font-semibold text-black">+LKR {option.price.toLocaleString()}</p>
                        </div>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Divider */}
              <div className="h-px bg-black/10" />

              {/* Special Instructions */}
              <div className="flex flex-col gap-4">
                <h3 className="text-base lg:text-lg font-semibold text-black">
                  Special Instructions
                </h3>
                <textarea
                  placeholder="Add any special requests or notes for the service team..."
                  value={specialInstructions}
                  onChange={(e) => setSpecialInstructions(e.target.value)}
                  className="w-full h-28 p-4 bg-white rounded-lg border border-black/10 text-sm text-black resize-none outline-none focus:border-[#ff5d2e] transition-colors placeholder:text-black/40"
                />
              </div>
            </div>

            {/* Right column - Booking summary (Desktop) */}
            <div className="hidden lg:block lg:col-span-2">
              <div className="sticky top-24 bg-white rounded-2xl shadow-lg p-6 flex flex-col gap-6">
                <h3 className="text-lg font-semibold text-black">Booking Summary</h3>
                
                {/* Price breakdown */}
                <div className="flex flex-col gap-3">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-black/70">Service Fee</span>
                    <span className="font-medium text-black">LKR {service.basePrice.toLocaleString()}</span>
                  </div>
                  {id === '2' && selectedOilOption && (
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-black/70">{selectedOilOption.name}</span>
                      <span className="font-medium text-black">LKR {selectedOilOption.price.toLocaleString()}</span>
                    </div>
                  )}
                  <div className="h-px bg-black/10" />
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-black">Total</span>
                    <span className="text-xl font-bold text-[#ff5d2e]">LKR {totalPrice.toLocaleString()}</span>
                  </div>
                </div>

                {/* Vehicle input */}
                <div className="flex flex-col gap-2">
                  <label className="text-sm font-medium text-black/70">Your Vehicle</label>
                  <div className="w-full p-3 bg-[#fff7f5] rounded-lg flex items-center gap-3 focus-within:ring-2 focus-within:ring-[#ff5d2e]/30 transition-all">
                    <Car className="w-5 h-5 text-[#ff5d2e] flex-shrink-0" />
                    <input
                      type="text"
                      value={vehicleName}
                      onChange={e => setVehicleName(e.target.value)}
                      placeholder="e.g. Toyota Premio 2019"
                      className="flex-1 text-sm font-medium text-black bg-transparent outline-none placeholder:text-black/40"
                    />
                  </div>
                </div>

                {/* Book button */}
                <Link
                  to={`/book/${service.id}?oil=${selectedOil}&notes=${encodeURIComponent(specialInstructions)}&vehicle=${encodeURIComponent(vehicleName)}`}
                  className="w-full bg-[#ff5d2e] text-white py-4 rounded-xl font-semibold text-center shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] hover:bg-[#e54d1e] transition-colors"
                >
                  Book Now • LKR {totalPrice.toLocaleString()}
                </Link>

                <p className="text-xs text-black/50 text-center">
                  You won't be charged until after your service
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Mobile bottom CTA */}
        <div className="lg:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-black/10 p-4 safe-area-pb flex flex-col gap-3">
          <div className="flex items-center gap-3 px-1 py-2 bg-[#fff7f5] rounded-xl focus-within:ring-2 focus-within:ring-[#ff5d2e]/30 transition-all">
            <Car className="w-5 h-5 text-[#ff5d2e] ml-3 flex-shrink-0" />
            <input
              type="text"
              value={vehicleName}
              onChange={e => setVehicleName(e.target.value)}
              placeholder="Enter vehicle name (e.g. Toyota Premio)"
              className="flex-1 text-sm font-medium text-black bg-transparent outline-none placeholder:text-black/40 pr-3"
            />
          </div>
          <Link
            to={`/book/${service.id}?oil=${selectedOil}&notes=${encodeURIComponent(specialInstructions)}&vehicle=${encodeURIComponent(vehicleName)}`}
            className="w-full bg-[#ff5d2e] text-white py-4 rounded-xl font-semibold flex items-center justify-center gap-2 shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)]"
          >
            <span>Book now</span>
            <span className="w-1 h-1 rounded-full bg-white" />
            <span>LKR {totalPrice.toLocaleString()}</span>
          </Link>
        </div>
      </div>
    </AppLayout>
  );
}
