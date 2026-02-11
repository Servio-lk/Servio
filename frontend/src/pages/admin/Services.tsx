import { useEffect, useState } from 'react';
import { adminApi } from '../../services/adminApi';
import { Package, Plus, Search, Edit, Trash2, Filter, Clock } from 'lucide-react';
import { toast } from 'sonner';

export function AdminServices() {
  const [services, setServices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    loadServices();
  }, []);

  const loadServices = async () => {
    try {
      setLoading(true);
      const response = await adminApi.getAllServices();
      setServices(response.data || []);
    } catch (error) {
      console.error('Failed to load services:', error);
      toast.error('Failed to load services');
    } finally {
      setLoading(false);
    }
  };

  const handleToggleStatus = async (id: number, currentStatus: boolean) => {
    try {
      await adminApi.toggleServiceStatus(id, !currentStatus);
      toast.success(`Service ${!currentStatus ? 'activated' : 'deactivated'} successfully`);
      loadServices();
    } catch (error) {
      console.error('Failed to toggle service:', error);
      toast.error('Failed to update service status');
    }
  };

  const filteredServices = services.filter(service =>
    service.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    service.description?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#ff5d2e] mx-auto"></div>
          <p className="mt-4 text-black/70">Loading services...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-black">Services Management</h1>
          <p className="text-black/70 mt-1">Manage your service offerings and prices</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e54d1e] transition-colors shadow-lg shadow-[#ff5d2e]/20">
          <Plus className="h-4 w-4" />
          <span>Add New Service</span>
        </button>
      </div>

      <div className="bg-white rounded-xl border border-black/5 shadow-sm overflow-hidden">
        {/* Toolbar */}
        <div className="p-4 border-b border-black/5 flex flex-col sm:flex-row gap-4 justify-between items-center">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search services..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-gray-50 border-transparent focus:bg-white focus:border-[#ff5d2e] focus:ring-0 rounded-lg transition-all text-sm"
            />
          </div>
          <button className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-600 hover:text-black hover:bg-gray-50 rounded-lg transition-colors">
            <Filter className="h-4 w-4" />
            Filter
          </button>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50/50 border-b border-black/5">
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Service Details</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Category</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Price</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Duration</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filteredServices.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                    <div className="bg-gray-50 rounded-full w-16 h-16 flex items-center justify-center mx-auto mb-4">
                      <Package className="h-8 w-8 text-gray-400" />
                    </div>
                    <p className="text-lg font-medium text-black">No services found</p>
                    <p className="text-sm text-gray-500">Try adjusting your search or add a new service.</p>
                  </td>
                </tr>
              ) : (
                filteredServices.map((service) => (
                  <tr key={service.id} className="hover:bg-gray-50/50 transition-colors group">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 rounded-lg bg-gray-100 overflow-hidden flex-shrink-0 border border-black/5">
                          {service.imageUrl ? (
                            <img
                              src={service.imageUrl}
                              alt={service.name}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center text-gray-400">
                              <Package className="w-6 h-6" />
                            </div>
                          )}
                        </div>
                        <div>
                          <p className="font-semibold text-black text-sm">{service.name}</p>
                          <p className="text-xs text-gray-500 line-clamp-1 max-w-[200px]">{service.description}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-50 text-blue-700">
                        {service.category?.name || 'Uncategorized'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm font-medium text-black">
                      {service.basePrice ? `Rs. ${service.basePrice.toLocaleString()}` : service.priceRange}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {service.durationMinutes ? (
                        <div className="flex items-center gap-1">
                          <Clock className="w-4 h-4 text-gray-400" />
                          {service.durationMinutes} min
                        </div>
                      ) : '-'}
                    </td>
                    <td className="px-6 py-4">
                      <button
                        onClick={() => handleToggleStatus(service.id, service.isActive)}
                        className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium transition-colors ${service.isActive
                          ? 'bg-green-50 text-green-700 border border-green-200'
                          : 'bg-gray-100 text-gray-600 border border-gray-200'
                          }`}
                      >
                        <div className={`w-1.5 h-1.5 rounded-full ${service.isActive ? 'bg-green-500' : 'bg-gray-400'}`} />
                        {service.isActive ? 'Active' : 'Inactive'}
                      </button>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button
                          className="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="Edit"
                        >
                          <Edit className="h-4 w-4" />
                        </button>
                        <button
                          className="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                          title="Delete"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Footer / Pagination Placeholder */}
        <div className="p-4 border-t border-black/5 bg-gray-50/50 flex items-center justify-between text-xs text-gray-500">
          <span>Showing {filteredServices.length} results</span>
          <div className="flex gap-2">
            <button className="px-3 py-1 border rounded hover:bg-white disabled:opacity-50" disabled>Previous</button>
            <button className="px-3 py-1 border rounded hover:bg-white disabled:opacity-50" disabled>Next</button>
          </div>
        </div>
      </div>
    </div>
  );
}
