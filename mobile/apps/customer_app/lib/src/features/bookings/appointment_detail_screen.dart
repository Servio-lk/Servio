import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_core/shared_core.dart';
import '../chats/customer_chat_screen.dart';
import '../services/services_providers.dart';
import '../services/service_detail_screen.dart';
import '../services/service_detail_resolver.dart';

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

String? _imageForService(String serviceType) => _serviceImageMap[serviceType];

class AppointmentDetailScreen extends ConsumerWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
  });

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
        return const Color(0xFFF59E0B);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return PhosphorIconsFill.checkCircle;
      case 'IN_PROGRESS':
        return PhosphorIconsBold.wrench;
      case 'COMPLETED':
        return PhosphorIconsFill.checkCircle;
      case 'CANCELLED':
        return PhosphorIconsFill.xCircle;
      default:
        return PhosphorIconsFill.clock;
    }
  }

  String _statusDescription(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return 'Your booking is confirmed! Please arrive at the scheduled time.';
      case 'IN_PROGRESS':
        return 'Your vehicle is currently being serviced by our technician.';
      case 'COMPLETED':
        return 'Service completed successfully. Thank you for choosing Servio!';
      case 'CANCELLED':
        return 'This appointment has been cancelled.';
      default:
        return 'Booking requested. Waiting for administrator confirmation.';
    }
  }

  Future<void> _callServiceCenter() async {
    final uri = Uri(scheme: 'tel', path: '+94112345678');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _rebook(BuildContext context, WidgetRef ref) {
    final categories = ref.read(serviceCategoriesProvider).asData?.value;
    final detail = resolveServiceDetail(appointment.serviceType, categories);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(data: detail),
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerChatScreen(appointment: appointment),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(appointment.status);
    final statusIcon = _statusIcon(appointment.status);
    final statusDesc = _statusDescription(appointment.status);
    final isUpcomingOrOngoing = ['CONFIRMED', 'IN_PROGRESS']
        .contains(appointment.status.toUpperCase());
    final isPending = appointment.status.toUpperCase() == 'PENDING';
    final isFinished = ['COMPLETED', 'CANCELLED']
        .contains(appointment.status.toUpperCase());
    final imagePath = _imageForService(appointment.serviceType);

    return Scaffold(
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
              // ── Header Bar ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: PhosphorIcon(
                            PhosphorIconsBold.arrowLeft,
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appointment Details',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '#${appointment.id}',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable Body ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: PhosphorIcon(
                                statusIcon,
                                size: 24,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        appointment.statusLabel,
                                        style: GoogleFonts.instrumentSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                        ),
                                      ),
                                      Text(
                                        '#${appointment.id}',
                                        style: GoogleFonts.instrumentSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    statusDesc,
                                    style: GoogleFonts.instrumentSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // QR Code Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.04),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFFFE7DF),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (appointment.customerName != null &&
                                appointment.customerName!.isNotEmpty) ...[
                              Text(
                                appointment.customerName!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0EC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Pass ID: #SERVIO-${appointment.id}',
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFF5D2E),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black12,
                                  width: 1,
                                ),
                              ),
                              child: QrImageView(
                                data: 'SERVIO-APT-${appointment.id}',
                                version: QrVersions.auto,
                                size: 200,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Show this QR code at the service center for instant check-in',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 13,
                                color: Colors.black54,
                                height: 1.3,
                              ),
                            ),
                            if (isPending) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFED7AA),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const PhosphorIcon(
                                      PhosphorIconsFill.clockCounterClockwise,
                                      size: 14,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Pending admin approval',
                                      style: GoogleFonts.instrumentSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Service Details Section
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.04),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service Details',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (imagePath != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  height: 140,
                                  width: double.infinity,
                                  child: Image.asset(
                                    imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              appointment.serviceType,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            if (appointment.notes != null &&
                                appointment.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Notes: ${appointment.notes!}',
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Appointment Meta Info Cards
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.04),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Date & Time
                            _DetailInfoRow(
                              icon: PhosphorIconsRegular.calendarBlank,
                              label: 'Date & Time',
                              value:
                                  '${appointment.formattedDate} · ${appointment.formattedTime}',
                            ),
                            const Divider(height: 24, thickness: 0.5),

                            // Vehicle
                            _DetailInfoRow(
                              icon: PhosphorIconsRegular.car,
                              label: 'Vehicle',
                              value: appointment.vehicleDisplay,
                            ),
                            const Divider(height: 24, thickness: 0.5),

                            // Location
                            _DetailInfoRow(
                              icon: PhosphorIconsRegular.mapPin,
                              label: 'Service Location',
                              value: appointment.location ??
                                  'Servio Main Service Center, Colombo 07',
                            ),
                            if (appointment.assignedMechanicName != null &&
                                appointment
                                    .assignedMechanicName!.isNotEmpty) ...[
                              const Divider(height: 24, thickness: 0.5),
                              _DetailInfoRow(
                                icon: PhosphorIconsRegular.userGear,
                                label: 'Assigned Specialist',
                                value: appointment.assignedMechanicName!,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Cost & Payment Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFE7DF),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  appointment.actualCost != null
                                      ? 'Total Cost'
                                      : 'Estimated Cost',
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF4B4B4B),
                                  ),
                                ),
                                Text(
                                  appointment.formattedCost,
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFF5D2E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const PhosphorIcon(
                                  PhosphorIconsRegular.creditCard,
                                  size: 16,
                                  color: Colors.black45,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  appointment.paymentMethod ??
                                      'Pay at service center (Cash / Card)',
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // ── Action Buttons Footer ──
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Color.fromRGBO(0, 0, 0, 0.08),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUpcomingOrOngoing) ...[
                        GestureDetector(
                          onTap: () => _openChat(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5D2E),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(255, 93, 46, 0.4),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const PhosphorIcon(
                                  PhosphorIconsFill.chatCircleDots,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Message Service Team',
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (isFinished) ...[
                        GestureDetector(
                          onTap: () => _rebook(context, ref),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5D2E),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(255, 93, 46, 0.4),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const PhosphorIcon(
                                  PhosphorIconsBold.arrowClockwise,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Rebook This Service',
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      GestureDetector(
                        onTap: _callServiceCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFFE7DF),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const PhosphorIcon(
                                PhosphorIconsBold.phoneCall,
                                color: Color(0xFFFF5D2E),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Call Service Center',
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFF5D2E),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0EC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: PhosphorIcon(
            icon,
            size: 20,
            color: const Color(0xFFFF5D2E),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.instrumentSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
