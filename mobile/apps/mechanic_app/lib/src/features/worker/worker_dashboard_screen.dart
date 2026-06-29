import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:shared_core/shared_core.dart';
import '../bookings/models/appointment_model.dart';
import 'worker_providers.dart';

class WorkerDashboardScreen extends ConsumerStatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  ConsumerState<WorkerDashboardScreen> createState() =>
      _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends ConsumerState<WorkerDashboardScreen> {
  static const _primary = Color(0xFFFF5D2E);
  static const _paper = Color(0xFFFFF7F5);

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(activeAppointmentsProvider);
    final mechanicAsync = ref.watch(currentMechanicProvider);
    final mechanicName = mechanicAsync.maybeWhen(
      data: (mechanic) => mechanic?['full_name']?.toString(),
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: _paper,
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
                    child: CircularProgressIndicator(color: _primary),
                  ),
                  error: (err, _) => _ErrorState(
                    message: err.toString().replaceFirst('Exception: ', ''),
                    onRetry: () {
                      ref.invalidate(currentMechanicProvider);
                      ref.invalidate(activeAppointmentsProvider);
                    },
                  ),
                  data: (appointments) => RefreshIndicator(
                    color: _primary,
                    onRefresh: () async {
                      ref.invalidate(currentMechanicProvider);
                      ref.invalidate(activeAppointmentsProvider);
                    },
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          sliver: SliverList.list(
                            children: [
                              _SearchRequestBar(
                                onRequest: () => _showSnack(
                                  'Parts request flow is coming soon.',
                                ),
                                onSignOut: _handleSignOut,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _selectedTab == 0
                                    ? 'Ongoing jobs'
                                    : _tabLabels[_selectedTab],
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        if (_selectedTab != 0)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _PlaceholderTab(
                              label: _tabLabels[_selectedTab],
                            ),
                          )
                        else if (appointments.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyJobs(),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverList.separated(
                              itemCount: appointments.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) => _JobCard(
                                job: appointments[index],
                                isHighlighted: index == 0,
                                mechanicName: mechanicName,
                                onMessage: () => context.push(
                                  '/worker/chat/${appointments[index].id}',
                                ),
                                onCall: () => _showSnack(
                                  'Customer call action is not connected yet.',
                                ),
                                onDone: () => _markDone(appointments[index]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _WorkerTabBar(
                selectedTab: _selectedTab,
                onSelect: (index) => setState(() => _selectedTab = index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markDone(AppointmentModel job) async {
    try {
      await ref
          .read(workerRepositoryProvider)
          .updateAppointmentStatus(job.id, 'COMPLETED');
      ref.invalidate(activeAppointmentsProvider);
      _showSnack('Job marked done.', isError: false);
    } catch (_) {
      _showSnack('Could not update job status.');
    }
  }

  Future<void> _handleSignOut() async {
    await SupabaseService().signOut();
    if (mounted) context.go('/signin');
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.black87 : Colors.green,
      ),
    );
  }
}

const _tabLabels = ['Home', 'Jobs', 'Inventory', 'Staff'];
const _tabRegularIcons = [
  PhosphorIconsRegular.house,
  PhosphorIconsRegular.wrench,
  PhosphorIconsRegular.package,
  PhosphorIconsRegular.users,
];
const _tabFillIcons = [
  PhosphorIconsFill.house,
  PhosphorIconsFill.wrench,
  PhosphorIconsFill.package,
  PhosphorIconsFill.users,
];

class _SearchRequestBar extends StatelessWidget {
  final VoidCallback onRequest;
  final VoidCallback onSignOut;

  const _SearchRequestBar({required this.onRequest, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7DF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const PhosphorIcon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 28,
                  color: Colors.black,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search for parts',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(width: 1, height: 42, color: Colors.black12),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: FilledButton.icon(
                    onPressed: onRequest,
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.package,
                      size: 24,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Request',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5D2E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(112, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Sign out',
          onPressed: onSignOut,
          icon: const PhosphorIcon(PhosphorIconsRegular.signOut, size: 24),
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final AppointmentModel job;
  final bool isHighlighted;
  final String? mechanicName;
  final VoidCallback onMessage;
  final VoidCallback onCall;
  final VoidCallback onDone;

  const _JobCard({
    required this.job,
    required this.isHighlighted,
    required this.mechanicName,
    required this.onMessage,
    required this.onCall,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final progress = _statusProgress(job.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFFF5D2E)
              : Colors.black.withValues(alpha: 0.04),
          width: isHighlighted ? 1 : 0.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x168A8A8A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ServiceIcon(serviceType: job.serviceType),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.serviceType,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoLine(
                      icon: PhosphorIconsFill.car,
                      text: job.vehicleDisplay,
                    ),
                    const SizedBox(height: 5),
                    _InfoLine(
                      icon: PhosphorIconsFill.clock,
                      text: _timeRange(job.appointmentDate),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: const Color(0xFFCCCCCC),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00B649)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _shortTime(job.appointmentDate),
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Text(
                _timeLeft(job.appointmentDate),
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _NotesBox(notes: job.notes),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE6E6E6), height: 1),
          const SizedBox(height: 18),
          Row(
            children: [
              _CustomerAvatar(seed: job.profileId ?? job.id.toString()),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    Text(
                      _customerState(job.status),
                      style: GoogleFonts.instrumentSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEA0000),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                job.plateDisplay,
                style: GoogleFonts.instrumentSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _OutlineActionButton(
                  icon: PhosphorIconsRegular.chatText,
                  label: 'Message',
                  onPressed: onMessage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OutlineActionButton(
                  icon: PhosphorIconsRegular.phoneOutgoing,
                  label: 'Call',
                  onPressed: onCall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE6E6E6), height: 1),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Assign to: ',
                  style: GoogleFonts.instrumentSans(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF545454),
                  ),
                ),
                TextSpan(
                  text:
                      '${mechanicName == null || mechanicName!.isEmpty ? 'You' : mechanicName} (Mechanic)',
                  style: GoogleFonts.instrumentSans(color: Colors.black),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE9E4)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                const PhosphorIcon(
                  PhosphorIconsBold.clockCounterClockwise,
                  size: 28,
                  color: Color(0xFF333333),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Activity timeline',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                const PhosphorIcon(
                  PhosphorIconsRegular.caretDown,
                  size: 22,
                  color: Colors.black,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton.icon(
              onPressed: onDone,
              icon: const PhosphorIcon(
                PhosphorIconsRegular.checkCircle,
                size: 28,
                color: Colors.white,
              ),
              label: Text(
                'Done',
                style: GoogleFonts.instrumentSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5D2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _statusProgress(String status) {
    switch (status) {
      case 'COMPLETED':
        return 1;
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
}

class _ServiceIcon extends StatelessWidget {
  final String serviceType;

  const _ServiceIcon({required this.serviceType});

  @override
  Widget build(BuildContext context) {
    final lower = serviceType.toLowerCase();
    final icon = lower.contains('battery')
        ? PhosphorIconsRegular.batteryCharging
        : lower.contains('wash')
        ? PhosphorIconsRegular.sparkle
        : lower.contains('lube') || lower.contains('oil')
        ? PhosphorIconsRegular.drop
        : PhosphorIconsRegular.wrench;

    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: PhosphorIcon(icon, size: 44, color: const Color(0xFFFF5D2E)),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(icon, size: 18, color: const Color(0xFF545454)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.instrumentSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF545454),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesBox extends StatelessWidget {
  final String? notes;

  const _NotesBox({this.notes});

  @override
  Widget build(BuildContext context) {
    final text = notes?.trim().isNotEmpty == true
        ? notes!.trim()
        : 'No special notes added for this job.';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE9E4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Notes: ',
              style: GoogleFonts.instrumentSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF545454),
              ),
            ),
            TextSpan(
              text: text,
              style: GoogleFonts.instrumentSans(color: Colors.black),
            ),
          ],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  final String seed;

  const _CustomerAvatar({required this.seed});

  @override
  Widget build(BuildContext context) {
    final initial = seed.isEmpty ? 'C' : seed.characters.first.toUpperCase();

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFFFE7DF),
      child: Text(
        initial,
        style: GoogleFonts.instrumentSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFFF5D2E),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: PhosphorIcon(icon, size: 26, color: Colors.black),
      label: Text(
        label,
        style: GoogleFonts.instrumentSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF333333),
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFFF9273)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

class _WorkerTabBar extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onSelect;

  const _WorkerTabBar({required this.selectedTab, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x1F000000))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: Row(
            children: List.generate(_tabLabels.length, (index) {
              final isActive = selectedTab == index;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelect(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        isActive
                            ? _tabFillIcons[index]
                            : _tabRegularIcons[index],
                        size: 28,
                        color: isActive
                            ? Colors.black
                            : Colors.black.withValues(alpha: 0.46),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tabLabels[index],
                        style: GoogleFonts.instrumentSans(
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isActive
                              ? Colors.black
                              : Colors.black.withValues(alpha: 0.48),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 18,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFFF5D2E)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PhosphorIcon(
              PhosphorIconsRegular.checkCircle,
              size: 52,
              color: Colors.black26,
            ),
            const SizedBox(height: 14),
            Text(
              'No ongoing jobs',
              style: GoogleFonts.instrumentSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String label;

  const _PlaceholderTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label tools are coming soon.',
        style: GoogleFonts.instrumentSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black45,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PhosphorIcon(
              PhosphorIconsRegular.warningCircle,
              size: 52,
              color: Colors.black45,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onRetry,
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
}
