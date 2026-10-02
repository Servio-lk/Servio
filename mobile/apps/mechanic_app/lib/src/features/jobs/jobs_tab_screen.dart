import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';
import '../worker/worker_providers.dart';
import '../../shared/empty_state.dart';
import '../../shared/error_state.dart';
import 'weekly_stats_card.dart';
import 'assign_mechanic_sheet.dart';

class JobsTabScreen extends ConsumerStatefulWidget {
  const JobsTabScreen({super.key});

  @override
  ConsumerState<JobsTabScreen> createState() => _JobsTabScreenState();
}

class _JobsTabScreenState extends ConsumerState<JobsTabScreen> {
  int _selectedJobSubTab = 0; // 0: On-going, 1: Pending
  final Set<int> _expandedTimelines = {};

  Future<void> _markDone(AppointmentModel job) async {
    try {
      await ref
          .read(workerRepositoryProvider)
          .updateAppointmentStatus(job.id, 'COMPLETED');
      ref.invalidate(activeAppointmentsProvider);
      ref.invalidate(completedWeeklyAppointmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job #${job.id} for ${job.plateDisplay} marked done!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update job status.'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    }
  }

  void _toggleTimeline(int jobId) {
    setState(() {
      if (_expandedTimelines.contains(jobId)) {
        _expandedTimelines.remove(jobId);
      } else {
        _expandedTimelines.add(jobId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeJobsAsync = ref.watch(activeAppointmentsProvider);
    final pendingJobsAsync = ref.watch(pendingAppointmentsProvider);
    final completedJobsAsync = ref.watch(completedWeeklyAppointmentsProvider);

    final ongoingList = activeJobsAsync.asData?.value ?? [];
    final pendingList = pendingJobsAsync.asData?.value ?? [];
    final completedList = completedJobsAsync.asData?.value ?? [];

    return RefreshIndicator(
      color: const Color(0xFFFF5D2E),
      onRefresh: () async {
        ref.invalidate(activeAppointmentsProvider);
        ref.invalidate(pendingAppointmentsProvider);
        ref.invalidate(completedWeeklyAppointmentsProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Weekly Stat Card
          WeeklyStatsCard(
            jobsDoneCount: completedList.length,
            ongoingJobsCount: ongoingList.length,
            pendingJobsCount: pendingList.length,
          ),
          const SizedBox(height: 16),

          // Sub-Tab Switcher: On-going vs Pending
          _buildJobTabSwitcher(
            ongoingCount: ongoingList.length,
            pendingCount: pendingList.length,
          ),
          const SizedBox(height: 16),

          // Content according to selected tab
          if (_selectedJobSubTab == 0) ...[
            activeJobsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
                ),
              ),
              error: (err, _) => _buildErrorState(
                'active jobs',
                onRetry: () => ref.invalidate(activeAppointmentsProvider),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return _buildEmptyState(
                    icon: PhosphorIconsRegular.wrench,
                    title: 'No Ongoing Jobs',
                    description: 'There are currently no active repair jobs in progress.',
                    actionLabel: 'Check Pending Jobs',
                    onAction: () => setState(() => _selectedJobSubTab = 1),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildOngoingJobCard(job: job, isFirst: index == 0),
                    );
                  },
                );
              },
            ),
          ] else ...[
            pendingJobsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
                ),
              ),
              error: (err, _) => _buildErrorState(
                'pending jobs',
                onRetry: () => ref.invalidate(pendingAppointmentsProvider),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return _buildEmptyState(
                    icon: PhosphorIconsRegular.clockCountdown,
                    title: 'No Pending Jobs',
                    description: 'There are no pending appointments awaiting assignment.',
                    actionLabel: 'Refresh',
                    onAction: () => ref.invalidate(pendingAppointmentsProvider),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPendingJobCard(job: job),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab Switcher ─────────────────────────────────────────────────────────
  Widget _buildJobTabSwitcher({required int ongoingCount, required int pendingCount}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedJobSubTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedJobSubTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedJobSubTab == 0
                      ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsFill.wrench,
                      size: 16,
                      color: _selectedJobSubTab == 0 ? const Color(0xFFFF5D2E) : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'On-going Jobs ($ongoingCount)',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selectedJobSubTab == 0 ? Colors.black : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedJobSubTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedJobSubTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedJobSubTab == 1
                      ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsFill.hourglass,
                      size: 16,
                      color: _selectedJobSubTab == 1 ? const Color(0xFFFF5D2E) : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pending Jobs ($pendingCount)',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selectedJobSubTab == 1 ? Colors.black : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── On-going Job Card ─────────────────────────────────────────────────────
  Widget _buildOngoingJobCard({required AppointmentModel job, required bool isFirst}) {
    final isExpanded = _expandedTimelines.contains(job.id);
    final assignedMechanic = job.assignedMechanicName ?? 'Assigned to Shift';
    final progress = _statusProgress(job.status);
    final startTime = _shortTime(job.appointmentDate);
    final timeRange = _timeRange(job.appointmentDate);
    final timeLeft = _timeLeft(job.appointmentDate);

    final notesText = (job.notes?.trim().isNotEmpty == true)
        ? job.notes!.trim()
        : 'No special notes added for this job.';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isFirst ? Border.all(color: const Color(0xFFFF5D2E), width: 1) : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceIcon(job.serviceType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.serviceType,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const PhosphorIcon(PhosphorIconsRegular.car, size: 14, color: Color(0xFF545454)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.vehicleDisplay,
                            style: GoogleFonts.instrumentSans(fontSize: 12, color: const Color(0xFF545454)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const PhosphorIcon(PhosphorIconsRegular.clock, size: 14, color: Color(0xFF545454)),
                        const SizedBox(width: 4),
                        Text(
                          timeRange,
                          style: GoogleFonts.instrumentSans(fontSize: 12, color: const Color(0xFF545454)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                job.plateDisplay,
                style: GoogleFonts.instrumentSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (progress * 100).toInt(),
                    child: Container(color: const Color(0xFF00B649)),
                  ),
                  Expanded(
                    flex: ((1 - progress) * 100).toInt(),
                    child: Container(color: const Color(0xFFE0E0E0)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Started: $startTime',
                style: GoogleFonts.instrumentSans(fontSize: 11, color: Colors.black54),
              ),
              Text(
                timeLeft,
                style: GoogleFonts.instrumentSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF5D2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF0EBE8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes: ',
                  style: GoogleFonts.instrumentSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                Expanded(
                  child: Text(
                    notesText,
                    style: GoogleFonts.instrumentSans(fontSize: 11, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const PhosphorIcon(PhosphorIconsRegular.userCheck, size: 16, color: Color(0xFF545454)),
              const SizedBox(width: 6),
              Text(
                'Mechanic: ',
                style: GoogleFonts.instrumentSans(fontSize: 12, color: const Color(0xFF545454)),
              ),
              Expanded(
                child: Text(
                  assignedMechanic,
                  style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/worker/chat/${job.id}'),
                  icon: const PhosphorIcon(PhosphorIconsRegular.chatText, size: 18, color: Colors.black87),
                  label: Text(
                    'Chat',
                    style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFB29E)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Direct calling customer...'), backgroundColor: Colors.black87),
                    );
                  },
                  icon: const PhosphorIcon(PhosphorIconsRegular.phoneOutgoing, size: 18, color: Colors.black87),
                  label: Text(
                    'Call',
                    style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFB29E)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Activity Timeline Accordion
          GestureDetector(
            onTap: () => _toggleTimeline(job.id),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEBEBEB)),
              ),
              child: Row(
                children: [
                  const PhosphorIcon(PhosphorIconsBold.chartBar, size: 18, color: Color(0xFFFF5D2E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Activity Timeline & Completed Tasks',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  PhosphorIcon(
                    isExpanded ? PhosphorIconsRegular.caretUp : PhosphorIconsRegular.caretDown,
                    size: 16,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            _buildTimelineContent(job.id),
          ],
          const SizedBox(height: 12),

          // Mark Done Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => _markDone(job),
              icon: const PhosphorIcon(PhosphorIconsFill.checkCircle, size: 20, color: Colors.white),
              label: Text(
                'Complete Job',
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5D2E),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pending Job Card (with Assign Mechanic Component) ─────────────────────
  Widget _buildPendingJobCard({required AppointmentModel job}) {
    final assignedMechanic = job.assignedMechanicName;
    final isAssigned = assignedMechanic != null && assignedMechanic.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceIcon(job.serviceType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PENDING ASSIGNMENT',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.serviceType,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.vehicleDisplay,
                      style: GoogleFonts.instrumentSans(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Text(
                job.plateDisplay,
                style: GoogleFonts.instrumentSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Scheduled for: ${job.formattedDate} at ${job.formattedTime}',
            style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(height: 14),

          // ── Component to Assign Mechanics ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE0D6)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isAssigned ? const Color(0xFFFF5D2E) : const Color(0xFFCCCCCC),
                  child: PhosphorIcon(
                    isAssigned ? PhosphorIconsFill.user : PhosphorIconsRegular.userPlus,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAssigned ? 'Assigned Mechanic' : 'Not Yet Assigned',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 11,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        isAssigned ? assignedMechanic : 'Tap to assign mechanic',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isAssigned ? Colors.black : const Color(0xFFFF5D2E),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    AssignMechanicSheet.show(
                      context,
                      job: job,
                      onAssigned: (_) {
                        ref.invalidate(pendingAppointmentsProvider);
                        ref.invalidate(activeAppointmentsProvider);
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5D2E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    isAssigned ? 'Change' : 'Assign',
                    style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Activity Timeline ────────────────────────────────────────────────────
  Widget _buildTimelineContent(int jobId) {
    return Consumer(
      builder: (context, ref, _) {
        final tasksAsync = ref.watch(jobTasksProvider(jobId));
        return tasksAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFF5D2E),
                ),
              ),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unable to load tasks for this job.',
                    style: GoogleFonts.instrumentSans(fontSize: 12, color: const Color(0xFFDC2626)),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(jobTasksProvider(jobId)),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 12,
                      color: const Color(0xFFFF5D2E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          data: (tasks) {
            if (tasks.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No checklist tasks logged for this job yet.',
                  style: GoogleFonts.instrumentSans(fontSize: 12, color: Colors.black45),
                ),
              );
            }
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: tasks.map((task) {
                  final timeStr = task.completedAt != null
                      ? _shortTime(task.completedAt!)
                      : (task.status == 'IN_PROGRESS' ? 'In Progress' : 'Pending');
                  return _buildTimelineItem(
                    title: task.description,
                    subtitle: task.instructions ?? (task.isCompleted ? 'Task completed' : 'Awaiting completion'),
                    time: timeStr,
                    isComplete: task.isCompleted,
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required String time,
    required bool isComplete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isComplete ? const Color(0xFF16A34A) : const Color(0xFFFF5D2E),
            ),
            child: Icon(
              isComplete ? Icons.check : Icons.circle,
              size: 10,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.instrumentSans(fontSize: 10, color: Colors.black45),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.instrumentSans(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceIcon(String serviceType) {
    final lower = serviceType.toLowerCase();
    final icon = lower.contains('battery')
        ? PhosphorIconsFill.batteryCharging
        : lower.contains('wash')
            ? PhosphorIconsFill.sparkle
            : lower.contains('lube') || lower.contains('oil')
                ? PhosphorIconsFill.drop
                : PhosphorIconsFill.wrench;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: PhosphorIcon(icon, size: 30, color: const Color(0xFFFF5D2E)),
      ),
    );
  }

  double _statusProgress(String status) {
    switch (status) {
      case 'COMPLETED':
        return 1.0;
      case 'IN_PROGRESS':
        return 0.55;
      case 'CONFIRMED':
        return 0.20;
      default:
        return 0.10;
    }
  }

  String _timeRange(DateTime start) {
    final end = start.add(const Duration(hours: 2));
    return '${_shortTime(start)} - ${_shortTime(end)}';
  }

  String _shortTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _timeLeft(DateTime start) {
    final end = start.add(const Duration(hours: 2));
    final remaining = end.difference(DateTime.now());
    if (remaining.isNegative) return 'Due now';
    final hours = remaining.inHours;
    if (hours >= 1) return '$hours hr left';
    final minutes = remaining.inMinutes.clamp(0, 59);
    return '$minutes min left';
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return ServioEmptyState(
      icon: icon,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  Widget _buildErrorState(String label, {VoidCallback? onRetry}) {
    return ServioErrorState(
      message: 'Could not load $label. Pull down or tap retry to reload.',
      onRetry: onRetry,
    );
  }
}
