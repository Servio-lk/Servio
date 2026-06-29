import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkerChatScreen extends StatefulWidget {
  final int appointmentId;

  const WorkerChatScreen({super.key, required this.appointmentId});

  @override
  State<WorkerChatScreen> createState() => _WorkerChatScreenState();
}

class _WorkerChatScreenState extends State<WorkerChatScreen> {
  final _client = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  RealtimeChannel? _channel;
  int? _repairId;
  int? _conversationId;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  @override
  void dispose() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final repair = await _client
          .from('repair_jobs')
          .select('id')
          .eq('appointment_id', widget.appointmentId)
          .maybeSingle();

      if (repair == null) {
        setState(() {
          _loading = false;
          _error = 'Chat will be available after this appointment becomes a repair job.';
        });
        return;
      }

      final repairId = repair['id'] as int;
      final conversation = await _client
          .from('repair_conversations')
          .select('id')
          .eq('repair_job_id', repairId)
          .maybeSingle();

      if (conversation == null) {
        setState(() {
          _repairId = repairId;
          _loading = false;
          _error = 'This repair conversation has not been opened yet.';
        });
        return;
      }

      final conversationId = conversation['id'] as int;
      final messages = await _client
          .from('repair_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      setState(() {
        _repairId = repairId;
        _conversationId = conversationId;
        _messages = List<Map<String, dynamic>>.from(messages as List);
        _loading = false;
      });

      _subscribe(conversationId);
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not load chat. Please check your connection.';
      });
    }
  }

  void _subscribe(int conversationId) {
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }

    _channel = _client
        .channel('repair-conversation:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'repair_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (mounted && row['id'] != null) {
              setState(() {
                final exists = _messages.any((message) => message['id'] == row['id']);
                if (!exists) _messages = [..._messages, row];
              });
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    final conversationId = _conversationId;
    final repairId = _repairId;
    final user = _client.auth.currentUser;

    if (body.isEmpty || conversationId == null || repairId == null || user == null) return;

    setState(() => _sending = true);
    try {
      await _client.from('repair_messages').insert({
        'conversation_id': conversationId,
        'repair_job_id': repairId,
        'sender_id': user.id,
        'sender_role': 'MECHANIC',
        'body': body,
      });
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message not sent. It will work again when you are back online and authorized.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Repair Chat',
          style: GoogleFonts.instrumentSans(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5D2E)));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PhosphorIcon(PhosphorIconsRegular.chatCircleDots, size: 48, color: Colors.black38),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSans(fontSize: 16, color: Colors.black54),
              ),
              TextButton(
                onPressed: _loadConversation,
                child: const Text('Retry', style: TextStyle(color: Color(0xFFFF5D2E))),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet.',
                    style: GoogleFonts.instrumentSans(color: Colors.black45),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
                ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0x11000000))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Message customer or admin...',
                      filled: true,
                      fillColor: const Color(0xFFF7F7F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _sendMessage,
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFFFF5D2E)),
                  icon: _sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final role = (message['sender_role'] ?? '').toString();
    final isMechanic = role == 'MECHANIC';
    final color = isMechanic ? const Color(0xFFFF5D2E) : Colors.white;
    final textColor = isMechanic ? Colors.white : Colors.black87;

    return Align(
      alignment: isMechanic ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: isMechanic ? null : Border.all(color: const Color(0x11000000)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMechanic)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  role == 'ADMIN' ? 'Admin' : 'Customer',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
              ),
            Text(
              (message['body'] ?? '').toString(),
              style: GoogleFonts.instrumentSans(fontSize: 14, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
