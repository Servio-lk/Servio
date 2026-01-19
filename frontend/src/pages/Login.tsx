import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { apiService } from "@/services/api";
import LogoImage from "@/assets/images/Logo.svg";
import GarageImage from "@/assets/images/Garage image.png";

function LoginLogo() {
  return (
    <div className="flex flex-col items-center justify-center w-full mb-4 md:mb-6">
      <img src={LogoImage} alt="Servio Logo" className="h-16 md:h-20 lg:h-24 w-auto" />
    </div>
  );
}

function LoginHeader() {
  return (
    <div className="flex flex-col gap-2 md:gap-3 items-center text-center w-full">
      <LoginLogo />
      <h1 className="font-semibold text-xl md:text-2xl lg:text-3xl text-black">
        Welcome Back to Servio
      </h1>
      <p className="text-sm md:text-base text-gray-700">
        Log in to manage your vehicle's service.
      </p>
    </div>
  );
}

function EmailInput({ 
  value, 
  onChange 
}: { 
  value: string; 
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void 
}) {
  return (
    <div className="w-full">
      <Input
        type="email"
        value={value}
        onChange={onChange}
        placeholder="Email"
        className="h-11 md:h-12 lg:h-[59px] rounded-lg border border-gray-200 px-3 md:px-4 text-sm md:text-base focus-visible:ring-2 focus-visible:ring-[#FF5D2E]"
      />
    </div>
  );
}

function PasswordInput({ 
  value, 
  onChange 
}: { 
  value: string; 
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void 
}) {
  return (
    <div className="w-full">
      <Input
        type="password"
        value={value}
        onChange={onChange}
        placeholder="Password"
        className="h-11 md:h-12 lg:h-[59px] rounded-lg border border-gray-200 px-3 md:px-4 text-sm md:text-base focus-visible:ring-2 focus-visible:ring-[#FF5D2E]"
      />
    </div>
  );
}

function LoginButton({ onClick, disabled }: { onClick: () => void; disabled?: boolean }) {
  return (
    <Button
      onClick={onClick}
      disabled={disabled}
      className="w-full h-10 md:h-11 lg:h-12 bg-[#FF5D2E] hover:bg-[#FF5D2E]/90 text-white font-semibold text-sm md:text-base rounded-lg shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] disabled:opacity-50 disabled:cursor-not-allowed"
    >
      {disabled ? "Logging in..." : "Log In"}
    </Button>
  );
}

function ForgotPassword() {
  return (
    <div className="flex justify-center w-full">
      <button className="text-xs md:text-sm text-gray-600 hover:text-gray-900 underline">
        Forgot Password?
      </button>
    </div>
  );
}

function OrDivider() {
  return (
    <div className="flex items-center gap-3 md:gap-4 w-full">
      <Separator className="flex-1 bg-gray-300" />
      <span className="text-xs md:text-sm text-gray-600 font-medium">or</span>
      <Separator className="flex-1 bg-gray-300" />
    </div>
  );
}

function GoogleIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
      <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
      <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
      <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
      <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
    </svg>
  );
}

function FacebookIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
      <path d="M24 12c0-6.627-5.373-12-12-12S0 5.373 0 12c0 5.99 4.388 10.954 10.125 11.854V15.47H7.078V12h3.047V9.356c0-3.007 1.792-4.668 4.533-4.668 1.312 0 2.686.234 2.686.234v2.953H15.83c-1.491 0-1.956.925-1.956 1.874V12h3.328l-.532 3.469h-2.796v8.385C19.612 22.954 24 17.99 24 12z" fill="#1877F2"/>
      <path d="M16.671 15.469L17.203 12h-3.328V9.749c0-.949.465-1.874 1.956-1.874h1.513V4.922s-1.374-.234-2.686-.234c-2.741 0-4.533 1.661-4.533 4.668V12H7.078v3.469h3.047v8.385a12.09 12.09 0 003.75 0V15.47h2.796z" fill="#fff"/>
    </svg>
  );
}

function GoogleLoginButton({ onClick }: { onClick: () => void }) {
  return (
    <Button
      onClick={onClick}
      variant="outline"
      className="w-full h-10 md:h-11 lg:h-12 bg-white hover:bg-gray-50 text-black font-medium text-sm md:text-base rounded-lg border border-[#FFE7DF] flex items-center justify-center gap-2"
    >
      <GoogleIcon />
      <span className="hidden sm:inline">Log In with Google</span>
      <span className="sm:hidden">Google</span>
    </Button>
  );
}

