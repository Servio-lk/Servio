import { useEffect, useMemo, useState } from 'react';
import { CalendarDays, Edit2, Plus, Search, Trash2, Wrench } from 'lucide-react';
import { toast } from 'sonner';
import { adminApi } from '@/services/adminApi';

type StaffMember = {
  id: number;
  fullName: string;
  email: string;
  phone: string;
  specialization?: string;
  experienceYears?: number;
  status?: string;
  isActive?: boolean;
  activeJobCount?: number;
};

type StaffForm = {
  fullName: string;
  email: string;
  phone: string;
  specialization: string;
  experienceYears: string;
  status: string;
  isActive: boolean;
};

const emptyForm: StaffForm = {
  fullName: '',
  email: '',
  phone: '',
  specialization: '',
  experienceYears: '',
  status: 'AVAILABLE',
  isActive: true,
};

const defaultWorkingHours = [
  { dayOfWeek: 'MONDAY', shiftStart: '09:00', shiftEnd: '17:00' },
  { dayOfWeek: 'TUESDAY', shiftStart: '09:00', shiftEnd: '17:00' },
  { dayOfWeek: 'WEDNESDAY', shiftStart: '09:00', shiftEnd: '17:00' },
  { dayOfWeek: 'THURSDAY', shiftStart: '09:00', shiftEnd: '17:00' },
  { dayOfWeek: 'FRIDAY', shiftStart: '09:00', shiftEnd: '17:00' },
];

