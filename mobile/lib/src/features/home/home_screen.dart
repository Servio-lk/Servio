import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/services_providers.dart';
import '../services/models/service_model.dart';

// ─── ICON MAPPING ────────────────────────────────────────────────────────────

const _suggestionIconMap = <String, String>{
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user name from Supabase auth
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? '';
    final firstName = fullName.isNotEmpty ? fullName.split(' ').first : 'there';

    // Watch featured services
    final featuredAsync = ref.watch(featuredServicesProvider);

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
                const _SearchContainer(),
                const SizedBox(height: 16),
                const _ServiceCenterContainer(),
                // Suggestions Header
                const _SuggestionsHeader(),
                // Suggestions List — from Supabase
                _SuggestionsListLive(featuredAsync: featuredAsync),
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

// ─── SUGGESTIONS LIST (live from Supabase) ───────────────────────────────────

class _SuggestionsListLive extends StatelessWidget {
  final AsyncValue<List<ServiceModel>> featuredAsync;
  const _SuggestionsListLive({required this.featuredAsync});

  @override
  Widget build(BuildContext context) {
    return featuredAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (services) {
        if (services.isEmpty) return const SizedBox.shrink();
        final items = services.take(4).toList();
        return Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final svc = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < items.length - 1 ? 8 : 0,
              ),
              child: _SuggestionItem(
                title: svc.name,
                iconPath:
                    _suggestionIconMap[svc.name] ??
                    'assets/service icons/Lube Services.png',
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── SEARCH CONTAINER ────────────────────────────────────────────────────────

class _SearchContainer extends StatelessWidget {
  const _SearchContainer();

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: Colors.black.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            // Later button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PhosphorIcon(
                    PhosphorIconsFill.calendarDots,
                    size: 24,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Later',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              color: Colors.black.withOpacity(0.8),
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
                    color: Colors.black.withOpacity(0.7),
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

  const _SuggestionItem({required this.title, required this.iconPath});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.build, size: 24, color: Color(0xFFFF5D2E)),
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
            color: Colors.black.withOpacity(0.5),
          ),
        ],
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
          // Star decoration (top right)
          Positioned(
            right: -40,
            top: -7,
            child: CustomPaint(
              size: const Size(224, 224),
              painter: _StarPainter(),
            ),
          ),
          // Mechanic icon placeholder (on top of star)
          Positioned(
            right: 35,
            top: 54,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5D2E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const PhosphorIcon(
                PhosphorIconsBold.engine,
                size: 48,
                color: Color(0xFFFF5D2E),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(8),
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

// ─── STAR PAINTER (for offer card decoration) ────────────────────────────────

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Colors.white, Color(0xFFFFBBA7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final strokePaint = Paint()
      ..color = Colors.black.withOpacity(0.02)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.48;
    final innerR = size.width * 0.38;
    const points = 12;

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
