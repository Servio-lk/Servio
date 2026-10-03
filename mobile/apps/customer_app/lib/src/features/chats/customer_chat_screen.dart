import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class CustomerChatScreen extends ConsumerStatefulWidget {
  final AppointmentModel appointment;
  final ApiClient? apiClient;

  const CustomerChatScreen({
    super.key,
    required this.appointment,
    this.apiClient,
  });

  @override
  ConsumerState<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends ConsumerState<CustomerChatScreen> {
  late final ApiClient _apiClient;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  Timer? _pollingTimer;
  supa.RealtimeChannel? _realtimeChannel;
  int? _repairId;
  int? _conversationId;
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
    _realtimeChannel?.unsubscribe();
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

      int? resolvedRepairId;
      int? resolvedConvId;
      String? resolvedChannel;

      // 1. Try REST appointment conversation endpoint
      try {
        final convResponse = await _apiClient.get<RepairConversationModel>(
          '/appointments/${widget.appointment.id}/conversation',
          fromJson: (data) =>
              RepairConversationModel.fromJson(data as Map<String, dynamic>),
        );

        final conversation = convResponse.data;
        if (conversation != null) {
          resolvedRepairId = conversation.repairJobId;
          resolvedConvId = conversation.id;
          resolvedChannel = conversation.realtimeChannel;
        }
      } catch (convError) {
        debugPrint('REST conversation fetch: $convError');
      }

      // 2. Direct Supabase lookup fallback if REST endpoint didn't provide conversation
      if (resolvedRepairId == null) {
        final supaClient = SupabaseService().safeClient;
        if (supaClient != null) {
          try {
            final jobRows = await supaClient
                .from('repair_jobs')
                .select('id')
                .eq('appointment_id', widget.appointment.id)
                .limit(1);

            if (jobRows.isNotEmpty) {
              resolvedRepairId = (jobRows.first['id'] as num?)?.toInt();
            } else {
              final newJob = await supaClient.from('repair_jobs').insert({
                'appointment_id': widget.appointment.id,
                'title': widget.appointment.serviceType,
                'status': widget.appointment.status.toUpperCase() == 'IN_PROGRESS'
                    ? 'IN_PROGRESS'
                    : 'PENDING',
              }).select('id').maybeSingle();
              if (newJob != null) {
                resolvedRepairId = (newJob['id'] as num?)?.toInt();
              }
            }

            if (resolvedRepairId != null) {
              final convRows = await supaClient
                  .from('repair_conversations')
                  .select('id')
                  .eq('repair_job_id', resolvedRepairId)
                  .limit(1);

              if (convRows.isNotEmpty) {
                resolvedConvId = (convRows.first['id'] as num?)?.toInt();
              } else {
                final newConv = await supaClient.from('repair_conversations').insert({
                  'repair_job_id': resolvedRepairId,
                  'is_read_only': false,
                }).select('id').maybeSingle();
                if (newConv != null) {
                  resolvedConvId = (newConv['id'] as num?)?.toInt();
                }
              }

              final currentUser = supaClient.auth.currentUser;
              if (currentUser != null && resolvedConvId != null) {
                final memberRef = 'user:${currentUser.id}';
                await supaClient.from('repair_conversation_members').upsert({
                  'conversation_id': resolvedConvId,
                  'role': 'CUSTOMER',
                  'member_ref': memberRef,
                  'member_user_id': currentUser.id,
                  'can_write': true,
                }, onConflict: 'conversation_id,role,member_ref');
              }
            }
          } catch (supaErr) {
            debugPrint('Supabase direct conversation lookup fallback: $supaErr');
          }
        }
      }

      final activeRepairId = resolvedRepairId ?? widget.appointment.id;
      _repairId = activeRepairId;
      _conversationId = resolvedConvId;

      await _fetchMessages(activeRepairId, isInitialLoad: true);
      _setupRealtimeChannel(activeRepairId, resolvedConvId, resolvedChannel);
      _startPolling(activeRepairId);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error loading customer conversation: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load chat. Please check your connection.';
        });
      }
    }
  }

  void _setMessages(List<RepairMessageModel> incoming) {
    final map = <int, RepairMessageModel>{};
    for (final m in incoming) {
      map[m.id] = m;
    }
    final list = map.values.toList();
    list.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
    _messages = list;
  }

  void _upsertMessage(RepairMessageModel incoming) {
    final existingIndex = _messages.indexWhere((m) =>
        m.id == incoming.id ||
        (m.id > 1000000000000 &&
            m.body == incoming.body &&
            m.senderRole == incoming.senderRole &&
            m.createdAt.difference(incoming.createdAt).abs().inSeconds < 10));

    if (existingIndex >= 0) {
      _messages[existingIndex] = incoming;
    } else {
      _messages.add(incoming);
    }
    _messages.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
  }

  Future<void> _markIncomingAsRead(int repairId, int? conversationId) async {
    final supaClient = SupabaseService().safeClient;
    if (supaClient == null) return;
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      if (conversationId != null) {
        await supaClient
            .from('repair_messages')
            .update({'read_at': nowUtc})
            .eq('conversation_id', conversationId)
            .eq('sender_role', 'MECHANIC')
            .isFilter('read_at', null);
      } else {
        await supaClient
            .from('repair_messages')
            .update({'read_at': nowUtc})
            .eq('repair_job_id', repairId)
            .eq('sender_role', 'MECHANIC')
            .isFilter('read_at', null);
      }
    } catch (_) {}
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
          event: supa.PostgresChangeEvent.all,
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
                setState(() {
                  _upsertMessage(incoming);
                });
                _scrollToBottom();
                if (incoming.isMechanic) {
                  _markIncomingAsRead(repairId, conversationId);
                }
              } catch (e) {
                debugPrint('Error parsing realtime message: $e');
              }
            }
          },
        )
        ..subscribe();
    } catch (e) {
      debugPrint('Realtime subscription error: $e');
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
      List<RepairMessageModel>? messages;

      // Level 1: REST /repairs/$repairId/messages
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
        if (msgResponse.data != null) {
          messages = msgResponse.data;
        }
      } catch (_) {}

      // Level 2: REST /appointments/${widget.appointment.id}/messages
      if (messages == null) {
        try {
          final msgResponse = await _apiClient.get<List<RepairMessageModel>>(
            '/appointments/${widget.appointment.id}/messages',
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
          if (msgResponse.data != null) {
            messages = msgResponse.data;
          }
        } catch (_) {}
      }

      // Level 3: Direct Supabase query
      if (messages == null) {
        final supaClient = SupabaseService().safeClient;
        if (supaClient != null) {
          try {
            dynamic raw;
            if (_conversationId != null) {
              raw = await supaClient
                  .from('repair_messages')
                  .select()
                  .or('conversation_id.eq.$_conversationId,repair_job_id.eq.$repairId')
                  .order('created_at', ascending: true);
            } else {
              raw = await supaClient
                  .from('repair_messages')
                  .select()
                  .eq('repair_job_id', repairId)
                  .order('created_at', ascending: true);
            }
            if (raw is List) {
              messages = raw
                  .map((e) =>
                      RepairMessageModel.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          } catch (supaErr) {
            debugPrint('Direct Supabase message fetch: $supaErr');
          }
        }
      }

      if (messages != null && mounted) {
        final previousCount = _messages.length;
        setState(() {
          _setMessages(messages!);
          _loading = false;
          _error = null;
        });

        if (_messages.length > previousCount || isInitialLoad) {
          _scrollToBottom();
        }
      }
      _markIncomingAsRead(repairId, _conversationId);
    } catch (e) {
      debugPrint('Error fetching customer messages: $e');
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
      senderRole: 'CUSTOMER',
      body: body,
      createdAt: DateTime.now(),
      readAt: null,
    );

    setState(() {
      _upsertMessage(tempMsg);
    });
    if (customText == null) _messageController.clear();
    _scrollToBottom();

    // Broadcast through Realtime
    try {
      _realtimeChannel?.sendBroadcastMessage(
        event: 'new_message',
        payload: tempMsg.toJson(),
      );
    } catch (_) {}

    bool sent = false;

    // 1. Try REST /appointments/${widget.appointment.id}/messages
    try {
      await _apiClient.post<RepairMessageModel>(
        '/appointments/${widget.appointment.id}/messages',
        body: {'body': body, 'senderRole': 'CUSTOMER'},
      );
      sent = true;
    } catch (_) {}

    // 2. Try REST /repairs/$repairId/messages
    if (!sent) {
      try {
        await _apiClient.post<RepairMessageModel>(
          '/repairs/$repairId/messages',
          body: {'body': body, 'senderRole': 'CUSTOMER'},
        );
        sent = true;
      } catch (_) {}
    }

    // 3. Fallback to Supabase direct insert
    if (!sent) {
      final supaClient = SupabaseService().safeClient;
      if (supaClient != null) {
        try {
          final currentUser = supaClient.auth.currentUser;
          final senderId = currentUser?.id ?? 'customer';

          int? convId = _conversationId;
          if (convId == null) {
            final convRow = await supaClient
                .from('repair_conversations')
                .select('id')
                .eq('repair_job_id', repairId)
                .maybeSingle();
            if (convRow != null) {
              convId = (convRow['id'] as num?)?.toInt();
              _conversationId = convId;
            }
          }

          if (convId != null) {
            await supaClient.from('repair_messages').insert({
              'conversation_id': convId,
              'repair_job_id': repairId,
              'sender_id': senderId,
              'sender_role': 'CUSTOMER',
              'body': body,
              'read_at': null,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            });
            sent = true;
          }
        } catch (e) {
          debugPrint('Direct Supabase message insert: $e');
        }
      }
    }

    if (mounted) setState(() => _sending = false);
  }

  Future<void> _capturePhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked == null) return;

      final file = File(picked.path);
      final filename =
          'chat_${widget.appointment.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final supaClient = SupabaseService().safeClient;
      if (supaClient != null) {
        try {
          await supaClient.storage
              .from('repair_attachments')
              .upload('photos/$filename', file);

          final publicUrl = supaClient.storage
              .from('repair_attachments')
              .getPublicUrl('photos/$filename');

          await _sendMessage('Photo: $publicUrl');
          return;
        } catch (_) {}
      }

      await _sendMessage('[Photo: ${picked.name}]');
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mechanicName = widget.appointment.assignedMechanicName ?? 'Servio Workshop Advisor';
    final serviceType = widget.appointment.serviceType;
    final vehiclePlate = widget.appointment.plateDisplay;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leadingWidth: 40,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsBold.arrowLeft, size: 22, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: ServiceIconHelper.getServiceColors(serviceType).background,
              child: Icon(
                ServiceIconHelper.getPhosphorIcon(serviceType),
                size: 20,
                color: ServiceIconHelper.getServiceColors(serviceType).primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mechanicName,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$serviceType • $vehiclePlate',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Service Info Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7F5),
              border: Border(
                bottom: BorderSide(color: Color(0xFFFFE7DF), width: 1),
              ),
            ),
            child: Row(
              children: [
                const PhosphorIcon(
                  PhosphorIconsFill.wrench,
                  size: 18,
                  color: Color(0xFFFF5D2E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.appointment.vehicleDisplay} (${widget.appointment.plateDisplay})',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Date: ${widget.appointment.formattedDate} · ${widget.appointment.formattedTime}',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE7DF)),
                  ),
                  child: Text(
                    widget.appointment.statusLabel,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF5D2E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error banner if any
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
                    onPressed: _loadConversation,
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE7DF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: PhosphorIcon(
                                    PhosphorIconsFill.chatCircleDots,
                                    size: 28,
                                    color: Color(0xFFFF5D2E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Start the conversation',
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ask questions or check progress with your service technician.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  _quickPromptChip('How is the progress?'),
                                  _quickPromptChip('When will it be ready?'),
                                  _quickPromptChip('Please check the brakes too'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessageBubble(msg);
                        },
                      ),
          ),

          // Bottom Input Field
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _capturePhoto(ImageSource.gallery),
                    icon: const PhosphorIcon(PhosphorIconsRegular.paperclip, size: 22, color: Colors.black54),
                  ),
                  IconButton(
                    onPressed: () => _capturePhoto(ImageSource.camera),
                    icon: const PhosphorIcon(PhosphorIconsRegular.camera, size: 22, color: Colors.black54),
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
                          hintText: 'Message technician...',
                          hintStyle: GoogleFonts.instrumentSans(fontSize: 14, color: Colors.black45),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: GoogleFonts.instrumentSans(fontSize: 14),
                        onSubmitted: (_) => _sendMessage(),
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

  Widget _quickPromptChip(String prompt) {
    return ActionChip(
      label: Text(
        prompt,
        style: GoogleFonts.instrumentSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFFF5D2E),
        ),
      ),
      backgroundColor: const Color(0xFFFFF0EC),
      side: const BorderSide(color: Color(0xFFFFE0D6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () => _sendMessage(prompt),
    );
  }

  Widget _buildMessageBubble(RepairMessageModel message) {
    final isCustomer = message.isCustomer;
    final timeStr = _formatMessageTime(message.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCustomer ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCustomer) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFFFE7DF),
              child: const Icon(
                PhosphorIconsFill.wrench,
                size: 14,
                color: Color(0xFFFF5D2E),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.76,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCustomer ? const Color(0xFFFF5D2E) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCustomer ? 16 : 4),
                  bottomRight: Radius.circular(isCustomer ? 4 : 16),
                ),
                border: isCustomer
                    ? null
                    : Border.all(color: const Color(0xFFE5E5E5), width: 0.8),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.04),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isCustomer) ...[
                    Text(
                      'Technician',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF5D2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message.body,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 14,
                      height: 1.35,
                      color: isCustomer ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 10,
                          color: isCustomer ? Colors.white70 : Colors.black38,
                        ),
                      ),
                      if (isCustomer) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 13,
                          color: message.isRead ? Colors.lightBlueAccent : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }
}
