import { useState, useEffect } from 'react';
import type { ServiceRecordRequest, ServiceRecord } from '@/services/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';

interface ServiceRecordFormProps {
  vehicleId: number;
  initialData?: ServiceRecord | null;
  onSubmit: (data: ServiceRecordRequest) => Promise<void>;
  onCancel: () => void;
  isSubmitting: boolean;
}

export function ServiceRecordForm({ 
  vehicleId, 
  initialData, 
  onSubmit, 
  onCancel,
  isSubmitting 
}: ServiceRecordFormProps) {
  const [formData, setFormData] = useState<ServiceRecordRequest>({
    vehicleId,
    serviceType: '',
    description: '',
    serviceDate: new Date().toISOString().split('T')[0],
    mileage: 0,
    cost: 0
  });

  useEffect(() => {
    if (initialData) {
      setFormData({
        vehicleId: initialData.vehicleId,
        serviceType: initialData.serviceType,
        description: initialData.description,
        serviceDate: initialData.serviceDate,
        mileage: initialData.mileage,
        cost: initialData.cost
      });
    }
  }, [initialData]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4 bg-white p-6 rounded-lg border border-gray-200">
      <h3 className="text-lg font-semibold mb-4">
        {initialData ? 'Edit Service Record' : 'Add New Service Record'}
      </h3>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label htmlFor="serviceType">Service Type</Label>
          <Input
            id="serviceType"
            placeholder="e.g. Oil Change, Brake Repair"
            value={formData.serviceType}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, serviceType: e.target.value })}
            required
          />
        </div>
        
        <div className="space-y-2">
          <Label htmlFor="serviceDate">Date</Label>
          <Input
            id="serviceDate"
            type="date"
            value={formData.serviceDate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, serviceDate: e.target.value })}
            required
          />
        </div>
        
        <div className="space-y-2">
          <Label htmlFor="mileage">Mileage</Label>
          <Input
            id="mileage"
            type="number"
            min="0"
            value={formData.mileage}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, mileage: parseInt(e.target.value) || 0 })}
            required
          />
        </div>
        
        <div className="space-y-2">
          <Label htmlFor="cost">Cost ($)</Label>
          <Input
            id="cost"
            type="number"
            min="0"
            step="0.01"
            value={formData.cost}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, cost: parseFloat(e.target.value) || 0 })}
            required
          />
        </div>
      </div>
      
      <div className="space-y-2">
        <Label htmlFor="description">Description</Label>
        <Textarea
          id="description"
          placeholder="Details about the service performed..."
          value={formData.description}
          onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setFormData({ ...formData, description: e.target.value })}
          rows={3}
        />
      </div>
      
      <div className="flex justify-end gap-3 pt-4">
        <Button type="button" variant="outline" onClick={onCancel}>
          Cancel
        </Button>
        <Button type="submit" disabled={isSubmitting} className="bg-[#ff5d2e] hover:bg-[#e04e24]">
          {isSubmitting ? 'Saving...' : (initialData ? 'Update Record' : 'Save Record')}
        </Button>
      </div>
    </form>
  );
}