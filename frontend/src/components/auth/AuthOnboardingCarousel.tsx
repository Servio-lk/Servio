import { useState, useEffect, useRef, useCallback } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import onboarding1 from "@/assets/images/onboarding/1.png";
import onboarding2 from "@/assets/images/onboarding/2.png";
import onboarding3 from "@/assets/images/onboarding/3.png";
import onboarding4 from "@/assets/images/onboarding/4.png";

export interface OnboardingSlide {
  image: string;
  title: string;
  subtitle: string;
}

const slides: OnboardingSlide[] = [
  {
    image: onboarding1,
    title: "Your vehicle's\nbest friend",
    subtitle: "We handle the maintenance,\nyou enjoy the ride.",
  },
  {
    image: onboarding2,
    title: "Effortless booking",
    subtitle: "Booking the most trusted mechanics has\nnever been smoother.",
  },
  {
    image: onboarding3,
    title: "Never miss a\nservice",
    subtitle: "Receive alerts when your vehicle needs\nattention.",
  },
  {
    image: onboarding4,
    title: "Track your service\nhistory",
    subtitle:
      "Stay on top of your vehicle's health with a\nlog of every oil change, tire rotation, and\ninspection.",
  },
];

const AUTO_PLAY_INTERVAL = 4500; // 4.5 seconds

export function AuthOnboardingCarousel() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isPaused, setIsPaused] = useState(false);
  const touchStartX = useRef<number | null>(null);
  const touchEndX = useRef<number | null>(null);

  const nextSlide = useCallback(() => {
    setCurrentIndex((prev) => (prev + 1) % slides.length);
  }, []);

  const prevSlide = useCallback(() => {
    setCurrentIndex((prev) => (prev - 1 + slides.length) % slides.length);
  }, []);

  const goToSlide = (index: number) => {
    setCurrentIndex(index);
  };

  // Auto-play timer
  useEffect(() => {
    if (isPaused) return;

    const timer = setInterval(() => {
      nextSlide();
    }, AUTO_PLAY_INTERVAL);

    return () => clearInterval(timer);
  }, [isPaused, nextSlide]);

  // Touch handlers for mobile / tablet gestures
  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartX.current = e.touches[0].clientX;
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    touchEndX.current = e.touches[0].clientX;
  };

  const handleTouchEnd = () => {
    if (touchStartX.current !== null && touchEndX.current !== null) {
      const diff = touchStartX.current - touchEndX.current;
      if (Math.abs(diff) > 50) {
        if (diff > 0) {
          nextSlide();
        } else {
          prevSlide();
        }
      }
    }
    touchStartX.current = null;
    touchEndX.current = null;
  };

  return (
    <div
      className="relative w-full h-full flex flex-col justify-between items-center overflow-hidden select-none border-l border-gray-100 group"
      onMouseEnter={() => setIsPaused(true)}
      onMouseLeave={() => setIsPaused(false)}
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
      role="region"
      aria-label="Servio features carousel"
    >

      {/* Main carousel sliding container */}
      <div className="w-full flex-1 flex flex-col items-center justify-center relative z-10 px-6 sm:px-10 py-8">
        <div className="w-full max-w-[460px] overflow-hidden">
          <div
            className="flex transition-transform duration-500 ease-out"
            style={{ transform: `translateX(-${currentIndex * 100}%)` }}
          >
            {slides.map((slide, index) => (
              <div
                key={index}
                className="w-full flex-shrink-0 flex flex-col items-center justify-center text-center px-4"
                aria-hidden={currentIndex !== index}
              >
                {/* Illustration container */}
                <div className="relative w-full max-w-[520px] h-[240px] xl:h-[380px] flex items-center justify-center mb-8">
                  <div className="absolute inset-0" />
                  <img
                    src={slide.image}
                    alt={slide.title.replace("\n", " ")}
                    className="relative z-10 w-auto max-w-[90%] object-contain transition-transform duration-500 hover:scale-105"
                  />
                </div>

                {/* Title */}
                <h2 className="text-2xl xl:text-3xl font-semibold text-gray-900 tracking-tight leading-[1.2] whitespace-pre-line mb-3 font-['Instrument_Sans',sans-serif]">
                  {slide.title}
                </h2>

                {/* Subtitle */}
                <p className="text-sm xl:text-base font-medium text-[#4B4B4B] leading-relaxed whitespace-pre-line max-w-sm mx-auto font-['Instrument_Sans',sans-serif]">
                  {slide.subtitle}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Previous & Next hover controls */}
        <button
          onClick={prevSlide}
          className="absolute left-4 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-white/90 shadow-md border border-gray-100 flex items-center justify-center text-gray-700 opacity-0 group-hover:opacity-100 transition-all duration-300 hover:bg-white hover:scale-110 hover:text-[#FF5D2E] focus:opacity-100"
          aria-label="Previous slide"
        >
          <ChevronLeft className="w-5 h-5" />
        </button>
        <button
          onClick={nextSlide}
          className="absolute right-4 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-white/90 shadow-md border border-gray-100 flex items-center justify-center text-gray-700 opacity-0 group-hover:opacity-100 transition-all duration-300 hover:bg-white hover:scale-110 hover:text-[#FF5D2E] focus:opacity-100"
          aria-label="Next slide"
        >
          <ChevronRight className="w-5 h-5" />
        </button>
      </div>

      {/* Dots Indicator - exactly matching mobile app */}
      <div className="relative z-10 pb-8 sm:pb-12 flex items-center justify-center gap-2">
        {slides.map((_, index) => {
          const isActive = currentIndex === index;
          return (
            <button
              key={index}
              onClick={() => goToSlide(index)}
              className={`h-2 rounded-full transition-all duration-300 ease-out focus:outline-none focus-visible:ring-2 focus-visible:ring-[#FF5D2E] ${
                isActive
                  ? "w-6 bg-[#FF5D2E]"
                  : "w-2 bg-[#D9D9D9] hover:bg-gray-400"
              }`}
              aria-label={`Go to slide ${index + 1}`}
              aria-current={isActive ? "true" : undefined}
            />
          );
        })}
      </div>
    </div>
  );
}

export default AuthOnboardingCarousel;
