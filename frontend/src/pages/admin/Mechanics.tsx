import { useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import {
  Briefcase,
  CalendarBlank,
  CaretDown,
  CaretUp,
  CloudArrowUp,
  EnvelopeSimple,
  FileText,
  IdentificationBadge,
  MapPin,
  PencilSimple,
  Phone,
  Plus,
  Trash,
  UserCircle,
  Wrench,
  X,
} from '@phosphor-icons/react';
import { Search } from 'lucide-react';
import { toast } from 'sonner';
import { adminApi } from '@/services/adminApi';

type StaffDetails = {
  employeeCode: string;
  branch: string;
  jobTitle: string;
  employmentType: string;
  joiningDate: string;
  skillTags: string;
  nicNumber: string;
  passportNumber: string;
  dateOfBirth: string;
  gender: string;
  drivingLicenseNumber: string;
  licenseClasses: string;
  licenseExpiryDate: string;
  addressLine1: string;
  addressLine2: string;
  city: string;
  district: string;
  postalCode: string;
  emergencyContactName: string;
  emergencyContactRelationship: string;
  emergencyContactPhone: string;
  bankName: string;
  bankBranch: string;
  accountHolderName: string;
  accountNumber: string;
  epfNumber: string;
  etfNumber: string;
};

type StaffDocument = {
  id?: number;
  documentType: string;
  originalFilename?: string;
  url: string;
  publicId: string;
  resourceType?: string;
  contentType?: string;
  bytes?: number;
  uploadedAt?: string;
};

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
  employeeCode?: string;
  branch?: string;
  jobTitle?: string;
  profilePhotoUrl?: string;
  details?: Partial<StaffDetails>;
  documents?: StaffDocument[];
};

type StaffForm = {
  fullName: string;
  email: string;
  phone: string;
  specialization: string;
  experienceYears: string;
  status: string;
  isActive: boolean;
  details: StaffDetails;
  documents: StaffDocument[];
};

const emptyDetails: StaffDetails = {
  employeeCode: '',
  branch: 'Colombo Service Center',
  jobTitle: 'Mechanic',
  employmentType: 'FULL_TIME',
  joiningDate: '',
  skillTags: '',
  nicNumber: '',
  passportNumber: '',
  dateOfBirth: '',
  gender: '',
  drivingLicenseNumber: '',
  licenseClasses: '',
  licenseExpiryDate: '',
  addressLine1: '',
  addressLine2: '',
  city: '',
  district: '',
  postalCode: '',
  emergencyContactName: '',
  emergencyContactRelationship: '',
  emergencyContactPhone: '',
  bankName: '',
  bankBranch: '',
  accountHolderName: '',
  accountNumber: '',
  epfNumber: '',
  etfNumber: '',
};

const emptyForm: StaffForm = {
  fullName: '',
  email: '',
  phone: '',
  specialization: '',
  experienceYears: '',
  status: 'AVAILABLE',
  isActive: true,
  details: emptyDetails,
  documents: [],
};

const defaultWorkingHours = [
  { dayOfWeek: 'MONDAY', shiftStart: '09:00', shiftEnd: '17:00' },
  { dayOfWeek: 'TUESDAY', shiftStart: '09:00', shiftEnd: '17:00' },
  { dayOfWeek: 'WEDNESDAY', shiftStart: '09:00', shiftEnd: '17:00' },
  { dayOfWeek: 'THURSDAY', shiftStart: '09:00', shiftEnd: '17:00' },
  { dayOfWeek: 'FRIDAY', shiftStart: '09:00', shiftEnd: '17:00' },
];

const documentTypes = [
  { value: 'NIC_COPY', label: 'NIC copy' },
  { value: 'DRIVING_LICENSE', label: 'Driving license' },
  { value: 'CERTIFICATE', label: 'Training certificate' },
  { value: 'POLICE_CLEARANCE', label: 'Police clearance' },
  { value: 'OTHER', label: 'Other document' },
];

const inputClass = 'w-full rounded-lg border border-black/10 bg-white px-3 py-2 text-sm text-black focus:border-[#ff5d2e] focus:outline-none';
const labelClass = 'mb-1.5 block text-xs font-semibold uppercase tracking-wide text-black/45';

