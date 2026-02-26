import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'appointments_providers.dart';
import 'models/appointment_model.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(userAppointmentsProvider);

    return Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Text(
                'Activity',
                style: GoogleFonts.instrumentSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: appointmentsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const PhosphorIcon(
                          PhosphorIconsRegular.wifiSlash,
                          size: 48,
                          color: Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Could not load appointments.\nPlease check your connection.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => ref.invalidate(userAppointmentsProvider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5D2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Retry',
                              style: GoogleFonts.instrumentSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const PhosphorIcon(
                            PhosphorIconsRegular.calendarBlank,
                            size: 48,
                            color: Colors.black26,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bookings yet',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your appointment history will appear here.',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 14,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final upcoming = appointments
                      .where((a) => a.isUpcoming)
                      .toList();
                  final past = appointments
                      .where((a) => !a.isUpcoming)
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      if (upcoming.isNotEmpty) ...[
                        _SectionLabel(label: 'Upcoming'),
                        const SizedBox(height: 8),
                        ...upcoming.map(
                          (a) => _AppointmentCard(appointment: a),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (past.isNotEmpty) ...[
                        _SectionLabel(label: 'Past'),
                        const SizedBox(height: 8),
                        ...past.map((a) => _AppointmentCard(appointment: a)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SECTION LABEL ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.instrumentSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }
}

// ─── APPOINTMENT CARD ────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentCard({required this.appointment});

  Color get _statusColor {
    switch (appointment.status) {
      case 'CONFIRMED':
        return const Color(0xFF22C55E);
      case 'IN_PROGRESS':
        return const Color(0xFFFF5D2E);
      case 'COMPLETED':
        return const Color(0xFF6B7280);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateParts = appointment.formattedDate.split(' ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date badge
          Container(
            width: 44,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7DF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(
                  dateParts.isNotEmpty ? dateParts[0] : '',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4B4B4B),
                  ),
                ),
                Text(
                  dateParts.length > 1 ? dateParts[1] : '',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.serviceType,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.formattedTime,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF4B4B4B),
                  ),
                ),
                if (appointment.vehicleMake != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    appointment.vehicleDisplay,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF4B4B4B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Status + cost
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appointment.statusLabel,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                appointment.formattedCost,
                style: GoogleFonts.instrumentSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
