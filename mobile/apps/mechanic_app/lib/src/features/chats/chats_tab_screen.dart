import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';
import '../worker/worker_providers.dart';
import '../../shared/empty_state.dart';
import '../../shared/error_state.dart';

class _ClientChatThread {
  final String clientId;
  final String clientName;
  final AppointmentModel primaryJob;
  final List<AppointmentModel> allJobs;

  const _ClientChatThread({
    required this.clientId,
    required this.clientName,
    required this.primaryJob,
    required this.allJobs,
  });
}

class ChatsTabScreen extends ConsumerStatefulWidget {
  const ChatsTabScreen({super.key});

  @override
  ConsumerState<ChatsTabScreen> createState() => _ChatsTabScreenState();
}

class _ChatsTabScreenState extends ConsumerState<ChatsTabScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeJobsAsync = ref.watch(activeAppointmentsProvider);
    final pendingJobsAsync = ref.watch(pendingAppointmentsProvider);

    final activeJobs = activeJobsAsync.asData?.value ?? [];
    final pendingJobs = pendingJobsAsync.asData?.value ?? [];
    final allJobs = [...activeJobs, ...pendingJobs];

    final hasError = activeJobsAsync.hasError && pendingJobsAsync.hasError && allJobs.isEmpty;
    final isLoading = (activeJobsAsync.isLoading || pendingJobsAsync.isLoading) && allJobs.isEmpty;

    // Group appointments by client: One unified chat thread per client showing service details
    final clientThreadsMap = <String, _ClientChatThread>{};
    for (final job in allJobs) {
      final key = (job.userId != null && job.userId!.isNotEmpty)
          ? job.userId!
          : (job.customerName != null && job.customerName!.isNotEmpty)
              ? job.customerName!.toLowerCase().trim()
              : 'job_${job.id}';

      final clientName = job.customerName ?? job.userId ?? 'Customer';

      if (!clientThreadsMap.containsKey(key)) {
        clientThreadsMap[key] = _ClientChatThread(
          clientId: key,
          clientName: clientName,
          primaryJob: job,
          allJobs: [job],
        );
      } else {
        final existing = clientThreadsMap[key]!;
        final updatedJobs = [...existing.allJobs, job];
        // Sort priority: IN_PROGRESS (0) > CONFIRMED (1) > PENDING (2) > others (3)
        updatedJobs.sort((a, b) {
          int priority(AppointmentModel m) {
            final s = m.status.toUpperCase();
            if (s == 'IN_PROGRESS') return 0;
            if (s == 'CONFIRMED') return 1;
            if (s == 'PENDING') return 2;
            return 3;
          }
          final cmp = priority(a).compareTo(priority(b));
          if (cmp != 0) return cmp;
          return b.appointmentDate.compareTo(a.appointmentDate);
        });

        clientThreadsMap[key] = _ClientChatThread(
          clientId: key,
          clientName: (existing.clientName == 'Customer' || existing.clientName.isEmpty)
              ? clientName
              : existing.clientName,
          primaryJob: updatedJobs.first,
          allJobs: updatedJobs,
        );
      }
    }

    final q = _searchQuery.toLowerCase();
    final filteredThreads = clientThreadsMap.values.where((thread) {
      if (q.isEmpty) return true;
      if (thread.clientName.toLowerCase().contains(q)) return true;
      for (final j in thread.allJobs) {
        if (j.plateDisplay.toLowerCase().contains(q) ||
            j.vehicleDisplay.toLowerCase().contains(q) ||
            j.serviceType.toLowerCase().contains(q)) {
          return true;
        }
      }
      return false;
    }).toList();

    // Sort chats according to newest on top (descending appointmentDate and ID)
    filteredThreads.sort((a, b) {
      final dateA = a.primaryJob.appointmentDate;
      final dateB = b.primaryJob.appointmentDate;
      final cmp = dateB.compareTo(dateA);
      if (cmp != 0) return cmp;
      return b.primaryJob.id.compareTo(a.primaryJob.id);
    });

    return Column(
      children: [
        // WhatsApp-like Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search client or vehicle plate...',
                hintStyle: GoogleFonts.instrumentSans(fontSize: 14, color: Colors.black45),
                prefixIcon: const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass, size: 20, color: Colors.black45),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Colors.black45),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: GoogleFonts.instrumentSans(fontSize: 14),
            ),
          ),
        ),

        // WhatsApp-style Conversations List (One chat per client showing service details)
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF5D2E),
            onRefresh: () async {
              ref.invalidate(activeAppointmentsProvider);
              ref.invalidate(pendingAppointmentsProvider);
            },
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
                  )
                : hasError
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 400,
                          child: ServioErrorState(
                            message: 'Could not load conversation threads. Tap retry to reload.',
                            onRetry: () {
                              ref.invalidate(activeAppointmentsProvider);
                              ref.invalidate(pendingAppointmentsProvider);
                            },
                          ),
                        ),
                      )
                    : filteredThreads.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 400,
                              child: ServioEmptyState(
                                icon: PhosphorIconsRegular.chatCircleDots,
                                title: 'No Conversations Found',
                                description: _searchQuery.isNotEmpty
                                    ? 'No customer conversations match "$_searchQuery".'
                                    : 'There are no active or pending appointments for customer chat.',
                                actionLabel: _searchQuery.isNotEmpty ? 'Clear Search' : 'Refresh',
                                onAction: () {
                                  if (_searchQuery.isNotEmpty) {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  } else {
                                    ref.invalidate(activeAppointmentsProvider);
                                    ref.invalidate(pendingAppointmentsProvider);
                                  }
                                },
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filteredThreads.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              indent: 76,
                              color: Color(0xFFF0F0F0),
                            ),
                            itemBuilder: (context, index) {
                              final thread = filteredThreads[index];
                              final clientName = thread.clientName;
                              final primaryJob = thread.primaryJob;
                              final serviceDetail = primaryJob.serviceType;
                              final time = primaryJob.formattedDate;
                              final isMultiple = thread.allJobs.length > 1;
                              final status = primaryJob.status.toUpperCase();

                              Color statusBg;
                              Color statusFg;
                              if (status == 'IN_PROGRESS') {
                                statusBg = const Color(0xFFFEF3C7);
                                statusFg = const Color(0xFFB45309);
                              } else if (status == 'CONFIRMED') {
                                statusBg = const Color(0xFFDCFCE7);
                                statusFg = const Color(0xFF15803D);
                              } else {
                                statusBg = const Color(0xFFF3F4F6);
                                statusFg = const Color(0xFF4B5563);
                              }

                              return InkWell(
                                onTap: () => context.push('/worker/chat/${primaryJob.id}'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    children: [
                                      // Avatar with dynamic service badge
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          CircleAvatar(
                                            radius: 26,
                                            backgroundColor: ServiceIconHelper.getServiceColors(serviceDetail).background,
                                            child: Text(
                                              clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                                              style: GoogleFonts.instrumentSans(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: ServiceIconHelper.getServiceColors(serviceDetail).primary,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: -2,
                                            bottom: -2,
                                            child: Container(
                                              padding: const EdgeInsets.all(3.5),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.08),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                ServiceIconHelper.getPhosphorIcon(serviceDetail),
                                                size: 13,
                                                color: ServiceIconHelper.getServiceColors(serviceDetail).primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),

                                      // Text content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    clientName,
                                                    style: GoogleFonts.instrumentSans(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  time,
                                                  style: GoogleFonts.instrumentSans(
                                                    fontSize: 11,
                                                    color: Colors.black45,
                                                    fontWeight: FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            // Service Details & Plate info
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF3F4F6),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    primaryJob.plateDisplay,
                                                    style: GoogleFonts.instrumentSans(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Icon(
                                                  ServiceIconHelper.getPhosphorIcon(serviceDetail),
                                                  size: 13,
                                                  color: ServiceIconHelper.getServiceColors(serviceDetail).primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '${primaryJob.vehicleDisplay} • $serviceDetail',
                                                    style: GoogleFonts.instrumentSans(
                                                      fontSize: 13,
                                                      color: Colors.black54,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: statusBg,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    primaryJob.status.replaceAll('_', ' '),
                                                    style: GoogleFonts.instrumentSans(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: statusFg,
                                                    ),
                                                  ),
                                                ),
                                                if (isMultiple) ...[
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFFECE5),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '+${thread.allJobs.length - 1}',
                                                      style: GoogleFonts.instrumentSans(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w700,
                                                        color: const Color(0xFFFF5D2E),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }
}
