import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'appointments_providers.dart';
import 'package:shared_core/shared_core.dart';
import 'appointment_detail_screen.dart';
import '../services/services_providers.dart';
import '../services/service_detail_screen.dart';
import '../services/service_detail_resolver.dart';

// ─── SERVICE IMAGE MAPPING (service_type → local asset) ──────────────────────

const _serviceImageMap = <String, String>{
  'Washing Packages': 'assets/service images/Washing Packages.jpg',
  'Lube Services': 'assets/service images/Lubricant Service.jpg',
  'Lubricant Service': 'assets/service images/Lubricant Service.jpg',
  'Exterior & Interior Detailing':
      'assets/service images/Exterior Detailing.jpg',
  'Exterior Detailing': 'assets/service images/Exterior Detailing.jpg',
  'Interior Detailing': 'assets/service images/Interior detailing.jpg',
  'Engine Tune ups': 'assets/service images/Mechanical Repair.jpg',
  'Inspection Reports': 'assets/service images/Mulipoint Inspection Report.jpg',
  'Multipoint Inspection Report':
      'assets/service images/Mulipoint Inspection Report.jpg',
  'Tyre Services': 'assets/service images/Periodic Maintenance.jpg',
  'Periodic Maintenance': 'assets/service images/Periodic Maintenance.jpg',
  'Battery Services': 'assets/service images/Electrical & Electronic.jpg',
  'Electrical & Electronic':
      'assets/service images/Electrical & Electronic.jpg',
  'Insurance Claims': 'assets/service images/General Collision Repair.jpg',
  'General Collision Repair':
      'assets/service images/General Collision Repair.jpg',
  'Full Paints': 'assets/service images/Complete Paint.jpg',
  'Complete Paint': 'assets/service images/Complete Paint.jpg',
  'AC Repair and Service': 'assets/service images/AC Repair and Service.jpg',
  'Mechanical Repair': 'assets/service images/Mechanical Repair.jpg',
  'Waxing': 'assets/service images/Washing Packages.jpg',
};

const _serviceIconMap = <String, String>{
  'Washing Packages': 'assets/service icons/Washing Packages.png',
  'Lube Services': 'assets/service icons/Lube Services.png',
  'Lubricant Service': 'assets/service icons/Lube Services.png',
  'Exterior & Interior Detailing':
      'assets/service icons/Exterior & Interior Detailing.png',
  'Exterior Detailing':
      'assets/service icons/Exterior & Interior Detailing.png',
  'Interior Detailing':
      'assets/service icons/Exterior & Interior Detailing.png',
  'Engine Tune ups': 'assets/service icons/Engine Tune ups.png',
  'Inspection Reports': 'assets/service icons/Inspection Reports.png',
  'Tyre Services': 'assets/service icons/Tyre Services.png',
  'Battery Services': 'assets/service icons/Battery Services.png',
  'Insurance Claims': 'assets/service icons/Insurance Claims.png',
  'Full Paints': 'assets/service icons/Full Paints.png',
  'Waxing': 'assets/service icons/Waxing.png',
  'Undercarriage Degreasing':
      'assets/service icons/Undercarriage Degreasing.png',
  'Windscreen Treatments': 'assets/service icons/Windscreen Treatments.png',
  'Wheel Alignment': 'assets/service icons/Wheel Alignment.png',
  'Part Replacements': 'assets/service icons/Part Replacements.png',
};

String? _imageForService(String serviceType) => _serviceImageMap[serviceType];

String _iconForService(String serviceType) =>
    _serviceIconMap[serviceType] ?? 'assets/service icons/Lube Services.png';

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'CONFIRMED':
      return const Color(0xFF22C55E);
    case 'IN_PROGRESS':
      return const Color(0xFFFF5D2E);
    case 'COMPLETED':
      return const Color(0xFF6B7280);
    case 'CANCELLED':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFFF59E0B); // PENDING = amber
  }
}

