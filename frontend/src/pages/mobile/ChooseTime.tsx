import { useState } from 'react';
import { ArrowLeft, Circle } from 'lucide-react';

export default function ChooseTime() {
  const [selectedDate, setSelectedDate] = useState('Tomorrow');
  const [selectedTime, setSelectedTime] = useState('9:00 AM - 9:30 AM');

  const dates = [
    { label: 'Tomorrow', date: 'Oct 26' },
    { label: 'Mon', date: 'Oct 27' },
    { label: 'Tue', date: 'Oct 28' },
    { label: 'Wed', date: 'Oct 29' },
    { label: 'Thu', date: 'Oct 30' },
    { label: 'Fri', date: 'Oct 31' },
    { label: 'Sat', date: 'Nov 1' },
  ];

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
    '6:00 PM - 6:30 PM',
    '6:30 PM - 7:00 PM',
    '7:00 PM - 7:30 PM',
    '7:30 PM - 8:00 PM',
    '8:00 PM - 8:30 PM',
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

      {/* Header */}
      <div className="flex flex-col px-4">
        <button className="w-10 h-10 rounded-lg flex items-start">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <div className="flex items-center">
          <h1 className="flex-1 text-[28px] font-semibold text-black">Choose a time</h1>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 flex flex-col gap-4 py-4">
        {/* Date Selection */}
        <div className="flex gap-3 px-4 overflow-x-auto">
          {dates.map((dateOption) => (
            <button
              key={dateOption.label}
              onClick={() => setSelectedDate(dateOption.label)}
              className={`flex flex-col gap-3 items-center justify-center min-w-[109px] px-4 py-2 rounded-lg shadow-sm text-center ${
                selectedDate === dateOption.label
                  ? 'bg-white border border-[#ff5d2e]'
                  : 'bg-white border border-[#ffe7df]'
              }`}
            >
              <p className="text-base font-medium text-black">{dateOption.label}</p>
              <p className="text-xs text-[#4b4b4b]">{dateOption.date}</p>
            </button>
          ))}
        </div>

        {/* Divider */}
        <div className="h-2 flex items-center justify-center py-1">
          <div className="h-px bg-black/10 w-full" />
        </div>

        {/* Time Slots */}
        <div className="flex-1 flex flex-col px-4 overflow-y-auto">
          <div className="flex flex-col overflow-hidden rounded-lg py-1">
            {timeSlots.map((time, idx) => (
              <div key={time}>
                <button
                  onClick={() => setSelectedTime(time)}
                  className="flex items-center gap-3 py-1 px-3 w-full shadow-sm"
                >
                  <div className="flex-1 flex flex-col justify-center">
                    <p className="text-base font-medium text-black">{time}</p>
                  </div>
                  <div className="w-11 h-11 flex items-center justify-center">
                    <Circle
                      className={`w-6 h-6 ${
                        selectedTime === time ? 'fill-[#ff5d2e] text-[#ff5d2e]' : 'text-black/20'
                      }`}
                    />
                  </div>
                </button>
                {idx < timeSlots.length - 1 && (
                  <div className="h-2 flex items-center justify-center py-1">
                    <div className="h-px bg-black/4 w-full" />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Bottom Buttons */}
      <div className="flex flex-col gap-2 px-4 pt-4">
        <button className="bg-[#ff5d2e] text-white h-12 rounded-2xl border border-white shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] flex items-center justify-center">
          <span className="text-base font-medium">Schedule</span>
        </button>
        <button className="bg-white border border-[#ffe7df] h-12 rounded-2xl flex items-center justify-center">
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
