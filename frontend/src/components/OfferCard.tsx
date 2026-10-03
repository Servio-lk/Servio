import { Link } from 'react-router-dom';
import { toast } from 'sonner';

interface OfferCardProps {
    id: number;
    title: string;
    subtitle?: string | null;
    description?: string | null;
    discountType: string;
    discountValue: number;
    imageUrl?: string | null;
    promoCode?: string | null;
    validUntil?: string | null;
    expired?: boolean;
    onApply?: (code: string) => void;
    titleHref?: string;
}

function badgeLabel(discountType: string, discountValue: number) {
    const type = discountType?.toUpperCase();
    if (type === 'PERCENTAGE' || type === 'PERCENT') return `${discountValue}% OFF`;
    if (type === 'FIXED_AMOUNT' || type === 'FIXED') return `LKR ${discountValue} OFF`;
    return 'OFFER';
}

export function OfferCard({
    title, subtitle, description, discountType, discountValue,
    imageUrl, promoCode, validUntil, expired, onApply, titleHref,
  }: OfferCardProps) {
    const disabled = Boolean(expired);

    const copyCode = async () => {
      if (!promoCode || disabled) return;
      await navigator.clipboard.writeText(promoCode);
      toast.success(`Copied ${promoCode}`);
  };

  return (
    <article className={`bg-white rounded-2xl shadow-md overflow-hidden flex flex-col ${disabled ? 'opacity-50' : ''}`}>
      <div className="relative h-32 bg-[#fff7f5]">
        {imageUrl && <img src={imageUrl} alt="" className="w-full h-full object-cover" />}
        <span className="absolute top-3 left-3 bg-[#ff5d2e] text-white text-xs font-bold px-2 py-1 rounded">
          {badgeLabel(discountType, discountValue)}
        </span>
      </div>
      <div className="p-4 flex flex-col gap-2 flex-1">
        {titleHref ? (
          <Link to={titleHref} className="text-base font-semibold text-black hover:underline cursor-pointer">
            {title}
          </Link>
        ) : (
          <h3 className="text-base font-semibold text-black">{title}</h3>
        )}
        {subtitle && <p className="text-sm font-medium text-black/80">{subtitle}</p>}
        {description && <p className="text-sm text-black/60 line-clamp-2">{description}</p>}
        {validUntil && (
          <p className="text-xs text-black/40">
            {disabled ? 'Expired' : 'Valid until'} {new Date(validUntil).toLocaleDateString()}
          </p>
        )}
        {promoCode && (
          <div className="mt-auto flex items-center gap-2">
            <code className="flex-1 text-sm font-semibold tracking-wide bg-[#fff7f5] rounded-lg px-3 py-2">
              {promoCode}
            </code>
            <button type="button" disabled={disabled} onClick={copyCode}
              className="text-sm font-semibold text-[#ff5d2e] cursor-pointer hover:underline disabled:text-black/30 disabled:cursor-not-allowed disabled:no-underline">
              Copy
            </button>
            {onApply && (
              <button type="button" disabled={disabled} onClick={() => onApply(promoCode)}
              className="bg-[#ff5d2e] text-white text-sm font-semibold px-3 py-2 rounded-lg cursor-pointer transition-colors hover:bg-[#e54d1e] disabled:bg-black/20 disabled:cursor-not-allowed disabled:hover:bg-black/20">
                Apply
              </button>
            )}
          </div>
        )}
      </div>
    </article>
  );
}