import { useEffect, useMemo, useState } from 'react';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { Check, Clock, Image, Shield } from 'lucide-react';
import { AppLayout } from '@/components/layouts/AppLayout';
import { VehicleSelector } from '@/components/VehicleSelector';
import { apiService, type ServiceItem, type ServiceOption } from '@/services/api';

const serviceImages: Record<string, string> = {
  'Washing Packages': '/service images/Washing Packages.jpg',
  'Lube Services': '/service images/Lubricant Service.jpg',
  'Exterior & Interior Detailing': '/service images/Exterior Detailing.jpg',
  'Engine Tune ups': '/service images/Mechanical Repair.jpg',
  'Inspection Reports': '/service images/Mulipoint Inspection Report.jpg',
  'Tyre Services': '/service images/Mechanical Repair.jpg',
  'Waxing': '/service images/Exterior Detailing.jpg',
  'Undercarriage Degreasing': '/service images/Exterior Detailing.jpg',
  'Windscreen Treatments': '/service images/Exterior Detailing.jpg',
  'Battery Services': '/service images/Electrical & Electronic.jpg',
  'Packages': '/service images/Exterior Detailing.jpg',
  'Treatments': '/service images/Exterior Detailing.jpg',
  'Insurance Claims': '/service images/General Collision Repair.jpg',
  'Wheel Alignment': '/service images/Mechanical Repair.jpg',
  'Full Paints': '/service images/Complete Paint.jpg',
  'Part Replacements': '/service images/Mechanical Repair.jpg',
};

const fallbackIncluded = ['Professional inspection', 'Quality workmanship', 'Service recommendations', 'Warranty support'];

const formatLkr = (value?: number | null) => `LKR ${(Number(value) || 0).toLocaleString()}`;

const durationLabel = (minutes?: number | null) => {
  if (!minutes) return 'Varies';
  if (minutes < 60) return `${minutes} min`;
  const hours = Math.floor(minutes / 60);
  const remaining = minutes % 60;
  return remaining ? `${hours}-${hours + 1} hours` : `${hours} hour${hours > 1 ? 's' : ''}`;
};

function ServiceDetailSkeleton() {
  return (
    <AppLayout showNav={false}>
      <div className="min-h-screen max-w-5xl mx-auto w-full px-4 lg:px-6 py-6">
        <div className="h-10 w-10 rounded-lg bg-white animate-pulse mb-6" />
        <div className="grid grid-cols-1 lg:grid-cols-5 gap-6 lg:gap-8">
          <div className="lg:col-span-3 flex flex-col gap-6">
            <div className="aspect-[16/9] lg:aspect-[16/7] bg-[#ffe7df] rounded-2xl animate-pulse" />
            <div className="space-y-3">
              <div className="h-7 w-2/3 bg-gray-200 rounded animate-pulse" />
              <div className="h-5 w-40 bg-[#ffe7df] rounded animate-pulse" />
              <div className="h-4 w-full bg-gray-100 rounded animate-pulse" />
              <div className="h-4 w-5/6 bg-gray-100 rounded animate-pulse" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              {Array.from({ length: 4 }).map((_, index) => (
                <div key={index} className="h-12 bg-white rounded-lg animate-pulse" />
              ))}
            </div>
            <div className="space-y-2">
              {Array.from({ length: 3 }).map((_, index) => (
                <div key={index} className="h-16 bg-white rounded-lg animate-pulse" />
              ))}
            </div>
          </div>
          <div className="hidden lg:block lg:col-span-2">
            <div className="sticky top-24 bg-white rounded-2xl shadow-lg p-6 space-y-4">
              <div className="h-6 w-40 bg-gray-200 rounded animate-pulse" />
              <div className="h-20 bg-[#fff7f5] rounded-lg animate-pulse" />
              <div className="h-12 bg-gray-100 rounded-lg animate-pulse" />
              <div className="h-12 bg-[#ff5d2e]/20 rounded-xl animate-pulse" />
            </div>
          </div>
        </div>
      </div>
    </AppLayout>
  );
}

