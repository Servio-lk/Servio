import { useEffect, useState } from 'react';
import { Warehouse, Search, Plus, MoreVertical, Trash2, Edit2 } from 'lucide-react';
import { toast } from 'sonner';

export function AdminServiceBays() {
  const [bays, setBays] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    bayNumber: '',
    description: '',
    type: 'GENERAL',
    capacity: '1',
  });

  useEffect(() => {
    loadBays();
  }, []);

  const loadBays = async () => {
    try {
      setLoading(true);
      const response = await fetch('http://localhost:3001/api/admin/service-bays', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
      });
      const data = await response.json();
      setBays(data.data || []);
    } catch (error) {
      console.error('Failed to load service bays:', error);
      toast.error('Failed to load service bays');
    } finally {
      setLoading(false);
    }
  };

  const handleAddBay = async () => {
    if (!formData.bayNumber || !formData.description) {
      toast.error('Please fill in all required fields');
      return;
    }

    try {
      const response = await fetch('http://localhost:3001/api/admin/service-bays', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
        body: JSON.stringify({
          ...formData,
          capacity: parseInt(formData.capacity),
        }),
      });
      
      if (response.ok) {
        toast.success('Service bay added successfully');
        setShowModal(false);
        setFormData({
          bayNumber: '',
          description: '',
          type: 'GENERAL',
          capacity: '1',
        });
        loadBays();
      } else {
        toast.error('Failed to add service bay');
      }
    } catch (error) {
      toast.error('Error adding service bay');
    }
  };

  const handleDeleteBay = async (id: number) => {
    if (confirm('Are you sure you want to delete this service bay?')) {
      try {
        const response = await fetch(`http://localhost:3001/api/admin/service-bays/${id}`, {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`,
          },
        });
        
        if (response.ok) {
          toast.success('Service bay deleted successfully');
          loadBays();
        } else {
          toast.error('Failed to delete service bay');
        }
      } catch (error) {
        toast.error('Error deleting service bay');
      }
    }
  };

  const handleUpdateStatus = async (id: number, newStatus: string) => {
    try {
      const response = await fetch(`http://localhost:3001/api/admin/service-bays/${id}/status/${newStatus}`, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
      });
      
      if (response.ok) {
        toast.success('Status updated successfully');
        loadBays();
      } else {
        toast.error('Failed to update status');
      }
    } catch (error) {
      toast.error('Error updating status');
    }
  };

  const filteredBays = bays.filter(
    (bay) =>
      bay.bayNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      bay.description.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#ff5d2e] mx-auto"></div>
          <p className="mt-4 text-black/70">Loading service bays...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-[#ff5d2e] rounded-lg flex items-center justify-center">
            <Warehouse className="w-6 h-6 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-black">Service Bays Management</h1>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="flex items-center gap-2 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e64d1e] transition-colors"
        >
          <Plus className="w-5 h-5" />
          <span>Add Service Bay</span>
        </button>
      </div>

      {/* Search Bar */}
      <div className="relative">
        <Search className="absolute left-3 top-3 w-5 h-5 text-black/40" />
        <input
          type="text"
          placeholder="Search service bays..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full pl-10 pr-4 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
        />
      </div>

      {/* Bays Table */}
      <div className="bg-white rounded-lg border border-black/10 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-black/5">
            <tr>
              <th className="px-6 py-3 text-left font-semibold text-black">Bay Number</th>
              <th className="px-6 py-3 text-left font-semibold text-black">Description</th>
              <th className="px-6 py-3 text-left font-semibold text-black">Type</th>
              <th className="px-6 py-3 text-left font-semibold text-black">Status</th>
              <th className="px-6 py-3 text-left font-semibold text-black">Capacity</th>
              <th className="px-6 py-3 text-right font-semibold text-black">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredBays.length > 0 ? (
              filteredBays.map((bay) => (
                <tr key={bay.id} className="border-t border-black/10 hover:bg-black/2">
                  <td className="px-6 py-3 font-medium text-black">{bay.bayNumber}</td>
                  <td className="px-6 py-3 text-black/70">{bay.description}</td>
                  <td className="px-6 py-3">{bay.type}</td>
                  <td className="px-6 py-3">
                    <select
                      value={bay.status}
                      onChange={(e) => handleUpdateStatus(bay.id, e.target.value)}
                      className={`px-3 py-1 rounded-full text-xs font-medium cursor-pointer ${
                        bay.status === 'AVAILABLE'
                          ? 'bg-green-50 text-green-700'
                          : bay.status === 'IN_USE'
                          ? 'bg-blue-50 text-blue-700'
                          : 'bg-red-50 text-red-700'
                      }`}
                    >
                      <option value="AVAILABLE">Available</option>
                      <option value="IN_USE">In Use</option>
                      <option value="MAINTENANCE">Maintenance</option>
                    </select>
                  </td>
                  <td className="px-6 py-3 text-black">{bay.capacity}</td>
                  <td className="px-6 py-3">
                    <div className="relative group inline-block">
                      <button className="p-2 hover:bg-black/5 rounded-lg">
                        <MoreVertical className="w-4 h-4 text-black/60" />
                      </button>
                      <div className="absolute right-0 top-full hidden group-hover:flex flex-col bg-white border border-black/10 rounded-lg shadow-lg">
                        <button className="px-4 py-2 text-sm text-black hover:bg-black/5 flex items-center gap-2">
                          <Edit2 className="w-4 h-4" />
                          Edit
                        </button>
                        <button
                          onClick={() => handleDeleteBay(bay.id)}
                          className="px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2 border-t border-black/10"
                        >
                          <Trash2 className="w-4 h-4" />
                          Delete
                        </button>
                      </div>
                    </div>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={6} className="px-6 py-8 text-center text-black/60">
                  No service bays found
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <h2 className="text-xl font-bold text-black mb-4">Add New Service Bay</h2>
            
            <div className="space-y-4">
              <input
                type="text"
                placeholder="Bay Number (e.g., Bay 1)"
                value={formData.bayNumber}
                onChange={(e) => setFormData({ ...formData, bayNumber: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
              />
              <input
                type="text"
                placeholder="Description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
              />
              <select
                value={formData.type}
                onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
              >
                <option value="GENERAL">General Service Bay</option>
                <option value="PAINT_BOOTH">Paint Booth</option>
                <option value="WASH_STATION">Wash Station</option>
                <option value="ALIGNMENT_STATION">Alignment Station</option>
                <option value="DIAGNOSTIC_STATION">Diagnostic Station</option>
              </select>
              <input
                type="number"
                placeholder="Capacity"
                min="1"
                value={formData.capacity}
                onChange={(e) => setFormData({ ...formData, capacity: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
              />
            </div>

            <div className="flex gap-3 mt-6">
              <button
                onClick={() => setShowModal(false)}
                className="flex-1 px-4 py-2 bg-black/5 text-black rounded-lg hover:bg-black/10 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleAddBay}
                className="flex-1 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e64d1e] transition-colors"
              >
                Add Bay
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
