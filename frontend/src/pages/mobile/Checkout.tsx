import { ArrowLeft, Car, Phone, Coins, ChevronRight } from 'lucide-react';

export default function Checkout() {
  const orderDetails = {
    service: 'Lubricant Service',
    date: 'Tomorrow (Oct 26)',
    time: '9:00 AM - 9:30 AM',
    serviceFee: 1500,
    oilType: 'Standard/Conventional Oil',
    oilPrice: 4000,
    total: 5500,
  };

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

      {/* Header */}
      <div className="flex flex-col px-4">
        <button className="w-10 h-10 rounded-lg flex items-start">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <div className="flex items-center">
          <h1 className="flex-1 text-[28px] font-semibold text-black">Checkout</h1>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 flex flex-col py-4 overflow-y-auto">
        {/* Order Summary */}
        <div className="flex flex-col gap-4 px-4">
          <p className="text-lg font-semibold text-black">Order Summary</p>
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 rounded bg-gray-200" />
            <p className="flex-1 text-lg font-medium text-[#4b4b4b]">{orderDetails.service}</p>
          </div>
          <div className="flex items-end gap-2">
            <div className="flex-1 flex items-center gap-1">
              <p className="text-base font-semibold text-[#4b4b4b]">{orderDetails.date}</p>
              <div className="w-1 h-1 rounded-full bg-[#4b4b4b]" />
              <p className="text-base font-semibold text-[#4b4b4b]">{orderDetails.time}</p>
            </div>
            <p className="text-sm font-semibold text-black underline">Edit</p>
          </div>
        </div>

        {/* Divider */}
        <div className="h-2 flex items-center justify-center py-1">
          <div className="h-px bg-black/10 w-full" />
        </div>

        {/* Price Breakdown */}
        <div className="flex flex-col gap-4 px-4">
          <p className="text-lg font-semibold text-black">Price Breakdown</p>
          <div className="flex flex-col gap-1 overflow-hidden rounded-lg py-1">
            <div className="flex items-center gap-3 p-1 shadow-sm font-medium">
              <p className="flex-1 text-sm text-[#4b4b4b]">Service Fee</p>
              <p className="text-xs text-black">+LKR {orderDetails.serviceFee.toLocaleString()}</p>
            </div>
            <div className="flex items-center gap-3 p-1 shadow-sm font-medium">
              <p className="flex-1 text-sm text-[#4b4b4b]">{orderDetails.oilType}</p>
              <p className="text-xs text-black">+LKR {orderDetails.oilPrice.toLocaleString()}</p>
            </div>
            <div className="flex items-center gap-3 p-1 shadow-sm">
              <p className="flex-1 text-sm font-bold text-[#4b4b4b]">Total</p>
              <p className="text-xs font-medium text-black">
                LKR {orderDetails.total.toLocaleString()}
              </p>
            </div>
          </div>
        </div>

        {/* Divider */}
        <div className="h-2 flex items-center justify-center py-1">
          <div className="h-px bg-black/10 w-full" />
        </div>

        {/* Details */}
        <div className="flex flex-col gap-1 overflow-hidden px-4 py-1 rounded-lg">
          <div className="flex items-center gap-3 py-1 shadow-sm">
            <Car className="w-6 h-6" />
            <div className="flex-1 flex flex-col justify-center font-medium text-sm text-[#4b4b4b]">
              <p>Toyota Premio</p>
            </div>
            <ChevronRight className="w-4 h-4" />
          </div>
          <div className="flex items-center gap-3 py-1 shadow-sm">
            <Phone className="w-6 h-6" />
            <div className="flex-1 flex flex-col justify-center font-medium text-sm text-[#4b4b4b]">
              <p>+94 72 4523 299</p>
            </div>
            <ChevronRight className="w-4 h-4" />
          </div>
        </div>

        {/* Divider */}
        <div className="h-2 flex items-center justify-center py-1">
          <div className="h-px bg-black/10 w-full" />
        </div>

        {/* Payment Method */}
        <div className="flex items-center gap-3 px-4 py-1 shadow-sm">
          <Coins className="w-6 h-6" />
          <div className="flex-1 flex flex-col justify-center font-medium text-sm text-[#4b4b4b]">
            <p>Cash</p>
          </div>
          <ChevronRight className="w-4 h-4" />
        </div>
      </div>

      {/* Bottom Buttons */}
      <div className="flex flex-col gap-2 px-4 pt-4">
        <button className="bg-[#ff5d2e] text-white h-12 rounded-2xl border border-white shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] flex items-center justify-center">
          <span className="text-base font-medium">Book</span>
        </button>
        <button className="bg-white border border-[#ffe7df] rounded-2xl p-3 flex items-center justify-center">
          <span className="text-base font-medium text-black">Cancel</span>
        </button>
      </div>

      {/* Home Indicator */}
      <div className="h-[34px] flex items-end justify-center pb-2">
        <div className="w-36 h-[5px] bg-black rounded-full" />
      </div>
    </div>
  );
}
