import { useEffect, useMemo, useState } from 'react';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { ArrowLeft, Check, Clock, Loader2, Star, Shield, Car } from 'lucide-react';
import { AppLayout } from '@/components/layouts/AppLayout';
import { VehicleSelector } from '@/components/VehicleSelector';
import { apiService } from '@/services/api';

type ServiceOption = {
  id: number;
  name: string;
  description?: string | null;
  priceAdjustment?: number | null;
  isDefault?: boolean | null;
};

type ServiceDetail = {
  id: number;
  name: string;
  description?: string | null;
  basePrice?: number | null;
  priceRange?: string | null;
  durationMinutes?: number | null;
  imageUrl?: string | null;
  categoryName?: string | null;
  options?: ServiceOption[];
};

const oilOptions = [
  { id: 'standard', name: 'Standard/Conventional Oil', price: 4000, description: 'Basic protection for everyday driving' },
  { id: 'synthetic-blend', name: 'Synthetic Blend Oil', price: 5500, description: 'Enhanced protection and performance' },
  { id: 'full-synthetic', name: 'Full Synthetic Oil', price: 7000, description: 'Maximum protection for high-performance engines' },
];

const serviceImages: Record<string, string> = {
  'Washing Packages': '/service images/Washing Packages.jpg',
  'Lube Services': '/service images/Lubricant Service.jpg',
  'AC Services': '/service images/AC Repair and Service.jpg',
  'Exterior & Interior Detailing': '/service images/Exterior Detailing.jpg',
  'Engine Tune ups': '/service images/Mechanical Repair.jpg',
  'Inspection Reports': '/service images/Mulipoint Inspection Report.jpg',
  'Tyre Services': '/service images/Mechanical Repair.jpg',
  'Waxing': '/service images/Exterior Detailing.jpg',
  'Undercarriage Degreasing': '/service images/Exterior Detailing.jpg',
  'Windscreen Treatments': '/service images/Exterior Detailing.jpg',
  'Battery Services': '/service images/Electrical & Electronic.jpg',
  'Nano Coating Packages': '/service images/Exterior Detailing.jpg',
  'Nano Coating Treatments': '/service images/Exterior Detailing.jpg',
  'Insurance Claims': '/service images/General Collision Repair.jpg',
  'Wheel Alignment': '/service images/Mechanical Repair.jpg',
  'Full Paints': '/service images/Complete Paint.jpg',
  'Part Replacements': '/service images/Mechanical Repair.jpg',
  'Repair & Modifications': '/service images/General Collision Repair.jpg',
};

