import { useEffect, useState } from 'react';
import { adminApi } from '../../services/adminApi';
import { Tag, Plus, Search } from 'lucide-react';
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
    return new Date(dateString).toLocaleDateString();
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gray-900"></div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-6 flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Offers Management</h1>
          <p className="text-gray-600 mt-2">Manage promotional offers</p>
        </div>
        <button className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
          <Plus className="h-5 w-5 mr-2" />
          Add Offer
        </button>
      </div>

      <div className="bg-white rounded-lg shadow mb-6">
        <div className="p-4 border-b">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search offers..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6">
          {filteredOffers.length === 0 ? (
            <div className="col-span-full text-center py-12 text-gray-500">
              <Tag className="h-12 w-12 mx-auto mb-2 text-gray-400" />
              <p>No offers found</p>
            </div>
          ) : (
            filteredOffers.map((offer) => (
              <div key={offer.id} className="border rounded-lg overflow-hidden hover:shadow-lg transition-shadow">
                {offer.imageUrl && (
                  <img
                    src={offer.imageUrl}
                    alt={offer.title}
                    className="w-full h-48 object-cover"
                  />
                )}
                <div className="p-4">
                  <div className="flex items-start justify-between mb-2">
                    <h3 className="font-bold text-lg text-gray-900">{offer.title}</h3>
                    <span
                      className={`px-2 py-1 rounded-full text-xs font-medium ${
                        offer.isActive
                          ? 'bg-green-100 text-green-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}
                    >
                      {offer.isActive ? 'Active' : 'Inactive'}
                    </span>
                  </div>
                  {offer.subtitle && (
                    <p className="text-sm text-gray-600 mb-2">{offer.subtitle}</p>
                  )}
                  <div className="mt-3 space-y-1">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-gray-600">Discount:</span>
                      <span className="font-medium">
                        {offer.discountType === 'PERCENTAGE'
                          ? `${offer.discountValue}%`
                          : `$${offer.discountValue}`}
                      </span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-gray-600">Valid Until:</span>
                      <span className="font-medium">{formatDate(offer.validUntil)}</span>
                    </div>
                  </div>
                  <div className="mt-4 flex space-x-2">
                    <button className="flex-1 px-3 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 text-sm">
                      Edit
                    </button>
                    <button className="flex-1 px-3 py-2 bg-red-600 text-white rounded hover:bg-red-700 text-sm">
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
