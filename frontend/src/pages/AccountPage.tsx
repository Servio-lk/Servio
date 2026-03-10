import { useState, useEffect } from 'react';
import {
  User, Car, Plus, Pencil, Trash2, Clock, Tag,
  Phone, MapPin, Mail, ChevronDown, ChevronUp, X, Save,
  Wrench, Calendar, BadgeDollarSign, Shield, HelpCircle,
} from 'lucide-react';
import { AppLayout } from '@/components/layouts/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import { apiService } from '@/services/api';
import type { VehicleDto, VehicleRequest, AppointmentDto, Offer } from '@/services/api';
import { OfferCard } from '@/components/OfferCard';
import { toast } from 'sonner';

// Service center info (static)
const SERVICE_CENTER = {
  name: 'Servio Service Center',
  address: 'No. 45, Galle Road, Colombo 03, Sri Lanka',
  phone: '+94 11 234 5678',
  mobile: '+94 76 123 4567',
  email: 'support@servio.lk',
  hours: [
    { days: 'Monday - Friday', time: '8:00 AM - 6:00 PM' },
    { days: 'Saturday', time: '8:00 AM - 2:00 PM' },
    { days: 'Sunday', time: 'Closed' },
  ],
};

function statusBadge(status: string) {
  const map: Record<string, string> = {
    PENDING: 'bg-yellow-50 text-yellow-700',
    CONFIRMED: 'bg-blue-50 text-blue-700',
    IN_PROGRESS: 'bg-purple-50 text-purple-700',
    COMPLETED: 'bg-green-50 text-green-700',
    CANCELLED: 'bg-red-50 text-red-700',
  };
  return map[status.toUpperCase()] || 'bg-gray-50 text-gray-700';
}

const emptyVehicle: VehicleRequest = {
  make: '',
  model: '',
  year: new Date().getFullYear(),
  licensePlate: '',
  vin: '',
};

