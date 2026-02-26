import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bookings/checkout_screen.dart';

// ─── CHOOSE A TIME SCREEN ────────────────────────────────────────────────────

class ChooseATimeScreen extends StatefulWidget {
  const ChooseATimeScreen({super.key});

  @override
  State<ChooseATimeScreen> createState() => _ChooseATimeScreenState();
}

class _ChooseATimeScreenState extends State<ChooseATimeScreen> {
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = 0;

  static const List<_DateOption> _dateOptions = [
    _DateOption(label: 'Tomorrow', date: 'Oct 26'),
    _DateOption(label: 'Mon', date: 'Oct 27'),
    _DateOption(label: 'Tue', date: 'Oct 28'),
    _DateOption(label: 'Wed', date: 'Oct 29'),
    _DateOption(label: 'Thu', date: 'Oct 30'),
    _DateOption(label: 'Fri', date: 'Oct 31'),
    _DateOption(label: 'Sat', date: 'Nov 1'),
  ];

  static const List<String> _timeSlots = [
    '9:00 AM - 9:30 AM',
    '9:30 AM - 10:00 AM',
    '10:00 AM - 10:30 AM',
    '10:30 AM - 11:00 AM',
    '11:00 AM - 11:30 AM',
    '11:30 AM - 12:00 PM',
    '12:00 PM - 12:30 PM',
    '12:30 PM - 1:00 PM',
    '1:00 PM - 1:30 PM',
    '1:30 PM - 2:00 PM',
    '2:00 PM - 2:30 PM',
    '2:30 PM - 3:00 PM',
    '3:00 PM - 3:30 PM',
    '3:30 PM - 4:00 PM',
    '4:00 PM - 4:30 PM',
    '4:30 PM - 5:00 PM',
    '5:00 PM - 5:30 PM',
    '5:30 PM - 6:00 PM',
    '6:00 PM - 6:30 PM',
    '6:30 PM - 7:00 PM',
    '7:00 PM - 7:30 PM',
    '7:30 PM - 8:00 PM',
    '8:00 PM - 8:30 PM',
  ];

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

              // ── Container: Date Selection + Divider + Time Slots ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      // Date Selection (horizontal scroll)
                      _DateSelectionRow(
                        dateOptions: _dateOptions,
                        selectedIndex: _selectedDateIndex,
                        onDateSelected: (index) {
                          setState(() => _selectedDateIndex = index);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Divider
                      const _SectionDivider(),

                      const SizedBox(height: 16),

                      // Time Slots (scrollable)
                      Expanded(
                        child: _TimeSlotList(
                          timeSlots: _timeSlots,
                          selectedIndex: _selectedTimeIndex,
                          onTimeSelected: (index) {
                            setState(() => _selectedTimeIndex = index);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom Buttons ──
              const _BottomButtonSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── DATA MODEL ──────────────────────────────────────────────────────────────

class _DateOption {
  final String label;
  final String date;

  const _DateOption({required this.label, required this.date});
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
              'Choose a time',
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

// ─── DATE SELECTION ROW ──────────────────────────────────────────────────────

class _DateSelectionRow extends StatelessWidget {
  final List<_DateOption> dateOptions;
  final int selectedIndex;
  final ValueChanged<int> onDateSelected;

  const _DateSelectionRow({
    required this.dateOptions,
    required this.selectedIndex,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dateOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return _DateOptionChip(
            option: dateOptions[index],
            isSelected: isSelected,
            onTap: () => onDateSelected(index),
          );
        },
      ),
    );
  }
}

class _DateOptionChip extends StatelessWidget {
  final _DateOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateOptionChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 109),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF5D2E)
                : const Color(0xFFFFE7DF),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day label
            Text(
              option.label,
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            // Date
            Text(
              option.date,
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF4B4B4B),
              ),
            ),
          ],
        ),
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

// ─── TIME SLOT LIST ──────────────────────────────────────────────────────────

class _TimeSlotList extends StatelessWidget {
  final List<String> timeSlots;
  final int selectedIndex;
  final ValueChanged<int> onTimeSelected;

  const _TimeSlotList({
    required this.timeSlots,
    required this.selectedIndex,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: timeSlots.length * 2 - 1, // items + dividers
          itemBuilder: (context, index) {
            // Even indices = time slots, odd indices = dividers
            if (index.isOdd) {
              return _buildItemDivider();
            }
            final slotIndex = index ~/ 2;
            return _TimeSlotItem(
              timeLabel: timeSlots[slotIndex],
              isSelected: selectedIndex == slotIndex,
              onTap: () => onTimeSelected(slotIndex),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemDivider() {
    return SizedBox(
      height: 8,
      child: Center(
        child: Container(
          height: 1,
          width: double.infinity,
          color: Colors.black.withValues(alpha: 0.04),
        ),
      ),
    );
  }
}

// ─── TIME SLOT ITEM ──────────────────────────────────────────────────────────

class _TimeSlotItem extends StatelessWidget {
  final String timeLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotItem({
    required this.timeLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 4,
            top: 4,
            bottom: 4,
          ),
          child: Row(
            children: [
              // Time label
              Expanded(
                child: Text(
                  timeLabel,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Radio button (44x44 tap target)
              SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: PhosphorIcon(
                    isSelected
                        ? PhosphorIconsFill.radioButton
                        : PhosphorIconsRegular.circle,
                    size: 24,
                    color: isSelected
                        ? const Color(0xFFFF5D2E)
                        : Colors.black,
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

// ─── BOTTOM BUTTON SECTION ───────────────────────────────────────────────────

class _BottomButtonSection extends StatelessWidget {
  const _BottomButtonSection();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
        child: Column(
          children: [
            // Schedule button
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(),
                  ),
                );
              },
              child: Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5D2E),
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
                  child: Text(
                    'Schedule',
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
                  border: Border.all(
                    color: const Color(0xFFFFE7DF),
                    width: 1,
                  ),
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

