import { useState, useEffect } from 'react';
import { ChevronLeft, ChevronRight, Clock, CheckCircle2, XCircle, Calendar } from 'lucide-react';
import { adminApi } from '@/services/adminApi';

// ── Types ──────────────────────────────────────────────────────────────────
interface Appointment {
    id: number;
    userName: string;
    userEmail: string;
    serviceType: string;
    appointmentDate: string;
    status: string;
    estimatedCost: number;
}

interface WorkingHoursSettings {
    workingDays: boolean[]; // index 0=Mon … 6=Sun
    startHour: number;     // 0–23
    endHour: number;       // 0–23
}

const DAY_LABELS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const MONTH_NAMES = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
];

const DEFAULT_SETTINGS: WorkingHoursSettings = {
    workingDays: [true, true, true, true, true, false, false], // Mon–Fri
    startHour: 9,
    endHour: 18,
};

function loadSettings(): WorkingHoursSettings {
    try {
        const raw = localStorage.getItem('servio_working_hours');
        if (raw) return JSON.parse(raw);
    } catch { }
    return DEFAULT_SETTINGS;
}

function saveSettings(s: WorkingHoursSettings) {
    localStorage.setItem('servio_working_hours', JSON.stringify(s));
}

// ── Status badge ───────────────────────────────────────────────────────────
function StatusBadge({ status }: { status: string }) {
    const colours: Record<string, string> = {
        CONFIRMED: 'bg-green-100 text-green-700',
        PENDING: 'bg-yellow-100 text-yellow-700',
        COMPLETED: 'bg-blue-100 text-blue-700',
        CANCELLED: 'bg-red-100 text-red-700',
    };
    return (
        <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${colours[status] ?? 'bg-gray-100 text-gray-600'}`}>
            {status}
        </span>
    );
}

// ── Main page ──────────────────────────────────────────────────────────────
export default function AdminCalendar() {
    const today = new Date();

    const [viewYear, setViewYear] = useState(today.getFullYear());
    const [viewMonth, setViewMonth] = useState(today.getMonth()); // 0-indexed
    const [selectedDay, setSelectedDay] = useState<Date>(today);

    const [allAppointments, setAllAppointments] = useState<Appointment[]>([]);
    const [isLoading, setIsLoading] = useState(true);

    const [settings, setSettings] = useState<WorkingHoursSettings>(loadSettings);
    const [settingsSaved, setSettingsSaved] = useState(false);

    // Load all appointments once
    useEffect(() => {
        const load = async () => {
            setIsLoading(true);
            try {
                const data = await adminApi.getAllAppointments();
                setAllAppointments(data?.data ?? []);
            } catch {
                setAllAppointments([]);
            } finally {
                setIsLoading(false);
            }
        };
        load();
    }, []);

    // Helper: appointment count for a calendar day
    const countForDay = (year: number, month: number, day: number) =>
        allAppointments.filter((a) => {
            const d = new Date(a.appointmentDate);
            return d.getFullYear() === year && d.getMonth() === month && d.getDate() === day;
        }).length;

    // Appointments for the selected day panel
    const dayAppointments = allAppointments.filter((a) => {
        const d = new Date(a.appointmentDate);
        return (
            d.getFullYear() === selectedDay.getFullYear() &&
            d.getMonth() === selectedDay.getMonth() &&
            d.getDate() === selectedDay.getDate()
        );
    }).sort((a, b) => new Date(a.appointmentDate).getTime() - new Date(b.appointmentDate).getTime());

    // Build calendar grid
    const firstDayOfMonth = new Date(viewYear, viewMonth, 1).getDay(); // 0=Sun
    // Shift so week starts Mon: Sun→6, Mon→0 …
    const startOffset = (firstDayOfMonth + 6) % 7;
    const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
    const cells: (number | null)[] = [
        ...Array(startOffset).fill(null),
        ...Array.from({ length: daysInMonth }, (_, i) => i + 1),
    ];
    // Pad to complete last row
    while (cells.length % 7 !== 0) cells.push(null);

    const navigateMonth = (dir: -1 | 1) => {
        const d = new Date(viewYear, viewMonth + dir, 1);
        setViewYear(d.getFullYear());
        setViewMonth(d.getMonth());
    };

    const handleSaveSettings = () => {
        saveSettings(settings);
        setSettingsSaved(true);
        setTimeout(() => setSettingsSaved(false), 2000);
    };

    const toggleDay = (i: number) => {
        setSettings(prev => {
            const days = [...prev.workingDays];
            days[i] = !days[i];
            return { ...prev, workingDays: days };
        });
    };

    const formatTime = (h: number) => {
        const period = h < 12 ? 'AM' : 'PM';
        const hour = h === 0 ? 12 : h > 12 ? h - 12 : h;
        return `${hour}:00 ${period}`;
    };

    const isToday = (day: number) =>
        day === today.getDate() &&
        viewMonth === today.getMonth() &&
        viewYear === today.getFullYear();

    const isSelected = (day: number) =>
        day === selectedDay.getDate() &&
        viewMonth === selectedDay.getMonth() &&
        viewYear === selectedDay.getFullYear();

    return (
        <div className="flex flex-col gap-6">
            {/* Page title */}
            <div className="flex items-center gap-3">
                <Calendar className="w-6 h-6 text-[#ff5d2e]" />
                <h1 className="text-2xl font-bold text-black">Calendar</h1>
            </div>

            <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
                {/* ── Left: calendar + working hours ── */}
                <div className="xl:col-span-2 flex flex-col gap-6">

                    {/* Month navigation */}
                    <div className="bg-white rounded-2xl shadow-sm border border-black/5 p-5">
                        <div className="flex items-center justify-between mb-5">
                            <button
                                onClick={() => navigateMonth(-1)}
                                className="p-2 hover:bg-[#fff7f5] rounded-lg transition-colors"
                            >
                                <ChevronLeft className="w-5 h-5" />
                            </button>
                            <h2 className="text-lg font-bold text-black">
                                {MONTH_NAMES[viewMonth]} {viewYear}
                            </h2>
                            <button
                                onClick={() => navigateMonth(1)}
                                className="p-2 hover:bg-[#fff7f5] rounded-lg transition-colors"
                            >
                                <ChevronRight className="w-5 h-5" />
                            </button>
                        </div>

                        {/* Day-of-week header */}
                        <div className="grid grid-cols-7 mb-2">
                            {DAY_LABELS.map(d => (
                                <div key={d} className="text-center text-xs font-semibold text-black/40 py-1">{d}</div>
                            ))}
                        </div>

                        {/* Calendar cells */}
                        <div className="grid grid-cols-7 gap-1">
                            {cells.map((day, idx) => {
                                if (day === null) return <div key={idx} />;
                                const count = countForDay(viewYear, viewMonth, day);
                                return (
                                    <button
                                        key={idx}
                                        onClick={() => setSelectedDay(new Date(viewYear, viewMonth, day))}
                                        className={`relative flex flex-col items-center justify-center rounded-xl py-2 transition-all min-h-[52px] ${isSelected(day)
                                                ? 'bg-[#ff5d2e] text-white shadow-md'
                                                : isToday(day)
                                                    ? 'bg-[#ffe7df] text-[#ff5d2e] font-semibold'
                                                    : 'hover:bg-[#fff7f5] text-black'
                                            }`}
                                    >
                                        <span className="text-sm font-medium">{day}</span>
                                        {count > 0 && (
                                            <span className={`text-[10px] font-bold mt-0.5 ${isSelected(day) ? 'text-white/80' : 'text-[#ff5d2e]'
                                                }`}>
                                                {count} apt{count > 1 ? 's' : ''}
                                            </span>
                                        )}
                                    </button>
                                );
                            })}
                        </div>
                    </div>

                    {/* ── Working Hours Config ── */}
                    <div className="bg-white rounded-2xl shadow-sm border border-black/5 p-5">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-lg font-bold text-black flex items-center gap-2">
                                <Clock className="w-5 h-5 text-[#ff5d2e]" /> Working Hours
                            </h2>
                            <button
                                onClick={handleSaveSettings}
                                className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-all ${settingsSaved
                                        ? 'bg-green-100 text-green-700'
                                        : 'bg-[#ff5d2e] text-white hover:bg-[#e54d1e]'
                                    }`}
                            >
                                {settingsSaved ? (
                                    <><CheckCircle2 className="w-4 h-4" /> Saved!</>
                                ) : 'Save Settings'}
                            </button>
                        </div>

                        {/* Working days */}
                        <div className="mb-5">
                            <p className="text-sm font-semibold text-black/60 mb-3">Working Days</p>
                            <div className="flex flex-wrap gap-2">
                                {DAY_LABELS.map((label, i) => (
                                    <button
                                        key={label}
                                        onClick={() => toggleDay(i)}
                                        className={`w-12 h-12 rounded-xl text-sm font-semibold transition-all ${settings.workingDays[i]
                                                ? 'bg-[#ff5d2e] text-white shadow-sm'
                                                : 'bg-gray-100 text-gray-400 hover:bg-gray-200'
                                            }`}
                                    >
                                        {label}
                                    </button>
                                ))}
                            </div>
                        </div>

                        {/* Hours */}
                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <p className="text-sm font-semibold text-black/60 mb-2">Opening Time</p>
                                <select
                                    value={settings.startHour}
                                    onChange={(e) => setSettings(prev => ({ ...prev, startHour: Number(e.target.value) }))}
                                    className="w-full border border-black/10 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#ff5d2e]"
                                >
                                    {Array.from({ length: 13 }, (_, i) => i + 6).map(h => (
                                        <option key={h} value={h}>{formatTime(h)}</option>
                                    ))}
                                </select>
                            </div>
                            <div>
                                <p className="text-sm font-semibold text-black/60 mb-2">Closing Time</p>
                                <select
                                    value={settings.endHour}
                                    onChange={(e) => setSettings(prev => ({ ...prev, endHour: Number(e.target.value) }))}
                                    className="w-full border border-black/10 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#ff5d2e]"
                                >
                                    {Array.from({ length: 13 }, (_, i) => i + 10).map(h => (
                                        <option key={h} value={h}>{formatTime(h)}</option>
                                    ))}
                                </select>
                            </div>
                        </div>

                        <p className="mt-3 text-xs text-black/40">
                            Working hours: {formatTime(settings.startHour)} – {formatTime(settings.endHour)} on {
                                settings.workingDays
                                    .map((on, i) => on ? DAY_LABELS[i] : null)
                                    .filter(Boolean)
                                    .join(', ') || 'no days selected'
                            }
                        </p>
                    </div>
                </div>

                {/* ── Right: day appointments panel ── */}
                <div className="bg-white rounded-2xl shadow-sm border border-black/5 p-5 xl:max-h-[calc(100vh-160px)] xl:overflow-y-auto">
                    <h2 className="text-lg font-bold text-black mb-1">
                        {selectedDay.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })}
                    </h2>
                    <p className="text-sm text-black/40 mb-5">
                        {dayAppointments.length} appointment{dayAppointments.length !== 1 ? 's' : ''}
                    </p>

                    {isLoading ? (
                        <div className="flex justify-center py-8">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#ff5d2e]" />
                        </div>
                    ) : dayAppointments.length === 0 ? (
                        <div className="flex flex-col items-center justify-center py-12 text-center">
                            <XCircle className="w-10 h-10 text-black/15 mb-3" />
                            <p className="text-sm text-black/40">No appointments this day</p>
                        </div>
                    ) : (
                        <div className="flex flex-col gap-3">
                            {dayAppointments.map((apt) => {
                                const time = new Date(apt.appointmentDate).toLocaleTimeString('en-US', {
                                    hour: 'numeric', minute: '2-digit', hour12: true,
                                });
                                return (
                                    <div key={apt.id} className="p-4 bg-[#fff7f5] rounded-xl border border-[#ffe7df]">
                                        <div className="flex items-start justify-between gap-2 mb-2">
                                            <span className="text-xs font-semibold text-[#ff5d2e] flex items-center gap-1">
                                                <Clock className="w-3 h-3" /> {time}
                                            </span>
                                            <StatusBadge status={apt.status} />
                                        </div>
                                        <p className="font-semibold text-black text-sm">{apt.serviceType}</p>
                                        <p className="text-xs text-black/50 mt-0.5">{apt.userName || 'Customer'}</p>
                                        <p className="text-xs text-black/40">{apt.userEmail}</p>
                                        <p className="text-xs font-medium text-[#ff5d2e] mt-2">
                                            LKR {apt.estimatedCost.toLocaleString()}
                                        </p>
                                    </div>
                                );
                            })}
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
