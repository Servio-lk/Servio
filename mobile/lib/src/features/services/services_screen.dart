import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── SERVICE ITEM MODEL ──────────────────────────────────────────────────────

class ServiceItem {
  final String title;
  final String iconPath;

  const ServiceItem({
    required this.title,
    required this.iconPath,
  });
}

// ─── SERVICE DATA ────────────────────────────────────────────────────────────

final List<ServiceItem> _periodicMaintenanceItems = const [
  ServiceItem(
    title: 'Washing Packages',
    iconPath: 'assets/service icons/Washing Packages.png',
  ),
  ServiceItem(
    title: 'Lube Services',
    iconPath: 'assets/service icons/Lube Services.png',
  ),
  ServiceItem(
    title: 'Exterior & Interior Detailing',
    iconPath: 'assets/service icons/Exterior & Interior Detailing.png',
  ),
  ServiceItem(
    title: 'Engine Tune ups',
    iconPath: 'assets/service icons/Engine Tune ups.png',
  ),
  ServiceItem(
    title: 'Inspection Reports',
    iconPath: 'assets/service icons/Inspection Reports.png',
  ),
  ServiceItem(
    title: 'Tyre Services',
    iconPath: 'assets/service icons/Tyre Services.png',
  ),
  ServiceItem(
    title: 'Waxing',
    iconPath: 'assets/service icons/Waxing.png',
  ),
  ServiceItem(
    title: 'Undercarriage Degreasing',
    iconPath: 'assets/service icons/Undercarriage Degreasing.png',
  ),
  ServiceItem(
    title: 'Windscreen Treatments',
    iconPath: 'assets/service icons/Windscreen Treatments.png',
  ),
  ServiceItem(
    title: 'Battery Services',
    iconPath: 'assets/service icons/Battery Services.png',
  ),
];

final List<ServiceItem> _nanoCoatingItems = const [
  ServiceItem(
    title: 'Packages',
    iconPath: 'assets/service icons/Nano Coating Packages.png',
  ),
  ServiceItem(
    title: 'Treatments',
    iconPath: 'assets/service icons/Nano Coating Treatments.png',
  ),
];

final List<ServiceItem> _collisionRepairsItems = const [
  ServiceItem(
    title: 'Insurance Claims',
    iconPath: 'assets/service icons/Insurance Claims.png',
  ),
  ServiceItem(
    title: 'Wheel Alignment',
    iconPath: 'assets/service icons/Wheel Alignment.png',
  ),
  ServiceItem(
    title: 'Full Paints',
    iconPath: 'assets/service icons/Full Paints.png',
  ),
  ServiceItem(
    title: 'Part Replacements',
    iconPath: 'assets/service icons/Part Replacements.png',
  ),
];

// ─── SERVICES SCREEN ─────────────────────────────────────────────────────────

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // ── Fixed Header: Title + Search ──
            const _HeaderSection(),
            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Periodic Maintenance
                      _ServiceSection(
                        title: 'Periodic Maintenance',
                        items: _periodicMaintenanceItems,
                      ),
                      const SizedBox(height: 16),
                      // Nano Coating
                      _ServiceSection(
                        title: 'Nano Coating',
                        items: _nanoCoatingItems,
                      ),
                      const SizedBox(height: 16),
                      // Collision Repairs
                      _ServiceSection(
                        title: 'Collision Repairs',
                        items: _collisionRepairsItems,
                      ),
                    ],
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

// ─── HEADER SECTION ──────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Services',
              style: GoogleFonts.instrumentSans(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Search Container
          const _SearchBar(),
        ],
      ),
    );
  }
}

// ─── SEARCH BAR ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7DF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsBold.magnifyingGlass,
            size: 24,
            color: Colors.black.withOpacity(0.8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search services',
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SERVICE SECTION (Category with items) ───────────────────────────────────

class _ServiceSection extends StatelessWidget {
  final String title;
  final List<ServiceItem> items;

  const _ServiceSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section padding top
        const SizedBox(height: 12),
        // Section Title
        SizedBox(
          width: double.infinity,
          child: Text(
            title,
            style: GoogleFonts.instrumentSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Service Items
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _ServiceItemWidget(item: items[index]);
          },
        ),
      ],
    );
  }
}

// ─── SERVICE ITEM WIDGET ─────────────────────────────────────────────────────

class _ServiceItemWidget extends StatelessWidget {
  final ServiceItem item;

  const _ServiceItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 56),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // Service icon (40x40)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  item.iconPath,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const PhosphorIcon(
                      PhosphorIconsBold.wrench,
                      size: 20,
                      color: Color(0xFFFF5D2E),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                item.title,
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            // Caret right
            PhosphorIcon(
              PhosphorIconsBold.caretRight,
              size: 24,
              color: Colors.black.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
