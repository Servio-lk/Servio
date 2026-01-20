import { ServiceRecord } from '@/services/api';
import { Button } from '@/components/ui/button';
import { CalendarIcon, Wrench, Trash2, Edit2 } from 'lucide-react';

interface ServiceRecordCardProps {
  record: ServiceRecord;
  onEdit: (record: ServiceRecord) => void;
  onDelete: (id: number) => void;
}

export function ServiceRecordCard({ record, onEdit, onDelete }: ServiceRecordCardProps) {
  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-100 p-4 hover:shadow-md transition-shadow">
      <div className="flex justify-between items-start mb-2">
        <div className="flex items-center gap-2">
          <div className="bg-orange-100 p-2 rounded-full">
            <Wrench className="w-4 h-4 text-orange-600" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900">{record.serviceType}</h3>
            <div className="flex items-center text-xs text-gray-500 gap-1">
              <CalendarIcon className="w-3 h-3" />
              {new Date(record.serviceDate).toLocaleDateString()}
            </div>
          </div>
        </div>
        <div className="text-right">
          <p className="font-bold text-gray-900">${record.cost.toFixed(2)}</p>
          <p className="text-xs text-gray-500">{record.mileage.toLocaleString()} mi</p>
        </div>
      </div>
      
      <p className="text-sm text-gray-600 mb-4 bg-gray-50 p-2 rounded">
        {record.description}
      </p>

      <div className="flex justify-end gap-2 border-t border-gray-100 pt-3">
        <Button 
          variant="ghost" 
          size="sm" 
          onClick={() => onEdit(record)}
          className="h-8 px-2 text-gray-500 hover:text-blue-600"
        >
          <Edit2 className="w-3.5 h-3.5 mr-1" />
          Edit
        </Button>
        <Button 
          variant="ghost" 
          size="sm" 
          onClick={() => onDelete(record.id)}
          className="h-8 px-2 text-gray-500 hover:text-red-600"
        >
          <Trash2 className="w-3.5 h-3.5 mr-1" />
          Delete
        </Button>
      </div>
    </div>
  );
}