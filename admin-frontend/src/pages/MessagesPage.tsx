import { useCallback, useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import {
  ChatCircleDots,
  Clock,
  PaperPlaneTilt,
  SpinnerGap,
  Wrench,
} from '@phosphor-icons/react';
import { AppLayout } from '@/components/layouts/AppLayout';
import { supabase } from '@/lib/supabase';
import { apiService } from '@/services/api';
import type { AppointmentDto, RepairConversationDto, RepairMessageDto } from '@/services/api';
import { toast } from 'sonner';

const chatStatuses = new Set(['CONFIRMED', 'IN_PROGRESS']);

function normalizeRealtimeMessage(row: any): RepairMessageDto {
  return {
    id: row.id,
    conversationId: row.conversationId ?? row.conversation_id,
    repairId: row.repairId ?? row.repair_job_id,
    senderId: row.senderId ?? row.sender_id,
    senderRole: row.senderRole ?? row.sender_role,
    body: row.body,
    createdAt: row.createdAt ?? row.created_at,
    readAt: row.readAt ?? row.read_at,
  };
}

export default function MessagesPage() {
  const { appointmentId } = useParams<{ appointmentId?: string }>();

  if (appointmentId) {
    return <AppointmentChat appointmentId={Number(appointmentId)} />;
  }

  return <MessagesList />;
}

function MessagesList() {
  const navigate = useNavigate();
  const [appointments, setAppointments] = useState<AppointmentDto[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        setLoading(true);
        const response = await apiService.getUserAppointments();
        const rows = (response.data || [])
          .filter((appointment) => chatStatuses.has(appointment.status))
          .sort((a, b) => new Date(b.appointmentDate).getTime() - new Date(a.appointmentDate).getTime());
        setAppointments(rows);
      } catch {
        toast.error('Could not load messages');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  return (
    <AppLayout>
      <div className="flex flex-col gap-6">
        <div>
          <h1 className="text-2xl lg:text-3xl font-semibold text-black">Messages</h1>
          <p className="mt-1 text-sm text-black/60">Chat with your service team about confirmed appointments.</p>
        </div>

        {loading ? (
          <div className="flex min-h-[320px] items-center justify-center">
            <SpinnerGap className="h-8 w-8 animate-spin text-[#ff5d2e]" />
          </div>
        ) : appointments.length === 0 ? (
          <div className="rounded-2xl border border-[#ffe7df] bg-white p-8 text-center">
            <ChatCircleDots className="mx-auto mb-3 h-12 w-12 text-black/25" />
            <h2 className="font-semibold text-black">No active chats yet</h2>
            <p className="mt-1 text-sm text-black/60">
              Messages appear here once your appointment is confirmed and a mechanic is assigned.
            </p>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {appointments.map((appointment) => (
              <button
                key={appointment.id}
                onClick={() => navigate(`/messages/${appointment.id}`)}
                className="flex items-center gap-4 rounded-2xl border border-black/5 bg-white p-4 text-left shadow-sm transition-colors hover:bg-[#fff7f5]"
              >
                <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-[#ffe7df] text-[#ff5d2e]">
                  <Wrench className="h-6 w-6" weight="duotone" />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="truncate font-semibold text-black">{appointment.serviceType}</p>
                  <p className="mt-1 flex items-center gap-1 text-sm text-black/55">
                    <Clock className="h-4 w-4" />
                    {new Date(appointment.appointmentDate).toLocaleString('en-US', {
                      month: 'short',
                      day: 'numeric',
                      hour: 'numeric',
                      minute: '2-digit',
                    })}
                  </p>
                </div>
                <span className="rounded-full bg-green-50 px-2.5 py-1 text-xs font-semibold text-green-700">
                  {appointment.status.replace(/_/g, ' ')}
                </span>
              </button>
            ))}
          </div>
        )}
      </div>
    </AppLayout>
  );
}

function AppointmentChat({ appointmentId }: { appointmentId: number }) {
  const [conversation, setConversation] = useState<RepairConversationDto | null>(null);
  const [messages, setMessages] = useState<RepairMessageDto[]>([]);
  const [body, setBody] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);

  const loadChat = useCallback(async () => {
    try {
      setLoading(true);
      const conversationResponse = await apiService.getAppointmentConversation(appointmentId);
      const nextConversation = conversationResponse.data;
      if (!nextConversation) throw new Error('Chat is not available yet');
      setConversation(nextConversation);

      const messagesResponse = await apiService.getRepairMessages(nextConversation.repairId);
      setMessages(messagesResponse.data || []);
    } catch (error: any) {
      toast.error(error.message || 'Chat is not available yet');
      setConversation(null);
      setMessages([]);
    } finally {
      setLoading(false);
    }
  }, [appointmentId]);

  useEffect(() => {
    loadChat();
  }, [loadChat]);

  useEffect(() => {
    if (!conversation?.conversationId) return;

    const channel = supabase
      .channel(conversation.realtimeChannel || `repair-conversation:${conversation.conversationId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'repair_messages',
          filter: `conversation_id=eq.${conversation.conversationId}`,
        },
        (payload) => {
          const row = normalizeRealtimeMessage(payload.new);
          setMessages((current) => (
            current.some((message) => message.id === row.id) ? current : [...current, row]
          ));
        },
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [conversation]);

  const sendMessage = async () => {
    if (!conversation || !body.trim()) return;
    try {
      setSending(true);
      const response = await apiService.sendRepairMessage(conversation.repairId, body);
      const sentMessage = response.data;
      if (!sentMessage) throw new Error('Message not sent');
      setMessages((current) => (
        current.some((message) => message.id === sentMessage.id) ? current : [...current, sentMessage]
      ));
      setBody('');
    } catch {
      toast.error('Message not sent. Please try again.');
    } finally {
      setSending(false);
    }
  };

  return (
    <AppLayout>
      <div className="flex h-[calc(100vh-150px)] min-h-[520px] flex-col overflow-hidden rounded-2xl border border-black/5 bg-white shadow-sm">
        <div className="border-b border-black/5 p-4">
          <Link to="/messages" className="text-sm font-medium text-[#ff5d2e] hover:underline">
            Back to messages
          </Link>
          <div className="mt-2 flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#ffe7df] text-[#ff5d2e]">
              <ChatCircleDots className="h-6 w-6" weight="duotone" />
            </div>
            <div>
              <h1 className="font-semibold text-black">Service team chat</h1>
              <p className="text-sm text-black/55">Appointment #{appointmentId}</p>
            </div>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto bg-[#fffaf8] p-4">
          {loading ? (
            <div className="flex h-full items-center justify-center">
              <SpinnerGap className="h-8 w-8 animate-spin text-[#ff5d2e]" />
            </div>
          ) : !conversation ? (
            <div className="flex h-full items-center justify-center text-center">
              <div>
                <ChatCircleDots className="mx-auto mb-3 h-12 w-12 text-black/25" />
                <p className="font-semibold text-black">Chat is not ready yet</p>
                <p className="mt-1 max-w-sm text-sm text-black/60">
                  Your service team will be available here after an admin assigns a mechanic.
                </p>
              </div>
            </div>
          ) : messages.length === 0 ? (
            <div className="flex h-full items-center justify-center text-center">
              <p className="text-sm text-black/50">No messages yet. Send the first update.</p>
            </div>
          ) : (
            <div className="flex flex-col gap-3">
              {messages.map((message) => {
                const isCustomer = message.senderRole === 'CLIENT';
                return (
                  <div key={message.id} className={`flex ${isCustomer ? 'justify-end' : 'justify-start'}`}>
                    <div className={`max-w-[78%] rounded-2xl px-4 py-3 ${
                      isCustomer
                        ? 'bg-[#ff5d2e] text-white'
                        : 'border border-black/5 bg-white text-black'
                    }`}>
                      {!isCustomer && (
                        <p className="mb-1 text-xs font-semibold text-black/45">
                          {message.senderRole === 'ADMIN' ? 'Admin' : 'Mechanic'}
                        </p>
                      )}
                      <p className="whitespace-pre-wrap text-sm leading-relaxed">{message.body}</p>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        <div className="border-t border-black/5 bg-white p-3">
          <div className="flex items-end gap-2">
            <textarea
              value={body}
              onChange={(event) => setBody(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === 'Enter' && !event.shiftKey) {
                  event.preventDefault();
                  sendMessage();
                }
              }}
              rows={1}
              placeholder="Message your service team..."
              disabled={!conversation || sending}
              className="max-h-28 flex-1 resize-none rounded-xl border border-black/10 bg-white px-3 py-2 text-sm focus:border-[#ff5d2e] focus:outline-none disabled:bg-black/5"
            />
            <button
              onClick={sendMessage}
              disabled={!conversation || !body.trim() || sending}
              className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#ff5d2e] text-white transition-colors hover:bg-[#e54d1e] disabled:opacity-50"
              aria-label="Send message"
            >
              {sending ? <SpinnerGap className="h-5 w-5 animate-spin" /> : <PaperPlaneTilt className="h-5 w-5" weight="fill" />}
            </button>
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
