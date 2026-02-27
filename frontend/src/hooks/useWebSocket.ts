import { useEffect, useRef, useCallback } from 'react';
import { Client } from '@stomp/stompjs';
import type { IMessage } from '@stomp/stompjs';

// Spring SockJS endpoint also accepts native WebSocket at /ws/websocket
const BASE_URL = (import.meta.env.VITE_API_URL || 'http://localhost:3001/api')
  .replace('/api', '')
  .replace(/^http/, 'ws');
const WS_URL = `${BASE_URL}/ws/websocket`;

export interface AppointmentEvent {
  type: 'CREATED' | 'UPDATED' | 'CANCELLED' | 'DELETED';
  appointmentId: number;
  userId: number | null;
  serviceType: string;
  status: string;
  appointmentDate: string;
}

/**
 * Subscribes to one or more STOMP topics and fires `onEvent` whenever a
 * message arrives.  The connection is torn down on unmount.
 *
 * Usage:
 *   useWebSocket(['/topic/appointments/user/7'], (event) => refresh());
 */
export function useWebSocket(
  topics: string[],
  onEvent: (event: AppointmentEvent) => void,
) {
  const clientRef = useRef<Client | null>(null);
  // Keep a stable reference to the latest callback so we never need to
  // reconnect just because the callback identity changed.
  const onEventRef = useRef(onEvent);
  useEffect(() => { onEventRef.current = onEvent; }, [onEvent]);

  const connect = useCallback(() => {
    if (clientRef.current?.active) return;

    const client = new Client({
      // Native WebSocket — no SockJS needed, works directly with Vite ESM
      brokerURL: WS_URL,
      reconnectDelay: 5000,
      onConnect: () => {
        topics.forEach(topic => {
          client.subscribe(topic, (msg: IMessage) => {
            try {
              const event: AppointmentEvent = JSON.parse(msg.body);
              onEventRef.current(event);
            } catch {
              // malformed message — ignore
            }
          });
        });
      },
      onStompError: (frame) => {
        console.warn('[WS] STOMP error', frame.headers['message']);
      },
    });

    client.activate();
    clientRef.current = client;
  }, // eslint-disable-next-line react-hooks/exhaustive-deps
  [topics.join(',')]);

  useEffect(() => {
    connect();
    return () => {
      clientRef.current?.deactivate();
      clientRef.current = null;
    };
  }, [connect]);
}
