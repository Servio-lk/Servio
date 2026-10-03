import { useCallback, useEffect, useState, useRef } from 'react';
import { apiService } from '@/services/api';
import type { RepairConversationDto, RepairMessageDto } from '@/services/api';
import { supabase } from '@/lib/supabase';
import { toast } from 'sonner';
import {
  MessageCircle,
  Search,
  Loader2,
  User,
  Car,
  Send,
  AlertCircle
} from 'lucide-react';
import { useSearchParams } from 'react-router-dom';

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

export default function AdminMessages() {
  const [searchParams] = useSearchParams();
  const [conversations, setConversations] = useState<RepairConversationDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  
  const [selectedChat, setSelectedChat] = useState<RepairConversationDto | null>(null);
  const [messages, setMessages] = useState<RepairMessageDto[]>([]);
  const [loadingChat, setLoadingChat] = useState(false);
  const [body, setBody] = useState('');
  const [sending, setSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const loadConversations = useCallback(async () => {
    try {
      setLoading(true);
      const response = await apiService.getAdminConversations();
      const loadedConversations = response.data || [];
      setConversations(loadedConversations);
    } catch (error) {
      toast.error('Failed to load conversations');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadConversations();
  }, [loadConversations]);

  useEffect(() => {
    if (conversations.length > 0) {
      const targetRepairId = searchParams.get('repairId');
      if (targetRepairId) {
        const targetConv = conversations.find(c => c.repairId.toString() === targetRepairId || c.appointmentId?.toString() === targetRepairId);
        if (targetConv) {
          handleSelectConversation(targetConv);
        }
      }
    }
  }, [conversations, searchParams]);

  // Mark messages as read when selecting a conversation
  const handleSelectConversation = async (conv: RepairConversationDto) => {
    setSelectedChat(conv);
    setLoadingChat(true);
    setBody('');
    try {
      const messagesResponse = await apiService.getRepairMessages(conv.repairId);
      setMessages(messagesResponse.data || []);
      
      if (conv.unreadCount && conv.unreadCount > 0) {
        await apiService.markRepairMessagesAsRead(conv.repairId);
        // Update local state to clear unread badge
        setConversations(current => current.map(c => 
          c.id === conv.id ? { ...c, unreadCount: 0 } : c
        ));
      }
    } catch (error) {
      toast.error('Failed to load messages');
      setMessages([]);
    } finally {
      setLoadingChat(false);
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }
  };

  useEffect(() => {
    if (!selectedChat?.conversationId) return;

    const channel = supabase
      .channel(selectedChat.realtimeChannel || `repair-conversation:${selectedChat.conversationId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'repair_messages',
          filter: `conversation_id=eq.${selectedChat.conversationId}`,
        },
        (payload) => {
          const row = normalizeRealtimeMessage(payload.new);
          setMessages((current) => {
            const isDuplicate = current.some((message) => message.id === row.id);
            if (isDuplicate) return current;
            return [...current, row];
          });
          setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
        },
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [selectedChat?.conversationId, selectedChat?.realtimeChannel]);

  const sendMessage = async () => {
    if (!selectedChat || !body.trim() || sending) return;
    try {
      setSending(true);
      const response = await apiService.sendRepairMessage(selectedChat.repairId, body);
      const sentMessage = response.data;
      if (!sentMessage) throw new Error('Message not sent');
      setMessages((current) => (
        current.some((message) => message.id === sentMessage.id) ? current : [...current, sentMessage]
      ));
      setBody('');
      setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
    } catch {
      toast.error('Message not sent. Please try again.');
    } finally {
      setSending(false);
    }
  };

  const filteredConversations = conversations.filter(c => 
    c.customerName?.toLowerCase().includes(search.toLowerCase()) || 
    c.vehicleInfo?.toLowerCase().includes(search.toLowerCase()) ||
    c.appointmentId?.toString().includes(search)
  );

  return (
    <div className="flex flex-col text-left h-[calc(100vh-120px)] w-full">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Messages</h1>
        <p className="text-gray-500">Communicate with customers and mechanics.</p>
      </div>

      <div className="flex flex-1 bg-white border border-gray-200 rounded-xl overflow-hidden shadow-sm">
        {/* Left Panel: Conversation List */}
        <div className="w-1/3 min-w-[320px] max-w-[400px] border-r border-gray-200 flex flex-col bg-gray-50">
          <div className="p-4 border-b border-gray-200 bg-white">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input 
                type="text" 
                placeholder="Search customers or vehicles..." 
                value={search}
                onChange={e => setSearch(e.target.value)}
                className="w-full pl-9 pr-4 py-2 bg-gray-100 border-transparent rounded-lg text-sm focus:border-[#ff5d2e] focus:bg-white focus:ring-2 focus:ring-[#ffe7df] transition-all"
              />
            </div>
          </div>
          
          <div className="flex-1 overflow-y-auto">
            {loading ? (
              <div className="flex justify-center p-8">
                <Loader2 className="w-6 h-6 animate-spin text-[#ff5d2e]" />
              </div>
            ) : filteredConversations.length === 0 ? (
              <div className="flex flex-col items-center justify-center p-8 text-center text-gray-500">
                <MessageCircle className="w-8 h-8 mb-2 opacity-50" />
                <p>No conversations found</p>
              </div>
            ) : (
              <div className="divide-y divide-gray-100">
                {filteredConversations.map(conv => (
                  <button
                    key={conv.id}
                    onClick={() => handleSelectConversation(conv)}
                    className={`w-full text-left p-4 transition-colors hover:bg-gray-100 ${
                      selectedChat?.id === conv.id ? 'bg-[#fff7f5] border-l-4 border-[#ff5d2e]' : 'border-l-4 border-transparent'
                    }`}
                  >
                    <div className="flex justify-between items-start mb-1">
                      <span className="font-semibold text-gray-900 truncate">
                        {conv.customerName || `Appointment #${conv.appointmentId}`}
                      </span>
                      {conv.unreadCount ? (
                        <span className="bg-[#ff5d2e] text-white text-xs font-bold px-2 py-0.5 rounded-full">
                          {conv.unreadCount}
                        </span>
                      ) : null}
                    </div>
                    <div className="flex items-center text-xs text-gray-500 mb-2 gap-2">
                      <span className="flex items-center gap-1"><Car className="w-3 h-3" /> {conv.vehicleInfo}</span>
                    </div>
                    <p className="text-sm text-gray-600 truncate">
                      {conv.lastMessage || 'No messages yet'}
                    </p>
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Right Panel: Chat Window */}
        <div className="flex-1 flex flex-col bg-white">
          {selectedChat ? (
            <>
              {/* Chat Header */}
              <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between bg-white z-10">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-full bg-[#ffe7df] flex items-center justify-center text-[#ff5d2e]">
                    <User className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="font-bold text-gray-900">
                      {selectedChat.customerName || `Customer for Appointment #${selectedChat.appointmentId}`}
                    </h3>
                    <p className="text-sm text-gray-500">
                      {selectedChat.vehicleInfo}
                    </p>
                  </div>
                </div>
                {selectedChat.isReadOnly && (
                  <div className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-100 text-gray-600 rounded-lg text-sm font-medium">
                    <AlertCircle className="w-4 h-4" />
                    Read Only
                  </div>
                )}
              </div>

              {/* Chat Messages */}
              <div className="flex-1 overflow-y-auto p-6 bg-gray-50">
                {loadingChat ? (
                  <div className="flex h-full items-center justify-center">
                    <Loader2 className="w-8 h-8 animate-spin text-[#ff5d2e]" />
                  </div>
                ) : messages.length === 0 ? (
                  <div className="flex h-full items-center justify-center text-center text-gray-500">
                    <p>No messages yet. Send a message to start the conversation.</p>
                  </div>
                ) : (
                  <div className="flex flex-col gap-4">
                    {messages.map((message) => {
                      const isAdmin = message.senderRole === 'ADMIN';
                      return (
                        <div key={message.id} className={`flex ${isAdmin ? 'justify-end' : 'justify-start'}`}>
                          <div className={`max-w-[70%] rounded-2xl px-5 py-3 shadow-sm ${
                            isAdmin
                              ? 'bg-[#ff5d2e] text-white rounded-br-sm'
                              : 'bg-white text-gray-900 border border-gray-100 rounded-bl-sm'
                          }`}>
                            {!isAdmin && (
                              <p className="mb-1 text-xs font-bold text-gray-400 uppercase tracking-wider">
                                {message.senderRole}
                              </p>
                            )}
                            <p className="whitespace-pre-wrap text-sm leading-relaxed">{message.body}</p>
                          </div>
                        </div>
                      );
                    })}
                    <div ref={messagesEndRef} />
                  </div>
                )}
              </div>

              {/* Chat Input */}
              <div className="p-4 bg-white border-t border-gray-200">
                {selectedChat.isReadOnly ? (
                  <div className="text-center p-3 bg-gray-50 rounded-xl text-gray-500 text-sm">
                    This conversation is closed and read-only.
                  </div>
                ) : (
                  <div className="flex items-end gap-3">
                    <textarea
                      value={body}
                      onChange={(e) => setBody(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' && !e.shiftKey) {
                          e.preventDefault();
                          sendMessage();
                        }
                      }}
                      placeholder="Type your message..."
                      disabled={sending}
                      rows={1}
                      className="flex-1 min-h-[44px] max-h-32 resize-none rounded-xl border border-gray-300 px-4 py-2.5 text-sm focus:border-[#ff5d2e] focus:ring-1 focus:ring-[#ff5d2e] transition-all disabled:bg-gray-50 disabled:text-gray-400"
                    />
                    <button
                      onClick={sendMessage}
                      disabled={!body.trim() || sending}
                      className="h-11 w-11 flex-shrink-0 flex items-center justify-center rounded-xl bg-[#ff5d2e] text-white transition-colors hover:bg-[#e04f24] disabled:opacity-50 disabled:hover:bg-[#ff5d2e]"
                    >
                      {sending ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send className="w-5 h-5 ml-0.5" />}
                    </button>
                  </div>
                )}
              </div>
            </>
          ) : (
            <div className="flex h-full flex-col items-center justify-center text-gray-400 p-8 text-center">
              <MessageCircle className="w-16 h-16 mb-4 opacity-20" />
              <h2 className="text-xl font-semibold text-gray-600">Select a conversation</h2>
              <p className="mt-2 max-w-sm">Choose a conversation from the sidebar to view messages and respond.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
