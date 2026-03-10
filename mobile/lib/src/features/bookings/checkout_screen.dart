import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'appointment_confirmed_screen.dart';
import 'appointments_repository.dart';

// ─── CHECKOUT SCREEN ─────────────────────────────────────────────────────────

class CheckoutScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String selectedTime;
  final String serviceType;
  final String estimatedCostStr;

  const CheckoutScreen({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.serviceType,
    required this.estimatedCostStr,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isBooking = false;
  final AppointmentsRepository _repository = AppointmentsRepository();

  Future<void> _handleBook() async {
    setState(() => _isBooking = true);
    try {
      final startTime = widget.selectedTime.split(' - ')[0]; // "9:00 AM"
      final parts = startTime.split(' ');
      final timeParts = parts[0].split(':');
      int h = int.parse(timeParts[0]);
      final int m = int.parse(timeParts[1]);
      final String period = parts[1];

      if (period == 'PM' && h != 12) {
        h += 12;
      } else if (period == 'AM' && h == 12) {
        h = 0;
      }

      final dt = widget.selectedDate;
      final appointmentDate = DateTime(dt.year, dt.month, dt.day, h, m);

      // Parse numeric cost from string (e.g., 'LKR 5,500.00' -> 5500.0)
      final withoutDecimal = widget.estimatedCostStr.contains('.')
          ? widget.estimatedCostStr.substring(
              0,
              widget.estimatedCostStr.lastIndexOf('.'),
            )
          : widget.estimatedCostStr;
      final digitsOnly = withoutDecimal.replaceAll(RegExp(r'[^0-9]'), '');
      final parsedCost = digitsOnly.isNotEmpty ? double.parse(digitsOnly) : 0.0;

      final appointment = await _repository.createAppointment(
        serviceType: widget.serviceType,
        appointmentDate: appointmentDate,
        estimatedCost: parsedCost,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AppointmentConfirmedScreen(
            appointmentId: appointment.id.toString(),
            serviceType: widget.serviceType,
            formattedDate: '${_formatDate(dt)} · ${widget.selectedTime}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to book: $e')));
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
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
              // ── Fixed Header: Back button + Title ──
              const _HeaderSection(),

              // ── Scrollable Content ──
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Summary
                        _OrderSummarySection(
                          selectedDate: widget.selectedDate,
                          selectedTime: widget.selectedTime,
                          formattedDate: _formatDate(widget.selectedDate),
                          serviceType: widget.serviceType,
                        ),

                        const SizedBox(height: 16),
                        const _SectionDivider(),
                        const SizedBox(height: 16),

                        // Price Breakdown
                        _PriceBreakdownSection(
                          estimatedCostStr: widget.estimatedCostStr,
                        ),

                        const SizedBox(height: 16),
                        const _SectionDivider(),
                        const SizedBox(height: 16),

                        // Vehicle & Phone Info
                        const _InfoItemsSection(),

                        const SizedBox(height: 16),
                        const _SectionDivider(),
                        const SizedBox(height: 16),

                        // Payment Method
                        const _PaymentMethodSection(),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom Buttons ──
              _BottomButtonSection(onBook: _handleBook, isBooking: _isBooking),
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
              'Checkout',
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

// ─── ORDER SUMMARY SECTION ───────────────────────────────────────────────────

class _OrderSummarySection extends StatelessWidget {
  final DateTime selectedDate;
  final String selectedTime;
  final String formattedDate;
  final String serviceType;

  const _OrderSummarySection({
    required this.selectedDate,
    required this.selectedTime,
    required this.formattedDate,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          SizedBox(
            width: double.infinity,
            child: Text(
              'Order Summary',
              style: GoogleFonts.instrumentSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Service icon + name (gap: 8)
          Row(
            children: [
              // Service image placeholder (40x40)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFFE7DF), width: 1),
                ),
                child: const Center(
                  child: PhosphorIcon(
                    PhosphorIconsRegular.wrench,
                    size: 20,
                    color: Color(0xFFFF5D2E),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Service Title
              Text(
                serviceType,
                style: GoogleFonts.instrumentSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4B4B4B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date/Time row + Edit (gap: 8, items-end)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Date + dot + time (flex-1, gap: 4)
              Expanded(
                child: Row(
                  children: [
                    Text(
                      formattedDate,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                    Flexible(
                      child: Text(
                        selectedTime,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B4B4B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Edit link
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Text(
                  'Edit',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── SECTION DIVIDER ─────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: Center(
        child: Container(
          height: 1,
          width: double.infinity,
          color: Colors.black.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}

// ─── PRICE BREAKDOWN SECTION ─────────────────────────────────────────────────

class _PriceBreakdownSection extends StatelessWidget {
  final String estimatedCostStr;
  const _PriceBreakdownSection({required this.estimatedCostStr});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          SizedBox(
            width: double.infinity,
            child: Text(
              'Price Breakdown',
              style: GoogleFonts.instrumentSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Price items (rounded: 8, overflow clip, py: 4, gap: 4)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  const _PriceLineItem(
                    label: 'Service Fee',
                    amount: '+LKR 1,500',
                    isBoldLabel: false,
                  ),
                  const SizedBox(height: 4),
                  const _PriceLineItem(
                    label: 'Standard/Conventional Oil',
                    amount: '+LKR 4,000',
                    isBoldLabel: false,
                  ),
                  const SizedBox(height: 4),
                  const _PriceLineItem(
                    label: 'Total',
                    amount: 'LKR 5,500',
                    isBoldLabel: true,
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

class _PriceLineItem extends StatelessWidget {
  final String label;
  final String amount;
  final bool isBoldLabel;

  const _PriceLineItem({
    required this.label,
    required this.amount,
    required this.isBoldLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            // Label
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: isBoldLabel ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF4B4B4B),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Amount
            Text(
              amount,
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── INFO ITEMS SECTION (Vehicle & Phone) ────────────────────────────────────

class _InfoItemsSection extends StatelessWidget {
  const _InfoItemsSection();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            // Toyota Premio
            _InfoItem(
              icon: PhosphorIconsRegular.car,
              label: 'Toyota Premio',
              onTap: () {},
            ),
            const SizedBox(height: 4),
            // Phone
            _InfoItem(
              icon: PhosphorIconsRegular.phone,
              label: '+94 72 4523 299',
              onTap: () {},
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
  final VoidCallback onTap;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Icon (24x24)
              PhosphorIcon(icon, size: 24, color: Colors.black),
              const SizedBox(width: 12),
              // Label (flex-1)
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
              // CaretRight (16x16, 0.5 opacity)
              const Opacity(
                opacity: 0.5,
                child: PhosphorIcon(
                  PhosphorIconsBold.caretRight,
                  size: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PAYMENT METHOD SECTION ──────────────────────────────────────────────────

class _PaymentMethodSection extends StatelessWidget {
  const _PaymentMethodSection();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle payment method selection
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // Money icon (24x24)
              const PhosphorIcon(
                PhosphorIconsRegular.money,
                size: 24,
                color: Colors.black,
              ),
              const SizedBox(width: 12),
              // Label (flex-1)
              Expanded(
                child: Text(
                  'Cash',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4B4B4B),
                  ),
                ),
              ),
              // CaretRight (16x16, 0.5 opacity)
              const Opacity(
                opacity: 0.5,
                child: PhosphorIcon(
                  PhosphorIconsBold.caretRight,
                  size: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── BOTTOM BUTTON SECTION ───────────────────────────────────────────────────

class _BottomButtonSection extends StatelessWidget {
  final VoidCallback onBook;
  final bool isBooking;

  const _BottomButtonSection({required this.onBook, required this.isBooking});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
        child: Column(
          children: [
            // Book button
            GestureDetector(
              onTap: isBooking ? null : onBook,
              child: Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isBooking ? Colors.grey : const Color(0xFFFF5D2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(255, 93, 46, 0.5),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: isBooking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Book',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Cancel button
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE7DF), width: 1),
                ),
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
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
