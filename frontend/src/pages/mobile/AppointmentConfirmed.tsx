import { ArrowLeft, Car, Phone, Coins, AlertTriangle } from 'lucide-react';

export default function AppointmentConfirmed() {
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
          <h1 className="flex-1 text-[28px] font-semibold text-black">Appointment Confirmed!</h1>
        </div>
      </div>

      {/* Content */}
      <div className="flex flex-col gap-6 p-4 rounded-2xl">
        {/* QR Code Section */}
        <div className="flex flex-col gap-4 items-center">
          <div className="flex items-start w-full">
            <p className="flex-1 text-lg font-bold text-black text-center leading-snug">
              Chamal Dissanayake
            </p>
          </div>
          <div className="flex items-center justify-center gap-2 py-1">
            <p className="text-xs font-medium text-[#4b4b4b]">Appointment ID:</p>
            <div className="border border-[#d7d7d7] rounded-2xl px-2 py-1 flex items-center gap-1">
              <p className="text-xs font-medium text-black">#SL-GOV-2025-00483</p>
            </div>
          </div>
          <div className="w-64 h-64 bg-white border-2 border-[#4b4b4b] rounded-lg flex items-center justify-center">
            {/* QR Code placeholder */}
            <div className="w-56 h-56 bg-gray-200" />
          </div>
        </div>

        {/* Service Details */}
        <div className="flex gap-2 items-start">
          <p className="font-bold text-base text-[#4b4b4b]">Service:</p>
          <div className="flex-1 flex flex-col gap-1 items-center justify-center font-medium">
            <p className="text-base text-black tracking-wide w-full">Lubricant Service</p>
            <p className="h-[17px] text-sm text-[#4b4b4b] w-full">Standard/Conventional Oil</p>
          </div>
        </div>

        {/* Date & Time */}
        <div className="bg-[#ffe7df] flex gap-4 items-start p-2 rounded-lg">
          <div className="bg-white p-2 rounded">
            <AlertTriangle className="w-6 h-6 text-black" />
          </div>
          <div className="flex flex-col gap-1 font-medium w-[237px]">
            <p className="text-xs text-[#4b4b4b]">DATE & TIME</p>
            <p className="text-base text-black tracking-wide leading-5">
              Oct 26 · 9:00 AM - 9:30 AM
            </p>
          </div>
        </div>

        {/* Additional Info */}
        <div className="flex flex-col gap-1 overflow-hidden py-1 rounded-lg">
          <div className="flex items-center gap-3 p-1 shadow-sm">
            <Car className="w-6 h-6" />
            <div className="flex-1 flex flex-col justify-center font-medium text-sm text-[#4b4b4b]">
              <p>Toyota Premio</p>
            </div>
          </div>
          <div className="flex items-center gap-3 p-1 shadow-sm">
            <Phone className="w-6 h-6" />
            <div className="flex-1 flex flex-col justify-center font-medium text-sm text-[#4b4b4b]">
              <p>+94 72 4523 299</p>
            </div>
          </div>
          <div className="bg-white flex items-center gap-3 p-1">
            <Coins className="w-6 h-6" />
            <div className="flex-1 flex flex-col justify-center font-medium text-sm text-[#4b4b4b]">
              <p>Pay by Cash</p>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom Button */}
      <div className="flex flex-col px-4 pt-4">
        <button className="bg-white border border-[#ffe7df] rounded-2xl p-3 flex items-center justify-center">
          <span className="text-base font-medium text-black">Add to calendar</span>
        </button>
      </div>

      {/* Home Indicator */}
      <div className="h-[34px] flex items-end justify-center pb-2">
        <div className="w-36 h-[5px] bg-black rounded-full" />
      </div>
    </div>
  );
}
