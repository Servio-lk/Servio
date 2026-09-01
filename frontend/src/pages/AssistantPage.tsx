import { useState, useRef, useEffect } from 'react';
import {
  Sparkle,
  PaperPlaneTilt,
  SpinnerGap,
  Car,
  Wrench,
  CalendarCheck,
  Robot,
  User as UserIcon,
  CheckCircle,
} from '@phosphor-icons/react';
import { AppLayout } from '@/components/layouts/AppLayout';
import { apiService } from '@/services/api';
import { toast } from 'sonner';

interface ChatMessage {
  id: string;
  sender: 'user' | 'assistant';
  text: string;
  tools?: string[];
  timestamp: string;
}

const QUICK_PROMPTS = [
  {
    icon: Car,
    title: 'Show My Vehicles',
    prompt: 'Can you show me all of my registered vehicles?',
  },
  {
    icon: Wrench,
    title: 'Services & Pricing',
    prompt: 'What auto services and repair packages do you offer with prices?',
  },
  {
    icon: CalendarCheck,
    title: 'Check Free Slots',
    prompt: 'What time slots are available for an appointment tomorrow?',
  },
  {
    icon: Sparkle,
    title: 'Book Oil Change',
    prompt: 'I would like to book a Full Synthetic Oil Change for next week.',
  },
];

const TOOL_LABELS: Record<string, string> = {
  get_user_vehicles: 'Fetched your vehicles',
  get_catalog_services: 'Loaded service catalog',
  get_service_details: 'Fetched service details',
  get_booked_slots: 'Checked slot availability',
  book_appointment: 'Booked service appointment',
};

