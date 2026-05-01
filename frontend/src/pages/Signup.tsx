import { useState, useRef, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { supabaseAuth } from "@/services/supabaseAuth";
import { apiService } from "@/services/api";
import { useAuth } from "@/contexts/AuthContext";
import LogoImage from "/ServioLogo.png";
import GarageImage from "@/assets/images/Garage image.png";
import { Car, CarFront, Bike, Truck, Bus } from "lucide-react";

// ----------------------------------------------------------------------
// Reusable Sub-components
// ----------------------------------------------------------------------

function SignupLogo() {
  return (
    <div className="flex flex-col items-center justify-center w-full mb-4 md:mb-6">
      <img src={LogoImage} alt="Servio Logo" className="h-16 md:h-20 lg:h-24 w-auto" />
    </div>
  );
}

function SignupHeader({
  step,
  title,
  subtitle,
}: {
  step: number;
  title: string;
  subtitle: string;
}) {
  return (
    <div className="flex flex-col items-center text-center w-full">
      <SignupLogo />
      <div className="p-2 bg-white rounded-sm inline-flex flex-col justify-start items-start gap-2 overflow-hidden mb-1">
        <div className="self-stretch rounded-sm inline-flex justify-start items-center gap-1 overflow-hidden">
          {[1, 2, 3, 4].map((i) => (
            <div
              key={i}
              className={`w-10 h-1 relative rounded transition-colors ${
                i <= step ? "bg-[#FF5D2E]" : "bg-black/20"
              }`}
            />
          ))}
        </div>
      </div>
      <h1 className="font-semibold text-xl md:text-2xl lg:text-3xl text-black">
        {title}
      </h1>
      <p className="text-sm md:text-base text-gray-700 mt-2">
        {subtitle}
      </p>
    </div>
  );
}

function CustomInput({
  value,
  onChange,
  placeholder,
  type = "text",
  maxLength,
}: {
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  placeholder: string;
  type?: string;
  maxLength?: number;
}) {
  return (
    <div className="w-full">
      <Input
        type={type}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        maxLength={maxLength}
        className="h-11 md:h-12 lg:h-[48px] rounded-lg border border-gray-200 px-3 md:px-4 text-sm md:text-base focus-visible:ring-2 focus-visible:ring-[#FF5D2E]"
      />
    </div>
  );
}

function PrimaryButton({ onClick, disabled, label }: { onClick: () => void; disabled?: boolean; label: string }) {
  return (
    <Button
      onClick={onClick}
      disabled={disabled}
      className="w-full h-10 md:h-11 lg:h-12 bg-[#FF5D2E] hover:bg-[#FF5D2E]/90 text-white font-semibold text-sm md:text-base rounded-lg shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] disabled:opacity-50 disabled:cursor-not-allowed"
    >
      {disabled ? "Please wait..." : label}
    </Button>
  );
}

// ----------------------------------------------------------------------
// Main Component
// ----------------------------------------------------------------------

export default function Signup() {
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();

  // Navigation State
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    // If the user visits /signup while already logged in, and isn't currently onboarding, redirect to home
    if (isAuthenticated && step === 1) {
      navigate('/home');
    }
  }, [isAuthenticated, step, navigate]);

  // Step 1 State: Account Details
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  
  // Step 2 State: OTP
  const [otp, setOtp] = useState(["", "", "", "", "", ""]);
  const otpRefs = [useRef<HTMLInputElement>(null), useRef<HTMLInputElement>(null), useRef<HTMLInputElement>(null), useRef<HTMLInputElement>(null), useRef<HTMLInputElement>(null), useRef<HTMLInputElement>(null)];
  const [resendCountdown, setResendCountdown] = useState(60);

  // Step 3 State: Vehicle
  const vehicleTypes = [
    { label: "Car", icon: <Car size={24} /> },
    { label: "SUV", icon: <CarFront size={24} /> },
    { label: "Bike", icon: <Bike size={24} /> },
    { label: "Van", icon: <Bus size={24} /> }, // approximate icon
    { label: "Truck", icon: <Truck size={24} /> },
    { label: "Bus", icon: <Bus size={24} /> },
  ];
  const [vehicleType, setVehicleType] = useState(0);
  const [makeModel, setMakeModel] = useState("");
  const [year, setYear] = useState("");
  const [registration, setRegistration] = useState("");
  const [nickname, setNickname] = useState("");

  // Step 4 State: Mileage
  const [mileage, setMileage] = useState("");
  const [lastServiceDate, setLastServiceDate] = useState("");

  // --- OTP Timer Effect ---
  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    if (step === 2 && resendCountdown > 0) {
      timer = setInterval(() => setResendCountdown((c) => c - 1), 1000);
    }
    return () => clearInterval(timer);
  }, [step, resendCountdown]);

  // --- Handlers ---
  const handleCreateAccount = async () => {
    if (!name || !email || !phone || !password) {
      toast.error("Please fill in all required fields");
      return;
    }
    if (password.length < 8) {
      toast.error("Password must be at least 8 characters");
      return;
    }

    setLoading(true);
    try {
      const { error } = await supabaseAuth.signUp({
        email,
        password,
        fullName: name,
        phone,
      });

      if (error) throw new Error(error.message);

      toast.success("Verification code sent. Please check your email.");
      setStep(2);
      setResendCountdown(60);
    } catch (err: any) {
      console.error(err);
      toast.error(err.message || "Failed to create account. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async (codeStr?: string) => {
    const code = codeStr || otp.join("");
    if (code.length < 6) {
      toast.error("Please enter the full 6-digit code");
      return;
    }

    setLoading(true);
    try {
      const { error } = await supabaseAuth.verifyEmailOtp(email, code);
      if (error) throw new Error(error.message);

      toast.success("Email verified!");
      setStep(3);
    } catch (err: any) {
      console.error(err);
      toast.error(err.message || "Invalid code. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleResendOtp = async () => {
    if (resendCountdown > 0) return;
    try {
      const { error } = await supabaseAuth.resendEmailOtp(email);
      if (error) throw new Error(error.message);
      toast.success("Verification code resent!");
      setResendCountdown(60);
    } catch (err: any) {
      console.error(err);
      toast.error("Failed to resend code.");
    }
  };

  const handleNextVehicle = () => {
    if (!makeModel) {
      toast.error("Please enter make & model");
      return;
    }
    if (!year || isNaN(Number(year)) || Number(year) < 1900 || Number(year) > 2030) {
      toast.error("Enter a valid year");
      return;
    }
    if (!registration) {
      toast.error("Please enter registration number");
      return;
    }
    setStep(4);
  };

  const handleFinishSetup = async () => {
    setLoading(true);
    try {
      const parts = makeModel.split(/\s+/).filter(Boolean);
      const make = parts[0];
      const model = parts.length > 1 ? parts.slice(1).join(" ") : parts[0];

      await apiService.createVehicle({
        make,
        model,
        year: parseInt(year),
        licensePlate: registration,
      });

      toast.success("Setup complete! Welcome to Servio.");
      navigate("/home");
    } catch (err: any) {
      console.error("Error saving vehicle:", err);
      toast.error("Failed to save vehicle. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleSkip = () => {
    navigate("/home");
  };

  // --- Step Content Renders ---
  
  const renderStep1 = () => (
    <div className="flex flex-col gap-3 md:gap-4 mt-4 md:mt-6 lg:mt-8 w-full">
      <div className="w-full">
        <label className="text-sm font-medium mb-1.5 block text-left">Full Name:</label>
        <CustomInput value={name} onChange={(e) => setName(e.target.value)} placeholder="Chamira Fernando" />
      </div>
      <div className="w-full">
        <label className="text-sm font-medium mb-1.5 block text-left">Email Address:</label>
        <CustomInput value={email} onChange={(e) => setEmail(e.target.value)} placeholder="name@example.com" type="email" />
      </div>
      <div className="w-full">
        <label className="text-sm font-medium mb-1.5 block text-left">Phone Number:</label>
        <CustomInput value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="07X XXX XXXX" type="tel" maxLength={10} />
      </div>
      <div className="w-full">
        <label className="text-sm font-medium mb-1.5 block text-left">Password:</label>
        <CustomInput value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Password" type="password" />
        <p className="text-xs text-gray-500 mt-1 text-left">Minimum 8 characters.</p>
      </div>

      <div className="mt-2 w-full">
        <PrimaryButton label="Create Account" onClick={handleCreateAccount} disabled={loading} />
      </div>

      <div className="mt-2 flex justify-center w-full">
        <p className="text-sm text-gray-600">
          Already have an account?{" "}
          <button onClick={() => navigate("/login")} className="text-[#FF5D2E] hover:underline font-semibold">
            Sign In
          </button>
        </p>
      </div>
    </div>
  );

  const renderStep2 = () => {
    return (
      <div className="flex flex-col items-center mt-4 md:mt-6 lg:mt-8 w-full">
        <div className="flex gap-2 justify-center mb-6 w-full">
          {otp.map((digit, i) => (
            <input
              key={i}
              ref={otpRefs[i]}
              type="text"
              inputMode="numeric"
              maxLength={1}
              value={digit}
              onChange={(e) => {
                const val = e.target.value.replace(/\D/g, "");
                const newOtp = [...otp];
                newOtp[i] = val;
                setOtp(newOtp);

                if (val && i < 5) {
                  otpRefs[i + 1].current?.focus();
                } else if (!val && i > 0) {
                  otpRefs[i - 1].current?.focus();
                }

                if (val && i === 5) {
                  const fullCode = newOtp.join("");
                  if (fullCode.length === 6) {
                    handleVerifyOtp(fullCode);
                  }
                }
              }}
              onKeyDown={(e) => {
                if (e.key === "Backspace" && !otp[i] && i > 0) {
                  otpRefs[i - 1].current?.focus();
                }
              }}
              className="w-12 h-14 text-center text-2xl font-semibold border-2 border-[#FFE7DF] bg-[#FFE7DF] rounded-lg focus:outline-none focus:border-[#FF5D2E]"
            />
          ))}
        </div>
        
        <p className="text-sm text-gray-600 mb-8 text-center">
          Didn't get the code?{" "}
          {resendCountdown > 0 ? (
            <span className="text-gray-400">Resend it ({resendCountdown.toString().padStart(2, "0")}s)</span>
          ) : (
            <button onClick={handleResendOtp} className="text-[#FF5D2E] hover:underline">
              Resend it
            </button>
          )}
        </p>

        <PrimaryButton label="Verify & Continue" onClick={() => handleVerifyOtp()} disabled={loading} />
      </div>
    );
  };

  const renderStep3 = () => (
    <div className="flex flex-col gap-3 md:gap-4 mt-4 md:mt-6 lg:mt-8 w-full">
      <div className="w-full">
        <label className="text-sm font-medium mb-1.5 block text-left">Vehicle Type:</label>
        <div className="grid grid-cols-3 gap-3">
          {vehicleTypes.map((v, i) => (
            <button
              key={i}
              onClick={() => setVehicleType(i)}
              className={`flex items-center justify-center gap-2 p-3 rounded-lg border transition-colors ${
                vehicleType === i
                  ? "bg-[#FF5D2E] text-white border-[#FF5D2E]"
                  : "bg-[#FFE7DF] text-black border-transparent hover:bg-[#FFD4C5]"
              }`}
            >
              {v.icon}
              <span className="text-sm font-medium">{v.label}</span>
            </button>
          ))}
        </div>
      </div>

      <div className="w-full">
        <label className="text-sm font-medium mb-1.5 block text-left">Vehicle Make & Model:</label>
        <CustomInput value={makeModel} onChange={(e) => setMakeModel(e.target.value)} placeholder="Toyota Corolla" />
      </div>
      <div className="w-full">
        <label className="text-sm font-medium mb-1.5 block text-left">Vehicle Year:</label>
        <CustomInput value={year} onChange={(e) => setYear(e.target.value)} placeholder="2019" type="number" />
      </div>
      <div className="w-full">
        <label className="text-sm font-medium mb-1.5 block text-left">Vehicle Registration No.:</label>
        <CustomInput value={registration} onChange={(e) => setRegistration(e.target.value)} placeholder="CBA-1234" />
      </div>
      <div className="w-full">
        <label className="text-sm font-medium mb-1.5 block text-left">Vehicle Nickname (Optional):</label>
        <CustomInput value={nickname} onChange={(e) => setNickname(e.target.value)} placeholder="e.g., The Daily Commuter" />
      </div>

      <div className="mt-2 w-full">
        <PrimaryButton label="Next Step" onClick={handleNextVehicle} />
      </div>
    </div>
  );

  const renderStep4 = () => (
    <div className="flex flex-col gap-3 md:gap-4 mt-4 md:mt-6 lg:mt-8 w-full">
      <div className="w-full">
        <label className="text-sm font-medium mb-1.5 block text-left">Current Mileage (Optional):</label>
        <CustomInput value={mileage} onChange={(e) => setMileage(e.target.value)} placeholder="45,000 km" type="number" />
        <p className="text-xs text-gray-500 mt-1 text-left">A rough estimate is fine!</p>
      </div>
      <div className="w-full">
        <label className="text-sm font-medium mb-1.5 block text-left">Last Service Date (Optional):</label>
        <CustomInput value={lastServiceDate} onChange={(e) => setLastServiceDate(e.target.value)} placeholder="YYYY-MM-DD" type="date" />
      </div>

      <div className="mt-2 flex flex-col gap-3 w-full">
        <PrimaryButton label="Finish Setup" onClick={handleFinishSetup} disabled={loading} />
        <Button
          onClick={handleSkip}
          disabled={loading}
          variant="outline"
          className="w-full h-10 md:h-11 lg:h-12 border-gray-300 text-gray-700 hover:bg-gray-50 font-semibold text-sm md:text-base rounded-lg"
        >
          Skip this for now
        </Button>
      </div>
    </div>
  );

  // --- Headers mapping ---
  const stepHeaders = [
    { title: "Let's get you on the road", subtitle: "Create your account to easily book services and track your vehicle's health." },
    { title: "Check your inbox", subtitle: `We sent a 6-digit code to ${email ? email.replace(/(?<=.).(?=[^@]*?.@)/g, "*") : "your email"}. Enter it below to verify your account.` },
    { title: "Add your primary vehicle", subtitle: "Tell us what you drive so we can fetch the right service schedules and parts." },
    { title: "Where are we starting?", subtitle: "Add your current stats so we can remind you when your next service is due." },
  ];

  return (
    <div className="flex h-screen w-full bg-white overflow-hidden fixed inset-0">
      {/* Left side - Form */}
      <div className="flex-1 overflow-y-auto bg-white">
        <div className="min-h-full flex flex-col items-center justify-center p-4 sm:p-6 md:p-8">
          <div className="w-full max-w-md py-4">
            <SignupHeader
              step={step}
              title={stepHeaders[step - 1].title}
              subtitle={stepHeaders[step - 1].subtitle}
            />

            {step === 1 && renderStep1()}
            {step === 2 && renderStep2()}
            {step === 3 && renderStep3()}
            {step === 4 && renderStep4()}
          </div>
        </div>
      </div>

      {/* Right side - Image */}
      <div className="hidden lg:block w-[500px] xl:w-[690px] h-full relative">
        <img
          src={GarageImage}
          alt="Garage"
          className="w-full h-full object-cover"
        />
      </div>
    </div>
  );
}