export function AdminMechanics() {
  const [staff, setStaff] = useState<StaffMember[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [showStaffModal, setShowStaffModal] = useState(false);
  const [editing, setEditing] = useState<StaffMember | null>(null);
  const [formData, setFormData] = useState<StaffForm>(emptyForm);
  const [scheduleFor, setScheduleFor] = useState<StaffMember | null>(null);
  const [workingHours, setWorkingHours] = useState(defaultWorkingHours);
  const [unavailableBlocks, setUnavailableBlocks] = useState<any[]>([]);

  useEffect(() => {
    loadStaff();
  }, []);

  const loadStaff = async () => {
    try {
      setLoading(true);
      const response = await adminApi.getStaff();
      setStaff(response.data || []);
    } catch (error) {
      console.error('Failed to load staff:', error);
      toast.error('Failed to load staff');
    } finally {
      setLoading(false);
    }
  };

  const filteredStaff = useMemo(() => {
    const query = searchQuery.toLowerCase();
    return staff.filter((member) =>
      member.fullName?.toLowerCase().includes(query) ||
      member.email?.toLowerCase().includes(query) ||
      member.specialization?.toLowerCase().includes(query)
    );
  }, [searchQuery, staff]);

  const openCreate = () => {
    setEditing(null);
    setFormData(emptyForm);
    setShowStaffModal(true);
  };

  const openEdit = (member: StaffMember) => {
    setEditing(member);
    setFormData({
      fullName: member.fullName || '',
      email: member.email || '',
      phone: member.phone || '',
      specialization: member.specialization || '',
      experienceYears: member.experienceYears ? String(member.experienceYears) : '',
      status: member.status || 'AVAILABLE',
      isActive: member.isActive !== false,
    });
    setShowStaffModal(true);
  };

  const closeForm = () => {
    setEditing(null);
    setFormData(emptyForm);
    setShowStaffModal(false);
  };

  const saveStaff = async () => {
    if (!formData.fullName || !formData.email || !formData.phone) {
      toast.error('Please fill in name, email, and phone');
      return;
    }

    const payload = {
      ...formData,
      experienceYears: formData.experienceYears ? Number(formData.experienceYears) : null,
    };

    try {
      const response = editing
        ? await adminApi.updateStaff(editing.id, payload)
        : await adminApi.createStaff(payload);
      if (!response.success) throw new Error(response.message);
      toast.success(editing ? 'Staff member updated' : 'Staff member created');
      closeForm();
      loadStaff();
    } catch (error: any) {
      toast.error(error.message || 'Failed to save staff member');
    }
  };

  const deactivateStaff = async (member: StaffMember) => {
    if (!confirm(`Deactivate ${member.fullName}?`)) return;
    try {
      const response = await adminApi.updateStaff(member.id, { ...member, isActive: false });
      if (!response.success) throw new Error(response.message);
      toast.success('Staff member deactivated');
      loadStaff();
    } catch (error: any) {
      toast.error(error.message || 'Failed to deactivate staff member');
    }
  };

  const openSchedule = async (member: StaffMember) => {
    setScheduleFor(member);
    try {
      const response = await adminApi.getStaffSchedule(member.id);
      setWorkingHours(response.data?.workingHours?.length ? response.data.workingHours : defaultWorkingHours);
      setUnavailableBlocks(response.data?.unavailableBlocks || []);
    } catch {
      setWorkingHours(defaultWorkingHours);
      setUnavailableBlocks([]);
    }
  };

  const saveSchedule = async () => {
    if (!scheduleFor) return;
    try {
      const response = await adminApi.updateStaffSchedule(scheduleFor.id, { workingHours, unavailableBlocks });
      if (!response.success) throw new Error(response.message);
      toast.success('Schedule saved');
      setScheduleFor(null);
    } catch (error: any) {
      toast.error(error.message || 'Failed to save schedule');
    }
  };

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="text-center">
          <div className="mx-auto h-12 w-12 animate-spin rounded-full border-b-2 border-[#ff5d2e]" />
          <p className="mt-4 text-black/70">Loading staff...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-[#ff5d2e]">
            <Wrench className="h-6 w-6 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-black">Staff Scheduling</h1>
            <p className="text-sm text-black/60">Manage mechanics, status, skills, and availability.</p>
          </div>
        </div>
        <button onClick={openCreate} className="flex items-center justify-center gap-2 rounded-lg bg-[#ff5d2e] px-4 py-2 text-white transition-colors hover:bg-[#e64d1e]">
          <Plus className="h-5 w-5" />
          <span>Add Staff</span>
        </button>
      </div>

      <div className="relative">
        <Search className="absolute left-3 top-3 h-5 w-5 text-black/40" />
        <input
          type="text"
          placeholder="Search by name, email, or specialty..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full rounded-lg border border-black/10 bg-white py-2 pl-10 pr-4 text-sm focus:border-[#ff5d2e] focus:outline-none"
        />
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
        {filteredStaff.map((member) => (
          <div key={member.id} className="rounded-lg border border-black/10 bg-white p-4">
            <div className="mb-3 flex items-start justify-between gap-3">
              <div>
                <h3 className="font-semibold text-black">{member.fullName}</h3>
                <p className="text-sm text-black/60">{member.specialization || 'General Service'}</p>
              </div>
              <span className={`rounded-full px-2 py-1 text-xs font-medium ${member.isActive === false ? 'bg-black/5 text-black/50' : 'bg-green-50 text-green-700'}`}>
                {member.isActive === false ? 'Inactive' : 'Active'}
              </span>
            </div>

            <div className="space-y-2 text-sm">
              <p><span className="text-black/60">Email:</span> <span className="text-black">{member.email}</span></p>
              <p><span className="text-black/60">Phone:</span> <span className="text-black">{member.phone}</span></p>
              <p><span className="text-black/60">Experience:</span> <span className="text-black">{member.experienceYears || '-'} years</span></p>
              <p><span className="text-black/60">Active jobs:</span> <span className="text-black">{member.activeJobCount || 0}</span></p>
              <span className="inline-flex rounded-full bg-[#ffe7df] px-2 py-1 text-xs font-medium text-[#ff5d2e]">
                {member.status || 'AVAILABLE'}
              </span>
            </div>

            <div className="mt-4 flex gap-2">
              <button onClick={() => openEdit(member)} className="flex flex-1 items-center justify-center gap-2 rounded-lg border border-black/10 px-3 py-2 text-sm text-black hover:bg-black/5">
                <Edit2 className="h-4 w-4" /> Edit
              </button>
              <button onClick={() => openSchedule(member)} className="flex flex-1 items-center justify-center gap-2 rounded-lg border border-black/10 px-3 py-2 text-sm text-black hover:bg-black/5">
                <CalendarDays className="h-4 w-4" /> Schedule
              </button>
              <button onClick={() => deactivateStaff(member)} className="rounded-lg border border-red-100 px-3 py-2 text-red-600 hover:bg-red-50">
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          </div>
        ))}
      </div>

      {!filteredStaff.length && (
        <div className="rounded-lg border border-black/10 bg-white py-10 text-center">
          <Wrench className="mx-auto mb-3 h-12 w-12 text-black/20" />
          <p className="text-black/60">No staff found</p>
        </div>
      )}

      {showStaffModal && (
        <StaffModal
          title={editing ? 'Edit Staff Member' : 'Add Staff Member'}
          formData={formData}
          setFormData={setFormData}
          onClose={closeForm}
          onSave={saveStaff}
        />
      )}

      {scheduleFor && (
        <ScheduleModal
          member={scheduleFor}
          workingHours={workingHours}
          setWorkingHours={setWorkingHours}
          unavailableBlocks={unavailableBlocks}
          setUnavailableBlocks={setUnavailableBlocks}
          onClose={() => setScheduleFor(null)}
          onSave={saveSchedule}
        />
      )}
    </div>
  );
}

function StaffModal({ title, formData, setFormData, onClose, onSave }: any) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="w-full max-w-md rounded-lg bg-white p-6">
        <h2 className="mb-4 text-xl font-bold text-black">{title}</h2>
        <div className="space-y-3">
          {[
            ['fullName', 'Full Name', 'text'],
            ['email', 'Email', 'email'],
            ['phone', 'Phone', 'tel'],
            ['specialization', 'Specialization / skills', 'text'],
            ['experienceYears', 'Years of Experience', 'number'],
          ].map(([key, placeholder, type]) => (
            <input
              key={key}
              type={type}
              placeholder={placeholder}
              value={formData[key]}
              onChange={(e) => setFormData({ ...formData, [key]: e.target.value })}
              className="w-full rounded-lg border border-black/10 bg-white px-3 py-2 text-sm focus:border-[#ff5d2e] focus:outline-none"
            />
          ))}
          <select
            value={formData.status}
            onChange={(e) => setFormData({ ...formData, status: e.target.value })}
            className="w-full rounded-lg border border-black/10 bg-white px-3 py-2 text-sm focus:border-[#ff5d2e] focus:outline-none"
          >
            <option value="AVAILABLE">Available</option>
            <option value="BUSY">Busy</option>
            <option value="ON_LEAVE">On leave</option>
          </select>
          <label className="flex items-center gap-2 text-sm text-black">
            <input type="checkbox" checked={formData.isActive} onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })} />
            Active staff member
          </label>
        </div>
        <div className="mt-6 flex gap-3">
          <button onClick={onClose} className="flex-1 rounded-lg bg-black/5 px-4 py-2 text-black hover:bg-black/10">Cancel</button>
          <button onClick={onSave} className="flex-1 rounded-lg bg-[#ff5d2e] px-4 py-2 text-white hover:bg-[#e64d1e]">Save</button>
        </div>
      </div>
    </div>
  );
}

