interface OfferCardProps {
  id: number;
  title: string;
  subtitle: string;
  discountType: string;
  discountValue: number;
  imageUrl?: string | null;
}

export function OfferCard({ title, subtitle, discountType, discountValue, imageUrl }: OfferCardProps) {
  const displayDiscount = discountType === 'percentage' 
    ? `${discountValue}%` 
    : discountType === 'fixed'
    ? `LKR ${discountValue}`
    : 'FREE';

  return (
    <div className="bg-white rounded-2xl shadow-md p-4 min-w-[280px] lg:min-w-0 flex flex-col gap-3 relative overflow-hidden">
      <div className="flex items-center gap-2">
        <span className="bg-[#ff5d2e] text-white text-xs font-bold px-2 py-1 rounded">
          {displayDiscount}
        </span>
      </div>
      <div className="text-base font-medium text-black">
        <p>{title}</p>
        <p className="font-semibold">{subtitle}</p>
      </div>
      {imageUrl && (
        <div className="w-full h-24 rounded-lg overflow-hidden">
          <img src={imageUrl} alt={`${title} ${subtitle}`} className="w-full h-full object-cover" />
        </div>
      )}
      <button className="bg-[#ff5d2e] text-white py-2 px-4 rounded-lg font-semibold text-sm shadow-[0px_4px_8px_0px_rgba(255,93,46,0.5)] hover:bg-[#e54d1e] transition-colors self-start">
        Book now
      </button>
      <div className="absolute right-[-20px] top-[-20px] w-32 h-32 opacity-10">
        <div className="w-full h-full rounded-full bg-[#ff5d2e]" />
      </div>
    </div>
  );
}
