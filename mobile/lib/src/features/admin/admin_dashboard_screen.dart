import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'admin_providers.dart';
import '../../core/services/supabase_service.dart';
import '../bookings/models/appointment_model.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.instrumentSans(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await SupabaseService().signOut();
              if (context.mounted) {
                context.go('/signin');
              }
            },
            icon: const PhosphorIcon(
              PhosphorIconsRegular.signOut,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PhosphorIcon(
                PhosphorIconsRegular.warningCircle,
                size: 48,
                color: Colors.black54,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load stats.',
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              TextButton(
                onPressed: () => ref.refresh(adminDashboardStatsProvider),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Color(0xFFFF5D2E)),
                ),
              ),
            ],
          ),
        ),
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminDashboardStatsProvider),
            color: const Color(0xFFFF5D2E),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Revenue',
                            value:
                                'Rs. ${NumberFormat('#,##0').format(stats.totalRevenue)}',
                            icon: PhosphorIconsRegular.currencyDollar,
                            color: const Color(0xFFFF5D2E),
                            bgColor: const Color(0xFFFFE7DF),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Pending Bookings',
                            value: stats.pendingBookings.toString(),
                            icon: PhosphorIconsRegular.calendar,
                            color: Colors.blue.shade600,
                            bgColor: Colors.blue.shade50,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Recent Activity Title
                    Text(
                      'Recent Activity',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Recent Activity List
                    if (stats.recentActivity.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'No recent activity',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.recentActivity.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final activity = stats.recentActivity[index];
                          return _ActivityCard(activity: activity);
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: PhosphorIcon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.instrumentSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.instrumentSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final AppointmentModel activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7DF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: PhosphorIcon(
                PhosphorIconsRegular.wrench,
                color: Color(0xFFFF5D2E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.serviceType,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${activity.formattedDate} at ${activity.formattedTime}',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: activity.status == 'PENDING'
                  ? Colors.orange.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              activity.status,
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: activity.status == 'PENDING'
                    ? Colors.orange.shade700
                    : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
