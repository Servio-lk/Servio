import { useState } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { ArrowLeft, Car, Phone, Coins, ChevronRight, Calendar, Clock } from 'lucide-react';
import { toast } from 'sonner';
import { AppLayout } from '@/components/layouts/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import { apiService } from '@/services/api';

export default function BookingPage() {
  const { id: serviceId } = useParams();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  
  const [selectedDate, setSelectedDate] = useState('Tomorrow');
  const [selectedTime, setSelectedTime] = useState('9:00 AM - 9:30 AM');
  const [isBooking, setIsBooking] = useState(false);
  const [currentStep, setCurrentStep] = useState<'time' | 'checkout'>('time');

  // Get data from URL params
  const selectedOil = searchParams.get('oil') || 'standard';
  const specialInstructions = searchParams.get('notes') || '';

  // Service catalog - same as ServiceDetailPage
  const servicesCatalog: { [key: string]: any } = {
    '1': { id: '1', name: 'Washing Packages', basePrice: 500 },
    '2': { id: '2', name: 'Lube Services', basePrice: 1500 },
    '3': { id: '3', name: 'Exterior & Interior Detailing', basePrice: 3000 },
    '4': { id: '4', name: 'Engine Tune ups', basePrice: 2500 },
    '5': { id: '5', name: 'Inspection Reports', basePrice: 1000 },
    '6': { id: '6', name: 'AC Services', basePrice: 1200 },
    '7': { id: '7', name: 'Tire Services', basePrice: 800 },
    '8': { id: '8', name: 'Wheel Alignment', basePrice: 1500 },
    '9': { id: '9', name: 'Repair & Modifications', basePrice: 2000 },
    '10': { id: '10', name: 'Battery Services', basePrice: 500 },
    '11': { id: '11', name: 'Nano Coating Packages', basePrice: 15000 },
    '12': { id: '12', name: 'Nano Coating Treatments', basePrice: 8000 },
    '13': { id: '13', name: 'Insurance Claims', basePrice: 0 },
    '14': { id: '14', name: 'Hybrid Services', basePrice: 3500 },
  };

  // Get current service details
  const currentService = servicesCatalog[serviceId || '2'] || servicesCatalog['2'];

  // Generate real dates for the next 7 days
  const generateDates = () => {
    const today = new Date();
    const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return Array.from({ length: 7 }, (_, i) => {
      const date = new Date(today);
      date.setDate(today.getDate() + i + 1); // Start from tomorrow
      
      const dayName = daysOfWeek[date.getDay()];
      const monthName = months[date.getMonth()];
      const dayNum = date.getDate();
      
      return {
        label: i === 0 ? 'Tomorrow' : dayName,
        date: `${monthName} ${dayNum}`,
        fullDate: date
      };
    });
  };

  const dates = generateDates();

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

  const oilOptions: Record<string, { name: string; price: number }> = {
    'standard': { name: 'Standard/Conventional Oil', price: 4000 },
    'synthetic-blend': { name: 'Synthetic Blend Oil', price: 5500 },
    'full-synthetic': { name: 'Full Synthetic Oil', price: 7000 },
  };

  // Calculate order details based on service type
  const isLubeService = serviceId === '2';
  const orderDetails = {
    service: currentService.name,
    serviceFee: currentService.basePrice,
    oilType: isLubeService ? (oilOptions[selectedOil]?.name || 'Standard Oil') : null,
    oilPrice: isLubeService ? (oilOptions[selectedOil]?.price || 4000) : 0,
    total: currentService.basePrice + (isLubeService ? (oilOptions[selectedOil]?.price || 4000) : 0),
  };

  const handleBook = async () => {
    if (!user) {
      toast.error('Please login to book a service');
      navigate('/login');
      return;
    }

    setIsBooking(true);
    
    try {
      // Convert selected date and time to ISO datetime
      const appointmentDateTime = convertToDateTime(selectedDate, selectedTime);
      
      console.log('Booking appointment:', {
        serviceType: orderDetails.service,
        appointmentDate: appointmentDateTime,
        estimatedCost: orderDetails.total
      });
      
      // Create appointment request
      const appointmentRequest = {
        serviceType: orderDetails.service,
        appointmentDate: appointmentDateTime,
        location: 'Colombo Service Center', // Default location
        notes: specialInstructions || (isLubeService ? `${orderDetails.oilType} - ${selectedTime}` : `${orderDetails.service} - ${selectedTime}`),
        estimatedCost: orderDetails.total,
      };

      const response = await apiService.createAppointment(appointmentRequest);
      
      console.log('Appointment response:', response);
      
      if (response.success && response.data) {
        toast.success('Appointment booked successfully!');
        navigate(`/confirmed/${response.data.id}`);
      } else {
        toast.error(response.message || 'Failed to book appointment');
      }
    } catch (error: any) {
      console.error('Booking error:', error);
      
      // More detailed error message
      let errorMessage = 'Failed to book appointment. ';
      if (error.message) {
        errorMessage += error.message;
      } else if (error.error) {
        errorMessage += error.error;
      } else {
        errorMessage += 'Please check your connection and try again.';
      }
      
      toast.error(errorMessage);
    } finally {
      setIsBooking(false);
    }
  };

  // Helper function to convert date and time to ISO datetime string
  const convertToDateTime = (dateLabel: string, timeSlot: string): string => {
    // Find the selected date from our generated dates array
    const selectedDateObj = dates.find(d => d.label === dateLabel);
    
    if (!selectedDateObj) {
      // Fallback to tomorrow if date not found
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      return tomorrow.toISOString();
    }
    
    // Use the actual date from the calendar
    const appointmentDate = new Date(selectedDateObj.fullDate);
    
    // Extract time from slot (e.g., "9:00 AM - 9:30 AM" -> "9:00 AM")
    const startTime = timeSlot.split(' - ')[0];
    
    // Parse time
    const [time, period] = startTime.split(' ');
    const [hours, minutes] = time.split(':').map(Number);
    
    let hour24 = hours;
    if (period === 'PM' && hours !== 12) {
      hour24 = hours + 12;
    } else if (period === 'AM' && hours === 12) {
      hour24 = 0;
    }
    
    appointmentDate.setHours(hour24, minutes, 0, 0);
    
    return appointmentDate.toISOString();
  };

  const selectedDateObj = dates.find(d => d.label === selectedDate);

  // Mobile view - Step-based
  const MobileTimeSelection = () => (
    <div className="flex flex-col gap-4 pb-24">
      {/* Date Selection */}
      <div className="flex gap-3 overflow-x-auto pb-2 -mx-4 px-4">
        {dates.map((dateOption) => (
          <button
            key={dateOption.label}
            onClick={() => setSelectedDate(dateOption.label)}
            className={`flex flex-col gap-2 items-center justify-center min-w-[100px] px-4 py-3 rounded-lg shadow-sm text-center flex-shrink-0 ${
              selectedDate === dateOption.label
                ? 'bg-white border-2 border-[#ff5d2e]'
                : 'bg-white border border-[#ffe7df]'
            }`}
          >
            <p className="text-base font-medium text-black">{dateOption.label}</p>
            <p className="text-xs text-black/50">{dateOption.date}</p>
          </button>
        ))}
      </div>

      {/* Divider */}
      <div className="h-px bg-black/10" />

      {/* Time Slots */}
      <div className="flex flex-col gap-2">
        {timeSlots.map((time) => (
          <button
            key={time}
            onClick={() => setSelectedTime(time)}
            className={`w-full p-4 rounded-lg flex items-center justify-between ${
              selectedTime === time
                ? 'bg-[#ffe7df] border-2 border-[#ff5d2e]'
                : 'bg-white border border-black/10'
            }`}
          >
            <span className="font-medium text-black">{time}</span>
            <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
              selectedTime === time ? 'border-[#ff5d2e]' : 'border-black/30'
            }`}>
              {selectedTime === time && (
                <div className="w-3 h-3 rounded-full bg-[#ff5d2e]" />
              )}
            </div>
          </button>
        ))}
      </div>
    </div>
  );

  const MobileCheckout = () => (
    <div className="flex flex-col gap-6 pb-24">
      {/* Order Summary */}
      <div className="flex flex-col gap-4">
        <h3 className="text-lg font-semibold text-black">Order Summary</h3>
        <div className="bg-white rounded-lg p-4 flex items-center gap-3">
          <div className="w-12 h-12 rounded bg-[#ffe7df]" />
          <div className="flex-1">
            <p className="font-medium text-black">{orderDetails.service}</p>
            <p className="text-sm text-black/50">{selectedDateObj?.date} • {selectedTime}</p>
          </div>
          <button 
            onClick={() => setCurrentStep('time')}
            className="text-sm font-medium text-[#ff5d2e]"
          >
            Edit
          </button>
        </div>
      </div>

      {/* Divider */}
      <div className="h-px bg-black/10" />

      {/* Price Breakdown */}
      <div className="flex flex-col gap-4">
        <h3 className="text-lg font-semibold text-black">Price Breakdown</h3>
        <div className="flex flex-col gap-2 bg-white rounded-lg p-4">
          <div className="flex items-center justify-between text-sm">
            <span className="text-black/70">Service Fee</span>
            <span className="font-medium text-black">+LKR {orderDetails.serviceFee.toLocaleString()}</span>
          </div>
          {isLubeService && orderDetails.oilType && (
            <div className="flex items-center justify-between text-sm">
              <span className="text-black/70">{orderDetails.oilType}</span>
              <span className="font-medium text-black">+LKR {orderDetails.oilPrice.toLocaleString()}</span>
            </div>
          )}
          <div className="h-px bg-black/10 my-2" />
          <div className="flex items-center justify-between">
            <span className="font-bold text-black">Total</span>
            <span className="font-bold text-black">LKR {orderDetails.total.toLocaleString()}</span>
          </div>
        </div>
      </div>

      {/* Divider */}
      <div className="h-px bg-black/10" />

      {/* Details */}
      <div className="flex flex-col gap-2">
        <button className="bg-white rounded-lg p-4 flex items-center gap-3 hover:bg-[#fff7f5] transition-colors">
          <Car className="w-5 h-5" />
          <span className="flex-1 text-left text-sm font-medium text-black/70">Toyota Premio</span>
          <ChevronRight className="w-4 h-4 text-black/50" />
        </button>
        <button className="bg-white rounded-lg p-4 flex items-center gap-3 hover:bg-[#fff7f5] transition-colors">
          <Phone className="w-5 h-5" />
          <span className="flex-1 text-left text-sm font-medium text-black/70">{user?.phone || '+94 72 4523 299'}</span>
          <ChevronRight className="w-4 h-4 text-black/50" />
        </button>
        <button className="bg-white rounded-lg p-4 flex items-center gap-3 hover:bg-[#fff7f5] transition-colors">
          <Coins className="w-5 h-5" />
          <span className="flex-1 text-left text-sm font-medium text-black/70">Cash</span>
          <ChevronRight className="w-4 h-4 text-black/50" />
        </button>
      </div>
    </div>
  );

  return (
    <AppLayout showNav={false}>
      <div className="min-h-screen flex flex-col">
        {/* Header */}
        <div className="sticky top-0 bg-gradient-to-b from-[#fff7f5] to-transparent z-10 pb-4">
          <div className="flex items-center gap-4 px-4 py-3 lg:px-0">
            <button
              onClick={() => {
                if (currentStep === 'checkout') {
                  setCurrentStep('time');
                } else {
                  navigate(-1);
                }
              }}
              className="w-10 h-10 bg-white rounded-lg flex items-center justify-center shadow-sm hover:shadow-md transition-shadow"
            >
              <ArrowLeft className="w-5 h-5" />
            </button>
            <h1 className="text-xl lg:text-2xl font-semibold text-black">
              {currentStep === 'time' ? 'Choose a Time' : 'Checkout'}
            </h1>
          </div>

          {/* Step indicator - Mobile only */}
          <div className="lg:hidden flex items-center gap-2 px-4 mt-2">
            <div className={`flex-1 h-1 rounded-full ${currentStep === 'time' ? 'bg-[#ff5d2e]' : 'bg-[#ffe7df]'}`} />
            <div className={`flex-1 h-1 rounded-full ${currentStep === 'checkout' ? 'bg-[#ff5d2e]' : 'bg-[#ffe7df]'}`} />
          </div>
        </div>

        {/* Main content */}
        <div className="flex-1 max-w-6xl mx-auto w-full px-4 lg:px-6">
          {/* Mobile view - Step based */}
          <div className="lg:hidden">
            {currentStep === 'time' ? <MobileTimeSelection /> : <MobileCheckout />}
          </div>

          {/* Desktop view - Side by side */}
          <div className="hidden lg:grid lg:grid-cols-5 gap-8">
            {/* Left column - Time selection */}
            <div className="lg:col-span-3 flex flex-col gap-6">
              {/* Date Selection */}
              <div className="flex flex-col gap-4">
                <h3 className="text-lg font-semibold text-black flex items-center gap-2">
                  <Calendar className="w-5 h-5 text-[#ff5d2e]" />
                  Select Date
                </h3>
                <div className="flex gap-3 overflow-x-auto pb-2">
                  {dates.map((dateOption) => (
                    <button
                      key={dateOption.label}
                      onClick={() => setSelectedDate(dateOption.label)}
                      className={`flex flex-col gap-2 items-center justify-center min-w-[120px] px-4 py-4 rounded-lg shadow-sm text-center transition-all ${
                        selectedDate === dateOption.label
                          ? 'bg-[#ff5d2e] text-white'
                          : 'bg-white border border-[#ffe7df] hover:border-[#ff5d2e]'
                      }`}
                    >
                      <p className="text-base font-medium">{dateOption.label}</p>
                      <p className={`text-sm ${selectedDate === dateOption.label ? 'text-white/70' : 'text-black/50'}`}>
                        {dateOption.date}
                      </p>
                    </button>
                  ))}
                </div>
              </div>

              {/* Time Selection */}
              <div className="flex flex-col gap-4">
                <h3 className="text-lg font-semibold text-black flex items-center gap-2">
                  <Clock className="w-5 h-5 text-[#ff5d2e]" />
                  Select Time
                </h3>
                <div className="grid grid-cols-3 gap-3">
                  {timeSlots.map((time) => (
                    <button
                      key={time}
                      onClick={() => setSelectedTime(time)}
                      className={`p-3 rounded-lg text-center transition-all ${
                        selectedTime === time
                          ? 'bg-[#ff5d2e] text-white'
                          : 'bg-white border border-[#ffe7df] hover:border-[#ff5d2e]'
                      }`}
                    >
                      <span className="text-sm font-medium">{time}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Special Instructions */}
              {specialInstructions && (
                <div className="flex flex-col gap-2 p-4 bg-[#fff7f5] rounded-lg">
                  <p className="text-sm font-medium text-black/70">Special Instructions</p>
                  <p className="text-sm text-black">{specialInstructions}</p>
                </div>
              )}
            </div>

            {/* Right column - Checkout summary */}
            <div className="lg:col-span-2">
              <div className="sticky top-24 bg-white rounded-2xl shadow-lg p-6 flex flex-col gap-6">
                <h3 className="text-lg font-semibold text-black">Booking Summary</h3>

                {/* Service info */}
                <div className="flex items-center gap-3 p-3 bg-[#fff7f5] rounded-lg">
                  <div className="w-12 h-12 bg-[#ffe7df] rounded-lg" />
                  <div className="flex-1">
                    <p className="font-medium text-black">{orderDetails.service}</p>
                    <p className="text-sm text-black/50">{selectedDateObj?.date} • {selectedTime}</p>
                  </div>
                </div>

                {/* Price breakdown */}
                <div className="flex flex-col gap-3">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-black/70">Service Fee</span>
                    <span className="font-medium text-black">LKR {orderDetails.serviceFee.toLocaleString()}</span>
                  </div>
                  {isLubeService && orderDetails.oilType && (
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-black/70">{orderDetails.oilType}</span>
                      <span className="font-medium text-black">LKR {orderDetails.oilPrice.toLocaleString()}</span>
                    </div>
                  )}
                  <div className="h-px bg-black/10" />
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-black">Total</span>
                    <span className="text-xl font-bold text-[#ff5d2e]">LKR {orderDetails.total.toLocaleString()}</span>
                  </div>
                </div>

                {/* Details */}
                <div className="flex flex-col gap-2">
                  <button className="w-full p-3 bg-[#fff7f5] rounded-lg flex items-center gap-3 hover:bg-[#ffe7df] transition-colors">
                    <Car className="w-5 h-5 text-[#ff5d2e]" />
                    <span className="flex-1 text-left text-sm font-medium text-black">Toyota Premio</span>
                    <ChevronRight className="w-4 h-4 text-black/50" />
                  </button>
                  <button className="w-full p-3 bg-[#fff7f5] rounded-lg flex items-center gap-3 hover:bg-[#ffe7df] transition-colors">
                    <Phone className="w-5 h-5 text-[#ff5d2e]" />
                    <span className="flex-1 text-left text-sm font-medium text-black">{user?.phone || '+94 72 4523 299'}</span>
                    <ChevronRight className="w-4 h-4 text-black/50" />
                  </button>
                  <button className="w-full p-3 bg-[#fff7f5] rounded-lg flex items-center gap-3 hover:bg-[#ffe7df] transition-colors">
                    <Coins className="w-5 h-5 text-[#ff5d2e]" />
                    <span className="flex-1 text-left text-sm font-medium text-black">Pay by Cash</span>
                    <ChevronRight className="w-4 h-4 text-black/50" />
                  </button>
                </div>

                {/* Book button */}
                <button
                  onClick={handleBook}
                  disabled={isBooking}
                  className="w-full bg-[#ff5d2e] text-white py-4 rounded-xl font-semibold shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] hover:bg-[#e54d1e] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isBooking ? 'Booking...' : 'Confirm Booking'}
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
                {isBooking ? 'Booking...' : 'Confirm Booking'}
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
