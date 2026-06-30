import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_core/shared_core.dart';
import 'worker_providers.dart';

class WorkerDashboardScreen extends ConsumerStatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  ConsumerState<WorkerDashboardScreen> createState() =>
      _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends ConsumerState<WorkerDashboardScreen> {
  int _selectedTab = 0;

  static final _tabRegularIcons = [
    PhosphorIcons.house(),
    PhosphorIcons.wrench(),
    PhosphorIcons.package(),
    PhosphorIcons.users(),
  ];
  static final _tabFillIcons = [
    PhosphorIcons.house(PhosphorIconsStyle.fill),
    PhosphorIcons.wrench(PhosphorIconsStyle.fill),
    PhosphorIcons.package(PhosphorIconsStyle.fill),
    PhosphorIcons.users(PhosphorIconsStyle.fill),
  ];
  static const _tabLabels = ['Home', 'Jobs', 'Inventory', 'Staff'];

  Future<void> _handleSignOut() async {
    await SupabaseService().signOut();
    if (mounted) context.go('/signin');
  }

  Future<void> _markDone(AppointmentModel job) async {
    try {
      await ref
          .read(workerRepositoryProvider)
          .updateAppointmentStatus(job.id, 'COMPLETED');
      ref.invalidate(activeAppointmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job marked done.'),
            backgroundColor: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(activeAppointmentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F5),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF7F5), Color(0xFFFBFBFB)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: appointmentsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
                  ),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(err.toString().replaceFirst('Exception: ', '')),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(activeAppointmentsProvider);
                            ref.invalidate(currentMechanicProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (appointments) => RefreshIndicator(
                    color: const Color(0xFFFF5D2E),
                    onRefresh: () async {
                      ref.invalidate(activeAppointmentsProvider);
                      ref.invalidate(currentMechanicProvider);
                    },
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          sliver: SliverList.list(
                            children: [
                              _buildSearchBar(),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Ongoing jobs',
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (appointments.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Center(
                                    child: Text('No active jobs found.'),
                                  ),
                                )
                              else
                                ...appointments.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final job = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildJobCard(
                                      job: job,
                                      isFirst: index == 0,
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildTabBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7DF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.magnifyingGlass(),
                            size: 24,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search for parts',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    color: Colors.black.withOpacity(0.2),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5D2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.package(PhosphorIconsStyle.fill),
                            size: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Request',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _handleSignOut,
          icon: PhosphorIcon(PhosphorIcons.signOut(), size: 28),
          color: Colors.black87,
        ),
      ],
    );
  }

  // ── Job Card ──────────────────────────────────────────────────────────────
  Widget _buildJobCard({required AppointmentModel job, required bool isFirst}) {
    final double actionVertPad = isFirst ? 12.0 : 16.0;
    final EdgeInsetsGeometry timelinePadding = isFirst
        ? const EdgeInsets.all(12)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 16);

    final progress = _statusProgress(job.status);
    final startTime = _shortTime(job.appointmentDate);
    final timeRange = _timeRange(job.appointmentDate);
    final timeLeft = _timeLeft(job.appointmentDate);

    final notesText = (job.notes?.trim().isNotEmpty == true)
        ? job.notes!.trim()
        : 'No special notes added for this job.';

    final customerState = _customerState(job.status);
    final customerInitial = (job.profileId != null && job.profileId!.isNotEmpty)
        ? 'C'
        : 'C';

    final assignedMechanic = job.assignedMechanicName ?? 'Pending Assignment';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isFirst
            ? Border.all(color: const Color(0xFFFF5D2E), width: 0.5)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x268A8A8A),
            blurRadius: 12,
            offset: Offset(0, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 22 / 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.car(),
                          size: 16,
                          color: const Color(0xFF545454),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.vehicleDisplay,
                            style: GoogleFonts.instrumentSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF545454),
                              letterSpacing: 0.06,
                              height: 13 / 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.clock(),
                          size: 16,
                          color: const Color(0xFF545454),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeRange,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF545454),
                            letterSpacing: 0.06,
                            height: 13 / 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
                    child: Container(color: const Color(0xFFCCCCCC)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                startTime,
                style: GoogleFonts.instrumentSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  letterSpacing: 0.06,
                  height: 13 / 11,
                ),
              ),
              Text(
                timeLeft,
                style: GoogleFonts.instrumentSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.6),
                  letterSpacing: 0.06,
                  height: 13 / 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDF4F1), width: 1),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes:',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF545454),
                    letterSpacing: 0.06,
                    height: 13 / 11,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    notesText,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      letterSpacing: 0.06,
                      height: 13 / 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 0.5, color: const Color(0xFFE6E6E6)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: Stack(
                  children: [
                    Positioned(
                      left: 12,
                      top: 3,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF9BB5D6),
                        ),
                        child: Center(
                          child: Text(
                            'C',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 3,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFD4A5A5),
                        ),
                        child: Center(
                          child: Text(
                            customerInitial,
                            style: GoogleFonts.instrumentSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 18,
                      child: Text(
                        'Customer',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF333333),
                          letterSpacing: -0.23,
                          height: 20 / 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      customerState,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEA0000),
                        letterSpacing: 0.06,
                        height: 13 / 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                job.plateDisplay,
                style: GoogleFonts.instrumentSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  icon: PhosphorIcons.chatText(),
                  label: 'Message',
                  verticalPad: actionVertPad,
                  onPressed: () => context.push('/worker/chat/${job.id}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSecondaryButton(
                  icon: PhosphorIcons.phoneOutgoing(),
                  label: 'Call',
                  verticalPad: actionVertPad,
                  onPressed: () {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Call action not implemented yet.'),
                          backgroundColor: Colors.black87,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 0.5, color: const Color(0xFFE6E6E6)),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Assign to:',
                style: GoogleFonts.instrumentSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF545454),
                  letterSpacing: 0.06,
                  height: 13 / 11,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$assignedMechanic (Mechanic)',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    letterSpacing: 0.06,
                    height: 13 / 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDF4F1), width: 1),
            ),
            padding: timelinePadding,
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.chartBar(PhosphorIconsStyle.bold),
                  size: 24,
                  color: const Color(0xFF333333),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Activity timeline',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF333333),
                      letterSpacing: -0.23,
                      height: 20 / 15,
                    ),
                  ),
                ),
                PhosphorIcon(
                  PhosphorIcons.caretDown(),
                  size: 16,
                  color: Colors.black,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _markDone(job),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5D2E),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: actionVertPad,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(
                    PhosphorIcons.checkCircle(),
                    size: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Done',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 19 / 15,
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

  Widget _buildSecondaryButton({
    required PhosphorIconData icon,
    required String label,
    required double verticalPad,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFFF9273), width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: verticalPad),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(icon, size: 24, color: Colors.black),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.instrumentSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
              height: 19 / 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceIcon(String serviceType) {
    final lower = serviceType.toLowerCase();
    final icon = lower.contains('battery')
        ? PhosphorIcons.batteryCharging(PhosphorIconsStyle.fill)
        : lower.contains('wash')
        ? PhosphorIcons.sparkle(PhosphorIconsStyle.fill)
        : lower.contains('lube') || lower.contains('oil')
        ? PhosphorIcons.drop(PhosphorIconsStyle.fill)
        : PhosphorIcons.wrench(PhosphorIconsStyle.fill);

    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: PhosphorIcon(icon, size: 40, color: const Color(0xFFFF5D2E)),
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
        return 0.18;
      default:
        return 0.08;
    }
  }

  String _customerState(String status) {
    if (status == 'IN_PROGRESS') return 'Service in progress';
    if (status == 'CONFIRMED') return 'Waiting Customer';
    return 'Pending confirmation';
  }

  String _timeRange(DateTime start) {
    final end = start.add(const Duration(hours: 2));
    return '${_shortTime(start)} - ${_shortTime(end)}';
  }

  String _shortTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
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

  // ── Bottom Tab Bar ────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 0.4,
            color: Colors.black.withOpacity(0.2),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 4),
            child: Row(
              children: List.generate(4, (i) {
                final bool isActive = _selectedTab == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          PhosphorIcon(
                            isActive
                                ? _tabFillIcons[i]
                                : _tabRegularIcons[i],
                            size: 24,
                            color: isActive
                                ? Colors.black
                                : Colors.black.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _tabLabels[i],
                            style: GoogleFonts.instrumentSans(
                              fontSize: 12,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isActive
                                  ? Colors.black
                                  : Colors.black.withOpacity(0.5),
                              height: 22 / 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (isActive)
                            Container(
                              width: 16,
                              height: 2,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5D2E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            )
                          else
                            const SizedBox(height: 2),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
