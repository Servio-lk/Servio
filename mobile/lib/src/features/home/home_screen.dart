import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SuggestionUiItem {
  final String title;
  final String iconPath;

  const _SuggestionUiItem({required this.title, required this.iconPath});
}

class HomeScreen extends ConsumerWidget {
  final VoidCallback? onSearchTap;
  final ValueChanged<String>? onSuggestionTap;

  const HomeScreen({super.key, this.onSearchTap, this.onSuggestionTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user name from Supabase auth
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? '';
    final firstName = fullName.isNotEmpty ? fullName.split(' ').first : 'there';

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting — now uses real name
                _GreetingSection(name: firstName),
                const SizedBox(height: 16),
                // Search + Service Center
                _SearchContainer(onTap: onSearchTap),
                const SizedBox(height: 16),
                const _ServiceCenterContainer(),
                // Suggestions Header
                const _SuggestionsHeader(),
                // Suggestions List — temporary static list (will be personalized later)
                _SuggestionsListStatic(onItemTap: onSuggestionTap),
                const SizedBox(height: 16),
                // Offers horizontal list
                const _OffersSection(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── GREETING ────────────────────────────────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  final String name;
  const _GreetingSection({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        'Hello, $name!',
        style: GoogleFonts.instrumentSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }
}

// ─── SUGGESTIONS LIST (static for current UI) ───────────────────────────────

class _SuggestionsListStatic extends StatelessWidget {
  final ValueChanged<String>? onItemTap;

  const _SuggestionsListStatic({this.onItemTap});

  static const List<_SuggestionUiItem> _items = [
    _SuggestionUiItem(
      title: 'Lube Services',
      iconPath: 'assets/service icons/Lube Services.png',
    ),
    _SuggestionUiItem(
      title: 'Washing Packages',
      iconPath: 'assets/service icons/Washing Packages.png',
    ),
    _SuggestionUiItem(
      title: 'Exterior & Interior Detailing',
      iconPath: 'assets/service icons/Exterior & Interior Detailing.png',
    ),
    _SuggestionUiItem(
      title: 'Engine Tune ups',
      iconPath: 'assets/service icons/Engine Tune ups.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: index < _items.length - 1 ? 8 : 0),
          child: _SuggestionItem(
            title: item.title,
            iconPath: item.iconPath,
            onTap: () => onItemTap?.call(item.title),
          ),
        );
      }).toList(),
    );
  }
}

// ─── SEARCH CONTAINER ────────────────────────────────────────────────────────

class _SearchContainer extends StatelessWidget {
  final VoidCallback? onTap;

  const _SearchContainer({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7DF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const PhosphorIcon(
              PhosphorIconsBold.magnifyingGlass,
              size: 24,
              color: Colors.black,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search services',
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            // Divider
            Container(
              width: 1,
              height: 24,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 8),
            // Emergency button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFF5D2E),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PhosphorIcon(
                    PhosphorIconsFill.warning,
                    size: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Emergency',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ─── SERVICE CENTER CONTAINER ────────────────────────────────────────────────

class _ServiceCenterContainer extends StatelessWidget {
  const _ServiceCenterContainer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE7DF), width: 1),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Garage icon container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEAE3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: PhosphorIcon(
              PhosphorIconsFill.garage,
              size: 24,
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 8),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last service',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Auto Miraj-Panadura',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
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

// ─── SUGGESTIONS HEADER ──────────────────────────────────────────────────────

class _SuggestionsHeader extends StatelessWidget {
  const _SuggestionsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Suggestions',
            style: GoogleFonts.instrumentSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Text(
            'See all',
            style: GoogleFonts.instrumentSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SUGGESTION ITEM ─────────────────────────────────────────────────────────

class _SuggestionItem extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback? onTap;

  const _SuggestionItem({
    required this.title,
    required this.iconPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        padding: const EdgeInsets.only(left: 4, right: 8, top: 4, bottom: 4),
        child: Row(
          children: [
            // Service icon from assets
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EC),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                iconPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.build,
                  size: 24,
                  color: Color(0xFFFF5D2E),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                title,
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
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── OFFERS SECTION ──────────────────────────────────────────────────────────

class _OffersSection extends StatelessWidget {
  const _OffersSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: const [_OfferCard(), SizedBox(width: 16), _OfferCard()],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 328,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Image Graphic (bottom right with some top padding)
          Positioned(
            right: 0,
            bottom: 0,
            top: 16,
            child: Image.asset(
              'assets/icons/Offer Image Container.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Offer text
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Enjoy 10% off on\nMechanical Repair',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                // Book now button
                Container(
                  width: 106,
                  padding: const EdgeInsets.all(12),
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
                  child: Center(
                    child: Text(
                      'Book now',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