function cloneEmptyForm(): StaffForm {
  return {
    ...emptyForm,
    details: { ...emptyDetails },
    documents: [],
  };
}

export function AdminMechanics() {
  const [staff, setStaff] = useState<StaffMember[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editing, setEditing] = useState<StaffMember | null>(null);
  const [formData, setFormData] = useState<StaffForm>(cloneEmptyForm());
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
    return staff.filter((member) => {
      const details = member.details || {};
      return [
        member.fullName,
        member.email,
        member.phone,
        member.specialization,
        member.employeeCode,
        member.branch,
        member.jobTitle,
        details.employeeCode,
        details.branch,
        details.jobTitle,
      ].some(value => String(value || '').toLowerCase().includes(query));
    });
  }, [searchQuery, staff]);

  const openCreate = () => {
    setEditing(null);
    setFormData(cloneEmptyForm());
    setDrawerOpen(true);
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
      details: { ...emptyDetails, ...(member.details || {}) },
      documents: member.documents || [],
    });
    setDrawerOpen(true);
  };

  const closeDrawer = () => {
    setEditing(null);
    setFormData(cloneEmptyForm());
    setDrawerOpen(false);
  };

  const buildPayload = () => ({
    fullName: formData.fullName.trim(),
    email: formData.email.trim(),
    phone: formData.phone.trim(),
    specialization: formData.specialization.trim(),
    experienceYears: formData.experienceYears ? Number(formData.experienceYears) : null,
    status: formData.status,
    isActive: formData.isActive,
    details: cleanObject(formData.details),
    documents: formData.documents,
  });

  const validateForm = () => {
    if (!formData.fullName.trim() || !formData.email.trim() || !formData.phone.trim()) {
      toast.error('Name, email, and phone are required');
      return false;
    }
    if (!formData.details.employeeCode.trim() || !formData.details.branch.trim() || !formData.details.jobTitle.trim()) {
      toast.error('Employee code, branch, and job title are required');
      return false;
    }
    return true;
  };

  const saveStaff = async () => {
    if (!validateForm()) return;
    try {
      const response = editing
        ? await adminApi.updateStaff(editing.id, buildPayload())
        : await adminApi.createStaff(buildPayload());
      if (!response.success) throw new Error(response.message);
      toast.success(editing ? 'Staff member updated' : 'Staff member created');
      closeDrawer();
      loadStaff();
    } catch (error: any) {
      toast.error(error.message || 'Failed to save staff member');
    }
  };

  const deactivateStaff = async (member: StaffMember) => {
    if (!confirm(`Deactivate ${member.fullName}?`)) return;
    try {
      const response = await adminApi.updateStaff(member.id, { isActive: false });
      if (!response.success) throw new Error(response.message);
      toast.success('Staff member deactivated');
      closeDrawer();
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
        <div className="text-left">
          <h1 className="text-2xl font-bold text-black">Staff Management</h1>
          <p className="text-sm text-black/60">Register mechanics, verify documents, and manage availability.</p>
        </div>
        <button onClick={openCreate} className="flex items-center justify-center gap-2 rounded-lg bg-[#ff5d2e] px-4 py-2 text-white transition-colors hover:bg-[#e64d1e]">
          <Plus className="h-5 w-5" weight="bold" />
          <span>Add Staff</span>
        </button>
      </div>

      <div className="relative w-1/2">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-black/40" />
        <input
          type="text"
          placeholder="Search by name, employee code, branch, email, or specialty..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full rounded-lg border border-black/10 bg-white py-2 pl-10 pr-4 text-sm focus:border-[#ff5d2e] focus:outline-none"
        />
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
        {filteredStaff.map((member) => {
          const details = member.details || {};
          return (
            <div key={member.id} className="rounded-lg border border-black/10 bg-white p-4">
              <div className="mb-3 flex items-start gap-3">
                <StaffAvatar member={member} />
                <div className="min-w-0 flex-1 text-left">
                  <h3 className="truncate font-semibold text-black">{member.fullName}</h3>
                  <p className="text-sm text-black/60">{member.specialization || 'General Service'}</p>
                  <p className="mt-1 text-xs text-black/45">{details.employeeCode || member.employeeCode || 'No employee code'} · {details.branch || member.branch || 'Branch not set'}</p>
                </div>
                <span className={`rounded-full px-2 py-1 text-xs font-medium ${member.isActive === false ? 'bg-black/5 text-black/50' : 'bg-green-50 text-green-700'}`}>
                  {member.isActive === false ? 'Inactive' : 'Active'}
                </span>
              </div>

              <div className="space-y-2 text-left text-sm">
                <p><span className="text-black/60">Email:</span> <span className="text-black">{member.email}</span></p>
                <p><span className="text-black/60">Phone:</span> <span className="text-black">{member.phone}</span></p>
                <p><span className="text-black/60">Title:</span> <span className="text-black">{details.jobTitle || member.jobTitle || '-'}</span></p>
                <p><span className="text-black/60">Active jobs:</span> <span className="text-black">{member.activeJobCount || 0}</span></p>
              </div>

              <div className="mt-4 flex gap-2">
                <button onClick={() => openEdit(member)} className="flex flex-1 items-center justify-center gap-2 rounded-lg border border-black/10 px-3 py-2 text-sm text-black hover:bg-black/5">
                  <PencilSimple className="h-4 w-4" /> Edit
                </button>
                <button onClick={() => openSchedule(member)} className="flex flex-1 items-center justify-center gap-2 rounded-lg border border-black/10 px-3 py-2 text-sm text-black hover:bg-black/5">
                  <CalendarBlank className="h-4 w-4" /> Schedule
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {!filteredStaff.length && (
        <div className="rounded-lg border border-black/10 bg-white py-10 text-center">
          <Wrench className="mx-auto mb-3 h-12 w-12 text-black/20" />
          <p className="text-black/60">No staff found</p>
        </div>
      )}

      {drawerOpen && (
        <StaffDrawer
          editing={editing}
          formData={formData}
          setFormData={setFormData}
          onClose={closeDrawer}
          onSave={saveStaff}
          onDeactivate={editing ? () => deactivateStaff(editing) : undefined}
          onSchedule={editing ? () => openSchedule(editing) : undefined}
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

function StaffDrawer({ editing, formData, setFormData, onClose, onSave, onDeactivate, onSchedule }: {
  editing: StaffMember | null;
  formData: StaffForm;
  setFormData: (form: StaffForm) => void;
  onClose: () => void;
  onSave: () => void;
  onDeactivate?: () => void;
  onSchedule?: () => void;
}) {
  const [openSections, setOpenSections] = useState<Record<string, boolean>>({
    basic: true,
    work: true,
    identity: false,
    contact: false,
    emergency: false,
    bank: false,
    documents: true,
  });
  const [uploading, setUploading] = useState<string | null>(null);
  const [generatingCode, setGeneratingCode] = useState(false);
  const [documentType, setDocumentType] = useState('NIC_COPY');

  const details = formData.details;
  const profilePhoto = formData.documents.find(doc => doc.documentType === 'PROFILE_PHOTO');

  const update = (key: keyof StaffForm, value: any) => setFormData({ ...formData, [key]: value });
  const updateDetails = (key: keyof StaffDetails, value: string) => setFormData({
    ...formData,
    details: { ...formData.details, [key]: value },
  });

  const uploadFile = async (file: File, type: string) => {
    try {
      setUploading(type);
      const response = await adminApi.uploadStaffFile(file, type, editing?.id);
      if (!response.success) throw new Error(response.message);
      const uploaded = response.data;
      const nextDocument: StaffDocument = {
        documentType: uploaded.documentType,
        originalFilename: uploaded.originalFilename,
        url: uploaded.url,
        publicId: uploaded.publicId,
        resourceType: uploaded.resourceType,
        contentType: uploaded.contentType,
        bytes: uploaded.bytes,
      };
      const documents = type === 'PROFILE_PHOTO'
        ? [...formData.documents.filter(doc => doc.documentType !== 'PROFILE_PHOTO'), nextDocument]
        : [...formData.documents, nextDocument];
      setFormData({ ...formData, documents });
      toast.success('File uploaded');
    } catch (error: any) {
      toast.error(error.message || 'Upload failed');
    } finally {
      setUploading(null);
    }
  };

  const removeDocument = (index: number) => {
    setFormData({
      ...formData,
      documents: formData.documents.filter((_, i) => i !== index),
    });
  };

  const generateEmployeeCode = async () => {
    try {
      setGeneratingCode(true);
      const response = await adminApi.generateStaffEmployeeCode();
      if (!response.success) throw new Error(response.message);
      updateDetails('employeeCode', response.data);
      toast.success('Employee code generated');
    } catch (error: any) {
      toast.error(error.message || 'Failed to generate employee code');
    } finally {
      setGeneratingCode(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/10 text-left" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <aside className="flex h-full w-full max-w-2xl flex-col bg-white shadow-2xl">
        <div className="border-b border-black/10 bg-[#fff7f5] px-5 py-4">
          <div className="flex items-start justify-between gap-4">
            <div className="flex min-w-0 items-start gap-4">
              <label className="group relative flex h-20 w-20 shrink-0 cursor-pointer items-center justify-center overflow-hidden rounded-lg border border-black/10 bg-white">
                {profilePhoto?.url ? (
                  <img src={profilePhoto.url} alt={formData.fullName || 'Staff'} className="h-full w-full object-cover" />
                ) : (
                  <UserCircle className="h-10 w-10 text-black/25" weight="duotone" />
                )}
                <span className="absolute inset-x-0 bottom-0 bg-black/55 py-1 text-center text-[10px] font-medium text-white opacity-0 transition-opacity group-hover:opacity-100">
                  Photo
                </span>
                <input
                  type="file"
                  accept="image/*"
                  className="hidden"
                  disabled={uploading === 'PROFILE_PHOTO'}
                  onChange={(e) => e.target.files?.[0] && uploadFile(e.target.files[0], 'PROFILE_PHOTO')}
                />
              </label>

              <div className="min-w-0 text-left">
                <h2 className="truncate text-xl font-bold text-black">{formData.fullName || (editing ? 'Edit staff member' : 'New staff member')}</h2>
                <div className="mt-2 flex flex-wrap gap-2">
                  {formData.phone && <Chip icon={<Phone />} label={formData.phone} />}
                  {formData.email && <Chip icon={<EnvelopeSimple />} label={formData.email} />}
                  <Chip label={details.branch || 'Branch not set'} tone="orange" />
                  <Chip label={formData.status.replace(/_/g, ' ')} tone={formData.status === 'AVAILABLE' ? 'green' : 'neutral'} />
                </div>
              </div>
            </div>
            <button onClick={onClose} className="rounded-lg p-2 text-black/50 hover:bg-white">
              <X className="h-5 w-5" />
            </button>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto px-5 py-4">
          <Section title="Basic Information" icon={<IdentificationBadge />} open={openSections.basic} onToggle={() => setOpenSections({ ...openSections, basic: !openSections.basic })}>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Field label="Full name *" value={formData.fullName} onChange={(v) => update('fullName', v)} />
              <div>
                <label className={labelClass}>Employee code *</label>
                <div className="flex gap-2">
                  <input
                    value={details.employeeCode || ''}
                    onChange={(e) => updateDetails('employeeCode', e.target.value)}
                    placeholder="EMP0001"
                    className={inputClass}
                  />
                  <button
                    type="button"
                    onClick={generateEmployeeCode}
                    disabled={generatingCode}
                    className="shrink-0 rounded-lg border border-[#ff5d2e] px-3 py-2 text-sm font-semibold text-[#ff5d2e] hover:bg-[#fff7f5] disabled:opacity-60"
                  >
                    {generatingCode ? '...' : 'Generate'}
                  </button>
                </div>
              </div>
              <Field label="Phone *" value={formData.phone} onChange={(v) => update('phone', v)} placeholder="+94 77 123 4567" />
              <Field label="Email *" type="email" value={formData.email} onChange={(v) => update('email', v)} />
              <SelectField label="Status" value={formData.status} onChange={(v) => update('status', v)} options={[
                ['AVAILABLE', 'Available'],
                ['BUSY', 'Busy'],
                ['ON_LEAVE', 'On leave'],
              ]} />
              <label className="flex items-end gap-2 rounded-lg border border-black/10 px-3 py-2 text-sm text-black">
                <input type="checkbox" checked={formData.isActive} onChange={(e) => update('isActive', e.target.checked)} />
                Active staff member
              </label>
            </div>
          </Section>

          <Section title="Work & Skills" icon={<Briefcase />} open={openSections.work} onToggle={() => setOpenSections({ ...openSections, work: !openSections.work })}>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Field label="Branch / service center *" value={details.branch} onChange={(v) => updateDetails('branch', v)} />
              <Field label="Job title *" value={details.jobTitle} onChange={(v) => updateDetails('jobTitle', v)} />
              <Field label="Primary specialization" value={formData.specialization} onChange={(v) => update('specialization', v)} placeholder="Engine repair, Electrical..." />
              <Field label="Years of experience" type="number" value={formData.experienceYears} onChange={(v) => update('experienceYears', v)} />
              <SelectField label="Employment type" value={details.employmentType} onChange={(v) => updateDetails('employmentType', v)} options={[
                ['FULL_TIME', 'Full time'],
                ['PART_TIME', 'Part time'],
                ['CONTRACT', 'Contract'],
                ['TRAINEE', 'Trainee'],
              ]} />
              <Field label="Joining date" type="date" value={details.joiningDate || ''} onChange={(v) => updateDetails('joiningDate', v)} />
              <div className="sm:col-span-2">
                <label className={labelClass}>Skill tags</label>
                <textarea value={details.skillTags} onChange={(e) => updateDetails('skillTags', e.target.value)} placeholder="Hybrid systems, diagnostics, bodywork, AC repair..." className={`${inputClass} min-h-20 resize-y`} />
              </div>
            </div>
          </Section>

          <Section title="Identity & License" icon={<IdentificationBadge />} open={openSections.identity} onToggle={() => setOpenSections({ ...openSections, identity: !openSections.identity })}>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Field label="NIC number" value={details.nicNumber} onChange={(v) => updateDetails('nicNumber', v)} />
              <Field label="Passport number" value={details.passportNumber} onChange={(v) => updateDetails('passportNumber', v)} />
              <Field label="Date of birth" type="date" value={details.dateOfBirth || ''} onChange={(v) => updateDetails('dateOfBirth', v)} />
              <SelectField label="Gender" value={details.gender} onChange={(v) => updateDetails('gender', v)} options={[
                ['', 'Select'],
                ['MALE', 'Male'],
                ['FEMALE', 'Female'],
                ['OTHER', 'Other'],
              ]} />
              <Field label="Driving license number" value={details.drivingLicenseNumber} onChange={(v) => updateDetails('drivingLicenseNumber', v)} />
              <Field label="License classes" value={details.licenseClasses} onChange={(v) => updateDetails('licenseClasses', v)} placeholder="A1, B, G1..." />
              <Field label="License expiry" type="date" value={details.licenseExpiryDate || ''} onChange={(v) => updateDetails('licenseExpiryDate', v)} />
            </div>
          </Section>

          <Section title="Contact & Address" icon={<MapPin />} open={openSections.contact} onToggle={() => setOpenSections({ ...openSections, contact: !openSections.contact })}>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Field label="Address line 1" value={details.addressLine1} onChange={(v) => updateDetails('addressLine1', v)} />
              <Field label="Address line 2" value={details.addressLine2} onChange={(v) => updateDetails('addressLine2', v)} />
              <Field label="City" value={details.city} onChange={(v) => updateDetails('city', v)} />
              <Field label="District" value={details.district} onChange={(v) => updateDetails('district', v)} />
              <Field label="Postal code" value={details.postalCode} onChange={(v) => updateDetails('postalCode', v)} />
            </div>
          </Section>

          <Section title="Emergency Contact" icon={<Phone />} open={openSections.emergency} onToggle={() => setOpenSections({ ...openSections, emergency: !openSections.emergency })}>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <Field label="Name" value={details.emergencyContactName} onChange={(v) => updateDetails('emergencyContactName', v)} />
              <Field label="Relationship" value={details.emergencyContactRelationship} onChange={(v) => updateDetails('emergencyContactRelationship', v)} />
              <Field label="Phone" value={details.emergencyContactPhone} onChange={(v) => updateDetails('emergencyContactPhone', v)} />
            </div>
          </Section>

          <Section title="Bank & Payroll" icon={<Briefcase />} open={openSections.bank} onToggle={() => setOpenSections({ ...openSections, bank: !openSections.bank })}>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Field label="Bank name" value={details.bankName} onChange={(v) => updateDetails('bankName', v)} />
              <Field label="Bank branch" value={details.bankBranch} onChange={(v) => updateDetails('bankBranch', v)} />
              <Field label="Account holder name" value={details.accountHolderName} onChange={(v) => updateDetails('accountHolderName', v)} />
              <Field label="Account number" value={details.accountNumber} onChange={(v) => updateDetails('accountNumber', v)} />
              <Field label="EPF number" value={details.epfNumber} onChange={(v) => updateDetails('epfNumber', v)} />
              <Field label="ETF number" value={details.etfNumber} onChange={(v) => updateDetails('etfNumber', v)} />
            </div>
          </Section>

          <Section title="Documents" icon={<FileText />} open={openSections.documents} onToggle={() => setOpenSections({ ...openSections, documents: !openSections.documents })}>
            <div
              onDragOver={(e) => e.preventDefault()}
              onDrop={(e) => {
                e.preventDefault();
                const file = e.dataTransfer.files?.[0];
                if (file) uploadFile(file, documentType);
              }}
              className="rounded-lg border border-dashed border-[#ffb69d] bg-[#fff7f5] p-5 text-center"
            >
              <CloudArrowUp className="mx-auto mb-2 h-8 w-8 text-[#ff5d2e]" />
              <p className="text-sm font-medium text-black">Drag and drop a file here</p>
              <p className="mt-1 text-xs text-black/50">JPG, PNG, WEBP, or PDF documents</p>
              <div className="mt-4 flex flex-col items-center justify-center gap-2 sm:flex-row">
                <select value={documentType} onChange={(e) => setDocumentType(e.target.value)} className={`${inputClass} max-w-xs`}>
                  {documentTypes.map(type => <option key={type.value} value={type.value}>{type.label}</option>)}
                </select>
                <label className="cursor-pointer rounded-lg bg-[#ff5d2e] px-4 py-2 text-sm font-semibold text-white hover:bg-[#e64d1e]">
                  {uploading && uploading !== 'PROFILE_PHOTO' ? 'Uploading...' : 'Browse files'}
                  <input type="file" accept="image/*,application/pdf" className="hidden" disabled={Boolean(uploading)} onChange={(e) => e.target.files?.[0] && uploadFile(e.target.files[0], documentType)} />
                </label>
              </div>
            </div>

            <div className="mt-4 space-y-2">
              {formData.documents.filter(doc => doc.documentType !== 'PROFILE_PHOTO').map((document, index) => {
                const actualIndex = formData.documents.findIndex(doc => doc === document);
                return (
                  <div key={`${document.publicId}-${index}`} className="flex items-center gap-3 rounded-lg border border-black/10 bg-white p-3">
                    <FileText className="h-5 w-5 text-[#ff5d2e]" />
                    <div className="min-w-0 flex-1 text-left">
                      <p className="truncate text-sm font-medium text-black">{document.originalFilename || document.documentType}</p>
                      <a href={document.url} target="_blank" rel="noreferrer" className="text-xs text-[#ff5d2e] hover:underline">{document.documentType.replace(/_/g, ' ')}</a>
                    </div>
                    <button onClick={() => removeDocument(actualIndex)} className="rounded-lg p-2 text-red-600 hover:bg-red-50">
                      <Trash className="h-4 w-4" />
                    </button>
                  </div>
                );
              })}
              {!formData.documents.some(doc => doc.documentType !== 'PROFILE_PHOTO') && (
                <p className="text-center text-sm text-black/45">No documents uploaded yet.</p>
              )}
            </div>
          </Section>
        </div>

        <div className="flex flex-col gap-2 border-t border-black/10 bg-white px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex gap-2">
            {onDeactivate && (
              <button onClick={onDeactivate} className="rounded-lg border border-red-100 px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-50">
                Deactivate
              </button>
            )}
            {onSchedule && (
              <button onClick={onSchedule} className="rounded-lg border border-black/10 px-4 py-2 text-sm font-medium text-black hover:bg-black/5">
                Edit schedule
              </button>
            )}
          </div>
          <div className="flex gap-2">
            <button onClick={onClose} className="rounded-lg bg-black/5 px-4 py-2 text-sm font-medium text-black hover:bg-black/10">Cancel</button>
            <button onClick={onSave} className="rounded-lg bg-[#ff5d2e] px-5 py-2 text-sm font-semibold text-white hover:bg-[#e64d1e]">
              {editing ? 'Save changes' : 'Create staff'}
            </button>
          </div>
        </div>
      </aside>
    </div>
  );
}

function StaffAvatar({ member }: { member: StaffMember }) {
  if (member.profilePhotoUrl) {
    return <img src={member.profilePhotoUrl} alt={member.fullName} className="h-12 w-12 rounded-lg border border-black/10 object-cover" />;
  }
  return (
    <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-[#ffe7df] text-[#ff5d2e]">
      <UserCircle className="h-7 w-7" weight="duotone" />
    </div>
  );
}

function Chip({ icon, label, tone = 'neutral' }: { icon?: ReactNode; label: string; tone?: 'neutral' | 'orange' | 'green' }) {
  const colors = tone === 'orange'
    ? 'bg-[#ffe7df] text-[#ff5d2e]'
    : tone === 'green'
      ? 'bg-green-50 text-green-700'
      : 'bg-white text-black/70 border border-black/10';
  return (
    <span className={`inline-flex max-w-full items-center gap-1 rounded-md px-2 py-1 text-xs font-medium ${colors}`}>
      {icon && <span className="h-3.5 w-3.5">{icon}</span>}
      <span className="truncate">{label}</span>
    </span>
  );
}

function Section({ title, icon, open, onToggle, children }: { title: string; icon: ReactNode; open: boolean; onToggle: () => void; children: ReactNode }) {
  return (
    <section className="mb-4">
      <button onClick={onToggle} className="flex w-full items-center gap-2 text-left">
        <span className="text-[#ff5d2e]">{icon}</span>
        <span className="font-semibold text-black/70">{title}</span>
        <span className="h-px flex-1 bg-black/10" />
        {open ? <CaretUp className="h-4 w-4 text-black/40" /> : <CaretDown className="h-4 w-4 text-black/40" />}
      </button>
      {open && <div className="mt-3 rounded-lg border border-black/5 bg-white p-4 shadow-sm">{children}</div>}
    </section>
  );
}

function Field({ label, value, onChange, type = 'text', placeholder }: { label: string; value: string; onChange: (value: string) => void; type?: string; placeholder?: string }) {
  return (
    <div>
      <label className={labelClass}>{label}</label>
      <input type={type} value={value || ''} onChange={(e) => onChange(e.target.value)} placeholder={placeholder} className={inputClass} />
    </div>
  );
}

function SelectField({ label, value, onChange, options }: { label: string; value: string; onChange: (value: string) => void; options: string[][] }) {
  return (
    <div>
      <label className={labelClass}>{label}</label>
      <select value={value || ''} onChange={(e) => onChange(e.target.value)} className={inputClass}>
        {options.map(([optionValue, optionLabel]) => <option key={optionValue} value={optionValue}>{optionLabel}</option>)}
      </select>
    </div>
  );
}

function cleanObject<T extends Record<string, any>>(value: T): T {
  return Object.fromEntries(Object.entries(value).map(([key, entry]) => [key, entry === '' ? null : entry])) as T;
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

export default AdminMechanics;