function ScheduleModal({ member, workingHours, setWorkingHours, unavailableBlocks, setUnavailableBlocks, onClose, onSave }: any) {
  const updateWorkingHour = (index: number, key: string, value: string) => {
    const next = [...workingHours];
    next[index] = { ...next[index], [key]: value };
    setWorkingHours(next);
  };

  const addUnavailableBlock = () => {
    setUnavailableBlocks([
      ...unavailableBlocks,
      { startsAt: new Date().toISOString().slice(0, 16), endsAt: new Date(Date.now() + 3600000).toISOString().slice(0, 16), reason: '' },
    ]);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-lg bg-white p-6">
        <h2 className="text-xl font-bold text-black">{member.fullName} Schedule</h2>
        <p className="mb-4 text-sm text-black/60">Working days, shift windows, and unavailable blocks.</p>

        <div className="space-y-3">
          {workingHours.map((row: any, index: number) => (
            <div key={`${row.dayOfWeek}-${index}`} className="grid grid-cols-1 gap-2 sm:grid-cols-3">
              <select value={row.dayOfWeek} onChange={(e) => updateWorkingHour(index, 'dayOfWeek', e.target.value)} className="rounded-lg border border-black/10 px-3 py-2 text-sm">
                {['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'].map((day) => <option key={day}>{day}</option>)}
              </select>
              <input type="time" value={row.shiftStart} onChange={(e) => updateWorkingHour(index, 'shiftStart', e.target.value)} className="rounded-lg border border-black/10 px-3 py-2 text-sm" />
              <input type="time" value={row.shiftEnd} onChange={(e) => updateWorkingHour(index, 'shiftEnd', e.target.value)} className="rounded-lg border border-black/10 px-3 py-2 text-sm" />
            </div>
          ))}
          <button onClick={() => setWorkingHours([...workingHours, { dayOfWeek: 'SATURDAY', shiftStart: '09:00', shiftEnd: '13:00' }])} className="rounded-lg border border-black/10 px-3 py-2 text-sm text-black hover:bg-black/5">
            Add working day
          </button>
        </div>

        <div className="mt-6">
          <div className="mb-3 flex items-center justify-between">
            <h3 className="font-semibold text-black">Unavailable Blocks</h3>
            <button onClick={addUnavailableBlock} className="rounded-lg border border-black/10 px-3 py-2 text-sm text-black hover:bg-black/5">Add block</button>
          </div>
          <div className="space-y-3">
            {unavailableBlocks.map((block: any, index: number) => (
              <div key={index} className="grid grid-cols-1 gap-2 sm:grid-cols-[1fr_1fr_1fr_auto]">
                <input type="datetime-local" value={String(block.startsAt).slice(0, 16)} onChange={(e) => {
                  const next = [...unavailableBlocks];
                  next[index] = { ...next[index], startsAt: e.target.value };
                  setUnavailableBlocks(next);
                }} className="rounded-lg border border-black/10 px-3 py-2 text-sm" />
                <input type="datetime-local" value={String(block.endsAt).slice(0, 16)} onChange={(e) => {
                  const next = [...unavailableBlocks];
                  next[index] = { ...next[index], endsAt: e.target.value };
                  setUnavailableBlocks(next);
                }} className="rounded-lg border border-black/10 px-3 py-2 text-sm" />
                <input placeholder="Reason" value={block.reason || ''} onChange={(e) => {
                  const next = [...unavailableBlocks];
                  next[index] = { ...next[index], reason: e.target.value };
                  setUnavailableBlocks(next);
                }} className="rounded-lg border border-black/10 px-3 py-2 text-sm" />
                <button onClick={() => setUnavailableBlocks(unavailableBlocks.filter((_: any, i: number) => i !== index))} className="rounded-lg border border-red-100 px-3 py-2 text-red-600 hover:bg-red-50">Remove</button>
              </div>
            ))}
          </div>
        </div>

        <div className="mt-6 flex gap-3">
          <button onClick={onClose} className="flex-1 rounded-lg bg-black/5 px-4 py-2 text-black hover:bg-black/10">Cancel</button>
          <button onClick={onSave} className="flex-1 rounded-lg bg-[#ff5d2e] px-4 py-2 text-white hover:bg-[#e64d1e]">Save Schedule</button>
        </div>
      </div>
    </div>
  );
}
