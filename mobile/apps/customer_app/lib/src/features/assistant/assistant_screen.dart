import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_core/shared_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final List<String> tools;
  final String timestamp;

  _ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.tools = const [],
    required this.timestamp,
  });
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      id: 'welcome',
      isUser: false,
      text:
          "Hello! I am Servio's AI Assistant. I can look up your registered vehicles, explore maintenance services and pricing, check open workshop slots, and schedule appointments for you.",
      timestamp: 'Just now',
    ),
  ];

  bool _loading = false;
  String? _conversationId;

  final List<String> _quickPrompts = [
    'Show my registered vehicles',
    'What services do you offer?',
    'Check open slots for tomorrow',
    'Book an oil change for next week',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final query = (quickText ?? _controller.text).trim();
    if (query.isEmpty || _loading) return;

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';

    setState(() {
      _messages.add(
        _ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          isUser: true,
          text: query,
          timestamp: timeStr,
        ),
      );
      if (quickText == null) _controller.clear();
      _loading = true;
    });
    _scrollToBottom();

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      final url = Uri.parse('${ApiConfig.apiBaseUrl}/agent/chat');
      final client = HttpClient();
      final request = await client.postUrl(url);

      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=UTF-8',
      );
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      final payload = jsonEncode({
        'message': query,
        if (_conversationId != null) 'conversationId': _conversationId,
      });

      request.write(payload);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;

      if (data != null) {
        _conversationId = data['conversationId'] as String?;
        final msg = data['message'] as String? ?? 'No response received.';
        final tools = (data['toolCallsExecuted'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        setState(() {
          _messages.add(
            _ChatMessage(
              id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
              isUser: false,
              text: msg,
              tools: tools,
              timestamp: timeStr,
            ),
          );
        });
      } else {
        final errorMsg =
            json['message'] as String? ?? 'Failed to reach AI service';
        setState(() {
          _messages.add(
            _ChatMessage(
              id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
              isUser: false,
              text: 'Notice: $errorMsg',
              timestamp: timeStr,
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          _ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            isUser: false,
            text:
                'Unable to reach the Servio backend at ${ApiConfig.apiBaseUrl}. Please ensure the backend is running.',
            timestamp: timeStr,
          ),
        );
      });
    } finally {
      setState(() {
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5D2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                PhosphorIconsFill.robot,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Servio AI Assistant',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Powered by Gemini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF5D2E),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'AI Assistant is thinking...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

            // Quick suggestion chips
            if (_messages.length <= 2)
              Container(
                height: 42,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickPrompts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final prompt = _quickPrompts[index];
                    return ActionChip(
                      label: Text(
                        prompt,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFFE0D6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () => _sendMessage(prompt),
                    );
                  },
                ),
              ),

            // Input bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color.fromRGBO(0, 0, 0, 0.08),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color.fromRGBO(0, 0, 0, 0.1),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ask about vehicles, services, or booking...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.black38,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _loading ? null : () => _sendMessage(),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5D2E),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        PhosphorIconsBold.paperPlaneTilt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFFECE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                PhosphorIconsFill.robot,
                size: 16,
                color: Color(0xFFFF5D2E),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isUser ? const Color(0xFFFF5D2E) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                ),
                border: msg.isUser
                    ? null
                    : Border.all(color: const Color.fromRGBO(0, 0, 0, 0.06)),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.03),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: msg.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.4,
                      color: msg.isUser ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  if (msg.tools.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: msg.tools.map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFFFD5C6),
                            ),
                          ),
                          child: Text(
                            '✓ $t',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF5D2E),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (msg.isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