export default function AssistantPage() {
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: 'welcome',
      sender: 'assistant',
      text: "Hello! I am Servio's AI Assistant. I can check your registered vehicles, explore service prices, check open workshop slots, and schedule appointments for you. How can I help you today?",
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    },
  ]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [conversationId, setConversationId] = useState<string | undefined>(undefined);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, loading]);

  const handleSend = async (textToSend?: string) => {
    const query = (textToSend || input).trim();
    if (!query || loading) return;

    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      sender: 'user',
      text: query,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages((prev) => [...prev, userMessage]);
    if (!textToSend) setInput('');
    setLoading(true);

    try {
      const response = await apiService.sendAgentMessage(query, conversationId);
      if (response.success && response.data) {
        setConversationId(response.data.conversationId);
        const assistantMessage: ChatMessage = {
          id: (Date.now() + 1).toString(),
          sender: 'assistant',
          text: response.data.message,
          tools: response.data.toolCallsExecuted,
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        };
        setMessages((prev) => [...prev, assistantMessage]);
      } else {
        toast.error(response.message || 'Failed to get agent response');
      }
    } catch (err: any) {
      toast.error(err.message || 'Error communicating with AI Assistant');
    } finally {
      setLoading(false);
    }
  };

  return (
    <AppLayout>
      <div className="flex h-[calc(100vh-140px)] min-h-[580px] flex-col overflow-hidden rounded-3xl border border-black/5 bg-white shadow-sm">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-black/5 bg-gradient-to-r from-white via-[#fff9f7] to-[#fff3ef] px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#ff5d2e] text-white shadow-md shadow-[#ff5d2e]/25">
              <Robot className="h-6 w-6" weight="fill" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-lg font-bold text-black">Servio AI Assistant</h1>
                <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-semibold text-emerald-700">
                  <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
                  Gemini Powered
                </span>
              </div>
              <p className="text-xs text-black/55">
                Vehicle lookups, service advice & automated appointment booking
              </p>
            </div>
          </div>
        </div>

        {/* Chat Messages */}
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {messages.map((msg) => {
            const isUser = msg.sender === 'user';
            return (
              <div
                key={msg.id}
                className={`flex gap-3 max-w-[85%] ${
                  isUser ? 'ml-auto flex-row-reverse' : 'mr-auto'
                }`}
              >
                <div
                  className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-xl text-xs font-semibold ${
                    isUser
                      ? 'bg-black/10 text-black'
                      : 'bg-[#ff5d2e]/15 text-[#ff5d2e]'
                  }`}
                >
                  {isUser ? <UserIcon className="h-4 w-4" /> : <Robot className="h-4 w-4" />}
                </div>

                <div className="space-y-1.5">
                  <div
                    className={`rounded-2xl px-4 py-3 text-sm leading-relaxed whitespace-pre-line shadow-xs ${
                      isUser
                        ? 'bg-[#ff5d2e] text-white rounded-tr-xs font-medium'
                        : 'bg-[#f8f9fa] text-black/90 rounded-tl-xs border border-black/5'
                    }`}
                  >
                    {msg.text}
                  </div>

                  {/* Tool execution badges */}
                  {msg.tools && msg.tools.length > 0 && (
                    <div className="flex flex-wrap gap-1.5 pt-1">
                      {msg.tools.map((tool, idx) => (
                        <span
                          key={idx}
                          className="inline-flex items-center gap-1 rounded-md bg-[#fff2ec] px-2 py-0.5 text-[11px] font-medium text-[#ff5d2e] border border-[#ff5d2e]/20"
                        >
                          <CheckCircle className="h-3 w-3" weight="bold" />
                          {TOOL_LABELS[tool] || tool}
                        </span>
                      ))}
                    </div>
                  )}

                  <p
                    className={`text-[10px] text-black/40 ${
                      isUser ? 'text-right' : 'text-left'
                    }`}
                  >
                    {msg.timestamp}
                  </p>
                </div>
              </div>
            );
          })}

          {loading && (
            <div className="flex gap-3 mr-auto max-w-[85%]">
              <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-[#ff5d2e]/15 text-[#ff5d2e]">
                <Robot className="h-4 w-4" />
              </div>
              <div className="flex items-center gap-2 rounded-2xl bg-[#f8f9fa] border border-black/5 px-4 py-3 text-sm text-black/60 rounded-tl-xs">
                <SpinnerGap className="h-4 w-4 animate-spin text-[#ff5d2e]" />
                Thinking & checking workshop data...
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>

        {/* Quick Suggestion Prompts */}
        {messages.length <= 2 && (
          <div className="border-t border-black/5 bg-[#fafafa] p-3">
            <p className="mb-2 text-xs font-medium text-black/50 px-1">Suggested questions:</p>
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
              {QUICK_PROMPTS.map((qp, i) => {
                const Icon = qp.icon;
                return (
                  <button
                    key={i}
                    onClick={() => handleSend(qp.prompt)}
                    className="flex items-center gap-2 rounded-xl border border-black/5 bg-white p-2.5 text-left text-xs font-medium text-black/80 hover:border-[#ff5d2e]/40 hover:bg-[#fff7f5] transition-colors"
                  >
                    <Icon className="h-4 w-4 text-[#ff5d2e] shrink-0" />
                    <span className="truncate">{qp.title}</span>
                  </button>
                );
              })}
            </div>
          </div>
        )}

        {/* Input Bar */}
        <div className="border-t border-black/5 p-4 bg-white">
          <form
            onSubmit={(e) => {
              e.preventDefault();
              handleSend();
            }}
            className="flex items-center gap-2"
          >
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Ask about your vehicles, service prices, or schedule an appointment..."
              disabled={loading}
              className="flex-1 rounded-2xl border border-black/10 bg-[#f8f9fa] px-4 py-3 text-sm text-black placeholder:text-black/40 focus:border-[#ff5d2e] focus:bg-white focus:outline-none transition-colors"
            />
            <button
              type="submit"
              disabled={!input.trim() || loading}
              className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#ff5d2e] text-white hover:bg-[#e04f24] disabled:opacity-40 disabled:cursor-not-allowed transition-colors shadow-sm"
              aria-label="Send message"
            >
              {loading ? (
                <SpinnerGap className="h-5 w-5 animate-spin" />
              ) : (
                <PaperPlaneTilt className="h-5 w-5" weight="bold" />
              )}
            </button>
          </form>
        </div>
      </div>
    </AppLayout>
  );
}