function FacebookLoginButton({ onClick }: { onClick: () => void }) {
  return (
    <Button
      onClick={onClick}
      variant="outline"
      className="w-full h-10 md:h-11 lg:h-12 bg-white hover:bg-gray-50 text-black font-medium text-sm md:text-base rounded-lg border border-[#FFE7DF] flex items-center justify-center gap-2"
    >
      <FacebookIcon />
      <span className="hidden sm:inline">Log In with Facebook</span>
      <span className="sm:hidden">Facebook</span>
    </Button>
  );
}

function GlobeIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
      <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z" fill="#0A82FF"/>
    </svg>
  );
}

function HelpIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
      <path d="M11 18h2v-2h-2v2zm1-16C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm0-14c-2.21 0-4 1.79-4 4h2c0-1.1.9-2 2-2s2 .9 2 2c0 2-3 1.75-3 5h2c0-2.25 3-2.5 3-5 0-2.21-1.79-4-4-4z" fill="#0A82FF"/>
    </svg>
  );
}

function SignupLink() {
  const navigate = useNavigate();
  
  return (
    <div className="flex justify-center items-center gap-2 w-full">
      <p className="text-xs md:text-sm text-gray-600">
        Don't have an account?
      </p>
      <button 
        onClick={() => navigate('/signup')}
        className="text-xs md:text-sm text-[#FF5D2E] hover:underline font-semibold"
      >
        Sign Up
      </button>
    </div>
  );
}

function LanguageSelector() {
  return (
    <div className="flex items-center gap-3 md:gap-6 justify-center">
      <button className="flex items-center gap-1.5 md:gap-2 px-2 md:px-3 py-1.5 md:py-2 text-[#0A82FF] font-medium hover:bg-gray-50 rounded transition-colors">
        <GlobeIcon />
        <span className="text-sm md:text-base lg:text-[17px]">English</span>
      </button>
      <button className="flex items-center gap-1.5 md:gap-2 px-2 md:px-3 py-1.5 md:py-2 text-[#0A82FF] font-medium hover:bg-gray-50 rounded transition-colors">
        <HelpIcon />
        <span className="text-sm md:text-base lg:text-[17px] hidden sm:inline">Help and support</span>
        <span className="text-sm sm:hidden">Help</span>
      </button>
    </div>
  );
}

function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleLogin = async () => {
    if (!email || !password) {
      setError("Please fill in all fields");
      return;
    }

    setLoading(true);
    setError("");

    try {
      const response = await apiService.login({ email, password });
      
      if (response.success) {
        console.log("Login successful:", response.data);
        // Navigate to dashboard or home page
        // navigate('/dashboard');
        alert("Login successful! Welcome back.");
      }
    } catch (err: any) {
      console.error("Login error:", err);
      setError(err.message || "Invalid email or password");
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleLogin = () => {
    console.log("Login with Google");
    alert("Google login coming soon!");
    // Add your Google login logic here
  };

  const handleFacebookLogin = () => {
    console.log("Login with Facebook");
    alert("Facebook login coming soon!");
    // Add your Facebook login logic here
  };

  return (
    <div className="w-full max-w-md px-4 sm:px-6 md:px-8">
      <div className="flex flex-col gap-3 md:gap-4 lg:gap-6">
        <LoginHeader />
        
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
            {error}
          </div>
        )}
        
        <div className="flex flex-col gap-3 md:gap-4 mt-4 md:mt-6 lg:mt-8">
          <EmailInput value={email} onChange={(e) => setEmail(e.target.value)} />
          <PasswordInput value={password} onChange={(e) => setPassword(e.target.value)} />
        </div>

        <LoginButton onClick={handleLogin} disabled={loading} />
        <ForgotPassword />
        
        <OrDivider />
        
        <div className="flex flex-col gap-3 md:gap-4">
          <GoogleLoginButton onClick={handleGoogleLogin} />
          <FacebookLoginButton onClick={handleFacebookLogin} />
        </div>

        <SignupLink />
        <LanguageSelector />
      </div>
    </div>
  );
}

export default function Login() {
  return (
    <div className="flex h-screen w-screen bg-white overflow-hidden">
      {/* Left side - Form */}
      <div className="flex-1 flex items-center justify-center p-4 sm:p-6 md:p-8 overflow-hidden">
        <div className="w-full h-full flex items-center justify-center max-h-screen py-4">
          <LoginForm />
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
