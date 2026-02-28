import { useState, useEffect, useRef } from 'react';
import { Car, ChevronDown, Search, Plus, X } from 'lucide-react';
import { apiService } from '@/services/api';
import type { VehicleDto } from '@/services/api';

interface VehicleSelectorProps {
  value: string;                          // current vehicle display name
  onSelect: (display: string) => void;    // called with "Make Model (Year) – Plate"
  className?: string;
  compact?: boolean;                      // smaller variant for mobile CTA
}

export function VehicleSelector({ value, onSelect, className = '', compact = false }: VehicleSelectorProps) {
  const [vehicles, setVehicles] = useState<VehicleDto[]>([]);
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const panelRef = useRef<HTMLDivElement>(null);
  const btnRef = useRef<HTMLButtonElement>(null);

  // Fetch user's saved vehicles on mount
  useEffect(() => {
    apiService
      .getMyVehicles()
      .then((res) => {
        if (res.success && res.data) setVehicles(res.data);
      })
      .catch(() => {})
      .finally(() => setIsLoading(false));
  }, []);

  // Close on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (
        panelRef.current && !panelRef.current.contains(e.target as Node) &&
        btnRef.current && !btnRef.current.contains(e.target as Node)
      ) {
        setIsOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  const formatVehicle = (v: VehicleDto) =>
    `${v.make} ${v.model} (${v.year}) – ${v.licensePlate}`;

  const filtered = vehicles.filter((v) => {
    if (!search.trim()) return true;
    const q = search.toLowerCase();
    return (
      v.make.toLowerCase().includes(q) ||
      v.model.toLowerCase().includes(q) ||
      v.licensePlate.toLowerCase().includes(q) ||
      String(v.year).includes(q)
    );
  });

  const handleSelect = (v: VehicleDto) => {
    onSelect(formatVehicle(v));
    setIsOpen(false);
    setSearch('');
  };

  const handleManualEntry = () => {
    if (search.trim()) {
      onSelect(search.trim());
    }
    setIsOpen(false);
    setSearch('');
  };

  if (compact) {
    // Compact version for mobile CTA bars
    return (
      <div className={`relative ${className}`}>
        <button
          ref={btnRef}
          onClick={() => setIsOpen((o) => !o)}
          className="w-full flex items-center gap-3 px-3 py-2.5 bg-[#fff7f5] rounded-xl focus-within:ring-2 focus-within:ring-[#ff5d2e]/30 transition-all"
        >
          <Car className="w-5 h-5 text-[#ff5d2e] shrink-0" />
          <span className={`flex-1 text-left text-sm font-medium truncate ${value ? 'text-black' : 'text-black/40'}`}>
            {value || 'Select or enter vehicle'}
          </span>
          <ChevronDown className={`w-4 h-4 text-black/40 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
        </button>

        {isOpen && (
          <div
            ref={panelRef}
            className="absolute left-0 right-0 bottom-full mb-2 bg-white rounded-xl shadow-xl border border-black/5 z-50 flex flex-col overflow-hidden"
            style={{ maxHeight: '280px' }}
          >
            <DropdownContent
              search={search}
              setSearch={setSearch}
              filtered={filtered}
              isLoading={isLoading}
              handleSelect={handleSelect}
              handleManualEntry={handleManualEntry}
            />
          </div>
        )}
      </div>
    );
  }

  // Default: full-size version for desktop sidebar / checkout sections
  return (
    <div className={`relative ${className}`}>
      <button
        ref={btnRef}
        onClick={() => setIsOpen((o) => !o)}
        className="w-full p-3 bg-[#fff7f5] rounded-lg flex items-center gap-3"
      >
        <Car className="w-5 h-5 text-[#ff5d2e] shrink-0" />
        <span className={`flex-1 text-left text-sm font-medium truncate ${value ? 'text-black' : 'text-black/40'}`}>
          {value || 'Select or enter vehicle'}
        </span>
        <ChevronDown className={`w-4 h-4 text-black/40 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {isOpen && (
        <div
          ref={panelRef}
          className="absolute left-0 right-0 top-full mt-1 bg-white rounded-xl shadow-xl border border-black/5 z-50 flex flex-col overflow-hidden"
          style={{ maxHeight: '300px' }}
        >
          <DropdownContent
            search={search}
            setSearch={setSearch}
            filtered={filtered}
            isLoading={isLoading}
            handleSelect={handleSelect}
            handleManualEntry={handleManualEntry}
          />
        </div>
      )}
    </div>
  );
}

// ── Shared dropdown inner content ────────────────────────────────────────────
function DropdownContent({
  search,
  setSearch,
  filtered,
  isLoading,
  handleSelect,
  handleManualEntry,
}: {
  search: string;
  setSearch: (v: string) => void;
  filtered: VehicleDto[];
  isLoading: boolean;
  handleSelect: (v: VehicleDto) => void;
  handleManualEntry: () => void;
}) {
  return (
    <>
      {/* Search input */}
      <div className="flex items-center gap-2 px-3 py-2 border-b border-black/5">
        <Search className="w-4 h-4 text-black/30 shrink-0" />
        <input
          autoFocus
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') handleManualEntry();
          }}
          placeholder="Search vehicles or type new…"
          className="flex-1 text-sm outline-none bg-transparent placeholder:text-black/30"
        />
        {search && (
          <button onClick={() => setSearch('')} className="p-0.5">
            <X className="w-3.5 h-3.5 text-black/30" />
          </button>
        )}
      </div>

      {/* Vehicle list */}
      <div className="overflow-y-auto flex-1">
        {isLoading ? (
          <p className="text-xs text-black/40 text-center py-4">Loading…</p>
        ) : filtered.length === 0 && !search.trim() ? (
          <p className="text-xs text-black/40 text-center py-4">
            No saved vehicles.
            <br />
            Add one in Account → My Vehicles
          </p>
        ) : (
          <>
            {filtered.map((v) => (
              <button
                key={v.id}
                onClick={() => handleSelect(v)}
                className="w-full flex items-center gap-3 px-3 py-2.5 hover:bg-[#fff7f5] transition-colors text-left"
              >
                <div className="w-8 h-8 bg-[#ffe7df] rounded-lg flex items-center justify-center shrink-0">
                  <Car className="w-4 h-4 text-[#ff5d2e]" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-black truncate">
                    {v.make} {v.model}{' '}
                    <span className="text-black/40">({v.year})</span>
                  </p>
                  <p className="text-xs text-black/50 truncate">{v.licensePlate}</p>
                </div>
              </button>
            ))}

            {/* Manual entry option when searching */}
            {search.trim() && (
              <button
                onClick={handleManualEntry}
                className="w-full flex items-center gap-3 px-3 py-2.5 hover:bg-[#fff7f5] transition-colors text-left border-t border-black/5"
              >
                <div className="w-8 h-8 bg-[#ffe7df] rounded-lg flex items-center justify-center shrink-0">
                  <Plus className="w-4 h-4 text-[#ff5d2e]" />
                </div>
                <p className="text-sm font-medium text-[#ff5d2e] truncate">
                  Use "{search.trim()}"
                </p>
              </button>
            )}
          </>
        )}
      </div>
    </>
  );
}




