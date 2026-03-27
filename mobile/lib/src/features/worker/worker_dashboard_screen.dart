import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'worker_providers.dart';
import '../../core/services/supabase_service.dart';
import '../bookings/models/appointment_model.dart';

class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(activeAppointmentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Worker Dashboard',
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
                context.go('/welcome');
              }
            },
            icon: const PhosphorIcon(
              PhosphorIconsRegular.signOut,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: appointmentsAsync.when(
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
                'Failed to load jobs.',
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              TextButton(
                onPressed: () => ref.refresh(activeAppointmentsProvider),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Color(0xFFFF5D2E)),
                ),
              ),
            ],
          ),
        ),
        data: (appointments) {
          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PhosphorIcon(
                    PhosphorIconsRegular.checkCircle,
                    size: 48,
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active jobs',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(activeAppointmentsProvider),
            color: const Color(0xFFFF5D2E),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final job = appointments[index];
                return _JobCard(job: job);
              },
            ),
          );
        },
      ),
    );
  }
}

class _JobCard extends ConsumerWidget {
  final AppointmentModel job;
  const _JobCard({required this.job});

  void _showUpdateStatusSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final statuses = ['PENDING', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Job Status',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...statuses.map(
                  (s) => ListTile(
                    title: Text(
                      s,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: job.status == s
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: job.status == s
                            ? const Color(0xFFFF5D2E)
                            : Colors.black,
                      ),
                    ),
                    trailing: job.status == s
                        ? const Icon(Icons.check, color: Color(0xFFFF5D2E))
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      if (job.status != s) {
                        try {
                          await ref
                              .read(workerRepositoryProvider)
                              .updateAppointmentStatus(job.id, s);
                          ref.invalidate(activeAppointmentsProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Status updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update status'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Job #${job.id}',
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: job.status == 'COMPLETED'
                      ? Colors.green.shade50
                      : job.status == 'IN_PROGRESS'
                      ? Colors.blue.shade50
                      : const Color(0xFFFFE7DF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  job.status,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: job.status == 'COMPLETED'
                        ? Colors.green.shade700
                        : job.status == 'IN_PROGRESS'
                        ? Colors.blue.shade700
                        : const Color(0xFFFF5D2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            job.serviceType,
            style: GoogleFonts.instrumentSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const PhosphorIcon(
                PhosphorIconsRegular.carProfile,
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                job.vehicleDisplay,
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const PhosphorIcon(
                PhosphorIconsRegular.calendar,
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                '${job.formattedDate} at ${job.formattedTime}',
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showUpdateStatusSheet(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5D2E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Update Status',
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
