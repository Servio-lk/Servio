import { useState } from 'react';
import { ArrowLeft, Check, Square } from 'lucide-react';

export default function ServiceDetail() {
  const [selectedOil] = useState('standard');
  const [specialInstructions, setSpecialInstructions] = useState('');

  const oilOptions = [
    { id: 'standard', name: 'Standard/Conventional Oil', price: '+LKR 4,000' },
    { id: 'synthetic-blend', name: 'Synthetic Blend Oil', price: '+LKR 4,000' },
    { id: 'full-synthetic', name: 'Full Synthetic Oil', price: '+LKR 4,000' },
  ];

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

      {/* Service Image */}
      <div className="w-full aspect-[375/185] overflow-hidden p-2 relative">
        <img
          src="/service images/Lubricant Service.jpg"
          alt="Lubricant Service"
          className="w-full h-full object-cover rounded"
        />
        <button className="absolute top-2 left-2 bg-white w-10 h-10 rounded-lg flex items-center justify-center">
          <ArrowLeft className="w-6 h-6" />
        </button>
      </div>

      {/* Content */}
      <div className="flex-1 flex flex-col gap-4 py-4 overflow-y-auto">
        {/* Description */}
        <div className="flex flex-col gap-2 px-4">
          <p className="text-xl font-semibold text-black">Lubricant Service</p>
          <p className="text-base font-semibold text-[#4b4b4b]">LKR 1,500.00</p>
          <div className="flex flex-col gap-2 text-sm text-black">
            <p>
              Protect your engine and maintain peak performance with our professional oil change
              service. We only use high-quality lubricants and filters, ensuring your vehicle runs
              smoothly and efficiently.
            </p>
            <p className="text-sm font-medium underline">Show more</p>
          </div>
        </div>

        {/* Divider */}
        <div className="h-2 flex items-center justify-center py-1">
          <div className="h-px bg-black/10 w-full" />
        </div>

        {/* Pricing and Oil Selection */}
        <div className="flex flex-col gap-4 px-4">
          <p className="text-base font-semibold text-black">Pricing and Oil Selection</p>
          <div className="bg-white rounded-lg overflow-hidden py-1">
            {oilOptions.map((option, idx) => (
              <div key={option.id}>
                <div className="flex items-center gap-3 py-1 px-3">
                  <div className="flex-1 flex flex-col gap-1 justify-center font-medium text-black">
                    <p className="text-base">{option.name}</p>
                    <p className="text-xs">{option.price}</p>
                  </div>
                  <div className="w-11 h-11 flex items-center justify-center">
                    {selectedOil === option.id ? (
                      <Check className="w-6 h-6 text-[#ff5d2e]" />
                    ) : (
                      <Square className="w-6 h-6 text-black/20" />
                    )}
                  </div>
                </div>
                {idx < oilOptions.length - 1 && (
                  <div className="h-2 flex items-center justify-center py-1">
                    <div className="h-px bg-black/4 w-full" />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Divider */}
        <div className="h-2 flex items-center justify-center py-1">
          <div className="h-px bg-black/10 w-full" />
        </div>

        {/* Special Instructions */}
        <div className="flex flex-col gap-4 px-4">
          <p className="text-base font-semibold text-black">Special Instructions</p>
          <div className="bg-white rounded-lg shadow-sm h-[107px] p-2">
            <textarea
              placeholder="Add a note"
              value={specialInstructions}
              onChange={(e) => setSpecialInstructions(e.target.value)}
              className="w-full h-full text-xs font-medium text-[#4b4b4b] bg-transparent border-none outline-none resize-none placeholder:text-[#4b4b4b]"
            />
          </div>
        </div>
      </div>

      {/* Bottom Button */}
      <div className="flex flex-col px-4 pt-4">
        <button className="bg-[#ff5d2e] text-white h-12 rounded-2xl border border-white shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] flex items-center justify-center gap-2">
          <span className="text-base font-medium">Book now</span>
          <div className="w-1 h-1 rounded-full bg-white" />
          <span className="text-base font-medium">LKR 5,500.00</span>
        </button>
      </div>

      {/* Home Indicator */}
      <div className="h-[34px] flex items-end justify-center pb-2">
        <div className="w-36 h-[5px] bg-black rounded-full" />
      </div>
    </div>
  );
}
