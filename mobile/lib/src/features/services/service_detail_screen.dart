import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── SERVICE DETAIL DATA MODEL ───────────────────────────────────────────────

class ServiceDetailData {
  final String title;
  final String basePrice;
  final String description;
  final String? imagePath; // local asset path, null = placeholder
  final String optionsTitle;
  final List<ServiceOption> options;

  const ServiceDetailData({
    required this.title,
    required this.basePrice,
    required this.description,
    this.imagePath,
    this.optionsTitle = 'Pricing and Options',
    this.options = const [],
  });
}

class ServiceOption {
  final String name;
  final String price;

  const ServiceOption({required this.name, required this.price});
}

// ─── REUSABLE SERVICE DETAIL SCREEN ─────────────────────────────────────────

class ServiceDetailScreen extends StatefulWidget {
  final ServiceDetailData data;

  const ServiceDetailScreen({super.key, required this.data});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  int _selectedOptionIndex = 0;
  bool _showFullDescription = false;

  // Calculate total price (base + selected option add-on)
  String get _totalPrice {
    final options = widget.data.options;
    if (options.isEmpty) return widget.data.basePrice;
    final base = _parseLKR(widget.data.basePrice);
    final addon = _parseLKR(options[_selectedOptionIndex].price);
    if (base == null || addon == null) return widget.data.basePrice;
    final total = base + addon;
    return 'LKR ${_formatNumber(total)}';
  }

  // Returns null if the price string is non-numeric (e.g. 'Free consultation')
  int? _parseLKR(String price) {
    // Remove currency prefix, plus sign, and decimal part, then parse
    // e.g. 'LKR 1,500.00' → '1500', '+LKR 4,000' → '4000'
    final withoutDecimal = price.contains('.') ? price.substring(0, price.lastIndexOf('.')) : price;
    final digitsOnly = withoutDecimal.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return null;
    return int.tryParse(digitsOnly);
  }

  String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()}.00';
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
        child: Column(
          children: [
            // ── Hero Image with back button ──
            _ServiceImageSection(imagePath: widget.data.imagePath),

            // ── Scrollable body ──
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      _DescriptionSection(
                        title: widget.data.title,
                        basePrice: widget.data.basePrice,
                        description: widget.data.description,
                        showFull: _showFullDescription,
                        onToggle: () => setState(
                            () => _showFullDescription = !_showFullDescription),
                      ),

                      // Oil / Options section (only if options exist)
                      if (widget.data.options.isNotEmpty) ...[
                        const _SectionDivider(),
                        _OptionsSection(
                          title: widget.data.optionsTitle,
                          options: widget.data.options,
                          selectedIndex: _selectedOptionIndex,
                          onSelectionChanged: (i) =>
                              setState(() => _selectedOptionIndex = i),
                        ),
                      ],

                      const _SectionDivider(),

                      // Special Instructions
                      const _SpecialInstructionsSection(),

                      // Extra bottom space so content clears the sticky button
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // ── Sticky bottom button ──
            _BottomButtonSection(totalPrice: _totalPrice),
          ],
        ),
      ),
    );
  }
}

// ─── SERVICE IMAGE SECTION ───────────────────────────────────────────────────

class _ServiceImageSection extends StatelessWidget {
  final String? imagePath;
  const _ServiceImageSection({this.imagePath});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 375 / 185,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          imagePath != null
              ? Image.asset(
                  imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _placeholder(),
                )
              : _placeholder(),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: PhosphorIcon(
                    PhosphorIconsBold.arrowLeft,
                    size: 24,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFFFE7DF),
        child: const Center(
          child: PhosphorIcon(
            PhosphorIconsBold.wrench,
            size: 48,
            color: Color(0xFFFF5D2E),
          ),
        ),
      );
}

// ─── DESCRIPTION SECTION ─────────────────────────────────────────────────────

class _DescriptionSection extends StatelessWidget {
  final String title;
  final String basePrice;
  final String description;
  final bool showFull;
  final VoidCallback onToggle;

  const _DescriptionSection({
    required this.title,
    required this.basePrice,
    required this.description,
    required this.showFull,
    required this.onToggle,
  });

  static const int _previewLength = 120;

  @override
  Widget build(BuildContext context) {
    final isLong = description.length > _previewLength;
    final displayText =
        (!showFull && isLong) ? '${description.substring(0, _previewLength)}…' : description;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.instrumentSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            basePrice,
            style: GoogleFonts.instrumentSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4B4B4B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayText,
            style: GoogleFonts.instrumentSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          if (isLong) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onToggle,
              child: Text(
                showFull ? 'Show less' : 'Show more',
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
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
    return Container(
      height: 8,
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.black.withValues(alpha: 0.06),
    );
  }
}

// ─── OPTIONS SECTION ─────────────────────────────────────────────────────────

class _OptionsSection extends StatelessWidget {
  final String title;
  final List<ServiceOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelectionChanged;

  const _OptionsSection({
    required this.title,
    required this.options,
    required this.selectedIndex,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.instrumentSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: List.generate(options.length, (index) {
                return Column(
                  children: [
                    if (index > 0)
                      Container(
                        height: 1,
                        color: Colors.black.withValues(alpha: 0.04),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    _OptionItem(
                      option: options[index],
                      isSelected: selectedIndex == index,
                      onTap: () => onSelectionChanged(index),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OPTION ITEM ─────────────────────────────────────────────────────────────

class _OptionItem extends StatelessWidget {
  final ServiceOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionItem({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.price,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: PhosphorIcon(
                  isSelected
                      ? PhosphorIconsRegular.checkSquare
                      : PhosphorIconsRegular.square,
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
    );
  }
}

// ─── SPECIAL INSTRUCTIONS SECTION ────────────────────────────────────────────

class _SpecialInstructionsSection extends StatelessWidget {
  const _SpecialInstructionsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Special Instructions',
            style: GoogleFonts.instrumentSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 107,
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
            padding: const EdgeInsets.all(8),
            child: TextField(
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Add a note',
                hintStyle: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4B4B4B),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BOTTOM BUTTON SECTION ───────────────────────────────────────────────────

class _BottomButtonSection extends StatelessWidget {
  final String totalPrice;
  const _BottomButtonSection({required this.totalPrice});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
          child: GestureDetector(
            onTap: () {
              // TODO: navigate to booking flow
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Book now',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    totalPrice,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
