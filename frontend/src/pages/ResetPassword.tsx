import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Eye, EyeOff } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { supabaseAuth } from "@/services/supabaseAuth";
import LogoImage from "/ServioLogo.png";
import GarageImage from "@/assets/images/Garage image.png";

function PasswordField({
  id,
  label,
  value,
  onChange,
  placeholder,
}: {
  id: string;
  label: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  placeholder: string;
}) {
  const [showPassword, setShowPassword] = useState(false);

  return (
    <div className="w-full space-y-2">
      <Label htmlFor={id} className="text-sm text-gray-700">
        {label}
      </Label>
      <div className="relative">
        <Input
          id={id}
          type={showPassword ? "text" : "password"}
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          className="h-11 md:h-12 lg:h-[48px] rounded-lg border border-gray-200 px-3 md:px-4 pr-11 text-sm md:text-base focus-visible:ring-2 focus-visible:ring-[#FF5D2E]"
        />
        <button
          type="button"
          onClick={() => setShowPassword((prev) => !prev)}
          className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
          aria-label={showPassword ? "Hide password" : "Show password"}
        >
          {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
        </button>
      </div>
    </div>
  );
}

export default function ResetPassword() {
  const navigate = useNavigate();
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [checkingSession, setCheckingSession] = useState(true);
  const [hasRecoverySession, setHasRecoverySession] = useState(false);

  useEffect(() => {
    let isMounted = true;

    const checkRecoverySession = async () => {
      try {
        const session = await supabaseAuth.getCurrentSession();
        if (isMounted) {
          setHasRecoverySession(!!session?.user);
        }
      } catch (error) {
        console.error("Recovery session check error:", error);
        if (isMounted) {
          setHasRecoverySession(false);
        }
      } finally {
        if (isMounted) {
          setCheckingSession(false);
        }
      }
    };

    checkRecoverySession();

    return () => {
      isMounted = false;
    };
  }, []);

  const handleUpdatePassword = async () => {
    if (password.length < 8) {
      toast.error("Password must be at least 8 characters");
      return;
    }

    if (password !== confirmPassword) {
      toast.error("Passwords do not match");
      return;
    }

    setLoading(true);

    try {
      const { error } = await supabaseAuth.updatePassword(password);
      if (error) throw new Error(error.message);

      await supabaseAuth.signOut();
      toast.success("Password updated successfully. Please log in with your new password.");
      navigate("/login", { replace: true });
    } catch (err: any) {
      console.error("Password update error:", err);
      toast.error(err.message || "Failed to update password");
    } finally {
      setLoading(false);
    }
  };

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
                  Reset your password
                </h1>
                <p className="text-sm md:text-base text-gray-700 mt-2">
                  Enter a new password for your Servio account.
                </p>
              </div>

              {checkingSession ? (
                <div className="flex flex-col items-center gap-3 py-8">
                  <div className="w-10 h-10 border-4 border-[#FF5D2E] border-t-transparent rounded-full animate-spin" />
                  <p className="text-sm text-gray-600">Checking reset link...</p>
                </div>
              ) : !hasRecoverySession ? (
                <div className="flex flex-col gap-4">
                  <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                    This password reset link is invalid or has expired. Please request a new reset link from the login page.
                  </div>
                  <Button
                    onClick={() => navigate("/login", { replace: true })}
                    className="w-full h-10 md:h-11 lg:h-12 bg-[#FF5D2E] hover:bg-[#FF5D2E]/90 text-white font-semibold text-sm md:text-base rounded-lg shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)]"
                  >
                    Back to Login
                  </Button>
                </div>
              ) : (
                <div className="flex flex-col gap-4">
                  <PasswordField
                    id="new-password"
                    label="New password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="New password"
                  />
                  <PasswordField
                    id="confirm-password"
                    label="Confirm password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder="Confirm password"
                  />
                  <Button
                    onClick={handleUpdatePassword}
                    disabled={loading}
                    className="w-full h-10 md:h-11 lg:h-12 bg-[#FF5D2E] hover:bg-[#FF5D2E]/90 text-white font-semibold text-sm md:text-base rounded-lg shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {loading ? "Updating password..." : "Update Password"}
                  </Button>
                  <button
                    type="button"
                    onClick={() => navigate("/login")}
                    className="text-xs md:text-sm text-gray-600 hover:text-gray-900 underline"
                  >
                    Back to Login
                  </button>
                </div>
              )}
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
