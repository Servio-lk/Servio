import { useEffect, useState } from 'react';
import { Users, Search, Plus, MoreVertical, Trash2, Edit2 } from 'lucide-react';
import { toast } from 'sonner';

export function AdminWalkInCustomers() {
  const [customers, setCustomers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    fullName: '',
    phone: '',
    email: '',
    vehicleMake: '',
    vehicleModel: '',
    vehicleYear: '',
    licensePlate: '',
    notes: '',
  });

  useEffect(() => {
    loadCustomers();
  }, []);

  const loadCustomers = async () => {
    try {
      setLoading(true);
      const response = await fetch('http://localhost:3001/api/admin/walk-in-customers', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
      });
      const data = await response.json();
      setCustomers(data.data || []);
    } catch (error) {
      console.error('Failed to load customers:', error);
      toast.error('Failed to load customers');
    } finally {
      setLoading(false);
    }
  };

  const handleAddCustomer = async () => {
    if (!formData.fullName || !formData.phone) {
      toast.error('Please fill in required fields');
      return;
    }

    try {
      const response = await fetch('http://localhost:3001/api/admin/walk-in-customers', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
        body: JSON.stringify({
          ...formData,
          vehicleYear: formData.vehicleYear ? parseInt(formData.vehicleYear) : null,
        }),
      });
      
      if (response.ok) {
        toast.success('Walk-in customer added successfully');
        setShowModal(false);
        setFormData({
          fullName: '',
          phone: '',
          email: '',
          vehicleMake: '',
          vehicleModel: '',
          vehicleYear: '',
          licensePlate: '',
          notes: '',
        });
        loadCustomers();
      } else {
        toast.error('Failed to add customer');
      }
    } catch (error) {
      toast.error('Error adding customer');
    }
  };

  const handleDeleteCustomer = async (id: number) => {
    if (confirm('Are you sure you want to delete this customer?')) {
      try {
        const response = await fetch(`http://localhost:3001/api/admin/walk-in-customers/${id}`, {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`,
          },
        });
        
        if (response.ok) {
          toast.success('Customer deleted successfully');
          loadCustomers();
        } else {
          toast.error('Failed to delete customer');
        }
      } catch (error) {
        toast.error('Error deleting customer');
      }
    }
  };

  const filteredCustomers = customers.filter(
    (customer) =>
      customer.fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      customer.phone.includes(searchQuery)
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#ff5d2e] mx-auto"></div>
          <p className="mt-4 text-black/70">Loading customers...</p>
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
            <Users className="w-6 h-6 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-black">Walk-In Customers</h1>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="flex items-center gap-2 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e64d1e] transition-colors"
        >
          <Plus className="w-5 h-5" />
          <span>Add Walk-In</span>
        </button>
      </div>

      {/* Search Bar */}
      <div className="relative">
        <Search className="absolute left-3 top-3 w-5 h-5 text-black/40" />
        <input
          type="text"
          placeholder="Search by name or phone..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full pl-10 pr-4 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
        />
      </div>

      {/* Customers List */}
      <div className="space-y-3">
        {filteredCustomers.length > 0 ? (
          filteredCustomers.map((customer) => (
            <div key={customer.id} className="bg-white rounded-lg border border-black/10 p-4">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <h3 className="font-semibold text-black">{customer.fullName}</h3>
                  <div className="grid grid-cols-2 gap-4 mt-3 text-sm">
                    <div>
                      <p className="text-black/60">Phone</p>
                      <p className="text-black">{customer.phone}</p>
                    </div>
                    <div>
                      <p className="text-black/60">Email</p>
                      <p className="text-black">{customer.email || 'N/A'}</p>
                    </div>
                    {customer.vehicleMake && (
                      <div>
                        <p className="text-black/60">Vehicle</p>
                        <p className="text-black">
                          {customer.vehicleYear} {customer.vehicleMake} {customer.vehicleModel}
                        </p>
                      </div>
                    )}
                    {customer.licensePlate && (
                      <div>
                        <p className="text-black/60">License Plate</p>
                        <p className="text-black">{customer.licensePlate}</p>
                      </div>
                    )}
                  </div>
                  {customer.notes && (
                    <div className="mt-3 p-2 bg-black/2 rounded text-sm text-black/70">
                      <p className="font-medium text-black/60">Notes:</p>
                      <p>{customer.notes}</p>
                    </div>
                  )}
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
                      onClick={() => handleDeleteCustomer(customer.id)}
                      className="px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2 border-t border-black/10"
                    >
                      <Trash2 className="w-4 h-4" />
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))
        ) : (
          <div className="text-center py-8">
            <Users className="w-12 h-12 text-black/20 mx-auto mb-3" />
            <p className="text-black/60">No walk-in customers found</p>
          </div>
        )}
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold text-black mb-4">Add Walk-In Customer</h2>
            
            <div className="space-y-3">
              <input
                type="text"
                placeholder="Full Name *"
                value={formData.fullName}
                onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
              />
              <input
                type="tel"
                placeholder="Phone *"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
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
                type="text"
                placeholder="Vehicle Make"
                value={formData.vehicleMake}
                onChange={(e) => setFormData({ ...formData, vehicleMake: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
              />
              <input
                type="text"
                placeholder="Vehicle Model"
                value={formData.vehicleModel}
                onChange={(e) => setFormData({ ...formData, vehicleModel: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
              />
              <input
                type="number"
                placeholder="Vehicle Year"
                value={formData.vehicleYear}
                onChange={(e) => setFormData({ ...formData, vehicleYear: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
              />
              <input
                type="text"
                placeholder="License Plate"
                value={formData.licensePlate}
                onChange={(e) => setFormData({ ...formData, licensePlate: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
              />
              <textarea
                placeholder="Notes"
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                className="w-full px-3 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e] resize-none h-24"
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
                onClick={handleAddCustomer}
                className="flex-1 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e64d1e] transition-colors"
              >
                Add Customer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
