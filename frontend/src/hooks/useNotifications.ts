import { useState, useEffect, useCallback, useRef } from 'react';
import { apiService, type NotificationDto } from '@/services/api';
import { useAuth } from '@/contexts/AuthContext';
import { supabase } from '@/lib/supabase';

export function useNotifications() {
  const { user } = useAuth();
  const [notifications, setNotifications] = useState<NotificationDto[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const seenIdsRef = useRef<Set<number>>(new Set());

  // Numeric user id — only available for local (non-Supabase) users
  const numericUserId = user?.id && !isNaN(Number(user.id)) ? Number(user.id) : null;

  const fetchNotifications = useCallback(async () => {
    if (!numericUserId) return;
    setIsLoading(true);
    try {
      const res = await apiService.getMyNotifications(numericUserId);
      if (res.success && res.data) {
        setNotifications(res.data);
        seenIdsRef.current = new Set(res.data.map(n => n.id));
        setUnreadCount(res.data.filter(n => !n.isRead).length);
      }
    } catch {
      // silently fail
    } finally {
      setIsLoading(false);
    }
  }, [numericUserId]);

  // Poll REST on mount + every 60 seconds
  useEffect(() => {
    fetchNotifications();
    const interval = setInterval(fetchNotifications, 60_000);
    return () => clearInterval(interval);
  }, [fetchNotifications]);

  // Supabase Realtime subscription. The REST fetch above remains the source of
  // truth for history and as a fallback when realtime briefly disconnects.
  useEffect(() => {
    if (!numericUserId) return;

    const channel = supabase
      .channel(`notifications:user:${numericUserId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'notifications',
          filter: `user_id=eq.${numericUserId}`,
        },
        (payload) => {
          const row = payload.new as Record<string, any>;
          const notification: NotificationDto = {
            id: Number(row.id),
            userId: Number(row.user_id),
            userName: row.user_name || '',
            title: row.title,
            message: row.message,
            type: row.type,
            isRead: Boolean(row.is_read),
            createdAt: row.created_at,
          };

          if (seenIdsRef.current.has(notification.id)) {
            return;
          }

          seenIdsRef.current.add(notification.id);
          setNotifications(prev => [notification, ...prev]);
          if (!notification.isRead) {
            setUnreadCount(prev => prev + 1);
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [numericUserId]);

  const markAsRead = useCallback(async (id: number) => {
    try {
      await apiService.markNotificationRead(id);
      setNotifications(prev =>
        prev.map(n => n.id === id ? { ...n, isRead: true } : n)
      );
      setUnreadCount(prev => Math.max(0, prev - 1));
    } catch {
      // silently fail
    }
  }, []);

  const markAllAsRead = useCallback(async () => {
    if (!numericUserId) return;
    try {
      await apiService.markAllNotificationsRead(numericUserId);
      setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
      setUnreadCount(0);
    } catch {
      // silently fail
    }
  }, [numericUserId]);

  return { notifications, unreadCount, isLoading, markAsRead, markAllAsRead, refresh: fetchNotifications };
}
