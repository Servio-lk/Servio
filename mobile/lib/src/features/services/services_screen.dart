import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'service_detail_screen.dart';

// ─── SERVICE ITEM MODEL ──────────────────────────────────────────────────────

class ServiceItem {
  final String title;
  final String iconPath;
  final String? imagePath;
  final String basePrice;
  final String description;
  final String optionsTitle;
  final List<ServiceOption> options;

  const ServiceItem({
    required this.title,
    required this.iconPath,
    this.imagePath,
    this.basePrice = 'LKR 0.00',
    this.description = '',
    this.optionsTitle = 'Pricing and Options',
    this.options = const [],
  });
}

// ─── SERVICE DATA ────────────────────────────────────────────────────────────

final List<ServiceItem> _periodicMaintenanceItems = const [
  ServiceItem(
    title: 'Washing Packages',
    iconPath: 'assets/service icons/Washing Packages.png',
    imagePath: 'assets/service images/Washing Packages.jpg',
    basePrice: 'LKR 1,500.00',
    description: 'Keep your vehicle spotless with our comprehensive washing packages. Choose from basic exterior wash to full interior-exterior detailing.',
  ),
  ServiceItem(
    title: 'Lube Services',
    iconPath: 'assets/service icons/Lube Services.png',
    imagePath: 'assets/service images/Lubricant Service.jpg',
    basePrice: 'LKR 1,500.00',
    description: 'Protect your engine and maintain peak performance with our professional oil change service. We only use high-quality lubricants and filters, ensuring your vehicle runs smoothly and efficiently.',
    optionsTitle: 'Pricing and Oil Selection',
    options: [
      ServiceOption(name: 'Standard/Conventional Oil', price: '+LKR 4,000'),
      ServiceOption(name: 'Synthetic Blend Oil', price: '+LKR 6,000'),
      ServiceOption(name: 'Full Synthetic Oil', price: '+LKR 8,000'),
    ],
  ),
  ServiceItem(
    title: 'Exterior & Interior Detailing',
    iconPath: 'assets/service icons/Exterior & Interior Detailing.png',
    imagePath: 'assets/service images/Exterior Detailing.jpg',
    basePrice: 'LKR 5,000.00',
    description: 'Give your vehicle a showroom finish with our professional exterior and interior detailing service using premium products.',
  ),
  ServiceItem(
    title: 'Engine Tune ups',
    iconPath: 'assets/service icons/Engine Tune ups.png',
    imagePath: 'assets/service images/Mechanical Repair.jpg',
    basePrice: 'LKR 3,500.00',
    description: 'Restore your engine\'s power and efficiency with a full tune-up including spark plugs, filters, and system checks.',
  ),
  ServiceItem(
    title: 'Inspection Reports',
    iconPath: 'assets/service icons/Inspection Reports.png',
    imagePath: 'assets/service images/Mulipoint Inspection Report.jpg',
    basePrice: 'LKR 2,000.00',
    description: 'Comprehensive multi-point vehicle inspection covering all critical systems with a detailed digital report.',
  ),
  ServiceItem(
    title: 'Tyre Services',
    iconPath: 'assets/service icons/Tyre Services.png',
    imagePath: 'assets/service images/Periodic Maintenance.jpg',
    basePrice: 'LKR 500.00',
    description: 'Full tyre services including rotation, balancing, inflation checks and replacement recommendations.',
  ),
  ServiceItem(
    title: 'Waxing',
    iconPath: 'assets/service icons/Waxing.png',
    basePrice: 'LKR 2,500.00',
    description: 'Protect your paintwork and restore shine with a professional hand wax application.',
  ),
  ServiceItem(
    title: 'Undercarriage Degreasing',
    iconPath: 'assets/service icons/Undercarriage Degreasing.png',
    basePrice: 'LKR 1,800.00',
    description: 'Deep clean the undercarriage to remove grease, grime and road debris that can cause corrosion.',
  ),
  ServiceItem(
    title: 'Windscreen Treatments',
    iconPath: 'assets/service icons/Windscreen Treatments.png',
    basePrice: 'LKR 1,200.00',
    description: 'Hydrophobic coating and chip repair services to keep your windscreen clear and safe in all conditions.',
  ),
  ServiceItem(
    title: 'Battery Services',
    iconPath: 'assets/service icons/Battery Services.png',
    imagePath: 'assets/service images/Electrical & Electronic.jpg',
    basePrice: 'LKR 500.00',
    description: 'Battery health check, terminal cleaning and replacement service for all vehicle makes and models.',
  ),
];

final List<ServiceItem> _nanoCoatingItems = const [
  ServiceItem(
    title: 'Packages',
    iconPath: 'assets/service icons/Nano Coating Packages.png',
    basePrice: 'LKR 25,000.00',
    description: 'Complete nano ceramic coating package providing long-lasting protection against UV rays, scratches and contaminants.',
  ),
  ServiceItem(
    title: 'Treatments',
    iconPath: 'assets/service icons/Nano Coating Treatments.png',
    basePrice: 'LKR 12,000.00',
    description: 'Targeted nano coating treatment for specific panels or surfaces to restore and protect your vehicle\'s finish.',
  ),
];