// ─── ACTIVITY SCREEN ─────────────────────────────────────────────────────────

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  void _openAppointmentDetail(BuildContext context, AppointmentModel appt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final appointmentsAsync = ref.watch(userAppointmentsProvider(userId));

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
          children: [
            // ── Scrollable Content ──
            Expanded(
              child: appointmentsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
                ),
                error: (err, _) => _ErrorView(
                  onRetry: () =>
                      ref.invalidate(userAppointmentsProvider(userId)),
                ),
                data: (appointments) {
                  final ongoing = appointments
                      .where((a) => a.status.toUpperCase() == 'IN_PROGRESS')
                      .toList()
                    ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

                  final upcoming = appointments
                      .where(
                        (a) =>
                            a.status.toUpperCase() != 'IN_PROGRESS' &&
                            !['COMPLETED', 'CANCELLED'].contains(
                              a.status.toUpperCase(),
                            ),
                      )
                      .toList()
                    ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

                  final past = appointments
                      .where(
                        (a) => ['COMPLETED', 'CANCELLED'].contains(
                          a.status.toUpperCase(),
                        ),
                      )
                      .toList()
                    ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

                  if (appointments.isEmpty) {
                    return const _EmptyView();
                  }

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Title ──
                          const _TitleSection(),
                          const SizedBox(height: 24),

                          // ── Ongoing Service Section (if any) ──
                          if (ongoing.isNotEmpty) ...[
                            _AppointmentCardSection(
                              title: 'Ongoing service',
                              appointment: ongoing.first,
                              onTap: () =>
                                  _openAppointmentDetail(context, ongoing.first),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // ── Upcoming Service Section ──
                          if (upcoming.isNotEmpty) ...[
                            _AppointmentCardSection(
                              title: 'Upcoming service',
                              appointment: upcoming.first,
                              onTap: () =>
                                  _openAppointmentDetail(context, upcoming.first),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // ── Past Services ──
                          if (past.isNotEmpty)
                            _PastServicesSection(
                              appointments: past,
                              onItemTap: (appt) =>
                                  _openAppointmentDetail(context, appt),
                            ),
                        ],
                      ),
                    ),
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

// ─── TITLE SECTION ───────────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  const _TitleSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity',
          style: GoogleFonts.instrumentSans(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track your vehicle service progress and history',
          style: GoogleFonts.instrumentSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

// ─── APPOINTMENT CARD SECTION (Upcoming or Ongoing) ──────────────────────────

class _AppointmentCardSection extends StatelessWidget {
  final String title;
  final AppointmentModel appointment;
  final VoidCallback? onTap;

  const _AppointmentCardSection({
    required this.title,
    required this.appointment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = _imageForService(appointment.serviceType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.instrumentSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE7DF), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 185,
                    width: double.infinity,
                    color: const Color(0xFFFFE7DF),
                    child: imagePath != null
                        ? Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        appointment.serviceType,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          appointment.status,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        appointment.statusLabel,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(appointment.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (appointment.vehicleMake != null) ...[
                  Row(
                    children: [
                      Text(
                        'For:',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4B4B4B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          appointment.vehicleDisplay,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Text(
                      appointment.formattedDate,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4B4B4B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4B4B4B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appointment.formattedTime,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4B4B4B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appointment.formattedCost,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        const PhosphorIcon(
                          PhosphorIconsBold.arrowRight,
                          size: 16,
                          color: Color(0xFFFF5D2E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View Details',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF5D2E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() => const Center(
    child: PhosphorIcon(
      PhosphorIconsRegular.wrench,
      size: 48,
      color: Color(0xFFFF5D2E),
    ),
  );
}

// ─── PAST SERVICES SECTION ───────────────────────────────────────────────────

class _PastServicesSection extends ConsumerWidget {
  final List<AppointmentModel> appointments;
  final ValueChanged<AppointmentModel>? onItemTap;

  const _PastServicesSection({
    required this.appointments,
    this.onItemTap,
  });

  void _rebook(BuildContext context, WidgetRef ref, String serviceType) {
    final categories = ref.read(serviceCategoriesProvider).asData?.value;
    final detail = resolveServiceDetail(serviceType, categories);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(data: detail),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Past',
                style: GoogleFonts.instrumentSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const PhosphorIcon(
              PhosphorIconsRegular.slidersHorizontal,
              size: 24,
              color: Colors.black,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...appointments.asMap().entries.map((entry) {
          final index = entry.key;
          final appointment = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < appointments.length - 1 ? 16 : 0,
            ),
            child: _PastServiceItem(
              appointment: appointment,
              onTap: () => onItemTap?.call(appointment),
              onRebook: () => _rebook(context, ref, appointment.serviceType),
            ),
          );
        }),
      ],
    );
  }
}

// ─── PAST SERVICE ITEM ───────────────────────────────────────────────────────

class _PastServiceItem extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onTap;
  final VoidCallback? onRebook;

  const _PastServiceItem({
    required this.appointment,
    this.onTap,
    this.onRebook,
  });

  @override
  Widget build(BuildContext context) {
    final iconPath = _iconForService(appointment.serviceType);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
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
        padding: const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7DF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  iconPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: PhosphorIcon(
                      PhosphorIconsRegular.car,
                      size: 24,
                      color: Color(0xFFFF5D2E),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appointment.serviceType,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        appointment.formattedDate,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4B4B4B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4B4B4B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appointment.formattedTime,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4B4B4B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.formattedCost,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onRebook,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5D2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(255, 93, 46, 0.5),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PhosphorIcon(
                      PhosphorIconsBold.arrowClockwise,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rebook',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
    );
  }
}

// ─── EMPTY & ERROR VIEWS ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PhosphorIcon(
            PhosphorIconsRegular.calendarX,
            size: 64,
            color: Color(0xFFFF5D2E),
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments yet',
            style: GoogleFonts.instrumentSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your upcoming and past bookings will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSans(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PhosphorIcon(
            PhosphorIconsRegular.warningCircle,
            size: 64,
            color: Color(0xFFFF5D2E),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load activity',
            style: GoogleFonts.instrumentSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again.',
            style: GoogleFonts.instrumentSans(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5D2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.instrumentSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
