import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { supabaseAuth } from "@/services/supabaseAuth";
import LogoImage from "/ServioLogo.png";
import GarageImage from "@/assets/images/Garage image.png";

export default function ForgotPassword() {
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [cooldownSeconds, setCooldownSeconds] = useState(0);
  const [hasSentLink, setHasSentLink] = useState(false);

  useEffect(() => {
    if (cooldownSeconds <= 0) return;

    const timer = window.setTimeout(() => {
      setCooldownSeconds((seconds) => seconds - 1);
    }, 1000);

    return () => window.clearTimeout(timer);
  }, [cooldownSeconds]);

  const handleSendResetLink = async () => {
    const trimmedEmail = email.trim();

    if (!trimmedEmail) {
      toast.error("Please enter your email address");
      return;
    }

    if (cooldownSeconds > 0) return;

    setLoading(true);

    try {
      const { error } = await supabaseAuth.resetPassword(trimmedEmail);
      if (error) throw new Error(error.message);

      setHasSentLink(true);
      setCooldownSeconds(60);
      toast.success("If an account exists for that email, a password reset link has been sent.");
    } catch (err: any) {
      console.error("Password reset request error:", err);
      toast.error(err.message || "Failed to send password reset email");
    } finally {
      setLoading(false);
    }
  };

  const isSendDisabled = loading || cooldownSeconds > 0;

  return (
    <div className="flex h-screen w-full bg-white overflow-hidden fixed inset-0">
      <div className="flex-1 flex items-center justify-center p-4 sm:p-6 md:p-8 overflow-hidden">
        <div className="w-full h-full flex items-center justify-center py-4">
          <div className="w-full max-w-md px-4 sm:px-6 md:px-8">
            <div className="flex flex-col gap-4 md:gap-5 lg:gap-6">
              <div className="flex flex-col items-center text-center w-full">
                <div className="flex flex-col items-center justify-center w-full mb-4 md:mb-6">
                  <img src={LogoImage} alt="Servio Logo" className="h-16 md:h-20 lg:h-24 w-auto" />
                </div>
                <h1 className="font-semibold text-xl md:text-2xl lg:text-3xl text-black">
                  Forgot password
                </h1>
                <p className="text-sm md:text-base text-gray-700 mt-2">
                  Enter your email address and we will send you a password reset link.
                </p>
              </div>

              <div className="w-full space-y-2">
                <Input
                  id="reset-email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Email"
                  className="h-11 md:h-12 lg:h-[48px] rounded-lg border border-gray-200 px-3 md:px-4 text-sm md:text-base focus-visible:ring-2 focus-visible:ring-[#FF5D2E]"
                />
              </div>

              {hasSentLink && (
                <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg text-sm">
                  Check your inbox for the password reset link.
                </div>
              )}

              <div className="flex flex-col gap-3">
                <Button
                  onClick={handleSendResetLink}
                  disabled={isSendDisabled}
                  className="w-full h-10 md:h-11 lg:h-12 bg-[#FF5D2E] hover:bg-[#FF5D2E]/90 text-white font-semibold text-sm md:text-base rounded-lg shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {loading ? "Sending reset link..." : "Send Password Reset Link"}
                </Button>

                {cooldownSeconds > 0 && (
                  <p className="text-center text-xs md:text-sm text-gray-600">
                    You can send another password reset link in {cooldownSeconds} seconds.
                  </p>
                )}

                <button
                  type="button"
                  onClick={() => navigate("/login")}
                  className="text-xs md:text-sm text-gray-600 hover:text-gray-900 underline"
                >
                  Back to Login
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

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