export default function ServiceDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [service, setService] = useState<ServiceItem | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedOptionId, setSelectedOptionId] = useState<number | null>(null);
  const [specialInstructions, setSpecialInstructions] = useState('');
  const [vehicleName, setVehicleName] = useState('');

  useEffect(() => {
    const fetchService = async () => {
      if (!id) return;
      try {
        setIsLoading(true);
        const response = await apiService.getServiceById(Number(id));
        if (response.success && response.data) {
          setService(response.data);
          const defaultOption = response.data.options?.find(option => option.isDefault) || response.data.options?.[0];
          setSelectedOptionId(defaultOption?.id ?? null);
        }
      } catch (error) {
        console.error('Failed to load service:', error);
      } finally {
        setIsLoading(false);
      }
    };
    fetchService();
  }, [id]);

  const selectedOption = useMemo<ServiceOption | undefined>(() => {
    if (!service?.options?.length) return undefined;
    return service.options.find(option => option.id === selectedOptionId) || service.options.find(option => option.isDefault) || service.options[0];
  }, [service, selectedOptionId]);

  if (isLoading) return <ServiceDetailSkeleton />;

  if (!service) {
    return (
      <AppLayout showNav={false}>
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <p className="text-xl font-semibold text-black mb-2">Service not found</p>
            <button onClick={() => navigate('/services')} className="text-[#ff5d2e] hover:underline">Return to services</button>
          </div>
        </div>
      </AppLayout>
    );
  }

  const includedItems = service.includedItems?.length ? service.includedItems : fallbackIncluded;
  const imageSrc = service.imageUrl || serviceImages[service.name];
  const basePrice = Number(service.basePrice || 0);
  const optionPrice = Number(selectedOption?.priceAdjustment || 0);
  const totalPrice = basePrice + optionPrice;
  const bookingUrl = `/book/${service.id}?option=${selectedOption?.id ?? ''}&notes=${encodeURIComponent(specialInstructions)}&vehicle=${encodeURIComponent(vehicleName)}`;

  return (
    <AppLayout showNav={false}>
      <div className="min-h-screen flex flex-col">
        <div className="sticky top-0 bg-gradient-to-b from-[#fff7f5] to-transparent z-10 pb-4">
          <div className="flex items-center gap-4 px-4 py-3 lg:px-0">
            <span className="text-lg font-semibold text-black lg:hidden">Service Details</span>
          </div>
        </div>

        <div className="flex-1 max-w-5xl mx-auto w-full px-4 lg:px-6 pb-32 lg:pb-8">
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-6 lg:gap-8">
            <div className="lg:col-span-3 flex flex-col gap-6">
              <div className="w-full aspect-[16/9] lg:aspect-[16/7] bg-[#ffe7df] rounded-2xl overflow-hidden relative flex items-center justify-center">
                {imageSrc ? <img src={imageSrc} alt={service.name} className="w-full h-full object-cover" /> : <Image className="w-10 h-10 text-[#ff5d2e]" />}
              </div>

              <div className="flex flex-col gap-4">
                <div>
                  <h1 className="text-xl lg:text-2xl font-semibold text-black text-left">{service.name}</h1>
                  <p className="text-lg font-semibold text-[#ff5d2e] mt-1 text-left">{service.priceRange || `from ${formatLkr(service.basePrice)}`}</p>
                </div>

                <div className="flex items-center gap-4 text-sm text-black/70">
                  <div className="flex items-center gap-1"><Clock className="w-4 h-4" /><span>{durationLabel(service.durationMinutes)}</span></div>
                  {service.warrantyIncluded !== false && <div className="flex items-center gap-1"><Shield className="w-4 h-4" /><span>Warranty included</span></div>}
                </div>

                <p className="text-base text-black/70 leading-relaxed text-left">{service.description}</p>
              </div>

              <div className="hidden lg:block">
                <h3 className="text-lg font-semibold text-black mb-3 text-left">What's Included</h3>
                <div className="grid grid-cols-2 gap-3 text-left">
                  {includedItems.map((feature, idx) => (
                    <div key={idx} className="flex items-center gap-2 p-3 bg-white rounded-lg">
                      <Check className="w-5 h-5 text-[#ff5d2e]" />
                      <span className="text-sm font-medium text-black">{feature}</span>
                    </div>
                  ))}
                </div>
              </div>

              {service.options?.length ? (
                <>
                  <div className="h-px bg-black/10" />
                  <div className="flex flex-col gap-4">
                    <h3 className="text-base lg:text-lg font-semibold text-black text-left">Packages</h3>
                    <div className="flex flex-col gap-2">
                      {service.options.map((option) => (
                        <button
                          key={option.id}
                          onClick={() => setSelectedOptionId(option.id)}
                          className={`w-full text-left p-4 rounded-lg transition-all ${selectedOption?.id === option.id ? 'bg-[#ffe7df] border-2 border-[#ff5d2e]' : 'bg-white border border-black/10 hover:border-[#ff5d2e]/50'}`}
                        >
                          <div className="flex items-center gap-3">
                            <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${selectedOption?.id === option.id ? 'border-[#ff5d2e]' : 'border-black/30'}`}>
                              {selectedOption?.id === option.id && <div className="w-3 h-3 rounded-full bg-[#ff5d2e]" />}
                            </div>
                            <div className="flex-1">
                              <p className="font-medium text-black">{option.name}</p>
                              <p className="text-sm text-black/50 hidden lg:block">{option.description}</p>
                            </div>
                            <p className="font-semibold text-black">+{formatLkr(option.priceAdjustment)}</p>
                          </div>
                        </button>
                      ))}
                    </div>
                  </div>
                </>
              ) : null}

              <div className="h-px bg-black/10" />
              <div className="flex flex-col gap-4">
                <h3 className="text-base lg:text-lg font-semibold text-black text-left">Special Instructions</h3>
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
                <div className="flex flex-col gap-3">
                  <div className="flex items-center justify-between text-sm"><span className="text-black/70">Service Fee</span><span className="font-medium text-black">{formatLkr(basePrice)}</span></div>
                  {selectedOption && <div className="flex items-center justify-between text-sm"><span className="text-black/70">{selectedOption.name}</span><span className="font-medium text-black">{formatLkr(optionPrice)}</span></div>}
                  <div className="h-px bg-black/10" />
                  <div className="flex items-center justify-between"><span className="font-semibold text-black">Total</span><span className="text-xl font-bold text-[#ff5d2e]">{formatLkr(totalPrice)}</span></div>
                </div>

                <div className="flex flex-col gap-2">
                  <label className="text-sm font-medium text-black/70 text-left">Your Vehicle</label>
                  <VehicleSelector value={vehicleName} onSelect={setVehicleName} />
                </div>

                <Link to={bookingUrl} className="w-full bg-[#ff5d2e] text-white py-4 rounded-xl font-semibold text-center shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] hover:bg-[#e54d1e] transition-colors">
                  Book Now • {formatLkr(totalPrice)}
                </Link>
                <p className="text-xs text-black/50 text-center">You won't be charged until after your service</p>
              </div>
            </div>
          </div>
        </div>

        <div className="lg:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-black/10 p-4 safe-area-pb flex flex-col gap-3">
          <VehicleSelector value={vehicleName} onSelect={setVehicleName} compact />
          <Link to={bookingUrl} className="w-full bg-[#ff5d2e] text-white py-4 rounded-xl font-semibold flex items-center justify-center gap-2 shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)]">
            <span>Book now</span><span className="w-1 h-1 rounded-full bg-white" /><span>{formatLkr(totalPrice)}</span>
          </Link>
        </div>
      </div>
    </AppLayout>
  );
}
