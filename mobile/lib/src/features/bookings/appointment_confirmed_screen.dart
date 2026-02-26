import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ─── APPOINTMENT CONFIRMED SCREEN ────────────────────────────────────────────

class AppointmentConfirmedScreen extends StatelessWidget {
  const AppointmentConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF7F5),
              Color(0xFFFBFBFB),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Fixed Header: Back button + Title ──
              const _HeaderSection(),

              // ── Scrollable Content ──
              const Expanded(
                child: SingleChildScrollView(
                  child: _AppointmentCard(),
                ),
              ),

              // ── Bottom Button ──
              const _BottomButtonSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HEADER SECTION ──────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button (40x40)
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PhosphorIcon(
                  PhosphorIconsBold.arrowLeft,
                  size: 24,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // Title
          SizedBox(
            width: double.infinity,
            child: Text(
              'Appointment Confirmed!',
              style: GoogleFonts.instrumentSans(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── APPOINTMENT CARD ────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── QR Code Container ──
          const _QrCodeSection(),

          const SizedBox(height: 24),

          // ── Service Info ──
          const _ServiceInfoSection(),

          const SizedBox(height: 24),

          // ── Date & Time Card ──
          const _DateTimeCard(),

          const SizedBox(height: 24),

          // ── Info Items (Car, Phone, Payment) ──
          const _InfoItemsList(),
        ],
      ),
    );
  }
}

// ─── QR CODE SECTION ─────────────────────────────────────────────────────────

class _QrCodeSection extends StatelessWidget {
  const _QrCodeSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          // Customer name (18px Bold, black, center, leading 22)
          Text(
            'Chamal Dissanayake',
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 22 / 18,
            ),
          ),
          const SizedBox(height: 16),

          // Appointment ID row (gap: 8, center, py: 4)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Label
                Text(
                  'Appointment ID:',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4B4B4B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8),
                // Badge (rounded: 16, px: 8, py: 4, border #D7D7D7)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD7D7D7),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '#SL-GOV-2025-00483',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // QR Code (256x256)
          QrImageView(
            data: 'SL-GOV-2025-00483',
            version: QrVersions.auto,
            size: 256,
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
        ],
      ),
    );
  }
}

// ─── SERVICE INFO SECTION ────────────────────────────────────────────────────

class _ServiceInfoSection extends StatelessWidget {
  const _ServiceInfoSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Service:" label (16px Bold, #4B4B4B)
          Text(
            'Service:',
            style: GoogleFonts.instrumentSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4B4B4B),
            ),
          ),
          const SizedBox(width: 8),
          // Service details (flex-1, gap: 4)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Service name (16px Medium, black, tracking 0.16)
                Text(
                  'Lubricant Service',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    letterSpacing: 0.16,
                  ),
                ),
                const SizedBox(height: 4),
                // Oil type (14px Medium, #4B4B4B, h: 17)
                SizedBox(
                  height: 17,
                  child: Text(
                    'Standard/Conventional Oil',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4B4B4B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DATE & TIME CARD ────────────────────────────────────────────────────────

class _DateTimeCard extends StatelessWidget {
  const _DateTimeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7DF),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar icon in white container (p: 8, rounded: 4)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const PhosphorIcon(
              PhosphorIconsRegular.calendarBlank,
              size: 24,
              color: Color(0xFF141414),
            ),
          ),
          const SizedBox(width: 16),
          // Date & Time text (gap: 4)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label (12px Medium, #4B4B4B)
                Text(
                  'DATE & TIME',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4B4B4B),
                  ),
                ),
                const SizedBox(height: 4),
                // Date/time value (16px Medium, black, tracking 0.16, leading 20)
                Text(
                  'Oct 26 · 9:00 AM - 9:30 AM',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    letterSpacing: 0.16,
                    height: 20 / 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── INFO ITEMS LIST ─────────────────────────────────────────────────────────

class _InfoItemsList extends StatelessWidget {
  const _InfoItemsList();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            // Toyota Premio
            const _InfoItem(
              icon: PhosphorIconsRegular.car,
              label: 'Toyota Premio',
            ),
            const SizedBox(height: 4),
            // Phone number
            const _InfoItem(
              icon: PhosphorIconsRegular.phone,
              label: '+94 72 4523 299',
            ),
            const SizedBox(height: 4),
            // Payment method
            const _InfoItem(
              icon: PhosphorIconsRegular.money,
              label: 'Pay by Cash',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            // Icon (24x24)
            PhosphorIcon(
              icon,
              size: 24,
              color: Colors.black,
            ),
            const SizedBox(width: 12),
            // Label (flex-1, 14px Medium, #4B4B4B)
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4B4B4B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BOTTOM BUTTON SECTION ───────────────────────────────────────────────────

class _BottomButtonSection extends StatelessWidget {
  const _BottomButtonSection();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
        child: GestureDetector(
          onTap: () {
            // Handle add to calendar action
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFE7DF),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Text(
                'Add to calendar',
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

