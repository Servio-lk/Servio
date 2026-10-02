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

  const userId = user?.id ?? null;

  const fetchNotifications = useCallback(async () => {
    if (!userId) return;
    setIsLoading(true);
    try {
      const res = await apiService.getMyNotifications(userId);
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
  }, [userId]);

  useEffect(() => {
    fetchNotifications();
    const interval = setInterval(fetchNotifications, 60_000);
    return () => clearInterval(interval);
  }, [fetchNotifications]);

  useEffect(() => {
    if (!userId) return;

    const channel = supabase
      .channel(`notifications:user:${userId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'notifications',
          filter: `user_id=eq.${userId}`,
        },
        (payload) => {
          const row = payload.new as Record<string, any>;
          const notification: NotificationDto = {
            id: Number(row.id),
            userId: String(row.user_id),
            userName: row.user_name || '',
            title: row.title,
            message: row.message,
            type: row.type,
            isRead: Boolean(row.is_read),
            createdAt: row.created_at,
            actionUrl: row.action_url ?? null,
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
  }, [userId]);

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
    if (!userId) return;
    try {
      await apiService.markAllNotificationsRead(userId);
      setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
      setUnreadCount(0);
    } catch {
      // silently fail
    }
  }, [userId]);

  const clearAll = useCallback(async () => {
    if (!userId) return;
    try {
      await apiService.clearNotifications(userId);
      setNotifications([]);
      setUnreadCount(0);
    } catch {
      // silently fail
    }
  }, [userId]);

  return {
    notifications,
    unreadCount,
    isLoading,
    markAsRead,
    markAllAsRead,
    clearAll,
    refresh: fetchNotifications,
  };
}