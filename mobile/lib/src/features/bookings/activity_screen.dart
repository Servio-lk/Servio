import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'appointments_providers.dart';
import 'models/appointment_model.dart';

// ─── SERVICE IMAGE MAPPING (service_type → local asset) ──────────────────────

const _serviceImageMap = <String, String>{
  'Washing Packages': 'assets/service images/Washing Packages.jpg',
  'Lube Services': 'assets/service images/Lubricant Service.jpg',
  'Lubricant Service': 'assets/service images/Lubricant Service.jpg',
  'Exterior & Interior Detailing': 'assets/service images/Exterior Detailing.jpg',
  'Exterior Detailing': 'assets/service images/Exterior Detailing.jpg',
  'Interior Detailing': 'assets/service images/Interior detailing.jpg',
  'Engine Tune ups': 'assets/service images/Mechanical Repair.jpg',
  'Inspection Reports': 'assets/service images/Mulipoint Inspection Report.jpg',
  'Multipoint Inspection Report': 'assets/service images/Mulipoint Inspection Report.jpg',
  'Tyre Services': 'assets/service images/Periodic Maintenance.jpg',
  'Periodic Maintenance': 'assets/service images/Periodic Maintenance.jpg',
  'Battery Services': 'assets/service images/Electrical & Electronic.jpg',
  'Electrical & Electronic': 'assets/service images/Electrical & Electronic.jpg',
  'Insurance Claims': 'assets/service images/General Collision Repair.jpg',
  'General Collision Repair': 'assets/service images/General Collision Repair.jpg',
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
  'Exterior & Interior Detailing': 'assets/service icons/Exterior & Interior Detailing.png',
  'Exterior Detailing': 'assets/service icons/Exterior & Interior Detailing.png',
  'Interior Detailing': 'assets/service icons/Exterior & Interior Detailing.png',
  'Engine Tune ups': 'assets/service icons/Engine Tune ups.png',
  'Inspection Reports': 'assets/service icons/Inspection Reports.png',
  'Tyre Services': 'assets/service icons/Tyre Services.png',
  'Battery Services': 'assets/service icons/Battery Services.png',
  'Insurance Claims': 'assets/service icons/Insurance Claims.png',
  'Full Paints': 'assets/service icons/Full Paints.png',
  'Waxing': 'assets/service icons/Waxing.png',
  'Undercarriage Degreasing': 'assets/service icons/Undercarriage Degreasing.png',
  'Windscreen Treatments': 'assets/service icons/Windscreen Treatments.png',
  'Wheel Alignment': 'assets/service icons/Wheel Alignment.png',
  'Part Replacements': 'assets/service icons/Part Replacements.png',
};

String? _imageForService(String serviceType) =>
    _serviceImageMap[serviceType];

String _iconForService(String serviceType) =>
    _serviceIconMap[serviceType] ?? 'assets/service icons/Lube Services.png';

// ─── ACTIVITY SCREEN ─────────────────────────────────────────────────────────

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
          children: [
            // ── Scrollable Content ──
            Expanded(
              child: appointmentsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
                ),
                error: (err, _) => _ErrorView(
                  onRetry: () => ref.invalidate(userAppointmentsProvider),
                ),
                data: (appointments) {
                  final upcoming =
                      appointments.where((a) => a.isUpcoming).toList();
                  final past =
                      appointments.where((a) => !a.isUpcoming).toList();

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

                          // ── Upcoming Service ──
                          if (upcoming.isNotEmpty) ...[
                            _UpcomingServiceSection(
                              appointment: upcoming.first,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // ── Past Services ──
                          if (past.isNotEmpty)
                            _PastServicesSection(appointments: past),
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

// ─── EMPTY VIEW ──────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
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
}

// ─── ERROR VIEW ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
              onTap: onRetry,
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
        const SizedBox(height: 4),
        Text(
          'Activity',
          style: GoogleFonts.instrumentSans(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

// ─── UPCOMING SERVICE SECTION ────────────────────────────────────────────────

class _UpcomingServiceSection extends StatelessWidget {
  final AppointmentModel appointment;
  const _UpcomingServiceSection({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final imagePath = _imageForService(appointment.serviceType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title (18px SemiBold, black)
        Text(
          'Upcoming service',
          style: GoogleFonts.instrumentSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),

        // Upcoming service card (rounded: 16, border #FFE7DF, p: 8, gap: 8)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFE7DF),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service image (h: 185, rounded: 8)
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
              const SizedBox(height: 8),

              // Service name (16px SemiBold, black)
              Text(
                appointment.serviceType,
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // For: Vehicle (gap: 4)
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

              // Date/Time row (gap: 4)
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

              // Price (14px Medium, black)
              Text(
                appointment.formattedCost,
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
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

class _PastServicesSection extends StatelessWidget {
  final List<AppointmentModel> appointments;
  const _PastServicesSection({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: "Past" + SlidersHorizontal icon (gap: 8)
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

        // Past service items (gap: 8)
        ...appointments.asMap().entries.map((entry) {
          final index = entry.key;
          final appointment = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < appointments.length - 1 ? 8 : 0,
            ),
            child: _PastServiceItem(appointment: appointment),
          );
        }),
      ],
    );
  }
}

// ─── PAST SERVICE ITEM ───────────────────────────────────────────────────────

class _PastServiceItem extends StatelessWidget {
  final AppointmentModel appointment;
  const _PastServiceItem({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final iconPath = _iconForService(appointment.serviceType);

    // bg: white, rounded: 8, shadow 0 2 8 rgba(0,0,0,0.04), p: 4, gap: 12
    return Container(
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
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Icon Container (bg: #FFE7DF, p: 8, rounded: 4, image 40x40)
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

          // Details Container (flex-1, gap: 4)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Service name (16px Medium, black, ellipsis)
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

                // Date/Time (gap: 4, 12px Medium #4B4B4B)
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

                // Price (12px Medium, black)
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

          // Rebook Button (bg: #FF5D2E, rounded: 8, p: 12, gap: 8,
          // border white, shadow 0 4 8 rgba(255,93,46,0.5))
          GestureDetector(
            onTap: () {
              // Handle rebook — navigate to services or booking flow
            },
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
    );
  }
}
