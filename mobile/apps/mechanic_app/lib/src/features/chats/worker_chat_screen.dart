import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../worker/worker_providers.dart';
import 'client_job_details_sheet.dart';
import 'job_task_checklist_sheet.dart';
import 'items_used_sheet.dart';

class WorkerChatScreen extends ConsumerStatefulWidget {
  final int appointmentId;
  final ApiClient? apiClient;

  const WorkerChatScreen({
    super.key,
    required this.appointmentId,
    this.apiClient,
  });

  @override
  ConsumerState<WorkerChatScreen> createState() => _WorkerChatScreenState();
}

class _WorkerChatScreenState extends ConsumerState<WorkerChatScreen> {
  late final ApiClient _apiClient;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  Timer? _pollingTimer;
  supa.RealtimeChannel? _realtimeChannel;
  int? _repairId;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<RepairMessageModel> _messages = [];
  AppointmentModel? _linkedJob;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient();
    _loadConversationAndJob();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversationAndJob() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Try fetching linked appointment details
      final activeJobs = await ref.read(workerRepositoryProvider).getActiveAppointments();
      final pendingJobs = await ref.read(workerRepositoryProvider).getPendingAppointments();
      final allJobs = [...activeJobs, ...pendingJobs];

      final matchingJob = allJobs.cast<AppointmentModel?>().firstWhere(
            (j) => j?.id == widget.appointmentId,
            orElse: () => null,
          );

      setState(() {
        _linkedJob = matchingJob;
      });

      // Fetch conversation associated with this appointment
      try {
        final convResponse = await _apiClient.get<RepairConversationModel>(
          '/appointments/${widget.appointmentId}/conversation',
          fromJson: (data) =>
              RepairConversationModel.fromJson(data as Map<String, dynamic>),
        );

        final conversation = convResponse.data;
        if (conversation != null) {
          final repairId = conversation.repairJobId;
          setState(() => _repairId = repairId);
          await _fetchMessages(repairId, isInitialLoad: true);
          _setupRealtimeChannel(repairId, conversation.id, conversation.realtimeChannel);
          _startPolling(repairId);
          return;
        }
      } catch (convError) {
        debugPrint('REST conversation fetch failed: $convError');
      }

