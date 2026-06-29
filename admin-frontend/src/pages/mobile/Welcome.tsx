import { useState } from 'react';
import { X } from 'lucide-react';

export default function Welcome() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  return (
    <div className="flex flex-col h-screen w-full bg-gradient-to-b from-[#fff7f5] to-[#fbfbfb]">
      {/* Status Bar */}
      <div className="flex items-center justify-between px-4 pt-5 pb-5 w-full">
        <div className="font-semibold text-[17px]">9:41</div>
        <div className="flex items-center gap-2">
          <div className="w-5 h-3">{/* Cellular */}</div>
          <div className="w-4 h-3">{/* Wifi */}</div>
          <div className="w-7 h-3">{/* Battery */}</div>
        </div>
      </div>

      {/* Spacer */}
      <div className="flex-1" />

      {/* Bottom Sheet */}
      <div className="bg-white rounded-t-2xl px-4 py-0 pb-0 flex flex-col gap-4">
        {/* Grabber */}
        <div className="flex items-center justify-center pt-[5px] pb-0">
          <div className="w-9 h-[5px] bg-[#cfcfcf] rounded-full" />
        </div>
        
        {/* Close Button */}
        <div className="flex justify-end">
          <button className="w-11 h-11 bg-[#f5f5f5] rounded-lg flex items-center justify-center">
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Welcome Message */}
        <div className="flex flex-col gap-4 py-1">
          <h1 className="text-[28px] font-semibold text-black text-center">
            Welcome Back to Servio
          </h1>
          <p className="text-base text-black">
            Log in to manage your vehicle's service.
          </p>
        </div>

        {/* Input Fields */}
        <div className="flex flex-col gap-1 w-full">
          <div className="flex flex-col gap-2 py-2">
            <div className="bg-white border border-black/10 rounded-lg p-2 min-h-[59px] flex items-center">
              <input
                type="email"
                placeholder="Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full text-base font-medium text-black/50 bg-transparent border-none outline-none placeholder:text-black/50"
              />
            </div>
          </div>
          <div className="flex flex-col gap-2 py-2">
            <div className="bg-white border border-black/10 rounded-lg p-2 min-h-[59px] flex items-center">
              <input
                type="password"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full text-base font-medium text-black/50 bg-transparent border-none outline-none placeholder:text-black/50"
              />
            </div>
          </div>
        </div>

        {/* Login Button */}
        <button className="w-full bg-[#ff5d2e] text-white py-3 px-3 rounded-lg font-semibold text-base border border-white shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)]">
          Log In
        </button>

        {/* Forgot Password */}
        <div className="flex items-center justify-center py-1">
          <p className="text-sm text-black/70 underline text-center">
            Forgot Password?
          </p>
        </div>

        {/* Divider */}
        <div className="flex items-center gap-2 py-1">
          <div className="flex-1 h-px bg-black/10" />
          <div className="text-sm font-medium text-black text-center">or</div>
          <div className="flex-1 h-px bg-black/10" />
        </div>

        {/* Social Login */}
        <div className="flex flex-col gap-4">
          <button className="w-full bg-white border border-[#ffe7df] rounded-lg py-3 px-3 flex items-center justify-center gap-2">
            <div className="w-6 h-6">{/* Google Icon */}</div>
            <span className="text-base font-medium text-black">Log In with Google</span>
          </button>
          <button className="w-full bg-white border border-[#ffe7df] rounded-lg py-3 px-3 flex items-center justify-center gap-2">
            <div className="w-6 h-6">{/* Facebook Icon */}</div>
            <span className="text-base font-medium text-black">Log In with Facebook</span>
          </button>
        </div>

        {/* Home Indicator */}
        <div className="h-[34px] flex items-end justify-center pb-2">
          <div className="w-36 h-[5px] bg-black rounded-full" />
        </div>
      </div>
    </div>
  );
}
