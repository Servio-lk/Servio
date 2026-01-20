import { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { apiService, ServiceRecord, ServiceRecordRequest } from '@/services/api';
import { ServiceRecordCard } from '@/components/service-history/ServiceRecordCard';
import { ServiceRecordForm } from '@/components/service-history/ServiceRecordForm';
import { Button } from '@/components/ui/button';
import { Plus } from 'lucide-react';
import { toast } from 'sonner';

export default function ServiceHistoryPage() {
  const { vehicleId } = useParams<{ vehicleId: string }>();
  const [records, setRecords] = useState<ServiceRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingRecord, setEditingRecord] = useState<ServiceRecord | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (vehicleId) {
      loadRecords();
    }
  }, [vehicleId]);

  const loadRecords = async () => {
    if (!vehicleId) return;
    try {
      setLoading(true);
      const response = await apiService.getServiceRecordsByVehicle(parseInt(vehicleId));
      if (response.success && response.data) {
        setRecords(response.data);
      }
    } catch (error) {
      toast.error('Failed to load service records');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (data: ServiceRecordRequest) => {
    try {
      setSubmitting(true);
      if (editingRecord) {
        await apiService.updateServiceRecord(editingRecord.id, data);
        toast.success('Service record updated');
      } else {
        await apiService.createServiceRecord(data);
        toast.success('Service record created');
      }
      setShowForm(false);
      setEditingRecord(null);
      loadRecords();
    } catch (error) {
      toast.error('Failed to save record');
      console.error(error);
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this record?')) return;
    try {
      await apiService.deleteServiceRecord(id);
      toast.success('Record deleted');
      setRecords(records.filter(r => r.id !== id));
    } catch (error) {
      toast.error('Failed to delete record');
    }
  };

  const handleEdit = (record: ServiceRecord) => {
    setEditingRecord(record);
    setShowForm(true);
  };

  if (loading) {
    return <div className="p-8 text-center">Loading history...</div>;
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Service History</h1>
          <p className="text-gray-500">Manage maintenance records for your vehicle</p>
        </div>
        <Button 
          onClick={() => { setEditingRecord(null); setShowForm(true); }}
          className="bg-[#ff5d2e] hover:bg-[#e04e24]"
        >
          <Plus className="w-4 h-4 mr-2" />
          Add Record
        </Button>
      </div>

      {showForm && vehicleId && (
        <div className="mb-8">
          <ServiceRecordForm
            vehicleId={parseInt(vehicleId)}
            initialData={editingRecord}
            onSubmit={handleSubmit}
            onCancel={() => { setShowForm(false); setEditingRecord(null); }}
            isSubmitting={submitting}
          />
        </div>
      )}

      <div className="space-y-4">
        {records.length === 0 && !showForm ? (
          <div className="text-center py-12 bg-gray-50 rounded-lg border border-dashed border-gray-300">
            <p className="text-gray-500">No service records found. Add your first one!</p>
          </div>
        ) : (
          records.map(record => (
            <ServiceRecordCard 
              key={record.id} 
              record={record} 
              onEdit={handleEdit}
              onDelete={handleDelete}
            />
          ))
        )}
      </div>
    </div>
  );
}