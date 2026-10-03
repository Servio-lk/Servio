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
  int? _conversationId;
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

      int? resolvedRepairId;
      int? resolvedConvId;
      String? resolvedChannel;

      // 1. Try REST appointment conversation endpoint
      try {
        final convResponse = await _apiClient.get<RepairConversationModel>(
          '/appointments/${widget.appointmentId}/conversation',
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
        debugPrint('REST conversation fetch failed: $convError');
      }

      // 2. Direct Supabase fallback if REST didn't provide conversation
      if (resolvedRepairId == null) {
        final supaClient = SupabaseService().safeClient;
        if (supaClient != null) {
          try {
            final jobRows = await supaClient
                .from('repair_jobs')
                .select('id')
                .eq('appointment_id', widget.appointmentId)
                .limit(1);

            if (jobRows.isNotEmpty) {
              resolvedRepairId = (jobRows.first['id'] as num?)?.toInt();
            } else {
              final newJob = await supaClient.from('repair_jobs').insert({
                'appointment_id': widget.appointmentId,
                'title': matchingJob?.serviceType ?? 'Vehicle Service',
                'status': 'IN_PROGRESS',
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
                  'role': 'MECHANIC',
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

      final activeRepairId = resolvedRepairId ?? widget.appointmentId;
      _repairId = activeRepairId;
      _conversationId = resolvedConvId;

      await _fetchMessages(activeRepairId, isInitialLoad: true);
      _setupRealtimeChannel(activeRepairId, resolvedConvId, resolvedChannel);
      _startPolling(activeRepairId);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error loading conversation: $e');
      setState(() {
        _loading = false;
        _error = 'Could not load chat. Please check your connection.';
      });
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
            .neq('sender_role', 'MECHANIC')
            .isFilter('read_at', null);
      } else {
        await supaClient
            .from('repair_messages')
            .update({'read_at': nowUtc})
            .eq('repair_job_id', repairId)
            .neq('sender_role', 'MECHANIC')
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
                if (!incoming.isMechanic) {
                  _markIncomingAsRead(repairId, conversationId);
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
      List<RepairMessageModel>? messages;

      // Level 1: Try REST /repairs/$repairId/messages
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
      } catch (_) {
        // Fallback to Level 2
      }

      // Level 2: Try REST /appointments/${widget.appointmentId}/messages
      if (messages == null) {
        try {
          final msgResponse = await _apiClient.get<List<RepairMessageModel>>(
            '/appointments/${widget.appointmentId}/messages',
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
        } catch (_) {
          // Fallback to Level 3
        }
      }

      // Level 3: Direct Supabase Database Fallback
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
            debugPrint('Direct Supabase message fetch fallback: $supaErr');
          }
        }
      }

      if (messages == null) {
        throw Exception('All message fetch sources failed');
      }

      final fetched = messages;

      if (mounted) {
        final previousCount = _messages.length;
        setState(() {
          _setMessages(fetched);
          _loading = false;
          _error = null;
        });

        if (_messages.length > previousCount || isInitialLoad) {
          _scrollToBottom();
        }
      }
      _markIncomingAsRead(repairId, _conversationId);
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
      readAt: null,
    );

    // Optimistic UI update with sorting
    setState(() {
      _upsertMessage(tempMsg);
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

    bool sent = false;

    // Level 1: Try REST /repairs/$repairId/messages
    try {
      await _apiClient.post<RepairMessageModel>(
        '/repairs/$repairId/messages',
        body: {'body': body},
      );
      sent = true;
    } catch (e) {
      // Try Level 2
    }

    // Level 2: Try REST /appointments/${widget.appointmentId}/messages
    if (!sent) {
      try {
        await _apiClient.post<RepairMessageModel>(
          '/appointments/${widget.appointmentId}/messages',
          body: {'body': body},
        );
        sent = true;
      } catch (e2) {
        // Try Level 3
      }
    }

    // Level 3: Direct Supabase Database Fallback
    if (!sent) {
      final supaClient = SupabaseService().safeClient;
      if (supaClient != null) {
        try {
          final currentUser = supaClient.auth.currentUser;
          final senderId = currentUser?.id ?? 'mechanic';

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
              'sender_role': 'MECHANIC',
              'body': body,
              'read_at': null,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            });
            sent = true;
          }
        } catch (supaErr) {
          debugPrint('Direct Supabase message insert fallback: $supaErr');
        }
      }
    }

    if (mounted) setState(() => _sending = false);
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
              backgroundColor: ServiceIconHelper.getServiceColors(_linkedJob?.serviceType).background,
              child: Text(
                clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                style: GoogleFonts.instrumentSans(
                  fontWeight: FontWeight.w700,
                  color: ServiceIconHelper.getServiceColors(_linkedJob?.serviceType).primary,
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

          // Persistent Client & Service Details Banner
          if (_linkedJob != null)
            InkWell(
              onTap: () => ClientJobDetailsSheet.show(context, job: _linkedJob!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ServiceIconHelper.getServiceColors(_linkedJob!.serviceType).background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        ServiceIconHelper.getPhosphorIcon(_linkedJob!.serviceType),
                        size: 16,
                        color: ServiceIconHelper.getServiceColors(_linkedJob!.serviceType).primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _linkedJob!.serviceType,
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: _linkedJob!.status.toUpperCase() == 'IN_PROGRESS'
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _linkedJob!.status.replaceAll('_', ' '),
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _linkedJob!.status.toUpperCase() == 'IN_PROGRESS'
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_linkedJob!.vehicleDisplay} • ${_linkedJob!.plateDisplay} • ${_linkedJob!.formattedDate}',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const PhosphorIcon(PhosphorIconsRegular.caretRight, size: 14, color: Colors.black38),
                  ],
                ),
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
                  _buildMessageStatusIcon(message),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(RepairMessageModel message) {
    // If optimistic temporary message (id > 1000000000000) or still sending:
    final isOptimistic = message.id > 1000000000000;
    if (isOptimistic) {
      return const PhosphorIcon(
        PhosphorIconsRegular.clock,
        size: 13,
        color: Colors.black38,
      );
    }

    if (message.readAt != null) {
      // Customer has read the message: double blue ticks
      return const PhosphorIcon(
        PhosphorIconsBold.checks,
        size: 14,
        color: Color(0xFF34B7F1), // WhatsApp blue double tick
      );
    }

    // Delivered / sent, but not yet read: grey double ticks
    return const PhosphorIcon(
      PhosphorIconsBold.checks,
      size: 14,
      color: Colors.black38, // WhatsApp grey double tick
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final m = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}
