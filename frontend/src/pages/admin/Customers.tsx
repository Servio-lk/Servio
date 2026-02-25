import { useEffect, useState } from 'react';
import { adminApi } from '../../services/adminApi';
import { Users, Search, Mail, Phone, Filter, MoreVertical, Plus, X } from 'lucide-react';
import { toast } from 'sonner';

interface CustomerProfile {
  id: string;
  fullName?: string | null;
  email?: string | null;
  phone?: string | null;
  role?: string | null;
  createdAt?: string | null;
  joined?: string | null;
}

interface AdminCustomerUser {
  id: number;
  fullName: string;
  email: string;
  phone?: string | null;
  role: string;
  createdAt: string;
}

interface VehicleDto {
  id: number;
  userId: number;
  userName: string;
  make: string;
  model: string;
  year?: number | null;
  licensePlate?: string | null;
  vin?: string | null;
  createdAt: string;
  updatedAt: string;
}

interface ServiceRecordDto {
  id: number;
  vehicleId: number;
  vehicleMake: string;
  vehicleModel: string;
  serviceType: string;
  description?: string | null;
  serviceDate: string;
  mileage?: number | null;
  cost?: number | null;
  createdAt: string;
  updatedAt?: string;
}

interface CustomerVehicleHistory {
  vehicle: VehicleDto;
  serviceRecords: ServiceRecordDto[];
}

interface CustomerDetails {
  profile: CustomerProfile;
  user?: AdminCustomerUser | null;
  vehicles: CustomerVehicleHistory[];
}

interface WalkInCustomerDto {
  id: number;
  fullName: string;
  phone: string;
  email?: string | null;
  vehicleMake?: string | null;
  vehicleModel?: string | null;
  vehicleYear?: number | null;
  licensePlate?: string | null;
  notes?: string | null;
  isRegistered: boolean;
  registeredUserId?: number | null;
  createdAt: string;
}

interface WalkInCustomerForm {
  fullName: string;
  phone: string;
  email: string;
  vehicleMake: string;
  vehicleModel: string;
  vehicleYear: string;
  licensePlate: string;
  notes: string;
}

const emptyWalkInForm: WalkInCustomerForm = {
  fullName: '',
  phone: '',
  email: '',
  vehicleMake: '',
  vehicleModel: '',
  vehicleYear: '',
  licensePlate: '',
  notes: '',
};

