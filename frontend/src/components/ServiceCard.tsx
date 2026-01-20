import { Link } from 'react-router-dom';
import { Warehouse, ChevronRight } from 'lucide-react';

interface ServiceCardProps {
  id: number;
  name: string;
  imageUrl?: string | null;
}

export function ServiceCard({ id, name, imageUrl }: ServiceCardProps) {
  return (
    <Link
      to={`/services/${id}`}
      className="bg-white rounded-lg shadow-sm p-3 flex items-center gap-3 hover:shadow-md transition-shadow"
    >
      <div className="w-12 h-12 rounded bg-[#ffe7df] flex items-center justify-center overflow-hidden">
        {imageUrl ? (
          <img src={imageUrl} alt={name} className="w-full h-full object-cover" />
        ) : (
          <Warehouse className="w-6 h-6 text-[#ff5d2e]" />
        )}
      </div>
      <p className="flex-1 text-base font-medium text-black">{name}</p>
      <ChevronRight className="w-5 h-5 text-black/50" />
    </Link>
  );
}
