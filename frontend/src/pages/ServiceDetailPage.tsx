import { useState } from 'react';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { ArrowLeft, Check, Clock, Star, Shield, ChevronRight } from 'lucide-react';
import { AppLayout } from '@/components/layouts/AppLayout';

export default function ServiceDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [selectedOil, setSelectedOil] = useState('standard');
  const [specialInstructions, setSpecialInstructions] = useState('');

  const service = {
    id: id,
    name: 'Lubricant Service',
    basePrice: 1500,
    description: 'Protect your engine and maintain peak performance with our professional oil change service. We only use high-quality lubricants and filters, ensuring your vehicle runs smoothly and efficiently.',
    duration: '30-45 min',
    rating: 4.8,
    reviews: 234,
    features: [
      'Premium quality oil',
      'Oil filter replacement',
      'Multi-point inspection',
      'Fluid level check',
    ],
  };

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
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="w-20 h-20 bg-[#ff5d2e]/20 rounded-full flex items-center justify-center">
                    <div className="w-12 h-12 bg-[#ff5d2e]/30 rounded-full" />
                  </div>
                </div>
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
                  {service.features.map((feature, idx) => (
                    <div key={idx} className="flex items-center gap-2 p-3 bg-white rounded-lg">
                      <Check className="w-5 h-5 text-green-500" />
                      <span className="text-sm font-medium text-black">{feature}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Divider */}
              <div className="h-px bg-black/10" />

              {/* Oil Selection */}
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
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-black/70">{selectedOilOption?.name}</span>
                    <span className="font-medium text-black">LKR {selectedOilOption?.price.toLocaleString()}</span>
                  </div>
                  <div className="h-px bg-black/10" />
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-black">Total</span>
                    <span className="text-xl font-bold text-[#ff5d2e]">LKR {totalPrice.toLocaleString()}</span>
                  </div>
                </div>

                {/* Vehicle selector */}
                <div className="flex flex-col gap-2">
                  <label className="text-sm font-medium text-black/70">Select Vehicle</label>
                  <button className="w-full p-3 bg-[#fff7f5] rounded-lg flex items-center justify-between hover:bg-[#ffe7df] transition-colors">
                    <span className="font-medium text-black">Toyota Premio</span>
                    <ChevronRight className="w-5 h-5 text-black/50" />
                  </button>
                </div>

                {/* Book button */}
                <Link
                  to={`/book/${service.id}?oil=${selectedOil}&notes=${encodeURIComponent(specialInstructions)}`}
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
        <div className="lg:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-black/10 p-4 safe-area-pb">
          <Link
            to={`/book/${service.id}?oil=${selectedOil}&notes=${encodeURIComponent(specialInstructions)}`}
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
