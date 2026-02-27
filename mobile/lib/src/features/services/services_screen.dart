import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'service_detail_screen.dart';
import 'models/service_model.dart';
import 'services_providers.dart';

// ─── LOCAL UI MODEL (unchanged — used by existing UI widgets) ────────────────

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

// ─── ASSET MAPPINGS (service name → local asset path) ────────────────────────

const _iconMap = <String, String>{
  'Washing Packages': 'assets/service icons/Washing Packages.png',
  'Lube Services': 'assets/service icons/Lube Services.png',
  'Exterior & Interior Detailing':
      'assets/service icons/Exterior & Interior Detailing.png',
  'Engine Tune ups': 'assets/service icons/Engine Tune ups.png',
  'Inspection Reports': 'assets/service icons/Inspection Reports.png',
  'Tyre Services': 'assets/service icons/Tyre Services.png',
  'Waxing': 'assets/service icons/Waxing.png',
  'Undercarriage Degreasing':
      'assets/service icons/Undercarriage Degreasing.png',
  'Windscreen Treatments': 'assets/service icons/Windscreen Treatments.png',
  'Battery Services': 'assets/service icons/Battery Services.png',
  'Packages': 'assets/service icons/Nano Coating Packages.png',
  'Treatments': 'assets/service icons/Nano Coating Treatments.png',
  'Insurance Claims': 'assets/service icons/Insurance Claims.png',
  'Wheel Alignment': 'assets/service icons/Wheel Alignment.png',
  'Full Paints': 'assets/service icons/Full Paints.png',
  'Part Replacements': 'assets/service icons/Part Replacements.png',
};

const _imageMap = <String, String>{
  'Washing Packages': 'assets/service images/Washing Packages.jpg',
  'Lube Services': 'assets/service images/Lubricant Service.jpg',
  'Exterior & Interior Detailing':
      'assets/service images/Exterior Detailing.jpg',
  'Engine Tune ups': 'assets/service images/Mechanical Repair.jpg',
  'Inspection Reports': 'assets/service images/Mulipoint Inspection Report.jpg',
  'Tyre Services': 'assets/service images/Periodic Maintenance.jpg',
  'Battery Services': 'assets/service images/Electrical & Electronic.jpg',
  'Insurance Claims': 'assets/service images/General Collision Repair.jpg',
  'Full Paints': 'assets/service images/Complete Paint.jpg',
};

ServiceItem _toServiceItem(ServiceModel m) => ServiceItem(
  title: m.name,
  iconPath: _iconMap[m.name] ?? 'assets/service icons/Lube Services.png',
  imagePath: _imageMap[m.name],
  basePrice: m.formattedBasePrice,
  description: m.description,
  optionsTitle: 'Pricing and Options',
  options: m.options
      .map((o) => ServiceOption(name: o.name, price: o.formattedPrice))
      .toList(),
);

// ─── SERVICES SCREEN ─────────────────────────────────────────────────────────

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
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
        .where(
          (item) =>
              item.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
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
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

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
              child: categoriesAsync.when(
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
                          'Could not load services.\n$err',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () =>
                              ref.invalidate(serviceCategoriesProvider),
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
                data: (categories) {
                  debugPrint(
                    '🟢 [ServicesScreen] data callback: ${categories.length} categories',
                  );
                  for (final cat in categories) {
                    debugPrint(
                      '   📁 ${cat.name}: ${cat.services.length} services',
                    );
                  }
                  // Map each Supabase category → list of ServiceItem
                  final sections = categories
                      .map((cat) {
                        final items = _filter(
                          cat.services.map(_toServiceItem).toList(),
                        );
                        return (title: cat.name, items: items);
                      })
                      .where((s) => s.items.isNotEmpty)
                      .toList();

                  final noResults = sections.isEmpty && _searchQuery.isNotEmpty;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 16,
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
                                for (int i = 0; i < sections.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 16),
                                  _ServiceSection(
                                    title: sections[i].title,
                                    items: sections[i].items,
                                    onItemTap: (item) =>
                                        _openDetail(context, item),
                                  ),
                                ],
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
