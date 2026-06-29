import { useState, useRef, useEffect } from 'react';
import { Bell, Check, CheckCheck, X } from 'lucide-react';
import { useNotifications } from '@/hooks/useNotifications';
import type { NotificationDto } from '@/services/api';

function timeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60_000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  return `${Math.floor(hrs / 24)}d ago`;
}

function typeColor(type: string): string {
  switch (type.toUpperCase()) {
    case 'REMINDER':    return 'bg-blue-50 text-blue-600';
    case 'APPOINTMENT': return 'bg-green-50 text-green-600';
    case 'PAYMENT':     return 'bg-purple-50 text-purple-600';
    default:            return 'bg-[#fff7f5] text-[#ff5d2e]';
  }
}

function NotificationItem({
  notification,
  onRead,
}: {
  notification: NotificationDto;
  onRead: (id: number) => void;
}) {
  return (
    <div
      className={`flex items-start gap-3 p-3 rounded-lg transition-colors ${
        notification.isRead ? 'bg-white' : 'bg-[#fff7f5]'
      }`}
    >
      {/* Type badge */}
      <div className={`mt-0.5 px-2 py-0.5 rounded text-[10px] font-semibold uppercase shrink-0 ${typeColor(notification.type)}`}>
        {notification.type}
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <p className="text-sm font-semibold text-black leading-snug">{notification.title}</p>
        <p className="text-xs text-black/60 mt-0.5 leading-snug">{notification.message}</p>
        <p className="text-[10px] text-black/40 mt-1">{timeAgo(notification.createdAt)}</p>
      </div>

      {/* Mark read button */}
      {!notification.isRead && (
        <button
          onClick={() => onRead(notification.id)}
          className="shrink-0 p-1 rounded hover:bg-black/5 transition-colors mt-0.5"
          title="Mark as read"
        >
          <Check className="w-3.5 h-3.5 text-[#ff5d2e]" />
        </button>
      )}
    </div>
  );
}

export function NotificationBell() {
  const [open, setOpen] = useState(false);
  const { notifications, unreadCount, isLoading, markAsRead, markAllAsRead } = useNotifications();
  const panelRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);

  // Close on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (
        panelRef.current && !panelRef.current.contains(e.target as Node) &&
        buttonRef.current && !buttonRef.current.contains(e.target as Node)
      ) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  return (
    <div className="relative">
      {/* Bell button */}
      <button
        ref={buttonRef}
        onClick={() => setOpen(o => !o)}
        className="relative p-2 hover:bg-[#fff7f5] rounded-lg transition-colors"
        aria-label="Notifications"
      >
        <Bell className="w-5 h-5 text-black/70" />
        {unreadCount > 0 && (
          <span className="absolute top-1 right-1 min-w-[16px] h-4 bg-[#ff5d2e] rounded-full flex items-center justify-center">
            <span className="text-[9px] font-bold text-white leading-none px-0.5">
              {unreadCount > 99 ? '99+' : unreadCount}
            </span>
          </span>
        )}
      </button>

      {/* Dropdown panel */}
      {open && (
        <div
          ref={panelRef}
          className="absolute right-0 top-full mt-2 w-80 bg-white rounded-2xl shadow-xl border border-black/5 z-50 flex flex-col overflow-hidden"
          style={{ maxHeight: '480px' }}
        >
          {/* Header */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-black/5">
            <div className="flex items-center gap-2">
              <h3 className="text-sm font-semibold text-black">Notifications</h3>
              {unreadCount > 0 && (
                <span className="bg-[#ff5d2e] text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full">
                  {unreadCount}
                </span>
              )}
            </div>
            <div className="flex items-center gap-1">
              {unreadCount > 0 && (
                <button
                  onClick={markAllAsRead}
                  className="flex items-center gap-1 text-xs text-[#ff5d2e] hover:underline font-medium px-2 py-1 rounded hover:bg-[#fff7f5] transition-colors"
                  title="Mark all as read"
                >
                  <CheckCheck className="w-3.5 h-3.5" />
                  All read
                </button>
              )}
              <button
                onClick={() => setOpen(false)}
                className="p-1 rounded hover:bg-black/5 transition-colors"
              >
                <X className="w-4 h-4 text-black/40" />
              </button>
            </div>
          </div>

          {/* List */}
          <div className="overflow-y-auto flex-1 p-2 flex flex-col gap-1">
            {isLoading ? (
              <div className="py-8 text-center text-sm text-black/40">Loading…</div>
            ) : notifications.length === 0 ? (
              <div className="py-8 text-center flex flex-col items-center gap-2">
                <Bell className="w-8 h-8 text-black/20" />
                <p className="text-sm text-black/40">No notifications yet</p>
              </div>
            ) : (
              notifications.map(n => (
                <NotificationItem key={n.id} notification={n} onRead={markAsRead} />
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}

