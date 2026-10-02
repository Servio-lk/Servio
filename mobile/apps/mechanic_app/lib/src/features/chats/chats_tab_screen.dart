import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../worker/worker_providers.dart';
import '../../shared/empty_state.dart';
import '../../shared/error_state.dart';

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

    final filteredJobs = allJobs.where((job) {
      final clientName = (job.customerName ?? job.userId ?? 'Customer').toLowerCase();
      final plate = job.plateDisplay.toLowerCase();
      final vehicle = job.vehicleDisplay.toLowerCase();
      final service = job.serviceType.toLowerCase();
      final q = _searchQuery.toLowerCase();
      return clientName.contains(q) ||
          plate.contains(q) ||
          vehicle.contains(q) ||
          service.contains(q);
    }).toList();

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

        // WhatsApp-style Conversations List
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
                    : filteredJobs.isEmpty
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
                            itemCount: filteredJobs.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              indent: 76,
                              color: Color(0xFFF0F0F0),
                            ),
                            itemBuilder: (context, index) {
                              final job = filteredJobs[index];
                              final clientName = job.customerName ?? job.userId ?? 'Customer (Job #${job.id})';
                              final lastMessage = 'Service: ${job.serviceType}';
                              final time = job.formattedDate;
                              final unread = 0;

                      return InkWell(
                        onTap: () => context.push('/worker/chat/${job.id}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              // Avatar
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: const Color(0xFFFFECE5),
                                    child: Text(
                                      clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                                      style: GoogleFonts.instrumentSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFFF5D2E),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 13,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
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
                                            color: unread > 0 ? const Color(0xFFFF5D2E) : Colors.black45,
                                            fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            job.plateDisplay,
                                            style: GoogleFonts.instrumentSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            lastMessage,
                                            style: GoogleFonts.instrumentSans(
                                              fontSize: 13,
                                              color: unread > 0 ? Colors.black87 : Colors.black54,
                                              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (unread > 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFF5D2E),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              unread.toString(),
                                              style: GoogleFonts.instrumentSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
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
