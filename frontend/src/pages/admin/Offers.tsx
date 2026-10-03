import { useEffect, useState } from 'react';
import { adminApi } from '../../services/adminApi';
import { Tag, Plus, Search, Filter, Calendar, Edit, Trash2 } from 'lucide-react';
import { toast } from 'sonner';

const emptyForm = {
  title: '',
  subtitle: '',
  description: '',
  discountType: 'PERCENTAGE',
  discountValue: '',
  imageUrl: '',
  promoCode: '',
  category: '',
  validUntil: '',
};

export function AdminOffers() {
  const [offers, setOffers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [form, setForm] = useState(emptyForm);

  useEffect(() => {
    loadOffers();
  }, []);

  const loadOffers = async () => {
    try {
      setLoading(true);
      const response = await adminApi.getAllOffers();
      setOffers(response.data || []);
    } catch (error) {
      console.error('Failed to load offers:', error);
      toast.error('Failed to load offers');
    } finally {
      setLoading(false);
    }
  };

  const filteredOffers = offers.filter(offer =>
    offer.title.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const offerPayload = () => ({
    title: form.title.trim(),
    subtitle: form.subtitle.trim() || null,
    description: form.description.trim() || null,
    discountType: form.discountType,
    discountValue: Number(form.discountValue),
    imageUrl: form.imageUrl.trim() || null,
    promoCode: form.promoCode.trim() ? form.promoCode.trim().toUpperCase() : null,
    category: form.category || null,
    validUntil: form.validUntil
      ? (form.validUntil.length === 16 ? `${form.validUntil}:00` : form.validUntil)
      : null,
    isActive: true,
  });

  const startEdit = (offer: any) => {
    setEditingId(offer.id);
    setForm({
      title: offer.title || '',
      subtitle: offer.subtitle || '',
      description: offer.description || '',
      discountType: offer.discountType || 'PERCENTAGE',
      discountValue: offer.discountValue != null ? String(offer.discountValue) : '',
      imageUrl: offer.imageUrl || '',
      promoCode: offer.promoCode || '',
      category: offer.category || '',
      validUntil: offer.validUntil ? String(offer.validUntil).slice(0, 16) : '',
    });
    setShowForm(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const saveOffer = async () => {
    if (!form.title.trim() || !form.discountValue) {
      toast.error('Title and discount value are required');
      return;
    }
    setSaving(true);
    try {
      const payload = offerPayload();
      const current = offers.find((offer) => offer.id === editingId);
      const response = editingId
        ? await adminApi.updateOffer(editingId, { ...payload, isActive: current?.isActive ?? true })
        : await adminApi.createOffer(payload);
      if (response.success) {
        toast.success(editingId ? 'Offer updated' : 'Offer created');
        setShowForm(false);
        setEditingId(null);
        setForm(emptyForm);
        await loadOffers();
      } else {
        toast.error(response.message || 'Could not save offer');
      }
    } catch {
      toast.error('Could not save offer');
    } finally {
      setSaving(false);
    }
  };

  const removeOffer = async (id: number) => {
    if (!window.confirm('Delete this offer?')) return;
    try {
      const response = await adminApi.deleteOffer(id);
      if (response.success) {
        toast.success('Offer deleted');
        setOffers((prev) => prev.filter((offer) => offer.id !== id));
      } else {
        toast.error(response.message || 'Could not delete offer');
      }
    } catch {
      toast.error('Could not delete offer');
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#ff5d2e] mx-auto"></div>
          <p className="mt-4 text-black/70">Loading offers...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl text-left font-bold text-black">Offers Management</h1>
          <p className="text-black/70 mt-1">Manage, create and track promotional offers</p>
        </div>
        <button
          type="button"
          onClick={() => {
            if (showForm && editingId == null) {
              setShowForm(false);
              return;
            }
            setEditingId(null);
            setForm(emptyForm);
            setShowForm(true);
          }}
          className="flex items-center gap-2 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e54d1e] transition-colors shadow-lg shadow-[#ff5d2e]/20"
        >
          <Plus className="h-4 w-4" />
          <span>Create New Offer</span>
        </button>
      </div>

      {showForm && (
        <div className="bg-white p-5 rounded-xl border border-black/5 shadow-sm grid grid-cols-1 sm:grid-cols-2 gap-3">
          <input className="border rounded-lg px-3 py-2 text-sm" placeholder="Title" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
          <input className="border rounded-lg px-3 py-2 text-sm" placeholder="Subtitle" value={form.subtitle} onChange={(e) => setForm({ ...form, subtitle: e.target.value })} />
          <input className="border rounded-lg px-3 py-2 text-sm sm:col-span-2" placeholder="Description" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
          <select className="border rounded-lg px-3 py-2 text-sm" value={form.discountType} onChange={(e) => setForm({ ...form, discountType: e.target.value })}>
            <option value="PERCENTAGE">Percentage</option>
            <option value="FIXED_AMOUNT">Fixed amount</option>
          </select>
          <input className="border rounded-lg px-3 py-2 text-sm" type="number" min="0" placeholder="Discount value" value={form.discountValue} onChange={(e) => setForm({ ...form, discountValue: e.target.value })} />
          <input className="border rounded-lg px-3 py-2 text-sm" placeholder="Promo code" value={form.promoCode} onChange={(e) => setForm({ ...form, promoCode: e.target.value })} />
          <select className="border rounded-lg px-3 py-2 text-sm" value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })}>
            <option value="">No category</option>
            <option value="NEW_USER">New User</option>
            <option value="LIMITED_TIME">Limited Time</option>
            <option value="SEASONAL">Seasonal</option>
          </select>
          <input className="border rounded-lg px-3 py-2 text-sm" placeholder="Image URL" value={form.imageUrl} onChange={(e) => setForm({ ...form, imageUrl: e.target.value })} />
          <input className="border rounded-lg px-3 py-2 text-sm" type="datetime-local" value={form.validUntil} onChange={(e) => setForm({ ...form, validUntil: e.target.value })} />
          <button type="button" disabled={saving} onClick={saveOffer} className="sm:col-span-2 justify-self-start bg-[#ff5d2e] text-white text-sm font-semibold px-4 py-2 rounded-lg disabled:opacity-50">
            {saving ? 'Saving...' : editingId ? 'Save changes' : 'Publish offer'}
          </button>
        </div>
      )}

      <div className="flex flex-col gap-6">
        {/* Toolbar */}
        <div className="bg-white p-4 rounded-xl border border-black/5 shadow-sm flex flex-col sm:flex-row gap-4 justify-between items-center">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search offers..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-gray-50 border-transparent focus:bg-white focus:border-[#ff5d2e] focus:ring-0 rounded-lg transition-all text-sm"
            />
          </div>
          <div className="flex gap-2 w-full sm:w-auto">
            <button className="flex-1 sm:flex-none flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-gray-600 hover:text-black hover:bg-gray-50 rounded-lg transition-colors border border-transparent hover:border-gray-200">
              <Filter className="h-4 w-4" />
              Filter
            </button>
          </div>
        </div>

        {/* Offers Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredOffers.length === 0 ? (
            <div className="col-span-full py-16 text-center bg-white rounded-xl border border-black/5 shadow-sm">
              <div className="bg-gray-50 rounded-full w-20 h-20 flex items-center justify-center mx-auto mb-4">
                <Tag className="h-10 w-10 text-gray-400" />
              </div>
              <h3 className="text-lg font-bold text-black">No offers found</h3>
              <p className="text-gray-500 mt-1">Create a new offer to get started</p>
            </div>
          ) : (
            filteredOffers.map((offer) => (
              <div key={offer.id} className="bg-white rounded-xl border border-black/5 shadow-sm hover:shadow-md transition-all overflow-hidden group flex flex-col h-full">
                {/* Image Section */}
                <div className="relative h-48 bg-gray-100 overflow-hidden">
                  {offer.imageUrl ? (
                    <img
                      src={offer.imageUrl}
                      alt={offer.title}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-gray-400 bg-gray-50">
                      <Tag className="h-10 w-10 opacity-20" />
                      <span className="ml-2 text-sm opacity-50">No Image</span>
                    </div>
                  )}
                  <div className="absolute top-3 right-3">
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-bold shadow-sm backdrop-blur-md ${offer.isActive
                          ? 'bg-white/90 text-green-700'
                          : 'bg-black/50 text-white'
                        }`}
                    >
                      {offer.isActive ? 'Active' : 'Inactive'}
                    </span>
                  </div>
                  <div className="absolute bottom-3 left-3 bg-white/90 backdrop-blur-md px-3 py-1 rounded-full text-xs font-bold text-[#ff5d2e] shadow-sm">
                    {offer.discountType === 'PERCENTAGE' ? `${offer.discountValue}% OFF` : `Rs. ${offer.discountValue} OFF`}
                  </div>
                </div>

                {/* Content Section */}
                <div className="p-5 flex-1 flex flex-col">
                  <h3 className="font-bold text-lg text-black leading-tight mb-1">{offer.title}</h3>
                  {offer.subtitle && (
                    <p className="text-sm text-gray-500 mb-4 line-clamp-2">{offer.subtitle}</p>
                  )}
                  {(offer.promoCode || offer.category) && (
                    <p className="text-xs text-black/50 mb-2">
                      {offer.category ? offer.category.replace('_', ' ') : 'General'}
                      {offer.promoCode ? ` · ${offer.promoCode}` : ''}
                    </p>
                  )}

                  <div className="mt-auto space-y-3 pt-4 border-t border-gray-100">
                    <div className="flex items-center text-sm text-gray-600">
                      <Calendar className="w-4 h-4 mr-2 text-gray-400" />
                      <span>Valid until <span className="font-medium text-black">{offer.validUntil ? formatDate(offer.validUntil) : 'No expiry'}</span></span>
                    </div>
                  </div>
                </div>

                {/* Actions Section */}
                <div className="px-5 py-4 bg-gray-50/50 border-t border-gray-100 flex gap-2">
                  <button type="button" onClick={() => startEdit(offer)} className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-white border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 hover:text-black hover:border-gray-300 transition-colors text-sm font-medium cursor-pointer">
                    <Edit className="w-4 h-4" />
                    Edit
                  </button>
                  <button type="button" onClick={() => removeOffer(offer.id)} className="flex items-center justify-center px-4 py-2 bg-white border border-red-100 text-red-600 rounded-lg hover:bg-red-50 hover:border-red-200 transition-colors text-sm font-medium">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}

export default AdminOffers;

