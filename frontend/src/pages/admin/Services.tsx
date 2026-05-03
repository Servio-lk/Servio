import { useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { adminApi } from '../../services/adminApi';
import { apiService, type ServiceCategory } from '../../services/api';
import {
  ArrowDown,
  ArrowUp,
  Check,
  Clock,
  Edit,
  Eye,
  EyeOff,
  Image,
  Package,
  Plus,
  Save,
  Search,
  Shield,
  Trash2,
  Upload,
  X,
} from 'lucide-react';
import { toast } from 'sonner';

type ServiceStatus = 'DRAFT' | 'PUBLISHED' | 'HIDDEN';

type ServiceOption = {
  id?: number;
  name: string;
  description: string;
  priceAdjustment: number;
  isDefault: boolean;
  displayOrder: number;
};

type ServicePhoto = {
  id?: number;
  url: string;
  publicId?: string;
  displayOrder: number;
  isPrimary: boolean;
};

type ServiceForm = {
  id?: number;
  categoryId: number | '';
  name: string;
  description: string;
  basePrice: number;
  durationMinutes: number;
  imageUrl: string;
  iconUrl: string;
  warrantyIncluded: boolean;
  isFeatured: boolean;
  includedItems: string[];
  options: ServiceOption[];
  photos: ServicePhoto[];
};

const emptyForm: ServiceForm = {
  categoryId: '',
  name: '',
  description: '',
  basePrice: 0,
  durationMinutes: 60,
  imageUrl: '',
  iconUrl: '',
  warrantyIncluded: true,
  isFeatured: false,
  includedItems: [''],
  options: [],
  photos: [],
};

const statusStyles: Record<ServiceStatus, string> = {
  PUBLISHED: 'bg-green-50 text-green-700 border-green-200',
  DRAFT: 'bg-amber-50 text-amber-700 border-amber-200',
  HIDDEN: 'bg-gray-100 text-gray-600 border-gray-200',
};

const formatLkr = (value?: number | null) => `LKR ${(Number(value) || 0).toLocaleString()}`;

const durationLabel = (minutes: number) => {
  if (!minutes) return '-';
  if (minutes < 60) return `${minutes} min`;
  const hours = Math.floor(minutes / 60);
  const remaining = minutes % 60;
  return remaining ? `${hours}h ${remaining}m` : `${hours} hour${hours > 1 ? 's' : ''}`;
};

export function AdminServices() {
  const [services, setServices] = useState<any[]>([]);
  const [categories, setCategories] = useState<ServiceCategory[]>([]);
  const [categoriesLoading, setCategoriesLoading] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [isDragActive, setIsDragActive] = useState(false);
  const [showDiscardDialog, setShowDiscardDialog] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<any | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | ServiceStatus>('ALL');
  const [mode, setMode] = useState<'list' | 'editor'>('list');
  const [form, setForm] = useState<ServiceForm>(emptyForm);
  const [previewOptionIndex, setPreviewOptionIndex] = useState(0);

  useEffect(() => {
    loadInitialData();
  }, []);

  const loadInitialData = async () => {
    try {
      setLoading(true);
      setCategoriesLoading(true);
      const [servicesResponse, categoriesResponse] = await Promise.all([
        adminApi.getAllServices(),
        apiService.getServiceCategories(),
      ]);
      setServices(servicesResponse.data || []);
      setCategories(categoriesResponse.data || []);
    } catch (error) {
      console.error('Failed to load services:', error);
      toast.error('Failed to load services');
    } finally {
      setCategoriesLoading(false);
      setLoading(false);
    }
  };

  const filteredServices = useMemo(() => {
    return services.filter(service => {
      const matchesSearch =
        service.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        service.description?.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesStatus = statusFilter === 'ALL' || (service.status || (service.isActive ? 'PUBLISHED' : 'HIDDEN')) === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [services, searchQuery, statusFilter]);

  const selectedOption = form.options[previewOptionIndex] || form.options.find(o => o.isDefault);
  const previewTotal = Number(form.basePrice || 0) + Number(selectedOption?.priceAdjustment || 0);
  const primaryPhoto = form.photos.find(p => p.isPrimary)?.url || form.imageUrl;

  const startCreate = () => {
    setForm({ ...emptyForm, categoryId: categories[0]?.id ?? '' });
    setPreviewOptionIndex(0);
    setMode('editor');
  };

  const startEdit = (service: any) => {
    const photos = (service.photos || []).map((photo: any, index: number) => ({
      id: photo.id,
      url: photo.url,
      publicId: photo.publicId,
      displayOrder: photo.displayOrder ?? index,
      isPrimary: Boolean(photo.isPrimary),
    }));
    const options = (service.options || []).map((option: any, index: number) => ({
      id: option.id,
      name: option.name || '',
      description: option.description || '',
      priceAdjustment: Number(option.priceAdjustment || 0),
      isDefault: Boolean(option.isDefault),
      displayOrder: option.displayOrder ?? index,
    }));

    setForm({
      id: service.id,
      categoryId: service.categoryId || service.category?.id || '',
      name: service.name || '',
      description: service.description || '',
      basePrice: Number(service.basePrice || 0),
      durationMinutes: Number(service.durationMinutes || 60),
      imageUrl: service.imageUrl || photos.find((p: ServicePhoto) => p.isPrimary)?.url || '',
      iconUrl: service.iconUrl || '',
      warrantyIncluded: service.warrantyIncluded ?? true,
      isFeatured: Boolean(service.isFeatured),
      includedItems: service.includedItems?.length ? service.includedItems : [''],
      options,
      photos,
    });
    setPreviewOptionIndex(Math.max(0, options.findIndex((option: ServiceOption) => option.isDefault)));
    setMode('editor');
  };

  const toPayload = (options?: { status?: ServiceStatus; isActive?: boolean }) => {
    const payload: Record<string, unknown> = {
    categoryId: form.categoryId || undefined,
    name: form.name.trim(),
    description: form.description.trim(),
    basePrice: Number(form.basePrice || 0),
    priceRange: `from LKR ${Number(form.basePrice || 0).toLocaleString()}`,
    durationMinutes: Number(form.durationMinutes || 1),
    imageUrl: primaryPhoto || form.imageUrl,
    iconUrl: form.iconUrl,
    warrantyIncluded: form.warrantyIncluded,
    isFeatured: form.isFeatured,
    includedItems: form.includedItems.map(item => item.trim()).filter(Boolean),
    options: normalizeOptions(form.options),
    photos: normalizePhotos(form.photos),
    };

    if (options?.status) {
      payload.status = options.status;
    }
    if (typeof options?.isActive === 'boolean') {
      payload.isActive = options.isActive;
    }

    return payload;
  };

  const normalizeOptions = (options: ServiceOption[]) => {
    const cleaned = options.filter(option => option.name.trim()).map((option, index) => ({
      ...option,
      name: option.name.trim(),
      description: option.description.trim(),
      priceAdjustment: Number(option.priceAdjustment || 0),
      displayOrder: index,
      isDefault: option.isDefault,
    }));
    if (cleaned.length && !cleaned.some(option => option.isDefault)) {
      cleaned[0].isDefault = true;
    }
    return cleaned;
  };

  const normalizePhotos = (photos: ServicePhoto[]) => {
    const cleaned = photos.filter(photo => photo.url.trim()).map((photo, index) => ({
      ...photo,
      url: photo.url.trim(),
      displayOrder: index,
      isPrimary: photo.isPrimary,
    }));
    if (cleaned.length && !cleaned.some(photo => photo.isPrimary)) {
      cleaned[0].isPrimary = true;
    }
    return cleaned;
  };

  const validateForm = () => {
    if (!form.name.trim()) {
      toast.error('Service name is required');
      return false;
    }
    if (Number(form.basePrice) < 0) {
      toast.error('Base price cannot be negative');
      return false;
    }
    return true;
  };

  const saveService = async () => {
    if (!validateForm()) return;
    try {
      setSaving(true);
      const payload = form.id ? toPayload() : toPayload({ status: 'PUBLISHED', isActive: true });
      const response = form.id
        ? await adminApi.updateService(form.id, payload)
        : await adminApi.createService(payload);
      if (!response.success) {
        toast.error(response.message || 'Failed to save service');
        return;
      }
      toast.success('Service saved successfully');
      setMode('list');
      await loadInitialData();
    } catch (error) {
      console.error('Failed to save service:', error);
      toast.error('Failed to save service');
    } finally {
      setSaving(false);
    }
  };

  const saveDraft = async () => {
    if (!validateForm()) return;
    try {
      setSaving(true);
      const payload = toPayload({ status: 'DRAFT', isActive: false });
      const response = form.id
        ? await adminApi.updateService(form.id, payload)
        : await adminApi.createService(payload);
      if (!response.success) {
        toast.error(response.message || 'Failed to save draft');
        return;
      }
      toast.success('Draft saved successfully');
      setMode('list');
      await loadInitialData();
    } catch (error) {
      console.error('Failed to save draft:', error);
      toast.error('Failed to save draft');
    } finally {
      setSaving(false);
    }
  };

  const publishService = async (service: any) => {
    try {
      await adminApi.publishService(service.id);
      toast.success('Service published successfully');
      loadInitialData();
    } catch (error) {
      console.error('Failed to publish service:', error);
      toast.error('Failed to publish service');
    }
  };

  const hideService = async (service: any) => {
    try {
      await adminApi.hideService(service.id);
      toast.success('Service hidden successfully');
      loadInitialData();
    } catch (error) {
      console.error('Failed to hide service:', error);
      toast.error('Failed to hide service');
    }
  };

  const deleteService = async (service: any) => {
    try {
      setDeleting(true);
      await adminApi.deleteService(service.id);
      toast.success('Service deleted successfully');
      setDeleteTarget(null);
      loadInitialData();
    } catch (error) {
      console.error('Failed to delete service:', error);
      toast.error('Failed to delete service');
    } finally {
      setDeleting(false);
    }
  };

  const requestDelete = (service: any) => {
    setDeleteTarget(service);
  };

  const confirmDiscardEdits = () => {
    setShowDiscardDialog(false);
    setMode('list');
    setForm({ ...emptyForm, categoryId: categories[0]?.id ?? '' });
    setPreviewOptionIndex(0);
  };

  const appendUploadedPhoto = (photo: { url: string; publicId?: string }) => {
    setForm(prev => {
      const nextPhoto: ServicePhoto = {
        url: photo.url,
        publicId: photo.publicId,
        displayOrder: prev.photos.length,
        isPrimary: prev.photos.length === 0,
      };
      return {
        ...prev,
        imageUrl: prev.imageUrl || nextPhoto.url,
        photos: [...prev.photos, nextPhoto],
      };
    });
  };

  const uploadPhotos = async (files: File[]) => {
    const imageFiles = files.filter(file => file.type.startsWith('image/'));
    if (!imageFiles.length) {
      toast.error('Only image files are allowed');
      return;
    }

    try {
      setUploading(true);
      for (const file of imageFiles) {
        const response = await adminApi.uploadServicePhoto(file);
        if (!response.success || !response.data) {
          toast.error(response.message || 'Failed to upload photo');
          continue;
        }
        appendUploadedPhoto({ url: response.data.url, publicId: response.data.publicId });
      }
      toast.success('Photo upload complete');
    } catch (error) {
      console.error('Failed to upload photo:', error);
      toast.error('Failed to upload photo');
    } finally {
      setUploading(false);
    }
  };

  const uploadPhoto = async (file: File) => uploadPhotos([file]);

  const handlePhotoDrop = (event: React.DragEvent<HTMLDivElement>) => {
    event.preventDefault();
    setIsDragActive(false);
    const files = Array.from(event.dataTransfer.files || []);
    if (files.length) {
      uploadPhotos(files);
    }
  };

  const handlePhotoDragOver = (event: React.DragEvent<HTMLDivElement>) => {
    event.preventDefault();
    if (!isDragActive) setIsDragActive(true);
  };

  const handlePhotoDragLeave = () => {
    setIsDragActive(false);
  };

  const addIncludedItem = () => setForm(prev => ({ ...prev, includedItems: [...prev.includedItems, ''] }));
  const updateIncludedItem = (index: number, value: string) => {
    setForm(prev => ({
      ...prev,
      includedItems: prev.includedItems.map((item, i) => (i === index ? value : item)),
    }));
  };
  const removeIncludedItem = (index: number) => {
    setForm(prev => ({ ...prev, includedItems: prev.includedItems.filter((_, i) => i !== index) }));
  };

  const addOption = () => {
    setForm(prev => ({
      ...prev,
      options: [
        ...prev.options,
        {
          name: '',
          description: '',
          priceAdjustment: 0,
          isDefault: prev.options.length === 0,
          displayOrder: prev.options.length,
        },
      ],
    }));
  };

  const updateOption = (index: number, field: keyof ServiceOption, value: string | number | boolean) => {
    setForm(prev => ({
      ...prev,
      options: prev.options.map((option, i) => {
        if (field === 'isDefault') {
          return { ...option, isDefault: i === index };
        }
        return i === index ? { ...option, [field]: value } : option;
      }),
    }));
  };

  const moveOption = (index: number, direction: -1 | 1) => {
    setForm(prev => {
      const options = [...prev.options];
      const nextIndex = index + direction;
      if (nextIndex < 0 || nextIndex >= options.length) return prev;
      [options[index], options[nextIndex]] = [options[nextIndex], options[index]];
      return { ...prev, options };
    });
  };

  const removeOption = (index: number) => {
    setForm(prev => {
      const options = prev.options.filter((_, i) => i !== index);
      if (options.length && !options.some(option => option.isDefault)) options[0].isDefault = true;
      return { ...prev, options };
    });
  };

  const setPrimaryPhoto = (index: number) => {
    setForm(prev => ({
      ...prev,
      imageUrl: prev.photos[index]?.url || prev.imageUrl,
      photos: prev.photos.map((photo, i) => ({ ...photo, isPrimary: i === index })),
    }));
  };

  const removePhoto = (index: number) => {
    setForm(prev => {
      const photos = prev.photos.filter((_, i) => i !== index);
      if (photos.length && !photos.some(photo => photo.isPrimary)) photos[0].isPrimary = true;
      return { ...prev, photos, imageUrl: photos.find(photo => photo.isPrimary)?.url || prev.imageUrl };
    });
  };

  if (loading) {
    return (
      <div className="flex flex-col gap-6">
        <div className="flex items-center justify-between">
          <div className="space-y-2">
            <div className="h-7 w-64 bg-gray-200 rounded animate-pulse" />
            <div className="h-4 w-80 bg-gray-100 rounded animate-pulse" />
          </div>
          <div className="h-10 w-40 bg-[#ffe7df] rounded-lg animate-pulse" />
        </div>
        <div className="bg-white rounded-xl border border-black/5 p-4 space-y-3">
          {Array.from({ length: 6 }).map((_, index) => (
            <div key={index} className="h-16 bg-gray-50 rounded-lg animate-pulse" />
          ))}
        </div>
      </div>
    );
  }

  if (mode === 'editor') {
    return (
      <div className="flex flex-col gap-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div>
              <h1 className="text-2xl text-left font-bold text-black">{form.id ? 'Edit Service' : 'Create Service'}</h1>
              <p className="text-black/70 mt-1">Build the service on the left and review the customer preview on the right</p>
            </div>
          </div>
          <div className="flex flex-wrap gap-2">
            {form.id ? (
              <>
                <button
                  onClick={() => setShowDiscardDialog(true)}
                  disabled={saving}
                  className="flex items-center gap-2 px-4 py-2 border border-black/10 text-black/70 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
                >
                  Cancel
                </button>
                <button
                  onClick={() => saveService()}
                  disabled={saving}
                  className="flex items-center gap-2 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e54d1e] transition-colors shadow-lg shadow-[#ff5d2e]/20 disabled:opacity-50"
                >
                  <Save className="h-4 w-4" />
                  Update Service
                </button>
              </>
            ) : (
              <>
                <button
                  onClick={() => saveDraft()}
                  disabled={saving}
                  className="flex items-center gap-2 px-4 py-2 border border-black/10 text-black/70 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
                >
                  Save Draft
                </button>
                <button
                  onClick={() => saveService()}
                  disabled={saving}
                  className="flex items-center gap-2 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e54d1e] transition-colors shadow-lg shadow-[#ff5d2e]/20 disabled:opacity-50"
                >
                  <Save className="h-4 w-4" />
                  Save Service
                </button>
              </>
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 xl:grid-cols-2 gap-6 items-start">
          <div className="bg-white rounded-xl border border-black/5 shadow-sm p-5 flex flex-col gap-6">
            <section className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Field label="Category">
                <select
                  value={form.categoryId}
                  onChange={e => setForm({ ...form, categoryId: e.target.value ? Number(e.target.value) : '' })}
                  className="input"
                  disabled={categoriesLoading || categories.length === 0}
                >
                  <option value="">{categoriesLoading ? 'Loading categories...' : 'Select a category'}</option>
                  {categories.map(category => (
                    <option key={category.id} value={category.id}>
                      {category.name}
                    </option>
                  ))}
                </select>
              </Field>
              <Field label="Service Name">
                <input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} className="input" placeholder="Lube Services" />
              </Field>
              <Field label="Base Price">
                <input type="number" min="0" value={form.basePrice} onChange={e => setForm({ ...form, basePrice: Number(e.target.value) })} className="input" />
              </Field>
              <Field label="Duration (minutes)">
                <input type="number" min="1" value={form.durationMinutes} onChange={e => setForm({ ...form, durationMinutes: Number(e.target.value) })} className="input" />
              </Field>
              <Field label="Icon">
                <div className="flex gap-2">
                  <input value={form.iconUrl} onChange={e => setForm({ ...form, iconUrl: e.target.value })} className="input flex-1" placeholder="/service icons/icon.png" />
                  <label className="flex items-center justify-center px-3 py-2 bg-gray-100 border border-black/10 rounded-lg cursor-pointer hover:bg-gray-200 transition-colors">
                    <Upload className="w-4 h-4" />
                    <input type="file" accept="image/*" disabled={uploading} onChange={async e => {
                      if (e.target.files?.[0]) {
                         try {
                           setUploading(true);
                           const response = await adminApi.uploadServiceIcon(e.target.files[0]);
                           if (response.success && response.data) {
                             setForm({ ...form, iconUrl: response.data.url });
                             toast.success('Icon uploaded');
                           }
                         } finally {
                           setUploading(false);
                         }
                      }
                    }} className="hidden" />
                  </label>
                </div>
              </Field>
            </section>

            <Field label="Description">
              <textarea value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} className="input min-h-28 resize-none" placeholder="Describe what customers get..." />
            </Field>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <label className="flex items-center gap-3 p-3 rounded-lg border border-black/10">
                <input type="checkbox" checked={form.warrantyIncluded} onChange={e => setForm({ ...form, warrantyIncluded: e.target.checked })} />
                <span className="text-sm font-medium text-black">Warranty included</span>
              </label>
              <label className="flex items-center gap-3 p-3 rounded-lg border border-black/10">
                <input type="checkbox" checked={form.isFeatured} onChange={e => setForm({ ...form, isFeatured: e.target.checked })} />
                <span className="text-sm font-medium text-black">Featured service</span>
              </label>
            </div>

            <section className="flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <h2 className="font-semibold text-black">Photos</h2>
                <label className="flex items-center gap-2 px-3 py-2 bg-[#fff7f5] text-[#ff5d2e] rounded-lg cursor-pointer hover:bg-[#ffe7df] transition-colors text-sm font-medium">
                  <Upload className="w-4 h-4" />
                  {uploading ? 'Uploading...' : 'Upload'}
                  <input
                    type="file"
                    accept="image/*"
                    multiple
                    disabled={uploading}
                    onChange={e => e.target.files?.length && uploadPhotos(Array.from(e.target.files))}
                    className="hidden"
                  />
                </label>
              </div>
              <div
                onDragOver={handlePhotoDragOver}
                onDragEnter={handlePhotoDragOver}
                onDragLeave={handlePhotoDragLeave}
                onDrop={handlePhotoDrop}
                className={`rounded-lg border border-dashed px-4 py-3 text-sm transition-colors ${isDragActive ? 'border-[#ff5d2e] bg-[#fff7f5] text-[#ff5d2e]' : 'border-black/10 bg-white text-black/50'}`}
              >
                Drag and drop images here or click Upload to browse
              </div>
              <input value={form.imageUrl} onChange={e => setForm({ ...form, imageUrl: e.target.value })} className="input" placeholder="Or paste an image URL" />
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                {form.photos.map((photo, index) => (
                  <div key={`${photo.url}-${index}`} className="relative rounded-lg overflow-hidden border border-black/10 bg-gray-50 aspect-video">
                    <img src={photo.url} alt="Service" className="w-full h-full object-cover" />
                    <div className="absolute inset-x-2 bottom-2 flex gap-1">
                      <button onClick={() => setPrimaryPhoto(index)} className="flex-1 px-2 py-1 bg-white/90 rounded text-xs font-medium text-black">
                        {photo.isPrimary ? 'Primary' : 'Set primary'}
                      </button>
                      <button onClick={() => removePhoto(index)} className="p-1 bg-white/90 rounded text-red-600">
                        <X className="w-3 h-3" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </section>

            <section className="flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <h2 className="font-semibold text-black">What's Included</h2>
                <button onClick={addIncludedItem} className="text-sm font-medium text-[#ff5d2e]">Add item</button>
              </div>
              {form.includedItems.map((item, index) => (
                <div key={index} className="flex gap-2">
                  <input value={item} onChange={e => updateIncludedItem(index, e.target.value)} className="input" placeholder="Spark plug check" />
                  <button onClick={() => removeIncludedItem(index)} className="p-2 text-red-600 hover:bg-red-50 rounded-lg">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              ))}
            </section>

            <section className="flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="font-semibold text-black">Selectable Packages</h2>
                  <p className="text-xs text-black/50">Optional add-ons like oil type, coating package, or inspection tier</p>
                </div>
                <button onClick={addOption} className="flex items-center gap-1 text-sm font-medium text-[#ff5d2e]">
                  <Plus className="w-4 h-4" /> Add package
                </button>
              </div>
              {form.options.map((option, index) => (
                <div key={index} className="p-3 border border-black/10 rounded-lg flex flex-col gap-3">
                  <div className="grid grid-cols-1 md:grid-cols-[1fr_140px] gap-3">
                    <input value={option.name} onChange={e => updateOption(index, 'name', e.target.value)} className="input" placeholder="Standard/Conventional Oil" />
                    <input type="number" min="0" value={option.priceAdjustment} onChange={e => updateOption(index, 'priceAdjustment', Number(e.target.value))} className="input" placeholder="4000" />
                  </div>
                  <textarea value={option.description} onChange={e => updateOption(index, 'description', e.target.value)} className="input min-h-16 resize-none" placeholder="Basic protection for everyday driving" />
                  <div className="flex flex-wrap items-center gap-2">
                    <button onClick={() => updateOption(index, 'isDefault', true)} className={`px-3 py-1 rounded-full border text-xs font-medium ${option.isDefault ? 'bg-[#ffe7df] text-[#ff5d2e] border-[#ff5d2e]' : 'bg-white text-black/60 border-black/10'}`}>
                      Default
                    </button>
                    <button onClick={() => moveOption(index, -1)} className="p-1.5 text-black/50 hover:bg-gray-50 rounded" title="Move up"><ArrowUp className="w-4 h-4" /></button>
                    <button onClick={() => moveOption(index, 1)} className="p-1.5 text-black/50 hover:bg-gray-50 rounded" title="Move down"><ArrowDown className="w-4 h-4" /></button>
                    <button onClick={() => removeOption(index)} className="ml-auto p-1.5 text-red-600 hover:bg-red-50 rounded" title="Remove"><Trash2 className="w-4 h-4" /></button>
                  </div>
                </div>
              ))}
              {form.options.length === 0 && <p className="text-sm text-black/50 bg-gray-50 rounded-lg p-3">No selectable packages. Customers will book the base service only.</p>}
            </section>
          </div>

          <ServicePreview
            form={form}
            primaryPhoto={primaryPhoto}
            selectedOption={selectedOption}
            selectedIndex={previewOptionIndex}
            onSelectOption={setPreviewOptionIndex}
            total={previewTotal}
          />
        </div>

        {showDiscardDialog && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
            <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <h3 className="text-lg font-semibold text-black">Discard edits?</h3>
                  <p className="text-sm text-black/60 mt-1">Your unsaved changes will be lost. Are you sure you want to go back?</p>
                </div>
                <button onClick={() => setShowDiscardDialog(false)} className="text-black/40 hover:text-black" aria-label="Close">
                  <X className="w-5 h-5" />
                </button>
              </div>
              <div className="mt-6 flex items-center justify-end gap-2">
                <button
                  onClick={() => setShowDiscardDialog(false)}
                  className="px-4 py-2 rounded-lg border border-black/10 text-black/70 hover:bg-gray-50"
                >
                  Keep editing
                </button>
                <button
                  onClick={confirmDiscardEdits}
                  className="px-4 py-2 rounded-lg bg-black text-white hover:bg-black/90"
                >
                  Discard
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl text-left font-bold text-black">Services Management</h1>
          <p className="text-black/70 mt-1">Manage service offerings, packages, photos, and publishing</p>
        </div>
        <button onClick={startCreate} className="flex items-center gap-2 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e54d1e] transition-colors shadow-lg shadow-[#ff5d2e]/20">
          <Plus className="h-4 w-4" />
          <span>Add New Service</span>
        </button>
      </div>

      <div className="bg-white rounded-xl border border-black/5 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-black/5 flex flex-col lg:flex-row gap-4 justify-between lg:items-center">
          <div className="relative w-full lg:w-96">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input value={searchQuery} onChange={e => setSearchQuery(e.target.value)} type="text" placeholder="Search services..." className="w-full pl-10 pr-4 py-2 bg-gray-50 border-transparent focus:bg-white focus:border-[#ff5d2e] focus:ring-0 rounded-lg transition-all text-sm" />
          </div>
          <div className="flex flex-wrap gap-2">
            {(['ALL', 'PUBLISHED', 'DRAFT', 'HIDDEN'] as const).map(status => (
              <button key={status} onClick={() => setStatusFilter(status)} className={`px-3 py-2 rounded-lg text-sm font-medium border transition-colors ${statusFilter === status ? 'bg-[#ffe7df] text-[#ff5d2e] border-[#ff5d2e]' : 'bg-white text-black/60 border-black/10 hover:bg-gray-50'}`}>
                {status === 'ALL' ? 'All' : status.charAt(0) + status.slice(1).toLowerCase()}
              </button>
            ))}
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50/50 border-b border-black/5">
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Service Details</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Price</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Packages</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filteredServices.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-gray-500">
                    <div className="bg-gray-50 rounded-full w-16 h-16 flex items-center justify-center mx-auto mb-4">
                      <Package className="h-8 w-8 text-gray-400" />
                    </div>
                    <p className="text-lg font-medium text-black">No services found</p>
                    <p className="text-sm text-gray-500">Try adjusting your search or add a new service.</p>
                  </td>
                </tr>
              ) : (
                filteredServices.map((service) => {
                  const status = service.status || (service.isActive ? 'PUBLISHED' : 'HIDDEN');
                  return (
                    <tr key={service.id} className="hover:bg-gray-50/50 transition-colors group">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-4">
                          <div className="w-12 h-12 rounded-lg bg-gray-100 overflow-hidden flex-shrink-0 border border-black/5 flex items-center justify-center">
                            {service.iconUrl ? <img src={service.iconUrl} alt={service.name} className="w-8 h-8 object-contain" /> : <Package className="w-6 h-6 text-gray-400" />}
                          </div>
                          <div>
                            <p className="font-semibold text-black text-sm">{service.name}</p>
                            {service.categoryName && <p className="text-xs text-black/40 mt-1">{service.categoryName}</p>}
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-sm font-medium text-black">{service.basePrice ? formatLkr(service.basePrice) : 'Quote required'}</td>
                      <td className="px-6 py-4 text-sm text-gray-500">{service.options?.length || 0}</td>
                      <td className="px-6 py-4"><span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border ${statusStyles[status as ServiceStatus]}`}>{status.charAt(0) + status.slice(1).toLowerCase()}</span></td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button onClick={() => startEdit(service)} className="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors" title="Edit"><Edit className="h-4 w-4" /></button>
                          {status !== 'PUBLISHED' ? (
                            <button onClick={() => publishService(service)} className="p-2 text-gray-500 hover:text-green-600 hover:bg-green-50 rounded-lg transition-colors" title="Publish"><Eye className="h-4 w-4" /></button>
                          ) : (
                            <button onClick={() => hideService(service)} className="p-2 text-gray-500 hover:text-amber-600 hover:bg-amber-50 rounded-lg transition-colors" title="Hide"><EyeOff className="h-4 w-4" /></button>
                          )}
                          <button onClick={() => requestDelete(service)} className="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors" title="Delete"><Trash2 className="h-4 w-4" /></button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        <div className="p-4 border-t border-black/5 bg-gray-50/50 flex items-center justify-between text-xs text-gray-500">
          <span>Showing {filteredServices.length} results</span>
          <span>{services.filter(s => (s.status || (s.isActive ? 'PUBLISHED' : 'HIDDEN')) === 'PUBLISHED').length} published</span>
        </div>
      </div>

      {deleteTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
            <div className="flex items-start justify-between gap-4">
              <div>
                <h3 className="text-lg font-semibold text-black">Delete service</h3>
                <p className="text-sm text-black/60 mt-1">This will permanently remove {deleteTarget.name}. This action cannot be undone.</p>
              </div>
              <button onClick={() => setDeleteTarget(null)} className="text-black/40 hover:text-black" aria-label="Close">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="mt-6 flex items-center justify-end gap-2">
              <button
                onClick={() => setDeleteTarget(null)}
                disabled={deleting}
                className="px-4 py-2 rounded-lg border border-black/10 text-black/70 hover:bg-gray-50 disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                onClick={() => deleteService(deleteTarget)}
                disabled={deleting}
                className="px-4 py-2 rounded-lg bg-red-600 text-white hover:bg-red-700 disabled:opacity-50"
              >
                {deleting ? 'Deleting...' : 'Delete'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <label className="flex flex-col gap-1.5 text-left">
      <span className="text-xs font-semibold text-black/60 uppercase tracking-wide">{label}</span>
      {children}
    </label>
  );
}

function ServicePreview({
  form,
  primaryPhoto,
  selectedOption,
  selectedIndex,
  onSelectOption,
  total,
}: {
  form: ServiceForm;
  primaryPhoto?: string;
  selectedOption?: ServiceOption;
  selectedIndex: number;
  onSelectOption: (index: number) => void;
  total: number;
}) {
  const includedItems = form.includedItems.filter(Boolean);

  return (
    <div className="sticky top-6 bg-white rounded-xl border border-black/5 shadow-sm p-5 flex flex-col gap-5">
      <div className="flex items-center justify-between">
        <h2 className="font-semibold text-black">Customer Preview</h2>
        {form.iconUrl && (
          <img src={form.iconUrl} alt="Icon" className="w-8 h-8 object-contain" />
        )}
      </div>
      <div className="aspect-[16/9] rounded-xl overflow-hidden bg-[#ffe7df] flex items-center justify-center">
        {primaryPhoto ? <img src={primaryPhoto} alt={form.name || 'Service preview'} className="w-full h-full object-cover" /> : <Image className="w-10 h-10 text-[#ff5d2e]" />}
      </div>
      <div>
        <div className="flex items-start justify-between gap-4">
          <div>
            <h3 className="text-xl font-semibold text-black">{form.name || 'Service name'}</h3>
            <p className="text-lg font-semibold text-[#ff5d2e] mt-1">from {formatLkr(form.basePrice)}</p>
          </div>
        </div>
        <div className="flex flex-wrap items-center gap-4 text-sm text-black/70 mt-3">
          <div className="flex items-center gap-1"><Clock className="w-4 h-4" />{durationLabel(form.durationMinutes)}</div>
          {form.warrantyIncluded && <div className="flex items-center gap-1"><Shield className="w-4 h-4" />Warranty included</div>}
        </div>
        <p className="text-sm text-black/70 leading-relaxed mt-3">{form.description || 'Service description will appear here.'}</p>
      </div>

      <div>
        <h3 className="text-base font-semibold text-black mb-3">What's Included</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
          {(includedItems.length ? includedItems : ['Add included items']).map((item, index) => (
            <div key={index} className="flex items-center gap-2 p-3 bg-gray-50 rounded-lg">
              <Check className="w-4 h-4 text-green-500 shrink-0" />
              <span className="text-sm font-medium text-black">{item}</span>
            </div>
          ))}
        </div>
      </div>

      {form.options.length > 0 && (
        <div>
          <h3 className="text-base font-semibold text-black mb-3">Selectable Packages</h3>
          <div className="flex flex-col gap-2">
            {form.options.map((option, index) => (
              <button
                key={index}
                onClick={() => onSelectOption(index)}
                className={`w-full text-left p-3 rounded-lg border transition-all ${selectedIndex === index ? 'bg-[#ffe7df] border-[#ff5d2e]' : 'bg-white border-black/10 hover:border-[#ff5d2e]/50'}`}
              >
                <div className="flex items-center gap-3">
                  <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${selectedIndex === index ? 'border-[#ff5d2e]' : 'border-black/30'}`}>
                    {selectedIndex === index && <div className="w-3 h-3 rounded-full bg-[#ff5d2e]" />}
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-black">{option.name || 'Package name'}</p>
                    <p className="text-xs text-black/50">{option.description || 'Package description'}</p>
                  </div>
                  <p className="font-semibold text-black">+{formatLkr(option.priceAdjustment)}</p>
                </div>
              </button>
            ))}
          </div>
        </div>
      )}

      <div className="bg-[#fff7f5] rounded-xl p-4 flex flex-col gap-3">
        <h3 className="font-semibold text-black">Booking Summary</h3>
        <div className="flex items-center justify-between text-sm">
          <span className="text-black/70">Service Fee</span>
          <span className="font-medium text-black">{formatLkr(form.basePrice)}</span>
        </div>
        {selectedOption && (
          <div className="flex items-center justify-between text-sm">
            <span className="text-black/70">{selectedOption.name || 'Selected package'}</span>
            <span className="font-medium text-black">{formatLkr(selectedOption.priceAdjustment)}</span>
          </div>
        )}
        <div className="h-px bg-black/10" />
        <div className="flex items-center justify-between">
          <span className="font-semibold text-black">Total</span>
          <span className="text-xl font-bold text-[#ff5d2e]">{formatLkr(total)}</span>
        </div>
      </div>
    </div>
  );
}