export default function ServiceDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [selectedOil, setSelectedOil] = useState('standard');
  const [specialInstructions, setSpecialInstructions] = useState('');
  const [vehicleName, setVehicleName] = useState('');
  const [service, setService] = useState<ServiceDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const loadService = async () => {
      try {
        setIsLoading(true);
        const serviceId = Number(id || 1);
        const response = await apiService.getServiceById(serviceId);

        if (response.success && response.data) {
          setService(response.data as ServiceDetail);
        } else {
          setService(null);
        }
      } catch (error) {
        console.error('Failed to load service details:', error);
        setService(null);
      } finally {
        setIsLoading(false);
      }
    };

    loadService();
  }, [id]);

  const isLubeService = service?.name === 'Lube Services' || id === '2';
  const selectedOilOption = oilOptions.find((option) => option.id === selectedOil);

  const displayBasePrice = useMemo(() => {
    if (!service) return 'Quote required';
    if (service.basePrice === null || service.basePrice === undefined || service.basePrice === 0) {
      return service.priceRange || 'Quote required';
    }
    return `LKR ${Number(service.basePrice).toLocaleString()}`;
  }, [service]);

  const totalPrice = (service?.basePrice || 0) + (isLubeService ? (selectedOilOption?.price || 0) : 0);

  const serviceImage = service
    ? (service.imageUrl || serviceImages[service.name] || serviceImages['Washing Packages'])
    : serviceImages['Washing Packages'];

  const priceLabel = service?.basePrice && service.basePrice > 0
    ? `LKR ${Number(service.basePrice).toLocaleString()}`
    : service?.priceRange || 'Quote required';

  const includedFeatures = isLubeService
    ? [
        'Premium quality oil',
        'Oil filter replacement',
        'Multi-point inspection',
        'Fluid level check',
      ]
    : [
        'Professional service by certified technicians',
        'Quality parts and materials',
        'Thorough inspection and workmanship',
        'Warranty coverage where applicable',
      ];

  if (isLoading) {
    return (
      <AppLayout showNav={false}>
        <div className="min-h-screen flex items-center justify-center">
          <div className="flex flex-col items-center">
            <Loader2 className="w-10 h-10 animate-spin text-[#ff5d2e] mb-4" />
            <p className="text-black/60 font-medium text-sm">Loading service details...</p>
          </div>
        </div>
      </AppLayout>
    );
  }

  if (!service) {
    return (
      <AppLayout showNav={false}>
        <div className="min-h-screen flex items-center justify-center">
          <div className="flex flex-col items-center text-center p-4">
            <p className="text-xl font-semibold text-black mb-2">Service not found</p>
            <button onClick={() => navigate('/services')} className="text-[#ff5d2e] hover:underline">
              Return to Services
            </button>
          </div>
        </div>
      </AppLayout>
    );
  }

  return (
    <AppLayout showNav={false}>
      <div className="min-h-screen flex flex-col">
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

        <div className="flex-1 max-w-5xl mx-auto w-full px-4 lg:px-6 pb-32 lg:pb-8">
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-6 lg:gap-8">
            <div className="lg:col-span-3 flex flex-col gap-6">
              <div className="w-full aspect-[16/9] lg:aspect-[16/7] bg-gradient-to-br from-[#ffe7df] to-[#fff7f5] rounded-2xl overflow-hidden relative">
                <img src={serviceImage} alt={service.name} className="w-full h-full object-cover" />
              </div>

              <div className="flex flex-col gap-4">
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <h1 className="text-xl lg:text-2xl font-semibold text-black">{service.name}</h1>
                    <p className="text-lg font-semibold text-[#ff5d2e] mt-1">{displayBasePrice}</p>
                  </div>
                  <div className="flex items-center gap-1 bg-[#fff7f5] px-3 py-2 rounded-lg">
                    <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                    <span className="font-semibold text-black">4.8</span>
                    <span className="text-sm text-black/50">(reviews)</span>
                  </div>
                </div>

                <div className="flex items-center gap-4 text-sm text-black/70">
                  <div className="flex items-center gap-1">
                    <Clock className="w-4 h-4" />
                    <span>{service.durationMinutes ? `${service.durationMinutes} min` : 'Varies'}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Shield className="w-4 h-4" />
                    <span>Warranty included</span>
                  </div>
                </div>

                <p className="text-base text-black/70 leading-relaxed">
                  {service.description || 'Service details are available from the booking system.'}
                </p>
              </div>

              <div className="hidden lg:block">
                <h3 className="text-lg font-semibold text-black mb-3">What's Included</h3>
                <div className="grid grid-cols-2 gap-3">
                  {includedFeatures.map((feature, idx) => (
                    <div key={idx} className="flex items-center gap-2 p-3 bg-white rounded-lg">
                      <Check className="w-5 h-5 text-green-500" />
                      <span className="text-sm font-medium text-black">{feature}</span>
                    </div>
                  ))}
                </div>
              </div>

              <div className="h-px bg-black/10" />

              {isLubeService && (
                <div className="flex flex-col gap-4">
                  <h3 className="text-base lg:text-lg font-semibold text-black">Pricing and Oil Selection</h3>
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
                            {selectedOil === option.id && <div className="w-3 h-3 rounded-full bg-[#ff5d2e]" />}
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

              <div className="h-px bg-black/10" />

              <div className="flex flex-col gap-4">
                <h3 className="text-base lg:text-lg font-semibold text-black">Special Instructions</h3>
                <textarea
                  placeholder="Add any special requests or notes for the service team..."
                  value={specialInstructions}
                  onChange={(e) => setSpecialInstructions(e.target.value)}
                  className="w-full h-28 p-4 bg-white rounded-lg border border-black/10 text-sm text-black resize-none outline-none focus:border-[#ff5d2e] transition-colors placeholder:text-black/40"
                />
              </div>
            </div>

            <div className="hidden lg:block lg:col-span-2">
              <div className="sticky top-24 bg-white rounded-2xl shadow-lg p-6 flex flex-col gap-6">
                <h3 className="text-lg font-semibold text-black">Booking Summary</h3>

                <div className="flex items-center gap-3 p-3 bg-[#fff7f5] rounded-lg">
                  <div className="w-12 h-12 bg-[#ffe7df] rounded-lg flex items-center justify-center overflow-hidden">
                    <Car className="w-6 h-6 text-[#ff5d2e]" />
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-black">{service.name}</p>
                    <p className="text-sm text-black/50">{service.categoryName || 'Service'} • {service.priceRange || priceLabel}</p>
                  </div>
                </div>

                <div className="flex flex-col gap-3">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-black/70">Service Fee</span>
                    <span className="font-medium text-black">{priceLabel}</span>
                  </div>
                  {isLubeService && selectedOilOption && (
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-black/70">{selectedOilOption.name}</span>
                      <span className="font-medium text-black">LKR {selectedOilOption.price.toLocaleString()}</span>
                    </div>
                  )}
                  <div className="h-px bg-black/10" />
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-black">Total</span>
                    <span className="text-xl font-bold text-[#ff5d2e]">
                      {service.basePrice && service.basePrice > 0
                        ? `LKR ${totalPrice.toLocaleString()}`
                        : priceLabel}
                    </span>
                  </div>
                </div>

                <div className="flex flex-col gap-2">
                  <label className="text-sm font-medium text-black/70">Your Vehicle</label>
                  <VehicleSelector value={vehicleName} onSelect={setVehicleName} />
                </div>

                <Link
                  to={`/book/${service.id}?oil=${selectedOil}&notes=${encodeURIComponent(specialInstructions)}&vehicle=${encodeURIComponent(vehicleName)}`}
                  className="w-full bg-[#ff5d2e] text-white py-4 rounded-xl font-semibold text-center shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] hover:bg-[#e54d1e] transition-colors"
                >
                  Book Now • {service.basePrice && service.basePrice > 0 ? `LKR ${totalPrice.toLocaleString()}` : priceLabel}
                </Link>

                <p className="text-xs text-black/50 text-center">You won't be charged until after your service</p>
              </div>
            </div>
          </div>
        </div>

        <div className="lg:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-black/10 p-4 safe-area-pb flex flex-col gap-3">
          <VehicleSelector value={vehicleName} onSelect={setVehicleName} compact />
          <Link
            to={`/book/${service.id}?oil=${selectedOil}&notes=${encodeURIComponent(specialInstructions)}&vehicle=${encodeURIComponent(vehicleName)}`}
            className="w-full bg-[#ff5d2e] text-white py-4 rounded-xl font-semibold flex items-center justify-center gap-2 shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)]"
          >
            <span>Book now</span>
            <span className="w-1 h-1 rounded-full bg-white" />
            <span>{service.basePrice && service.basePrice > 0 ? `LKR ${totalPrice.toLocaleString()}` : priceLabel}</span>
          </Link>
        </div>
      </div>
    </AppLayout>
  );
}