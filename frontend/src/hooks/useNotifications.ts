import { useState, useEffect, useCallback, useRef } from 'react';
import { Client } from '@stomp/stompjs';
import type { IMessage } from '@stomp/stompjs';
import { apiService, type NotificationDto } from '@/services/api';
import { useAuth } from '@/contexts/AuthContext';

const BASE_URL = (import.meta.env.VITE_API_URL || 'http://localhost:3001/api')
  .replace('/api', '')
  .replace(/^http/, 'ws');
const WS_URL = `${BASE_URL}/ws/websocket`;

export function useNotifications() {
  const { user } = useAuth();
  const [notifications, setNotifications] = useState<NotificationDto[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const clientRef = useRef<Client | null>(null);

  // Numeric user id — only available for local (non-Supabase) users
  const numericUserId = user?.id && !isNaN(Number(user.id)) ? Number(user.id) : null;

  const fetchNotifications = useCallback(async () => {
    if (!numericUserId) return;
    setIsLoading(true);
    try {
      const res = await apiService.getMyNotifications(numericUserId);
      if (res.success && res.data) {
        setNotifications(res.data);
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

  // Real-time WebSocket subscription
  useEffect(() => {
    if (!numericUserId) return;

    const client = new Client({
      brokerURL: WS_URL,
      reconnectDelay: 5000,
      onConnect: () => {
        client.subscribe(
          `/topic/notifications/user/${numericUserId}`,
          (msg: IMessage) => {
            try {
              const notification: NotificationDto = JSON.parse(msg.body);
              setNotifications(prev => [notification, ...prev]);
              setUnreadCount(prev => prev + 1);
            } catch {
              // malformed — ignore
            }
          }
        );
      },
      onStompError: (frame) => {
        console.warn('[Notifications WS] STOMP error', frame.headers['message']);
      },
    });

    client.activate();
    clientRef.current = client;

    return () => {
      client.deactivate();
      clientRef.current = null;
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

