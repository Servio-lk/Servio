import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { AppLayout } from '@/components/layouts/AppLayout';
import { OfferCard } from '@/components/OfferCard';
import { apiService, type Offer } from '@/services/api';
import { toast } from 'sonner';

const CATEGORIES = [
  { id: '', label: 'All' },
  { id: 'NEW_USER', label: 'New User' },
  { id: 'LIMITED_TIME', label: 'Limited Time' },
  { id: 'SEASONAL', label: 'Seasonal' },
];

export default function OffersPage() {
  const navigate = useNavigate();
  const [category, setCategory] = useState('');
  const [offers, setOffers] = useState<Offer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError('');
    apiService.getOffers(category || undefined)
      .then((res) => {
        if (cancelled) return;
        if (res.success && res.data) setOffers(res.data.filter((o) => !o.expired));
        else setError(res.message || 'Could not load offers');
      })
      .catch(() => { if (!cancelled) setError('Could not load offers'); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [category]);

  const applyCode = (code: string) => {
    sessionStorage.setItem('servio.promoCode', code);
    toast.success(`${code} will be applied at booking`);
    navigate('/services');
  };

  return (
    <AppLayout>
      <div className="max-w-5xl mx-auto px-4 py-6 flex flex-col gap-4">
        <h1 className="text-2xl font-semibold">Offers</h1>
        <div className="flex gap-2 overflow-x-auto">
          {CATEGORIES.map((c) => (
            <button key={c.id} type="button" onClick={() => setCategory(c.id)}
              className={`shrink-0 px-3 py-1.5 rounded-full text-sm font-medium ${
                category === c.id ? 'bg-[#ff5d2e] text-white' : 'bg-white text-black/70'
              }`}>
              {c.label}
            </button>
          ))}
        </div>
        {loading && <p className="text-black/50">Loading offers...</p>}
        {error && <p className="text-red-600 text-sm">{error}</p>}
        {!loading && !error && offers.length === 0 && (
          <p className="text-black/50">No active offers in this category.</p>
        )}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {offers.map((offer) => (
            <OfferCard key={offer.id} {...offer} onApply={applyCode} />
          ))}
        </div>
      </div>
    </AppLayout>
  );
}