export default function AccountPage() {
  const { user } = useAuth();

  // Vehicles
  const [vehicles, setVehicles] = useState<VehicleDto[]>([]);
  const [vehiclesLoading, setVehiclesLoading] = useState(true);
  const [showVehicleForm, setShowVehicleForm] = useState(false);
  const [editingVehicleId, setEditingVehicleId] = useState<number | null>(null);
  const [vehicleForm, setVehicleForm] = useState<VehicleRequest>({ ...emptyVehicle });

  // Last service
  const [lastService, setLastService] = useState<AppointmentDto | null>(null);
  const [serviceLoading, setServiceLoading] = useState(true);

  // Offers / promotions
  const [offers, setOffers] = useState<Offer[]>([]);
  const [offersLoading, setOffersLoading] = useState(true);

  // Collapsible sections
  const [openSections, setOpenSections] = useState<Record<string, boolean>>({
    profile: true,
    vehicles: true,
    lastService: true,
    promotions: false,
    help: false,
  });
  const toggle = (key: string) =>
    setOpenSections((p) => ({ ...p, [key]: !p[key] }));

  // Fetch data on mount
  useEffect(() => {
    if (!user) return;

    apiService
      .getMyVehicles()
      .then((res) => {
        if (res.success && res.data) setVehicles(res.data);
      })
      .catch(() => {})
      .finally(() => setVehiclesLoading(false));

    apiService
      .getUserAppointments()
      .then((res) => {
        if (res.success && res.data && res.data.length > 0) {
          const sorted = [...res.data].sort(
            (a, b) =>
              new Date(b.appointmentDate).getTime() -
              new Date(a.appointmentDate).getTime()
          );
          setLastService(sorted[0]);
        }
      })
      .catch(() => {})
      .finally(() => setServiceLoading(false));

    apiService
      .getActiveOffers()
      .then((res) => {
        if (res.success && res.data) setOffers(res.data);
      })
      .catch(() => {})
      .finally(() => setOffersLoading(false));
  }, [user]);

  // Vehicle CRUD handlers
  const openAddForm = () => {
    setEditingVehicleId(null);
    setVehicleForm({ ...emptyVehicle });
    setShowVehicleForm(true);
  };

  const openEditForm = (v: VehicleDto) => {
    setEditingVehicleId(v.id);
    setVehicleForm({
      userId: v.userId,
      make: v.make,
      model: v.model,
      year: v.year,
      licensePlate: v.licensePlate,
      vin: v.vin,
    });
    setShowVehicleForm(true);
  };

  const closeForm = () => {
    setShowVehicleForm(false);
    setEditingVehicleId(null);
    setVehicleForm({ ...emptyVehicle });
  };

  const saveVehicle = async () => {
    if (!vehicleForm.make || !vehicleForm.model || !vehicleForm.licensePlate) {
      toast.error('Please fill in make, model and license plate');
      return;
    }
    try {
      if (editingVehicleId) {
        const res = await apiService.updateVehicle(editingVehicleId, vehicleForm);
        if (res.success && res.data) {
          setVehicles((prev) =>
            prev.map((v) => (v.id === editingVehicleId ? res.data! : v))
          );
          toast.success('Vehicle updated');
        }
      } else {
        const res = await apiService.createVehicle(vehicleForm);
        if (res.success && res.data) {
          setVehicles((prev) => [...prev, res.data!]);
          toast.success('Vehicle added');
        }
      }
      closeForm();
    } catch {
      toast.error('Failed to save vehicle');
    }
  };

  const removeVehicle = async (id: number) => {
    try {
      await apiService.deleteVehicle(id);
      setVehicles((prev) => prev.filter((v) => v.id !== id));
      toast.success('Vehicle deleted');
    } catch {
      toast.error('Failed to delete vehicle');
    }
  };

  // Section header component
  const SectionHeader = ({
    icon: Icon,
    title,
    sectionKey,
  }: {
    icon: React.ElementType;
    title: string;
    sectionKey: string;
  }) => (
    <button
      onClick={() => toggle(sectionKey)}
      className="w-full flex items-center justify-between py-3"
    >
      <div className="flex items-center gap-3">
        <div className="w-9 h-9 bg-[#ffe7df] rounded-lg flex items-center justify-center">
          <Icon className="w-5 h-5 text-[#ff5d2e]" />
        </div>
        <h2 className="text-base font-semibold text-black">{title}</h2>
      </div>
      {openSections[sectionKey] ? (
        <ChevronUp className="w-5 h-5 text-black/40" />
      ) : (
        <ChevronDown className="w-5 h-5 text-black/40" />
      )}
    </button>
  );

  return (
    <AppLayout>
      <div className="flex flex-col gap-4 lg:gap-6">
        <h1 className="text-xl lg:text-2xl font-bold text-black">My Account</h1>

        {/* ── PROFILE ── */}
        <div className="bg-white rounded-2xl shadow-sm px-5">
          <SectionHeader icon={User} title="Profile" sectionKey="profile" />
          {openSections.profile && (
            <div className="pb-5 flex flex-col gap-4">
              <div className="flex items-center gap-4">
                <div className="w-16 h-16 bg-[#ffe7df] rounded-full flex items-center justify-center">
                  <User className="w-8 h-8 text-[#ff5d2e]" />
                </div>
                <div>
                  <p className="text-lg font-semibold text-black">
                    {user?.fullName || 'User'}
                  </p>
                  <p className="text-sm text-black/50">
                    {user?.role || 'Customer'}
                  </p>
                </div>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="flex items-center gap-3 p-3 bg-[#fff7f5] rounded-lg">
                  <Mail className="w-4 h-4 text-[#ff5d2e]" />
                  <span className="text-sm text-black">
                    {user?.email || '—'}
                  </span>
                </div>
                <div className="flex items-center gap-3 p-3 bg-[#fff7f5] rounded-lg">
                  <Phone className="w-4 h-4 text-[#ff5d2e]" />
                  <span className="text-sm text-black">
                    {user?.phone || 'Not set'}
                  </span>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* ── MY VEHICLES ── */}
        <div className="bg-white rounded-2xl shadow-sm px-5">
          <SectionHeader icon={Car} title="My Vehicles" sectionKey="vehicles" />
          {openSections.vehicles && (
            <div className="pb-5 flex flex-col gap-3">
              {vehiclesLoading ? (
                <p className="text-sm text-black/40 text-center py-4">
                  Loading vehicles…
                </p>
              ) : vehicles.length === 0 ? (
                <p className="text-sm text-black/40 text-center py-4">
                  No vehicles added yet
                </p>
              ) : (
                vehicles.map((v) => (
                  <div
                    key={v.id}
                    className="flex items-center gap-4 p-4 bg-[#fff7f5] rounded-xl"
                  >
                    <div className="w-11 h-11 bg-[#ffe7df] rounded-lg flex items-center justify-center">
                      <Car className="w-6 h-6 text-[#ff5d2e]" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-semibold text-black text-sm">
                        {v.make} {v.model}{' '}
                        <span className="text-black/40">({v.year})</span>
                      </p>
                      <p className="text-xs text-black/50 mt-0.5">
                        {v.licensePlate}
                        {v.vin ? ` • VIN: ${v.vin}` : ''}
                      </p>
                    </div>
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => openEditForm(v)}
                        className="p-2 hover:bg-white rounded-lg transition-colors"
                        title="Edit"
                      >
                        <Pencil className="w-4 h-4 text-black/40" />
                      </button>
                      <button
                        onClick={() => removeVehicle(v.id)}
                        className="p-2 hover:bg-red-50 rounded-lg transition-colors"
                        title="Delete"
                      >
                        <Trash2 className="w-4 h-4 text-red-400" />
                      </button>
                    </div>
                  </div>
                ))
              )}

              {showVehicleForm ? (
                <div className="bg-[#fff7f5] rounded-xl p-4 flex flex-col gap-3 border border-[#ffe7df]">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-semibold text-black">
                      {editingVehicleId ? 'Edit Vehicle' : 'Add Vehicle'}
                    </p>
                    <button
                      onClick={closeForm}
                      className="p-1 hover:bg-white rounded transition-colors"
                    >
                      <X className="w-4 h-4 text-black/40" />
                    </button>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <input
                      placeholder="Make (e.g. Toyota)"
                      value={vehicleForm.make}
                      onChange={(e) =>
                        setVehicleForm((p) => ({ ...p, make: e.target.value }))
                      }
                      className="w-full p-3 bg-white rounded-lg border border-black/10 text-sm outline-none focus:border-[#ff5d2e] transition-colors"
                    />
                    <input
                      placeholder="Model (e.g. Premio)"
                      value={vehicleForm.model}
                      onChange={(e) =>
                        setVehicleForm((p) => ({ ...p, model: e.target.value }))
                      }
                      className="w-full p-3 bg-white rounded-lg border border-black/10 text-sm outline-none focus:border-[#ff5d2e] transition-colors"
                    />
                    <input
                      placeholder="Year (e.g. 2020)"
                      type="number"
                      value={vehicleForm.year}
                      onChange={(e) =>
                        setVehicleForm((p) => ({
                          ...p,
                          year: Number(e.target.value),
                        }))
                      }
                      className="w-full p-3 bg-white rounded-lg border border-black/10 text-sm outline-none focus:border-[#ff5d2e] transition-colors"
                    />
                    <input
                      placeholder="License Plate (e.g. CAR-1234)"
                      value={vehicleForm.licensePlate}
                      onChange={(e) =>
                        setVehicleForm((p) => ({
                          ...p,
                          licensePlate: e.target.value,
                        }))
                      }
                      className="w-full p-3 bg-white rounded-lg border border-black/10 text-sm outline-none focus:border-[#ff5d2e] transition-colors"
                    />
                    <input
                      placeholder="VIN (optional)"
                      value={vehicleForm.vin || ''}
                      onChange={(e) =>
                        setVehicleForm((p) => ({ ...p, vin: e.target.value }))
                      }
                      className="w-full p-3 bg-white rounded-lg border border-black/10 text-sm outline-none focus:border-[#ff5d2e] transition-colors sm:col-span-2"
                    />
                  </div>
                  <button
                    onClick={saveVehicle}
                    className="self-end flex items-center gap-2 bg-[#ff5d2e] text-white text-sm font-medium px-5 py-2.5 rounded-lg hover:bg-[#e54d1e] transition-colors"
                  >
                    <Save className="w-4 h-4" />
                    {editingVehicleId ? 'Update' : 'Save'}
                  </button>
                </div>
              ) : (
                <button
                  onClick={openAddForm}
                  className="flex items-center gap-2 justify-center w-full py-3 border-2 border-dashed border-[#ffe7df] rounded-xl text-sm font-medium text-[#ff5d2e] hover:bg-[#fff7f5] transition-colors"
                >
                  <Plus className="w-4 h-4" />
                  Add Vehicle
                </button>
              )}
            </div>
          )}
        </div>

        {/* ── LAST SERVICE DETAILS ── */}
        <div className="bg-white rounded-2xl shadow-sm px-5">
          <SectionHeader
            icon={Wrench}
            title="Last Service Details"
            sectionKey="lastService"
          />
          {openSections.lastService && (
            <div className="pb-5">
              {serviceLoading ? (
                <p className="text-sm text-black/40 text-center py-4">
                  Loading…
                </p>
              ) : !lastService ? (
                <p className="text-sm text-black/40 text-center py-4">
                  No past services found
                </p>
              ) : (
                <div className="bg-[#fff7f5] rounded-xl p-4 flex flex-col gap-3">
                  <div className="flex items-center justify-between">
                    <p className="font-semibold text-black">
                      {lastService.serviceType}
                    </p>
                    <span
                      className={`text-xs font-semibold px-2.5 py-1 rounded-full ${statusBadge(lastService.status)}`}
                    >
                      {lastService.status.replace('_', ' ')}
                    </span>
                  </div>
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                    <div className="flex items-center gap-2">
                      <Calendar className="w-4 h-4 text-[#ff5d2e]" />
                      <div>
                        <p className="text-[10px] text-black/40 uppercase tracking-wide">
                          Date
                        </p>
                        <p className="text-sm font-medium text-black">
                          {new Date(
                            lastService.appointmentDate
                          ).toLocaleDateString('en-US', {
                            month: 'short',
                            day: 'numeric',
                            year: 'numeric',
                          })}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Clock className="w-4 h-4 text-[#ff5d2e]" />
                      <div>
                        <p className="text-[10px] text-black/40 uppercase tracking-wide">
                          Time
                        </p>
                        <p className="text-sm font-medium text-black">
                          {new Date(
                            lastService.appointmentDate
                          ).toLocaleTimeString('en-US', {
                            hour: '2-digit',
                            minute: '2-digit',
                          })}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <BadgeDollarSign className="w-4 h-4 text-[#ff5d2e]" />
                      <div>
                        <p className="text-[10px] text-black/40 uppercase tracking-wide">
                          Cost
                        </p>
                        <p className="text-sm font-medium text-black">
                          LKR{' '}
                          {(
                            lastService.actualCost ??
                            lastService.estimatedCost ??
                            0
                          ).toLocaleString()}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <MapPin className="w-4 h-4 text-[#ff5d2e]" />
                      <div>
                        <p className="text-[10px] text-black/40 uppercase tracking-wide">
                          Location
                        </p>
                        <p className="text-sm font-medium text-black">
                          {lastService.location || 'Service Center'}
                        </p>
                      </div>
                    </div>
                  </div>
                  {lastService.notes && (
                    <p className="text-xs text-black/50 mt-1 border-t border-black/5 pt-2">
                      {lastService.notes}
                    </p>
                  )}
                </div>
              )}
            </div>
          )}
        </div>

        {/* ── PROMOTIONS & OFFERS ── */}
        <div className="bg-white rounded-2xl shadow-sm px-5">
          <SectionHeader
            icon={Tag}
            title="Promotions & Offers"
            sectionKey="promotions"
          />
          {openSections.promotions && (
            <div className="pb-5">
              {offersLoading ? (
                <p className="text-sm text-black/40 text-center py-4">
                  Loading offers…
                </p>
              ) : offers.length === 0 ? (
                <p className="text-sm text-black/40 text-center py-4">
                  No active promotions right now
                </p>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {offers.map((offer) => (
                    <OfferCard
                      key={offer.id}
                      id={offer.id}
                      title={offer.title}
                      subtitle={offer.subtitle}
                      discountType={offer.discountType}
                      discountValue={offer.discountValue}
                      imageUrl={offer.imageUrl}
                    />
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        {/* ── SERVICE CENTER HELP ── */}
        <div className="bg-white rounded-2xl shadow-sm px-5">
          <SectionHeader
            icon={HelpCircle}
            title="Service Center Help"
            sectionKey="help"
          />
          {openSections.help && (
            <div className="pb-5 flex flex-col gap-4">
              <div className="flex flex-col gap-3">
                <div className="flex items-center gap-3 p-3 bg-[#fff7f5] rounded-lg">
                  <Shield className="w-5 h-5 text-[#ff5d2e]" />
                  <div>
                    <p className="text-sm font-semibold text-black">
                      {SERVICE_CENTER.name}
                    </p>
                    <p className="text-xs text-black/50">
                      {SERVICE_CENTER.address}
                    </p>
                  </div>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <a
                    href={`tel:${SERVICE_CENTER.phone}`}
                    className="flex items-center gap-3 p-3 bg-[#fff7f5] rounded-lg hover:bg-[#ffe7df] transition-colors"
                  >
                    <Phone className="w-4 h-4 text-[#ff5d2e]" />
                    <div>
                      <p className="text-[10px] text-black/40 uppercase tracking-wide">
                        Phone
                      </p>
                      <p className="text-sm font-medium text-black">
                        {SERVICE_CENTER.phone}
                      </p>
                    </div>
                  </a>
                  <a
                    href={`tel:${SERVICE_CENTER.mobile}`}
                    className="flex items-center gap-3 p-3 bg-[#fff7f5] rounded-lg hover:bg-[#ffe7df] transition-colors"
                  >
                    <Phone className="w-4 h-4 text-[#ff5d2e]" />
                    <div>
                      <p className="text-[10px] text-black/40 uppercase tracking-wide">
                        Mobile
                      </p>
                      <p className="text-sm font-medium text-black">
                        {SERVICE_CENTER.mobile}
                      </p>
                    </div>
                  </a>
                  <a
                    href={`mailto:${SERVICE_CENTER.email}`}
                    className="flex items-center gap-3 p-3 bg-[#fff7f5] rounded-lg hover:bg-[#ffe7df] transition-colors sm:col-span-2"
                  >
                    <Mail className="w-4 h-4 text-[#ff5d2e]" />
                    <div>
                      <p className="text-[10px] text-black/40 uppercase tracking-wide">
                        Email
                      </p>
                      <p className="text-sm font-medium text-black">
                        {SERVICE_CENTER.email}
                      </p>
                    </div>
                  </a>
                </div>
              </div>

              <div>
                <p className="text-sm font-semibold text-black mb-2">
                  Operating Hours
                </p>
                <div className="flex flex-col gap-2">
                  {SERVICE_CENTER.hours.map((h) => (
                    <div
                      key={h.days}
                      className="flex items-center justify-between p-3 bg-[#fff7f5] rounded-lg"
                    >
                      <span className="text-sm text-black">{h.days}</span>
                      <span
                        className={`text-sm font-medium ${h.time === 'Closed' ? 'text-red-500' : 'text-black'}`}
                      >
                        {h.time}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </AppLayout>
  );
}