final List<ServiceItem> _collisionRepairsItems = const [
  ServiceItem(
    title: 'Insurance Claims',
    iconPath: 'assets/service icons/Insurance Claims.png',
    imagePath: 'assets/service images/General Collision Repair.jpg',
    basePrice: 'Free consultation',
    description: 'We work directly with all major insurance providers to handle your claim from assessment to repair completion.',
  ),
  ServiceItem(
    title: 'Wheel Alignment',
    iconPath: 'assets/service icons/Wheel Alignment.png',
    basePrice: 'LKR 2,500.00',
    description: 'Computer-aided wheel alignment to restore handling, reduce tyre wear and improve fuel efficiency.',
  ),
  ServiceItem(
    title: 'Full Paints',
    iconPath: 'assets/service icons/Full Paints.png',
    imagePath: 'assets/service images/Complete Paint.jpg',
    basePrice: 'LKR 45,000.00',
    description: 'Factory-quality full vehicle respray using premium automotive paint with colour matching technology.',
  ),
  ServiceItem(
    title: 'Part Replacements',
    iconPath: 'assets/service icons/Part Replacements.png',
    basePrice: 'Price varies',
    description: 'Genuine and aftermarket part sourcing and replacement for all vehicle makes with fitment warranty.',
  ),
];

// ─── SERVICES SCREEN ─────────────────────────────────────────────────────────

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceItem> _filter(List<ServiceItem> items) {
    if (_searchQuery.isEmpty) return items;
    return items
        .where((item) =>
            item.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _openDetail(BuildContext context, ServiceItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          data: ServiceDetailData(
            title: item.title,
            basePrice: item.basePrice,
            description: item.description,
            imagePath: item.imagePath,
            optionsTitle: item.optionsTitle,
            options: item.options,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final periodicFiltered = _filter(_periodicMaintenanceItems);
    final nanoFiltered = _filter(_nanoCoatingItems);
    final collisionFiltered = _filter(_collisionRepairsItems);
    final noResults = periodicFiltered.isEmpty &&
        nanoFiltered.isEmpty &&
        collisionFiltered.isEmpty;

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
            // ── Fixed Header: Title + Search ──
            _HeaderSection(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: _clearSearch,
              hasQuery: _searchQuery.isNotEmpty,
            ),
            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 8, bottom: 16,
                  ),
                  child: noResults
                      ? Padding(
                          padding: const EdgeInsets.only(top: 64),
                          child: Center(
                            child: Text(
                              'No services found for "$_searchQuery"',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (periodicFiltered.isNotEmpty)
                              _ServiceSection(
                                title: 'Periodic Maintenance',
                                items: periodicFiltered,
                                onItemTap: (item) =>
                                    _openDetail(context, item),
                              ),
                            if (periodicFiltered.isNotEmpty &&
                                (nanoFiltered.isNotEmpty ||
                                    collisionFiltered.isNotEmpty))
                              const SizedBox(height: 16),
                            if (nanoFiltered.isNotEmpty)
                              _ServiceSection(
                                title: 'Nano Coating',
                                items: nanoFiltered,
                                onItemTap: (item) =>
                                    _openDetail(context, item),
                              ),
                            if (nanoFiltered.isNotEmpty &&
                                collisionFiltered.isNotEmpty)
                              const SizedBox(height: 16),
                            if (collisionFiltered.isNotEmpty)
                              _ServiceSection(
                                title: 'Collision Repairs',
                                items: collisionFiltered,
                                onItemTap: (item) =>
                                    _openDetail(context, item),
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
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasQuery;

  const _HeaderSection({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hasQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          _SearchBar(
            controller: controller,
            onChanged: onChanged,
            onClear: onClear,
            hasQuery: hasQuery,
          ),
        ],
      ),
    );
  }
}

// ─── SEARCH BAR ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasQuery;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hasQuery,
  });

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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsBold.magnifyingGlass,
            size: 24,
            color: Colors.black.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search services',
                hintStyle: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // X clear button — only shown while typing
          if (hasQuery)
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIconsBold.x,
                    size: 16,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── SERVICE SECTION ─────────────────────────────────────────────────────────

class _ServiceSection extends StatelessWidget {
  final String title;
  final List<ServiceItem> items;
  final ValueChanged<ServiceItem> onItemTap;

  const _ServiceSection({
    required this.title,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.instrumentSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) => _ServiceItemWidget(
            item: items[index],
            onTap: () => onItemTap(items[index]),
          ),
        ),
      ],
    );
  }
}

// ─── SERVICE ITEM WIDGET ─────────────────────────────────────────────────────

class _ServiceItemWidget extends StatelessWidget {
  final ServiceItem item;
  final VoidCallback onTap;

  const _ServiceItemWidget({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  item.iconPath,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
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
              const SizedBox(width: 12),
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
              PhosphorIcon(
                PhosphorIconsBold.caretRight,
                size: 24,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
