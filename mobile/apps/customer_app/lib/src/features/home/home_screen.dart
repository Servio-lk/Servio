import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_core/shared_core.dart';
import '../services/services_providers.dart';
import '../services/service_detail_screen.dart';
import '../services/service_detail_resolver.dart';

class _SuggestionUiItem {
  final String title;
  final String iconPath;

  const _SuggestionUiItem({required this.title, required this.iconPath});
}

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onSeeAllServices;
  final ValueChanged<String>? onSuggestionTap;
  final ValueChanged<OfferModel>? onOfferTap;

  const HomeScreen({
    super.key,
    this.onSearchTap,
    this.onSeeAllServices,
    this.onSuggestionTap,
    this.onOfferTap,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  StreamSubscription? _pushSubscription;
  RealtimeChannel? _offersChannel;

  @override
  void initState() {
    super.initState();
    _setupPushNotificationsListener();
    _setupSupabaseRealtime();
  }

  void _setupPushNotificationsListener() {
    try {
      _pushSubscription = PushNotificationService.onMessageStream.listen((message) {
        final type = message.data['type']?.toString().toUpperCase();
        final title = message.notification?.title?.toLowerCase() ?? '';
        final body = message.notification?.body?.toLowerCase() ?? '';
        if (type == 'PROMO' || title.contains('offer') || body.contains('offer')) {
          debugPrint('⚡ Offer notification received in foreground. Refreshing active offers.');
          if (mounted) {
            ref.invalidate(activeOffersProvider);
          }
        }
      });
    } catch (e) {
      debugPrint('Error attaching push notification listener: $e');
    }
  }

  void _setupSupabaseRealtime() {
    try {
      final client = SupabaseService().safeClient;
      if (client != null) {
        _offersChannel = client.channel('public:offers_realtime')
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'offers',
            callback: (payload) {
              debugPrint('⚡ Supabase realtime change in offers table: ${payload.eventType}');
              if (mounted) {
                ref.invalidate(activeOffersProvider);
              }
            },
          )
          ..subscribe();
      }
    } catch (e) {
      debugPrint('Error attaching Supabase offers realtime: $e');
    }
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    if (_offersChannel != null) {
      SupabaseService().safeClient?.removeChannel(_offersChannel!);
    }
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(activeOffersProvider);
    ref.invalidate(featuredServicesProvider);
    ref.invalidate(serviceCategoriesProvider);
    await ref.read(activeOffersProvider.future);
  }

  void _openServiceDetail(String title) {
    if (widget.onSuggestionTap != null) {
      widget.onSuggestionTap!(title);
      return;
    }
    final categories = ref.read(serviceCategoriesProvider).asData?.value;
    final detail = resolveServiceDetail(title, categories);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(data: detail),
      ),
    );
  }

  void _openOfferDetail(OfferModel offer) {
    if (widget.onOfferTap != null) {
      widget.onOfferTap!(offer);
      return;
    }
    final categories = ref.read(serviceCategoriesProvider).asData?.value;
    final detail = resolveOfferDetail(offer, categories);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(data: detail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: RefreshIndicator(
          color: const Color(0xFFFF5D2E),
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  _GreetingSection(name: firstName),
                  const SizedBox(height: 16),
                  // Search + Emergency Button
                  _SearchContainer(onSearchTap: widget.onSearchTap),
                  const SizedBox(height: 16),
                  // Suggestions Header
                  _SuggestionsHeader(onSeeAll: widget.onSeeAllServices),
                  // Suggestions List
                  _SuggestionsListStatic(onItemTap: _openServiceDetail),
                  const SizedBox(height: 16),
                  // Offers horizontal list from admin
                  _OffersSection(
                    ref: ref,
                    onOfferTap: _openOfferDetail,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
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

// ─── SEARCH CONTAINER ────────────────────────────────────────────────────────

class _SearchContainer extends StatelessWidget {
  final VoidCallback? onSearchTap;

  const _SearchContainer({this.onSearchTap});

  Future<void> _callEmergency() async {
    final uri = Uri(scheme: 'tel', path: '+94112345678');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

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
            Expanded(
              child: GestureDetector(
                onTap: onSearchTap,
                behavior: HitTestBehavior.opaque,
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
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
            GestureDetector(
              onTap: _callEmergency,
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SUGGESTIONS HEADER ──────────────────────────────────────────────────────

class _SuggestionsHeader extends StatelessWidget {
  final VoidCallback? onSeeAll;

  const _SuggestionsHeader({this.onSeeAll});

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
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Text(
              'See all',
              style: GoogleFonts.instrumentSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF5D2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SUGGESTIONS LIST ────────────────────────────────────────────────────────

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
      behavior: HitTestBehavior.opaque,
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
  final WidgetRef ref;
  final ValueChanged<OfferModel>? onOfferTap;

  const _OffersSection({required this.ref, this.onOfferTap});

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(activeOffersProvider);
    return offersAsync.when(
      loading: () => const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (offers) {
        if (offers.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Special Offers',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '${offers.length} active',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFFF5D2E),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: offers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) => _OfferCard(
                  offer: offers[index],
                  onTap: () => onOfferTap?.call(offers[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  final VoidCallback? onTap;

  const _OfferCard({required this.offer, this.onTap});

  String _badgeLabel() {
    if (offer.formattedDiscount.isNotEmpty) {
      return offer.formattedDiscount;
    }
    final type = offer.discountType?.toUpperCase();
    final val = offer.discountValue;
    if (type == 'PERCENTAGE' || type == 'PERCENT') {
      return '${val?.toStringAsFixed(0) ?? "0"}% OFF';
    }
    if (type == 'FIXED_AMOUNT' || type == 'FIXED') {
      return 'LKR ${val?.toStringAsFixed(0) ?? "0"} OFF';
    }
    return 'OFFER';
  }

  @override
  Widget build(BuildContext context) {
    final discount = _badgeLabel();
    final hasImageUrl = offer.imageUrl != null && offer.imageUrl!.isNotEmpty;
    final isExpired = !offer.isActive ||
        (offer.validUntil != null && offer.validUntil!.isBefore(DateTime.now()));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isExpired ? 0.6 : 1.0,
        child: Container(
          width: 290,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner with Image + Badge
              SizedBox(
                height: 105,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: const Color(0xFFFFF7F5)),
                    if (hasImageUrl)
                      Image.network(
                        offer.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackOfferImage(),
                      )
                    else
                      _fallbackOfferImage(),
                    // Badge overlay on top-left
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5D2E),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.15),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          discount,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.title,
                            style: GoogleFonts.instrumentSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          if (offer.subtitle != null &&
                              offer.subtitle!.isNotEmpty)
                            Text(
                              offer.subtitle!,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else if (offer.description != null &&
                              offer.description!.isNotEmpty)
                            Text(
                              offer.description!,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (offer.validUntil != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${isExpired ? "Expired" : "Valid until"} ${offer.validUntil!.month}/${offer.validUntil!.day}/${offer.validUntil!.year}',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Actions: Promo Code + Book now
                      Row(
                        children: [
                          if (offer.promoCode != null &&
                              offer.promoCode!.isNotEmpty) ...[
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: offer.promoCode!),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Copied ${offer.promoCode}'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7F5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFFE7DF),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          offer.promoCode!,
                                          style: GoogleFonts.instrumentSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: const Color(0xFFFF5D2E),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const PhosphorIcon(
                                        PhosphorIconsRegular.copy,
                                        size: 14,
                                        color: Color(0xFFFF5D2E),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          GestureDetector(
                            onTap: onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5D2E),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(255, 93, 46, 0.4),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Book now',
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _fallbackOfferImage() {
    return Image.asset(
      'assets/icons/Offer Image Container.png',
      fit: BoxFit.contain,
      alignment: Alignment.centerRight,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFFFE7DF),
        child: const Center(
          child: PhosphorIcon(
            PhosphorIconsBold.tag,
            size: 32,
            color: Color(0xFFFF5D2E),
          ),
        ),
      ),
    );
  }
}