      // If backend REST conversation not yet initialized, use appointmentId as repairId
      _repairId = widget.appointmentId;
      await _fetchMessages(widget.appointmentId, isInitialLoad: true);
      _setupRealtimeChannel(widget.appointmentId, null, null);
      _startPolling(widget.appointmentId);
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error loading conversation: $e');
      setState(() {
        _loading = false;
        _error = 'Could not load chat. Please check your connection.';
      });
    }
  }

  void _setupRealtimeChannel(int repairId, int? conversationId, String? customChannel) {
    final supaClient = SupabaseService().safeClient;
    if (supaClient == null) return;

    try {
      final channelName = customChannel ??
          (conversationId != null
              ? 'repair-conversation:$conversationId'
              : 'repair-conversation:$repairId');

      _realtimeChannel = supaClient.channel(channelName)
        ..onPostgresChanges(
          event: supa.PostgresChangeEvent.insert,
          schema: 'public',
          table: 'repair_messages',
          filter: supa.PostgresChangeFilter(
            type: supa.PostgresChangeFilterType.eq,
            column: conversationId != null ? 'conversation_id' : 'repair_id',
            value: conversationId ?? repairId,
          ),
          callback: (payload) {
            if (mounted) {
              try {
                final incoming = RepairMessageModel.fromJson(payload.newRecord);
                if (!_messages.any((m) => m.id == incoming.id)) {
                  setState(() {
                    _messages = [..._messages, incoming];
                  });
                  _scrollToBottom();
                }
              } catch (e) {
                debugPrint('Error parsing incoming realtime message: $e');
              }
            }
          },
        )
        ..subscribe();
    } catch (e) {
      debugPrint('Supabase realtime subscription failed: $e');
    }
  }

  void _startPolling(int repairId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
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

        if (_messages.length > previousCount || isInitialLoad) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      if (mounted && isInitialLoad && _messages.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Could not load chat messages.';
        });
      }
    }
  }

  Future<void> _sendMessage([String? customText]) async {
    final body = (customText ?? _messageController.text).trim();
    final repairId = _repairId;

    if (body.isEmpty || repairId == null) return;

    setState(() => _sending = true);
    final tempMsg = RepairMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      repairId: repairId,
      senderRole: 'MECHANIC',
      body: body,
      createdAt: DateTime.now(),
    );

    // Optimistic UI update
    setState(() {
      _messages = [..._messages, tempMsg];
    });
    if (customText == null) _messageController.clear();
    _scrollToBottom();

    // Broadcast through Supabase Realtime channel
    try {
      _realtimeChannel?.sendBroadcastMessage(
        event: 'new_message',
        payload: tempMsg.toJson(),
      );
    } catch (_) {}

    try {
      await _apiClient.post<RepairMessageModel>(
        '/repairs/$repairId/messages',
        body: {'body': body},
      );
    } catch (e) {
      debugPrint('REST message send error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _captureServicePhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked == null) return;

      final file = File(picked.path);
      if (!mounted) return;

      // Show preview & caption dialog
      final caption = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final captionController = TextEditingController(text: 'Service Status Update: Photo attached');
          return AlertDialog(
            title: Text(
              'Send Service Photo',
              style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(file, height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: captionController,
                  decoration: const InputDecoration(
                    labelText: 'Caption / Status Note',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, captionController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5D2E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send Photo'),
              ),
            ],
          );
        },
      );

      if (caption != null && caption.isNotEmpty) {
        await _sendMessage('📸 [Photo Update]: $caption');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service photo sent to customer!'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking service photo: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientName = _linkedJob?.customerName ?? _linkedJob?.userId ?? 'Customer';
    final vehiclePlate = _linkedJob?.plateDisplay ?? 'Job #${widget.appointmentId}';

    return Scaffold(
      backgroundColor: const Color(0xFFEFE7DE), // WhatsApp classic chat wallpaper tint
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x1A000000),
        leadingWidth: 32,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFECE5),
              child: Text(
                clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                style: GoogleFonts.instrumentSans(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF5D2E),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Active Job • $vehiclePlate',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // "View Client Job" button as requested
          if (_linkedJob != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () => ClientJobDetailsSheet.show(context, job: _linkedJob!),
                icon: const PhosphorIcon(PhosphorIconsFill.receipt, size: 16, color: Color(0xFFFF5D2E)),
                label: Text(
                  'View Job',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF5D2E),
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF2ED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // WhatsApp Quick Actions Bar: Tasks Checklist & Used Items & Camera
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionPill(
                    icon: PhosphorIconsFill.checkSquare,
                    label: 'Task Checklist',
                    onTap: () {
                      JobTaskChecklistSheet.show(
                        context,
                        appointmentId: widget.appointmentId,
                        onTaskCompleted: (taskSummary) => _sendMessage(taskSummary),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionPill(
                    icon: PhosphorIconsFill.package,
                    label: 'Items Used',
                    onTap: () {
                      ItemsUsedSheet.show(
                        context,
                        appointmentId: widget.appointmentId,
                        onPartLogged: (partSummary) => _sendMessage(partSummary),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => _captureServicePhoto(ImageSource.camera),
                  icon: const PhosphorIcon(PhosphorIconsFill.camera, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF2ED),
                    foregroundColor: const Color(0xFFFF5D2E),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFFEE2E2),
              child: Row(
                children: [
                  const PhosphorIcon(PhosphorIconsFill.warningCircle, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.instrumentSans(fontSize: 12, color: const Color(0xFF991B1B)),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadConversationAndJob,
                    child: Text(
                      'Retry',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Messages View
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5D2E)))
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No messages yet. Send a message to begin conversation.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.instrumentSans(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildWhatsAppBubble(msg);
                        },
                      ),
          ),

          // WhatsApp Bottom Input Field
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _captureServicePhoto(ImageSource.gallery),
                    icon: const PhosphorIcon(PhosphorIconsRegular.paperclip, size: 22, color: Colors.black54),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Type message to client...',
                          hintStyle: GoogleFonts.instrumentSans(fontSize: 14, color: Colors.black45),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: GoogleFonts.instrumentSans(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFFF5D2E),
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, size: 18, color: Colors.white),
                      onPressed: _sending ? null : () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(icon, size: 15, color: const Color(0xFFFF5D2E)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppBubble(RepairMessageModel message) {
    final isMe = message.isMechanicSender;
    final timeStr = _formatTime(message.createdAt);
    final isSystemTaskOrPart = message.body.startsWith('✓') || message.body.startsWith('Used item') || message.body.startsWith('📸');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: isMe
              ? (isSystemTaskOrPart ? const Color(0xFFFFEFE9) : const Color(0xFFFFDDD2))
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  message.isAdminSender ? 'Service Advisor' : 'Customer',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ),
            Text(
              message.body,
              style: GoogleFonts.instrumentSans(
                fontSize: 14,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.instrumentSans(fontSize: 10, color: Colors.black45),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const PhosphorIcon(
                    PhosphorIconsBold.checks,
                    size: 14,
                    color: Color(0xFF2563EB), // WhatsApp blue double tick
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}
