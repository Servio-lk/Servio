import { useEffect, useState } from 'react';
import { Wrench, Search, Plus, MoreVertical, Trash2, Edit2 } from 'lucide-react';
import { toast } from 'sonner';

export function AdminMechanics() {
  const [mechanics, setMechanics] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phone: '',
    specialization: '',
    experienceYears: '',
  });

  useEffect(() => {
    loadMechanics();
  }, []);

  const loadMechanics = async () => {
    try {
      setLoading(true);
      const response = await fetch('http://localhost:3001/api/admin/mechanics', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
      });
      const data = await response.json();
      setMechanics(data.data || []);
    } catch (error) {
      console.error('Failed to load mechanics:', error);
      toast.error('Failed to load mechanics');
    } finally {
      setLoading(false);
    }
  };

  const handleAddMechanic = async () => {
    if (!formData.fullName || !formData.email || !formData.phone) {
      toast.error('Please fill in all required fields');
      return;
    }

    try {
      const response = await fetch('http://localhost:3001/api/admin/mechanics', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
        body: JSON.stringify(formData),
      });
      
      if (response.ok) {
        toast.success('Mechanic added successfully');
        setShowModal(false);
        setFormData({
          fullName: '',
          email: '',
          phone: '',
          specialization: '',
          experienceYears: '',
        });
        loadMechanics();
      } else {
        toast.error('Failed to add mechanic');
      }
    } catch (error) {
      toast.error('Error adding mechanic');
    }
  };

  const handleDeleteMechanic = async (id: number) => {
    if (confirm('Are you sure you want to delete this mechanic?')) {
      try {
        const response = await fetch(`http://localhost:3001/api/admin/mechanics/${id}`, {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`,
          },
        });
        
        if (response.ok) {
          toast.success('Mechanic deleted successfully');
          loadMechanics();
        } else {
          toast.error('Failed to delete mechanic');
        }
      } catch (error) {
        toast.error('Error deleting mechanic');
      }
    }
  };

  const filteredMechanics = mechanics.filter(
    (mechanic) =>
      mechanic.fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      mechanic.specialization?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#ff5d2e] mx-auto"></div>
          <p className="mt-4 text-black/70">Loading mechanics...</p>
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
            <Wrench className="w-6 h-6 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-black">Mechanics Management</h1>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="flex items-center gap-2 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e64d1e] transition-colors"
        >
          <Plus className="w-5 h-5" />
          <span>Add Mechanic</span>
        </button>
      </div>

      {/* Search Bar */}
      <div className="relative">
        <Search className="absolute left-3 top-3 w-5 h-5 text-black/40" />
        <input
          type="text"
          placeholder="Search mechanics..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full pl-10 pr-4 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
        />
      </div>

      {/* Mechanics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredMechanics.length > 0 ? (
          filteredMechanics.map((mechanic) => (
            <div key={mechanic.id} className="bg-white rounded-lg border border-black/10 p-4">
              <div className="flex items-start justify-between mb-3">
                <div className="flex-1">
                  <h3 className="font-semibold text-black">{mechanic.fullName}</h3>
                  <p className="text-sm text-black/60">{mechanic.specialization || 'General Service'}</p>
                </div>
                <div className="relative group">
                  <button className="p-2 hover:bg-black/5 rounded-lg">
                    <MoreVertical className="w-4 h-4 text-black/60" />
                  </button>
                  <div className="absolute right-0 top-full hidden group-hover:flex flex-col bg-white border border-black/10 rounded-lg shadow-lg">
                    <button className="px-4 py-2 text-sm text-black hover:bg-black/5 flex items-center gap-2">
                      <Edit2 className="w-4 h-4" />
                      Edit
                    </button>
                    <button
                      onClick={() => handleDeleteMechanic(mechanic.id)}
                      className="px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2 border-t border-black/10"
                    >
                      <Trash2 className="w-4 h-4" />
                      Delete
                    </button>
                  </div>
                </div>
              </div>

              <div className="space-y-2 text-sm">
                <div className="flex items-center gap-2">
                  <span className="text-black/60">Email:</span>
                  <span className="text-black">{mechanic.email}</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-black/60">Phone:</span>
                  <span className="text-black">{mechanic.phone}</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-black/60">Experience:</span>
                  <span className="text-black">{mechanic.experienceYears || '-'} years</span>
                </div>
                <div className="flex items-center gap-2 pt-2">
                  <span className={`px-2 py-1 text-xs rounded-full font-medium ${
                    mechanic.status === 'AVAILABLE' 
                      ? 'bg-green-50 text-green-700' 
                      : 'bg-yellow-50 text-yellow-700'
                  }`}>
                    {mechanic.status || 'AVAILABLE'}
                  </span>
                </div>
              </div>
            </div>
          ))
        ) : (
          <div className="col-span-full text-center py-8">
            <Wrench className="w-12 h-12 text-black/20 mx-auto mb-3" />
            <p className="text-black/60">No mechanics found</p>
          </div>
        )}
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <h2 className="text-xl font-bold text-black mb-4">Add New Mechanic</h2>
            
            <div className="space-y-4">
              <input
                type="text"
                placeholder="Full Name"
                value={formData.fullName}
                onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
              />
              <input
                type="email"
                placeholder="Email"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
              />
              <input
                type="tel"
                placeholder="Phone"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
              />
              <input
                type="text"
                placeholder="Specialization (e.g., Engine, Electrical)"
                value={formData.specialization}
                onChange={(e) => setFormData({ ...formData, specialization: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
              />
              <input
                type="number"
                placeholder="Years of Experience"
                value={formData.experienceYears}
                onChange={(e) => setFormData({ ...formData, experienceYears: e.target.value })}
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
                onClick={handleAddMechanic}
                className="flex-1 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e64d1e] transition-colors"
              >
                Add Mechanic
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