export function AdminCustomers() {
  const [customers, setCustomers] = useState<CustomerProfile[]>([]);
  const [walkInCustomers, setWalkInCustomers] = useState<WalkInCustomerDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [walkInLoading, setWalkInLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCustomer, setSelectedCustomer] = useState<CustomerProfile | null>(null);
  const [customerDetails, setCustomerDetails] = useState<CustomerDetails | null>(null);
  const [detailsLoading, setDetailsLoading] = useState(false);
  const [walkInFormOpen, setWalkInFormOpen] = useState(false);
  const [walkInForm, setWalkInForm] = useState<WalkInCustomerForm>(emptyWalkInForm);
  const [walkInSubmitting, setWalkInSubmitting] = useState(false);

  useEffect(() => {
    loadCustomers();
    loadWalkInCustomers();
  }, []);

  const loadCustomers = async () => {
    try {
      setLoading(true);
      const response = await adminApi.getAllCustomers();
      setCustomers(response.data || []);
    } catch (error) {
      console.error('Failed to load customers:', error);
      toast.error('Failed to load customers');
    } finally {
      setLoading(false);
    }
  };

  const loadWalkInCustomers = async () => {
    try {
      setWalkInLoading(true);
      const response = await adminApi.getWalkInCustomers();
      setWalkInCustomers(response.data || []);
    } catch (error) {
      console.error('Failed to load walk-in customers:', error);
      toast.error('Failed to load walk-in customers');
    } finally {
      setWalkInLoading(false);
    }
  };

  const openCustomerDetails = async (customer: CustomerProfile) => {
    setSelectedCustomer(customer);
    setCustomerDetails(null);
    setDetailsLoading(true);
    try {
      const response = await adminApi.getCustomerDetails(customer.id);
      setCustomerDetails(response.data || null);
    } catch (error) {
      console.error('Failed to load customer details:', error);
      toast.error('Failed to load customer details');
    } finally {
      setDetailsLoading(false);
    }
  };

  const closeCustomerDetails = () => {
    setSelectedCustomer(null);
    setCustomerDetails(null);
  };

  const handleWalkInChange = (field: keyof WalkInCustomerForm, value: string) => {
    setWalkInForm((prev) => ({ ...prev, [field]: value }));
  };

  const handleCreateWalkIn = async () => {
    if (!walkInForm.fullName.trim() || !walkInForm.phone.trim()) {
      toast.error('Full name and phone are required');
      return;
    }

    try {
      setWalkInSubmitting(true);
      const payload = {
        fullName: walkInForm.fullName.trim(),
        phone: walkInForm.phone.trim(),
        email: walkInForm.email.trim() || null,
        vehicleMake: walkInForm.vehicleMake.trim() || null,
        vehicleModel: walkInForm.vehicleModel.trim() || null,
        vehicleYear: walkInForm.vehicleYear ? Number(walkInForm.vehicleYear) : null,
        licensePlate: walkInForm.licensePlate.trim() || null,
        notes: walkInForm.notes.trim() || null,
      };

      const response = await adminApi.createWalkInCustomer(payload);
      if (!response.success) {
        toast.error(response.message || 'Failed to create walk-in customer');
        return;
      }

      toast.success('Walk-in customer added');
      setWalkInForm(emptyWalkInForm);
      setWalkInFormOpen(false);
      loadWalkInCustomers();
    } catch (error) {
      console.error('Failed to create walk-in customer:', error);
      toast.error('Failed to create walk-in customer');
    } finally {
      setWalkInSubmitting(false);
    }
  };

  const filteredCustomers = customers.filter(
    (customer) =>
      (customer.fullName || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (customer.email || '').toLowerCase().includes(searchQuery.toLowerCase())
  );

  const formatDate = (dateString?: string | null) => {
    if (!dateString) return '—';
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const formatCurrency = (value?: number | null) => {
    if (value === null || value === undefined) return '—';
    return `LKR ${value.toLocaleString()}`;
  };

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
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-black">Customers Management</h1>
          <p className="text-black/70 mt-1">View customer profiles, vehicles, and service history</p>
        </div>
        <button
          onClick={() => setWalkInFormOpen(true)}
          className="flex items-center gap-2 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#ff4a1a] transition-colors"
        >
          <Plus className="w-4 h-4" />
          Add Walk-in
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl border border-black/5 shadow-sm p-6">
          <div className="text-sm text-gray-600 mb-1">Total Customers</div>
          <div className="text-3xl font-bold text-black">{customers.length}</div>
        </div>
        <div className="bg-white rounded-xl border border-black/5 shadow-sm p-6">
          <div className="text-sm text-gray-600 mb-1">Showing</div>
          <div className="text-3xl font-bold text-[#ff5d2e]">{filteredCustomers.length}</div>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-black/5 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-black/5 flex flex-col sm:flex-row gap-4 justify-between items-center">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search customers by name or email..."
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

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50/50 border-b border-black/5">
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">ID</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Name</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Email</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Phone</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Role</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Joined</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filteredCustomers.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-gray-500">
                    <div className="bg-gray-50 rounded-full w-16 h-16 flex items-center justify-center mx-auto mb-4">
                      <Users className="h-8 w-8 text-gray-400" />
                    </div>
                    <p className="text-lg font-medium text-black">No customers found</p>
                    <p className="text-sm text-gray-500">Try adjusting your search criteria.</p>
                  </td>
                </tr>
              ) : (
                filteredCustomers.map((customer) => (
                  <tr key={customer.id} className="hover:bg-gray-50/50 transition-colors group">
                    <td className="px-6 py-4 text-sm font-mono text-gray-400">
                      #{customer.id.slice(0, 8)}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="h-9 w-9 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold text-xs ring-2 ring-white">
                          {(customer.fullName || 'U').charAt(0).toUpperCase()}
                        </div>
                        <div className="font-medium text-black">
                          {customer.fullName || 'Unknown'}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center text-sm text-gray-600">
                        <Mail className="h-3.5 w-3.5 mr-2 text-gray-400" />
                        {customer.email || '—'}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center text-sm text-gray-600">
                        <Phone className="h-3.5 w-3.5 mr-2 text-gray-400" />
                        {customer.phone || 'N/A'}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 text-xs font-medium rounded-full border bg-gray-50 text-gray-700 border-gray-200">
                        {customer.role || 'CUSTOMER'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {formatDate(customer.createdAt || customer.joined)}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="relative inline-flex group">
                        <button className="text-gray-400 hover:text-black transition-colors p-1 rounded-full hover:bg-gray-100">
                          <MoreVertical className="w-4 h-4" />
                        </button>
                        <div className="absolute right-0 top-full mt-2 hidden group-hover:flex flex-col bg-white border border-black/10 rounded-lg shadow-lg z-10 min-w-[160px]">
                          <button
                            onClick={() => openCustomerDetails(customer)}
                            className="px-4 py-2 text-sm text-black hover:bg-gray-50 text-left"
                          >
                            View Profile
                          </button>
                          <button
                            onClick={() => openCustomerDetails(customer)}
                            className="px-4 py-2 text-sm text-black hover:bg-gray-50 text-left"
                          >
                            Service History
                          </button>
                        </div>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="p-4 border-t border-black/5 bg-gray-50/50 flex items-center justify-between text-xs text-gray-500">
          <span>Showing {filteredCustomers.length} results</span>
          <div className="flex gap-2">
            <button className="px-3 py-1 border rounded hover:bg-white disabled:opacity-50" disabled>Previous</button>
            <button className="px-3 py-1 border rounded hover:bg-white disabled:opacity-50" disabled>Next</button>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-black/5 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-black/5 flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-black">Walk-in Customers</h2>
            <p className="text-sm text-black/60">Quickly added customers without an account</p>
          </div>
          <span className="text-sm text-black/60">{walkInCustomers.length} total</span>
        </div>

        {walkInLoading ? (
          <div className="p-6 text-sm text-black/60">Loading walk-in customers...</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-gray-50/50 border-b border-black/5">
                  <th className="px-6 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Name</th>
                  <th className="px-6 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Phone</th>
                  <th className="px-6 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Vehicle</th>
                  <th className="px-6 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Plate</th>
                  <th className="px-6 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Added</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {walkInCustomers.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                      No walk-in customers yet.
                    </td>
                  </tr>
                ) : (
                  walkInCustomers.map((walkIn) => (
                    <tr key={walkIn.id} className="hover:bg-gray-50/50 transition-colors">
                      <td className="px-6 py-3 text-sm font-medium text-black">{walkIn.fullName}</td>
                      <td className="px-6 py-3 text-sm text-gray-600">{walkIn.phone}</td>
                      <td className="px-6 py-3 text-sm text-gray-600">
                        {[walkIn.vehicleMake, walkIn.vehicleModel, walkIn.vehicleYear]
                          .filter(Boolean)
                          .join(' ') || '—'}
                      </td>
                      <td className="px-6 py-3 text-sm text-gray-600">{walkIn.licensePlate || '—'}</td>
                      <td className="px-6 py-3 text-sm text-gray-500">{formatDate(walkIn.createdAt)}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {selectedCustomer && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-4xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h2 className="text-2xl font-bold text-black">{selectedCustomer.fullName || 'Customer Profile'}</h2>
                <p className="text-black/60">Customer profile and vehicle history</p>
              </div>
              <button
                onClick={closeCustomerDetails}
                className="text-black/60 hover:text-black text-2xl"
              >
                ×
              </button>
            </div>

            {detailsLoading ? (
              <div className="py-10 text-center text-black/60">Loading details...</div>
            ) : (
              <div className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="border border-black/5 rounded-lg p-4">
                    <p className="text-xs font-semibold text-black/50 mb-2">Profile</p>
                    <div className="space-y-2 text-sm text-black">
                      <div className="flex justify-between">
                        <span className="text-black/60">Email</span>
                        <span>{customerDetails?.profile.email || '—'}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-black/60">Phone</span>
                        <span>{customerDetails?.profile.phone || '—'}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-black/60">Joined</span>
                        <span>{formatDate(customerDetails?.profile.createdAt || customerDetails?.profile.joined || '')}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-black/60">Role</span>
                        <span>{customerDetails?.profile.role || 'CUSTOMER'}</span>
                      </div>
                    </div>
                  </div>

                  <div className="border border-black/5 rounded-lg p-4">
                    <p className="text-xs font-semibold text-black/50 mb-2">Account Link</p>
                    <div className="space-y-2 text-sm text-black">
                      <div className="flex justify-between">
                        <span className="text-black/60">User ID</span>
                        <span>{customerDetails?.user?.id ?? '—'}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-black/60">Email</span>
                        <span>{customerDetails?.user?.email || '—'}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-black/60">Role</span>
                        <span>{customerDetails?.user?.role || '—'}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-black/60">Created</span>
                        <span>{formatDate(customerDetails?.user?.createdAt)}</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="space-y-4">
                  <h3 className="text-lg font-semibold text-black">Vehicle Service History</h3>
                  {customerDetails?.vehicles?.length ? (
                    customerDetails.vehicles.map((vehicleHistory) => (
                      <div key={vehicleHistory.vehicle.id} className="border border-black/5 rounded-lg p-4">
                        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-2">
                          <div>
                            <p className="text-sm font-semibold text-black">
                              {vehicleHistory.vehicle.make} {vehicleHistory.vehicle.model}
                            </p>
                            <p className="text-xs text-black/60">
                              {vehicleHistory.vehicle.licensePlate || 'No plate'}
                              {vehicleHistory.vehicle.year ? ` • ${vehicleHistory.vehicle.year}` : ''}
                            </p>
                          </div>
                          <div className="text-xs text-black/60">
                            {vehicleHistory.serviceRecords.length} records
                          </div>
                        </div>

                        <div className="mt-3 space-y-2">
                          {vehicleHistory.serviceRecords.length === 0 ? (
                            <div className="text-sm text-black/50">No service records yet.</div>
                          ) : (
                            vehicleHistory.serviceRecords.map((record) => (
                              <div key={record.id} className="bg-gray-50/60 rounded-lg p-3 text-sm">
                                <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-2">
                                  <div>
                                    <p className="font-medium text-black">{record.serviceType}</p>
                                    <p className="text-xs text-black/50">
                                      {new Date(record.serviceDate).toLocaleDateString()}
                                      {record.mileage ? ` • ${record.mileage} km` : ''}
                                    </p>
                                  </div>
                                  <div className="text-sm font-semibold text-black">
                                    {formatCurrency(record.cost)}
                                  </div>
                                </div>
                                {record.description && (
                                  <p className="text-xs text-black/60 mt-2">{record.description}</p>
                                )}
                              </div>
                            ))
                          )}
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="text-sm text-black/50">No vehicles linked to this customer.</div>
                  )}
                </div>
              </div>
            )}

            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={closeCustomerDetails}
                className="px-4 py-2 bg-black/5 text-black rounded-lg hover:bg-black/10 transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {walkInFormOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-xl">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h2 className="text-xl font-bold text-black">Add Walk-in Customer</h2>
                <p className="text-black/60 text-sm">Quickly log customers without accounts.</p>
              </div>
              <button
                onClick={() => setWalkInFormOpen(false)}
                className="text-black/60 hover:text-black"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-semibold text-black/60">Full Name</label>
                <input
                  type="text"
                  value={walkInForm.fullName}
                  onChange={(e) => handleWalkInChange('fullName', e.target.value)}
                  className="mt-1 w-full px-3 py-2 border border-black/10 rounded-lg text-sm"
                  placeholder="e.g., Jane Silva"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-black/60">Phone</label>
                <input
                  type="text"
                  value={walkInForm.phone}
                  onChange={(e) => handleWalkInChange('phone', e.target.value)}
                  className="mt-1 w-full px-3 py-2 border border-black/10 rounded-lg text-sm"
                  placeholder="e.g., 0771234567"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-black/60">Email (optional)</label>
                <input
                  type="email"
                  value={walkInForm.email}
                  onChange={(e) => handleWalkInChange('email', e.target.value)}
                  className="mt-1 w-full px-3 py-2 border border-black/10 rounded-lg text-sm"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-black/60">Vehicle Make</label>
                <input
                  type="text"
                  value={walkInForm.vehicleMake}
                  onChange={(e) => handleWalkInChange('vehicleMake', e.target.value)}
                  className="mt-1 w-full px-3 py-2 border border-black/10 rounded-lg text-sm"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-black/60">Vehicle Model</label>
                <input
                  type="text"
                  value={walkInForm.vehicleModel}
                  onChange={(e) => handleWalkInChange('vehicleModel', e.target.value)}
                  className="mt-1 w-full px-3 py-2 border border-black/10 rounded-lg text-sm"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-black/60">Vehicle Year</label>
                <input
                  type="number"
                  value={walkInForm.vehicleYear}
                  onChange={(e) => handleWalkInChange('vehicleYear', e.target.value)}
                  className="mt-1 w-full px-3 py-2 border border-black/10 rounded-lg text-sm"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-black/60">License Plate</label>
                <input
                  type="text"
                  value={walkInForm.licensePlate}
                  onChange={(e) => handleWalkInChange('licensePlate', e.target.value)}
                  className="mt-1 w-full px-3 py-2 border border-black/10 rounded-lg text-sm"
                />
              </div>
              <div className="md:col-span-2">
                <label className="text-xs font-semibold text-black/60">Notes</label>
                <textarea
                  value={walkInForm.notes}
                  onChange={(e) => handleWalkInChange('notes', e.target.value)}
                  className="mt-1 w-full px-3 py-2 border border-black/10 rounded-lg text-sm min-h-[80px]"
                />
              </div>
            </div>

            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={() => setWalkInFormOpen(false)}
                className="px-4 py-2 bg-black/5 text-black rounded-lg hover:bg-black/10 transition-colors"
                disabled={walkInSubmitting}
              >
                Cancel
              </button>
              <button
                onClick={handleCreateWalkIn}
                className="px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e54d1e] transition-colors"
                disabled={walkInSubmitting}
              >
                {walkInSubmitting ? 'Saving...' : 'Save Walk-in'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
