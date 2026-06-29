import { useState, useEffect } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { Car, Phone, Coins, CreditCard, Calendar, Clock } from 'lucide-react';
import { toast } from 'sonner';
import { AppLayout } from '@/components/layouts/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import { apiService } from '@/services/api';
import { VehicleSelector } from '@/components/VehicleSelector';

const API_BASE_URL = (() => {
  let envApi = import.meta.env.VITE_API_URL;

  if (envApi && envApi.startsWith('http://') && window.location.protocol === 'https:') {
    envApi = undefined;
  }

  if (envApi) return envApi;

  const host = window.location.hostname;
  if (host === 'localhost' || host === '127.0.0.1') {
    return `http://${host}:3001/api`;
  }

  return `${window.location.origin}/api`;
})();

export default function BookingPage() {
  const { id: serviceId } = useParams();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { user } = useAuth();

  // Feature 2 fix: store index (0-6) instead of label string — always stable
  const [selectedDateIndex, setSelectedDateIndex] = useState(0);
  const [selectedTime, setSelectedTime] = useState('9:00 AM - 9:30 AM');
  const [isBooking, setIsBooking] = useState(false);
  const [currentStep, setCurrentStep] = useState<'time' | 'checkout'>('time');
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'payhere'>('cash');

  // Feature 1: track booked slots for the selected date
  const [bookedSlots, setBookedSlots] = useState<string[]>([]);
  const [isLoadingSlots, setIsLoadingSlots] = useState(false);

  const selectedOptionParam = searchParams.get('option');
  const specialInstructions = searchParams.get('notes') || '';

  const [vehicleName, setVehicleName] = useState(searchParams.get('vehicle') || '');

  const [currentService, setCurrentService] = useState<any>(null);
  const [isServiceLoading, setIsServiceLoading] = useState(true);
  const [selectedOptionId, setSelectedOptionId] = useState<number | null>(
    selectedOptionParam ? Number(selectedOptionParam) : null
  );

  useEffect(() => {
    const fetchService = async () => {
      try {
        setIsServiceLoading(true);
        // Fallback to ID 2 (Lube Services) if none provided
        const idToFetch = serviceId ? parseInt(serviceId) : 2;
        const response = await apiService.getServiceById(idToFetch);
        if (response.success && response.data) {
          setCurrentService(response.data);
          const options = response.data.options || [];
          const selectedFromUrl = selectedOptionParam
            ? options.find((option: any) => option.id === Number(selectedOptionParam))
            : null;
          const defaultOption = selectedFromUrl || options.find((option: any) => option.isDefault) || options[0];
          setSelectedOptionId(defaultOption?.id ?? null);
        }
      } catch (error) {
        console.error('Failed to load service:', error);
      } finally {
        setIsServiceLoading(false);
      }
    };
    fetchService();
  }, [serviceId, selectedOptionParam]);

  const generateDates = () => {
    const today = new Date();
    const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Array.from({ length: 7 }, (_, i) => {
      const date = new Date(today);
      date.setDate(today.getDate() + i + 1);
      return {
        label: i === 0 ? 'Tomorrow' : daysOfWeek[date.getDay()],
        date: `${months[date.getMonth()]} ${date.getDate()}`,
        fullDate: date,
        // ISO date string for the booked-slots API: YYYY-MM-DD
        isoDate: date.toISOString().split('T')[0],
      };
    });
  };

  const dates = generateDates();
  const selectedDateObj = dates[selectedDateIndex];

  const timeSlots = [
    '9:00 AM - 9:30 AM',
    '9:30 AM - 10:00 AM',
    '10:00 AM - 10:30 AM',
    '10:30 AM - 11:00 AM',
    '11:00 AM - 11:30 AM',
    '11:30 AM - 12:00 PM',
    '12:00 PM - 12:30 PM',
    '12:30 PM - 1:00 PM',
    '1:00 PM - 1:30 PM',
    '1:30 PM - 2:00 PM',
    '2:00 PM - 2:30 PM',
    '2:30 PM - 3:00 PM',
    '3:00 PM - 3:30 PM',
    '3:30 PM - 4:00 PM',
    '4:00 PM - 4:30 PM',
    '4:30 PM - 5:00 PM',
    '5:00 PM - 5:30 PM',
    '5:30 PM - 6:00 PM',
  ];

  // Feature 1: helper — extract "HH:mm" from a slot label like "9:00 AM - 9:30 AM"
  const slotToHHMM = (slot: string): string => {
    const startTime = slot.split(' - ')[0]; // "9:00 AM"
    const [time, period] = startTime.split(' ');
    const [h, m] = time.split(':').map(Number);
    let hour24 = h;
    if (period === 'PM' && h !== 12) hour24 = h + 12;
    else if (period === 'AM' && h === 12) hour24 = 0;
    return `${String(hour24).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
  };

  const isSlotBooked = (slot: string) => bookedSlots.includes(slotToHHMM(slot));

  // Feature 1: fetch booked slots whenever the selected date changes
  useEffect(() => {
    const fetchBookedSlots = async () => {
      setIsLoadingSlots(true);
      try {
        const res = await fetch(
          `${API_BASE_URL}/appointments/booked-slots?date=${selectedDateObj.isoDate}`
        );
        if (res.ok) {
          const data = await res.json();
          setBookedSlots(data.data ?? []);
          // If the currently-selected time just became booked, pick the first free slot
          if (data.data?.includes(slotToHHMM(selectedTime))) {
            const firstFree = timeSlots.find(s => !data.data.includes(slotToHHMM(s)));
            if (firstFree) setSelectedTime(firstFree);
          }
        }
      } catch {
        // silently fail — slots just won't be grayed out
      } finally {
        setIsLoadingSlots(false);
      }
    };
    fetchBookedSlots();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedDateIndex]);

  // Map service names to icon images in /public/service icons/
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
    'Nano Coating Packages': '/service icons/Nano Coating Packages.png',
    'Nano Coating Treatments': '/service icons/Nano Coating Treatments.png',
    'Insurance Claims': '/service icons/Insurance Claims.png',
    'Wheel Alignment': '/service icons/Wheel Alignment.png',
    'Full Paints': '/service icons/Full Paints.png',
    'Part Replacements': '/service icons/Part Replacements.png',
  };

  const serviceIconSrc = currentService?.name ? serviceIcons[currentService.name] : undefined;

  const serviceOptions = currentService?.options || [];
  const selectedOption = serviceOptions.find((option: any) => option.id === selectedOptionId)
    || serviceOptions.find((option: any) => option.isDefault)
    || serviceOptions[0];
  const orderDetails = {
    service: currentService?.name || '',
    serviceFee: currentService?.basePrice || 0,
    optionName: selectedOption?.name || null,
    optionPrice: selectedOption ? Number(selectedOption.priceAdjustment || 0) : 0,
    total: (currentService?.basePrice || 0) + (selectedOption ? Number(selectedOption.priceAdjustment || 0) : 0),
  };

  const convertToDateTime = (dateObj: Date, timeSlot: string): string => {
    const appointmentDate = new Date(dateObj);
    const startTime = timeSlot.split(' - ')[0];
    const [time, period] = startTime.split(' ');
    const [hours, minutes] = time.split(':').map(Number);
    let hour24 = hours;
    if (period === 'PM' && hours !== 12) hour24 = hours + 12;
    else if (period === 'AM' && hours === 12) hour24 = 0;
    appointmentDate.setHours(hour24, minutes, 0, 0);

    // Build a LOCAL-time ISO string (no UTC conversion).
    // Using toISOString() would shift to UTC, causing the backend to store the wrong
    // time and the confirmation screen to display the wrong time.
    // Example: 11:00 AM IST → toISOString() → "05:30Z" (wrong)
    //          11:00 AM IST → local ISO       → "...T11:00:00"   (correct)
    const pad = (n: number) => String(n).padStart(2, '0');
    return (
      `${appointmentDate.getFullYear()}-` +
      `${pad(appointmentDate.getMonth() + 1)}-` +
      `${pad(appointmentDate.getDate())}T` +
      `${pad(appointmentDate.getHours())}:` +
      `${pad(appointmentDate.getMinutes())}:00`
    );
  };


  const handleBook = async () => {
    if (!user) {
      toast.error('Please login to book a service');
      navigate('/login');
      return;
    }

    setIsBooking(true);
    try {
      // Step 1: Create the appointment (same for both payment methods)
      const appointmentDateTime = convertToDateTime(selectedDateObj.fullDate, selectedTime);
      const vehicleNote = vehicleName.trim() ? `Vehicle: ${vehicleName.trim()}` : '';
      const optionNote = orderDetails.optionName ? `${orderDetails.optionName} - ` : '';
      const baseNote = `${optionNote}${orderDetails.service} - ${selectedTime}`;
      const appointmentRequest = {
        serviceType: orderDetails.service,
        appointmentDate: appointmentDateTime,
        location: 'Colombo Service Center',
        notes: [specialInstructions, vehicleNote, baseNote].filter(Boolean).join(' | '),
        estimatedCost: orderDetails.total,
        customerName: user.fullName,
        customerEmail: user.email,
        customerPhone: user.phone || undefined,
      };

      const response = await apiService.createAppointment(appointmentRequest);
      if (!response.success || !response.data) {
        toast.error(response.message || 'Failed to book appointment');
        return;
      }

      const appointmentId = response.data.id;

      // Step 2: Handle chosen payment method
      if (paymentMethod === 'cash') {
        toast.success('Appointment booked successfully!');
        navigate(`/confirmed/${appointmentId}`);
      } else {
        // PayHere JS SDK — modal popup, no redirect
        const payRes = await apiService.initiatePayHerePayment(
          appointmentId,
          'LKR',
          serviceId ?? undefined,
        );
        if (!payRes.success || !payRes.data) {
          toast.error(payRes.message || 'Failed to initiate PayHere payment');
          setIsBooking(false);
          return;
        }
        const d = payRes.data;

        // Guard: ensure the PayHere JS SDK has loaded
        if (!window.payhere || typeof window.payhere.startPayment !== 'function') {
          toast.error('Payment gateway failed to load. Please refresh the page and try again.');
          // Release the slot by cancelling the appointment (use .catch to ignore backend 404s if not restarted yet)
          await apiService.cancelAppointment(appointmentId).catch(() => {/* ignore */});
          setIsBooking(false);
          return;
        }

        // Register callbacks before calling startPayment
        window.payhere.onCompleted = (_orderId: string) => {
          toast.success('Payment successful! Your appointment is confirmed.');
          navigate(`/confirmed/${appointmentId}`);
        };

        window.payhere.onDismissed = () => {
          toast.info('Payment cancelled. The time slot has been released.');
          // Free the slot so other users or the same user can book again
          apiService.cancelAppointment(appointmentId).catch(() => {/* best-effort */});
          setIsBooking(false);
        };

        window.payhere.onError = (error: string) => {
          toast.error(`Payment failed: ${error}. The time slot has been released.`);
          apiService.cancelAppointment(appointmentId).catch(() => {/* best-effort */});
          setIsBooking(false);
        };

        // Open in-page modal — user never leaves this page
        window.payhere.startPayment({
          sandbox:     d.sandboxMode,
          merchant_id: d.merchantId,
          return_url:  undefined,  // not used with JS SDK
          cancel_url:  undefined,  // not used with JS SDK
          notify_url:  d.notifyUrl,
          order_id:    d.orderId,
          items:       d.items,
          amount:      d.amount,
          currency:    d.currency,
          hash:        d.hash,
          first_name:  d.firstName,
          last_name:   d.lastName,
          email:       d.email,
          phone:       d.phone,
          address:     d.address,
          city:        d.city,
          country:     d.country,
        });
        // Callbacks handle setIsBooking(false) — skip the finally block
        return;
      }
    } catch (error: any) {
      let errorMessage = 'Failed to book appointment. ';
      if (error.message) errorMessage += error.message;
      else errorMessage += 'Please check your connection and try again.';
      toast.error(errorMessage);
    } finally {
      setIsBooking(false);
    }
  };

  // ── Time slot button (reused in both mobile + desktop) ────────────────────
  const TimeSlotButton = ({ time, variant }: { time: string; variant: 'list' | 'grid' }) => {
    const booked = isSlotBooked(time);
    const selected = selectedTime === time && !booked;

    if (variant === 'list') {
      return (
        <button
          key={time}
          onClick={() => !booked && setSelectedTime(time)}
          disabled={booked}
          className={`w-full p-4 rounded-lg flex items-center justify-between transition-all ${booked
            ? 'bg-gray-100 border border-gray-200 cursor-not-allowed opacity-60'
            : selected
              ? 'bg-[#ffe7df] border-2 border-[#ff5d2e]'
              : 'bg-white border border-black/10 hover:border-[#ff5d2e]'
            }`}
        >
          <span className={`font-medium ${booked ? 'text-gray-400 line-through' : 'text-black'}`}>
            {time}
          </span>
          {booked ? (
            <span className="text-xs text-gray-400 font-medium">Booked</span>
          ) : (
            <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${selected ? 'border-[#ff5d2e]' : 'border-black/30'
              }`}>
              {selected && <div className="w-3 h-3 rounded-full bg-[#ff5d2e]" />}
            </div>
          )}
        </button>
      );
    }

    // grid variant (desktop)
    return (
      <button
        key={time}
        onClick={() => !booked && setSelectedTime(time)}
        disabled={booked}
        className={`p-3 rounded-lg text-center transition-all ${booked
          ? 'bg-gray-100 border border-gray-200 cursor-not-allowed opacity-60'
          : selected
            ? 'bg-[#ff5d2e] text-white'
            : 'bg-white border border-[#ffe7df] hover:border-[#ff5d2e]'
          }`}
      >
        <span className={`text-sm font-medium ${booked && !selected ? 'text-gray-400 line-through' : ''}`}>
          {time}
        </span>
        {booked && <div className="text-xs text-gray-400 mt-0.5">Booked</div>}
      </button>
    );
  };

  const PackageSelector = () => {
    if (!serviceOptions.length) return null;
    return (
      <div className="flex flex-col gap-3">
        <h3 className="text-lg font-semibold text-black text-left">Select Package</h3>
        <div className="flex flex-col gap-2">
          {serviceOptions.map((option: any) => (
            <button
              key={option.id}
              onClick={() => setSelectedOptionId(option.id)}
              className={`w-full text-left p-4 rounded-lg transition-all ${
                selectedOptionId === option.id
                  ? 'bg-[#ffe7df] border-2 border-[#ff5d2e]'
                  : 'bg-white border border-black/10 hover:border-[#ff5d2e]/50'
              }`}
            >
              <div className="flex items-center gap-3">
                <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${selectedOptionId === option.id ? 'border-[#ff5d2e]' : 'border-black/30'}`}>
                  {selectedOptionId === option.id && <div className="w-3 h-3 rounded-full bg-[#ff5d2e]" />}
                </div>
                <div className="flex-1">
                  <p className="font-medium text-black">{option.name}</p>
                  <p className="text-sm text-black/50">{option.description}</p>
                </div>
                <p className="font-semibold text-black">+LKR {Number(option.priceAdjustment || 0).toLocaleString()}</p>
              </div>
            </button>
          ))}
        </div>
      </div>
    );
  };

  // ── Mobile views ──────────────────────────────────────────────────────────
  const MobileTimeSelection = () => (
    <div className="flex flex-col gap-4 pb-24">
      <div className="flex gap-3 overflow-x-auto pb-2 -mx-4 px-4">
        {dates.map((dateOption, i) => (
          <button
            key={i}
            onClick={() => setSelectedDateIndex(i)}
            className={`flex flex-col gap-2 items-center justify-center min-w-[100px] px-4 py-3 rounded-lg shadow-sm text-center flex-shrink-0 ${selectedDateIndex === i
              ? 'bg-white border-2 border-[#ff5d2e]'
              : 'bg-white border border-[#ffe7df]'
              }`}
          >
            <p className="text-base font-medium text-black">{dateOption.label}</p>
            <p className="text-xs text-black/50">{dateOption.date}</p>
          </button>
        ))}
      </div>

      <div className="h-px bg-black/10" />

      <PackageSelector />

      {serviceOptions.length > 0 && <div className="h-px bg-black/10" />}

      <div className="flex flex-col gap-2">
        {isLoadingSlots ? (
          <div className="text-center py-8 text-black/40 text-sm">Loading available slots...</div>
        ) : (
          timeSlots.map((time) => <TimeSlotButton key={time} time={time} variant="list" />)
        )}
      </div>
    </div>
  );

  const MobileCheckout = () => (
    <div className="flex flex-col gap-6 pb-24">
      <div className="flex flex-col gap-4">
        <h3 className="text-lg font-semibold text-black">Order Summary</h3>
        <div className="bg-white rounded-lg p-4 flex items-center gap-3">
          <div className="w-12 h-12 rounded bg-[#ffe7df] flex items-center justify-center overflow-hidden">
            {serviceIconSrc ? (
              <img src={serviceIconSrc} alt={orderDetails.service} className="w-8 h-8 object-contain" />
            ) : (
              <Car className="w-6 h-6 text-[#ff5d2e]" />
            )}
          </div>
          <div className="flex-1">
            <p className="font-medium text-black">{orderDetails.service}</p>
            <p className="text-sm text-black/50">{selectedDateObj?.date} • {selectedTime}</p>
          </div>
          <button onClick={() => setCurrentStep('time')} className="text-sm font-medium text-[#ff5d2e]">
            Edit
          </button>
        </div>
      </div>

      <div className="h-px bg-black/10" />

      <div className="flex flex-col gap-4">
        <h3 className="text-lg font-semibold text-black">Price Breakdown</h3>
        <div className="flex flex-col gap-2 bg-white rounded-lg p-4">
          <div className="flex items-center justify-between text-sm">
            <span className="text-black/70">Service Fee</span>
            <span className="font-medium text-black">+LKR {orderDetails.serviceFee.toLocaleString()}</span>
          </div>
          {orderDetails.optionName && (
            <div className="flex items-center justify-between text-sm">
              <span className="text-black/70">{orderDetails.optionName}</span>
              <span className="font-medium text-black">+LKR {orderDetails.optionPrice.toLocaleString()}</span>
            </div>
          )}
          <div className="h-px bg-black/10 my-2" />
          <div className="flex items-center justify-between">
            <span className="font-bold text-black">Total</span>
            <span className="font-bold text-black">LKR {orderDetails.total.toLocaleString()}</span>
          </div>
        </div>
      </div>

      <div className="h-px bg-black/10" />

      <div className="flex flex-col gap-2">
        <VehicleSelector
          value={vehicleName}
          onSelect={setVehicleName}
        />
        <div className="bg-white rounded-lg p-4 flex items-center gap-3">
          <Phone className="w-5 h-5 flex-shrink-0" />
          <span className="flex-1 text-left text-sm font-medium text-black/70">{user?.phone || '+94 72 4523 299'}</span>
        </div>
        {/* Payment method selector */}
        <div className="flex flex-col gap-2">
          <p className="text-xs font-medium text-black/50 px-1">Payment Method</p>
          <div className="flex gap-2">
            <button
              onClick={() => setPaymentMethod('cash')}
              className={`flex-1 p-3 rounded-lg border-2 flex items-center gap-2 transition-all ${
                paymentMethod === 'cash'
                  ? 'border-[#ff5d2e] bg-[#ffe7df]'
                  : 'bg-white border-black/10 hover:border-[#ff5d2e]/50'
              }`}
            >
              <Coins className={`w-4 h-4 ${paymentMethod === 'cash' ? 'text-[#ff5d2e]' : 'text-black/40'}`} />
              <span className={`text-sm font-medium ${paymentMethod === 'cash' ? 'text-[#ff5d2e]' : 'text-black/60'}`}>Cash</span>
            </button>
            <button
              onClick={() => setPaymentMethod('payhere')}
              className={`flex-1 p-3 rounded-lg border-2 flex items-center gap-2 transition-all ${
                paymentMethod === 'payhere'
                  ? 'border-[#ff5d2e] bg-[#ffe7df]'
                  : 'bg-white border-black/10 hover:border-[#ff5d2e]/50'
              }`}
            >
              <CreditCard className={`w-4 h-4 ${paymentMethod === 'payhere' ? 'text-[#ff5d2e]' : 'text-black/40'}`} />
              <span className={`text-sm font-medium ${paymentMethod === 'payhere' ? 'text-[#ff5d2e]' : 'text-black/60'}`}>Card</span>
            </button>
          </div>
          <div className="mt-2 flex justify-center">
            <a href="https://www.payhere.lk" target="_blank" rel="noopener noreferrer">
              <img src="https://www.payhere.lk/downloads/images/payhere_short_banner.png" alt="PayHere" width="250"/>
            </a>
          </div>
        </div>
      </div>
    </div>
  );

  if (isServiceLoading) {
    return (
      <AppLayout showNav={false}>
        <div className="min-h-screen max-w-6xl mx-auto w-full px-4 lg:px-6 py-6">
          <div className="h-10 w-10 bg-white rounded-lg animate-pulse mb-6" />
          <div className="hidden lg:grid lg:grid-cols-5 gap-8">
            <div className="lg:col-span-3 flex flex-col gap-6">
              <div className="h-24 bg-white rounded-lg animate-pulse" />
              <div className="grid grid-cols-3 gap-3">
                {Array.from({ length: 9 }).map((_, index) => <div key={index} className="h-12 bg-white rounded-lg animate-pulse" />)}
              </div>
            </div>
            <div className="lg:col-span-2">
              <div className="bg-white rounded-2xl shadow-lg p-6 space-y-4">
                <div className="h-6 w-40 bg-gray-200 rounded animate-pulse" />
                <div className="h-16 bg-[#fff7f5] rounded-lg animate-pulse" />
                <div className="h-32 bg-gray-50 rounded-lg animate-pulse" />
                <div className="h-12 bg-[#ff5d2e]/20 rounded-xl animate-pulse" />
              </div>
            </div>
          </div>
          <div className="lg:hidden flex flex-col gap-3">
            {Array.from({ length: 6 }).map((_, index) => <div key={index} className="h-16 bg-white rounded-lg animate-pulse" />)}
          </div>
        </div>
      </AppLayout>
    );
  }

  if (!currentService) {
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
        {/* Header */}
        <div className="sticky top-0 bg-gradient-to-b from-[#fff7f5] to-transparent z-10 pb-4">
          <div className="max-w-6xl mx-auto w-full px-4 lg:px-6 py-3 flex items-center">
            <h1 className="text-xl lg:text-2xl font-semibold text-black ml-2 lg:ml-0">
              {currentStep === 'time' ? 'Choose a Time' : 'Checkout'}
            </h1>
          </div>

          <div className="lg:hidden flex items-center gap-2 px-4 mt-2">
            <div className={`flex-1 h-1 rounded-full ${currentStep === 'time' ? 'bg-[#ff5d2e]' : 'bg-[#ffe7df]'}`} />
            <div className={`flex-1 h-1 rounded-full ${currentStep === 'checkout' ? 'bg-[#ff5d2e]' : 'bg-[#ffe7df]'}`} />
          </div>
        </div>

        {/* Main content */}
        <div className="flex-1 max-w-6xl mx-auto w-full px-4 lg:px-6">
          {/* Mobile */}
          <div className="lg:hidden">
            {currentStep === 'time' ? <MobileTimeSelection /> : <MobileCheckout />}
          </div>

          {/* Desktop */}
          <div className="hidden lg:grid lg:grid-cols-5 gap-8">
            {/* Left — Time selection */}
            <div className="lg:col-span-3 flex flex-col gap-6">
              {/* Date picker */}
              <div className="flex flex-col gap-4">
                <h3 className="text-lg font-semibold text-black flex items-center gap-2">
                  <Calendar className="w-5 h-5 text-[#ff5d2e]" /> Select Date
                </h3>
                <div className="flex gap-3 overflow-x-auto pb-2">
                  {dates.map((dateOption, i) => (
                    <button
                      key={i}
                      onClick={() => setSelectedDateIndex(i)}
                      className={`flex flex-col gap-2 items-center justify-center min-w-[120px] px-4 py-4 rounded-lg shadow-sm text-center transition-all ${selectedDateIndex === i
                        ? 'bg-[#ff5d2e] text-white'
                        : 'bg-white border border-[#ffe7df] hover:border-[#ff5d2e]'
                        }`}
                    >
                      <p className="text-base font-medium">{dateOption.label}</p>
                      <p className={`text-sm ${selectedDateIndex === i ? 'text-white/70' : 'text-black/50'}`}>
                        {dateOption.date}
                      </p>
                    </button>
                  ))}
                </div>
              </div>

              {/* Time slots */}
              <div className="flex flex-col gap-4">
                <h3 className="text-lg font-semibold text-black flex items-center gap-2">
                  <Clock className="w-5 h-5 text-[#ff5d2e]" /> Select Time
                </h3>
                {isLoadingSlots ? (
                  <div className="text-center py-8 text-black/40 text-sm">Loading available slots...</div>
                ) : (
                  <div className="grid grid-cols-3 gap-3">
                    {timeSlots.map((time) => <TimeSlotButton key={time} time={time} variant="grid" />)}
                  </div>
                )}
              </div>

              <PackageSelector />

              {specialInstructions && (
                <div className="flex flex-col gap-2 p-4 bg-[#fff7f5] rounded-lg">
                  <p className="text-sm font-medium text-black/70">Special Instructions</p>
                  <p className="text-sm text-black">{specialInstructions}</p>
                </div>
              )}
            </div>

            {/* Right — Booking summary */}
            <div className="lg:col-span-2">
              <div className="sticky top-24 bg-white rounded-2xl shadow-lg p-6 flex flex-col gap-6">
                <h3 className="text-lg font-semibold text-black">Booking Summary</h3>

                <div className="flex items-center gap-3 p-3 bg-[#fff7f5] rounded-lg">
                  <div className="w-12 h-12 bg-[#ffe7df] rounded-lg flex items-center justify-center overflow-hidden">
                    {serviceIconSrc ? (
                      <img src={serviceIconSrc} alt={orderDetails.service} className="w-8 h-8 object-contain" />
                    ) : (
                      <Car className="w-6 h-6 text-[#ff5d2e]" />
                    )}
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-black">{orderDetails.service}</p>
                    <p className="text-sm text-black/50">{selectedDateObj?.date} • {selectedTime}</p>
                  </div>
                </div>

                <div className="flex flex-col gap-3">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-black/70">Service Fee</span>
                    <span className="font-medium text-black">LKR {orderDetails.serviceFee.toLocaleString()}</span>
                  </div>
                  {orderDetails.optionName && (
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-black/70">{orderDetails.optionName}</span>
                      <span className="font-medium text-black">LKR {orderDetails.optionPrice.toLocaleString()}</span>
                    </div>
                  )}
                  <div className="h-px bg-black/10" />
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-black">Total</span>
                    <span className="text-xl font-bold text-[#ff5d2e]">LKR {orderDetails.total.toLocaleString()}</span>
                  </div>
                </div>

                <div className="flex flex-col gap-2">
                  <VehicleSelector
                    value={vehicleName}
                    onSelect={setVehicleName}
                  />
                  {vehicleName.trim() && (
                    <p className="text-xs text-black/50 px-1">Vehicle will be noted in your appointment</p>
                  )}
                  <div className="w-full p-3 bg-[#fff7f5] rounded-lg flex items-center gap-3">
                    <Phone className="w-5 h-5 text-[#ff5d2e] flex-shrink-0" />
                    <span className="flex-1 text-left text-sm font-medium text-black">{user?.phone || '+94 72 4523 299'}</span>
                  </div>
                  {/* Payment method selector */}
                  <div className="flex flex-col gap-2">
                    <p className="text-xs font-medium text-black/50">Payment Method</p>
                    <div className="flex gap-2">
                      <button
                        onClick={() => setPaymentMethod('cash')}
                        className={`flex-1 p-3 rounded-lg border-2 flex items-center gap-2 transition-all ${
                          paymentMethod === 'cash'
                            ? 'border-[#ff5d2e] bg-[#ffe7df]'
                            : 'bg-white border-black/10 hover:border-[#ff5d2e]/50'
                        }`}
                      >
                        <Coins className={`w-4 h-4 ${paymentMethod === 'cash' ? 'text-[#ff5d2e]' : 'text-black/40'}`} />
                        <span className={`text-sm font-medium ${paymentMethod === 'cash' ? 'text-[#ff5d2e]' : 'text-black/60'}`}>Cash</span>
                      </button>
                      <button
                        onClick={() => setPaymentMethod('payhere')}
                        className={`flex-1 p-3 rounded-lg border-2 flex items-center gap-2 transition-all ${
                          paymentMethod === 'payhere'
                            ? 'border-[#ff5d2e] bg-[#ffe7df]'
                            : 'bg-white border-black/10 hover:border-[#ff5d2e]/50'
                        }`}
                      >
                        <CreditCard className={`w-4 h-4 ${paymentMethod === 'payhere' ? 'text-[#ff5d2e]' : 'text-black/40'}`} />
                        <span className={`text-sm font-medium ${paymentMethod === 'payhere' ? 'text-[#ff5d2e]' : 'text-black/60'}`}>Card</span>
                      </button>
                    </div>
                    <div className="mt-2 flex justify-center">
                      <a href="https://www.payhere.lk" target="_blank" rel="noopener noreferrer">
                        <img src="https://www.payhere.lk/downloads/images/payhere_short_banner.png" alt="PayHere" width="250"/>
                      </a>
                    </div>
                  </div>
                  {vehicleName.trim() && (
                    <div className="mt-1 p-3 bg-[#fff7f5] rounded-lg border border-[#ffe7df]">
                      <p className="text-xs text-black/50 mb-1">Appointment Summary</p>
                      <p className="text-sm font-medium text-black">{orderDetails.service}</p>
                      <p className="text-xs text-black/60">{selectedDateObj?.date} • {selectedTime}</p>
                      <p className="text-xs text-[#ff5d2e] font-medium mt-1">Vehicle: {vehicleName.trim()}</p>
                    </div>
                  )}
                </div>

                <button
                  onClick={handleBook}
                  disabled={isBooking}
                  className="w-full bg-[#ff5d2e] text-white py-4 rounded-xl font-semibold shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] hover:bg-[#e54d1e] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isBooking
                    ? (paymentMethod === 'payhere' ? 'Processing...' : 'Booking...')
                    : (paymentMethod === 'payhere' ? 'Pay Now' : 'Confirm Booking')}
                </button>

                <button
                  onClick={() => navigate(-1)}
                  className="w-full py-3 border border-[#ffe7df] rounded-xl font-medium text-black hover:bg-[#fff7f5] transition-colors"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Mobile bottom CTA */}
        <div className="lg:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-black/10 p-4 safe-area-pb flex flex-col gap-2">
          {currentStep === 'time' ? (
            <button
              onClick={() => setCurrentStep('checkout')}
              className="w-full bg-[#ff5d2e] text-white py-4 rounded-xl font-semibold shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)]"
            >
              Continue to Checkout
            </button>
          ) : (
            <>
              <button
                onClick={handleBook}
                disabled={isBooking}
                className="w-full bg-[#ff5d2e] text-white py-4 rounded-xl font-semibold shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] disabled:opacity-50"
              >
                {isBooking
                  ? (paymentMethod === 'payhere' ? 'Processing...' : 'Booking...')
                  : (paymentMethod === 'payhere' ? 'Pay Now' : 'Confirm Booking')}
              </button>
              <button
                onClick={() => navigate(-1)}
                className="w-full py-3 border border-[#ffe7df] rounded-xl font-medium text-black"
              >
                Cancel
              </button>
            </>
          )}
        </div>
      </div>
    </AppLayout>
  );
}
