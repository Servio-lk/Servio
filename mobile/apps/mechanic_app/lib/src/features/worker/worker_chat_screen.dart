import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';

class WorkerChatScreen extends StatefulWidget {
  final int appointmentId;
  final ApiClient? apiClient;

  const WorkerChatScreen({
    super.key,
    required this.appointmentId,
    this.apiClient,
  });

  @override
  State<WorkerChatScreen> createState() => _WorkerChatScreenState();
}

class _WorkerChatScreenState extends State<WorkerChatScreen> {
  late final ApiClient _apiClient;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  Timer? _pollingTimer;
  int? _repairId;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<RepairMessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient();
    _loadConversation();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
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

      // Fetch conversation associated with this appointment
      final convResponse = await _apiClient.get<RepairConversationModel>(
        '/appointments/${widget.appointmentId}/conversation',
        fromJson: (data) =>
            RepairConversationModel.fromJson(data as Map<String, dynamic>),
      );

      final conversation = convResponse.data;
      if (conversation == null) {
        setState(() {
          _loading = false;
          _error =
              'Chat will be available after this appointment becomes an active repair job.';
        });
        return;
      }

      final repairId = conversation.repairJobId;

      setState(() {
        _repairId = repairId;
      });

      await _fetchMessages(repairId, isInitialLoad: true);
      _startPolling(repairId);
    } catch (e) {
      debugPrint('Error loading conversation: $e');
      setState(() {
        _loading = false;
        _error = 'Could not load chat. Please check your connection.';
      });
    }
  }

  void _startPolling(int repairId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_loading && !_sending) {
        _fetchMessages(repairId, isInitialLoad: false);
      }
    });
  }

  Future<void> _fetchMessages(int repairId, {bool isInitialLoad = false}) async {
    try {
      final msgResponse = await _apiClient.get<List<RepairMessageModel>>(
        '/repairs/$repairId/messages',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) =>
                    RepairMessageModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <RepairMessageModel>[];
        },
      );

      final fetched = msgResponse.data ?? <RepairMessageModel>[];

      if (mounted) {
        final previousCount = _messages.length;
        setState(() {
          _messages = fetched;
          _loading = false;
          _error = null;
        });

        if (fetched.length > previousCount || isInitialLoad) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      if (isInitialLoad && mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load chat messages.';
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    final repairId = _repairId;

    if (body.isEmpty || repairId == null) return;

    setState(() => _sending = true);
    try {
      final response = await _apiClient.post<RepairMessageModel>(
        '/repairs/$repairId/messages',
        body: {'body': body},
        fromJson: (data) =>
            RepairMessageModel.fromJson(data as Map<String, dynamic>),
      );

      _messageController.clear();
      final sent = response.data;
      if (sent != null && mounted) {
        setState(() {
          if (!_messages.any((m) => m.id == sent.id)) {
            _messages = [..._messages, sent];
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Message not sent. Please check your connection.',
            ),
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
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PhosphorIcon(
                PhosphorIconsRegular.chatCircleDots,
                size: 48,
                color: Colors.black38,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              TextButton(
                onPressed: _loadConversation,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Color(0xFFFF5D2E)),
                ),
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
                  itemBuilder: (context, index) =>
                      _MessageBubble(message: _messages[index]),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5D2E),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
  final RepairMessageModel message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMechanic = message.isMechanicSender;
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
          border:
              isMechanic ? null : Border.all(color: const Color(0x11000000)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMechanic)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  message.isAdminSender ? 'Admin' : 'Customer',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
              ),
            Text(
              message.body,
              style:
                  GoogleFonts.instrumentSans(fontSize: 14, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
