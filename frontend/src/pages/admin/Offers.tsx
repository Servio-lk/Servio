import { useEffect, useState } from 'react';
import { adminApi } from '../../services/adminApi';
import { Tag, Plus, Search, Filter, Calendar, Edit, Trash2, Percent, DollarSign } from 'lucide-react';
import { toast } from 'sonner';

export function AdminOffers() {
  const [offers, setOffers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

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
          <h1 className="text-2xl font-bold text-black">Offers Management</h1>
          <p className="text-black/70 mt-1">Manage, create and track promotional offers</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e54d1e] transition-colors shadow-lg shadow-[#ff5d2e]/20">
          <Plus className="h-4 w-4" />
          <span>Create New Offer</span>
        </button>
      </div>

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
                  <div className="absolute bottom-3 left-3 bg-white/90 backdrop-blur-md px-3 py-1 rounded-full text-xs font-bold text-[#ff5d2e] flex items-center shadow-sm">
                    {offer.discountType === 'PERCENTAGE' ? <Percent className="w-3 h-3 mr-1" /> : <DollarSign className="w-3 h-3 mr-1" />}
                    {offer.discountType === 'PERCENTAGE' ? `${offer.discountValue}% OFF` : `Rs. ${offer.discountValue} OFF`}
                  </div>
                </div>

                {/* Content Section */}
                <div className="p-5 flex-1 flex flex-col">
                  <h3 className="font-bold text-lg text-black leading-tight mb-1">{offer.title}</h3>
                  {offer.subtitle && (
                    <p className="text-sm text-gray-500 mb-4 line-clamp-2">{offer.subtitle}</p>
                  )}

                  <div className="mt-auto space-y-3 pt-4 border-t border-gray-100">
                    <div className="flex items-center text-sm text-gray-600">
                      <Calendar className="w-4 h-4 mr-2 text-gray-400" />
                      <span>Valid until <span className="font-medium text-black">{formatDate(offer.validUntil)}</span></span>
                    </div>
                  </div>
                </div>

                {/* Actions Section */}
                <div className="px-5 py-4 bg-gray-50/50 border-t border-gray-100 flex gap-2">
                  <button className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-white border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 hover:text-black hover:border-gray-300 transition-colors text-sm font-medium">
                    <Edit className="w-4 h-4" />
                    Edit
                  </button>
                  <button className="flex items-center justify-center px-4 py-2 bg-white border border-red-100 text-red-600 rounded-lg hover:bg-red-50 hover:border-red-200 transition-colors text-sm font-medium">
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
