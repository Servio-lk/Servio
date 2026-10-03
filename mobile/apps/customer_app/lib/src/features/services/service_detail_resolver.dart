import 'package:shared_core/shared_core.dart';
import 'service_detail_screen.dart';

/// Asset image map for services
const Map<String, String> _serviceImageMap = {
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

/// Preset defaults if backend categories are still loading or offline
final Map<String, ServiceDetailData> _fallbackServiceDetails = {
  'Lube Services': const ServiceDetailData(
    title: 'Lube Services',
    basePrice: 'LKR 1,500.00',
    description:
        'Professional oil change with premium lubricants to protect your engine. '
        'Our certified technicians use only high-quality filters and perform a complimentary multi-point check.',
    imagePath: 'assets/service images/Lubricant Service.jpg',
    optionsTitle: 'Oil Selection',
    options: [
      ServiceOption(name: 'Standard/Conventional Oil', price: '+LKR 4,000'),
      ServiceOption(name: 'Synthetic Blend Oil', price: '+LKR 5,500'),
      ServiceOption(name: 'Full Synthetic Oil', price: '+LKR 7,000'),
    ],
  ),
  'Washing Packages': const ServiceDetailData(
    title: 'Washing Packages',
    basePrice: 'LKR 2,000.00',
    description:
        'Comprehensive exterior high-pressure foam wash, wheel dressing, '
        'interior vacuuming, and dashboard wiping for a fresh, clean drive.',
    imagePath: 'assets/service images/Washing Packages.jpg',
    optionsTitle: 'Package Type',
    options: [
      ServiceOption(name: 'Express Body Wash', price: '+LKR 1,500'),
      ServiceOption(name: 'Complete Wash & Underwash', price: '+LKR 3,000'),
      ServiceOption(name: 'Premium Ceramic Foam Wash', price: '+LKR 5,000'),
    ],
  ),
  'Exterior & Interior Detailing': const ServiceDetailData(
    title: 'Exterior & Interior Detailing',
    basePrice: 'LKR 8,500.00',
    description:
        'Deep interior steam cleaning, stain extraction, leather conditioning, '
        '3-stage exterior paint correction, cut & polish, and protective sealant.',
    imagePath: 'assets/service images/Exterior Detailing.jpg',
    optionsTitle: 'Detailing Level',
    options: [
      ServiceOption(name: 'Interior Deep Clean', price: '+LKR 6,000'),
      ServiceOption(name: 'Exterior Cut & Polish', price: '+LKR 8,000'),
      ServiceOption(name: 'Full Complete Detail', price: '+LKR 14,000'),
    ],
  ),
  'Engine Tune ups': const ServiceDetailData(
    title: 'Engine Tune ups',
    basePrice: 'LKR 2,500.00',
    description:
        'Keep your engine running at peak performance. Full inspection and adjustment '
        'of spark plugs, air filter, fuel injectors, throttle body, and diagnostic computer scan.',
    imagePath: 'assets/service images/Mechanical Repair.jpg',
    optionsTitle: 'Tune Up Package',
    options: [
      ServiceOption(name: 'Standard Tune Up & Scan', price: '+LKR 3,500'),
      ServiceOption(name: 'Comprehensive Electronic Tune Up', price: '+LKR 6,500'),
      ServiceOption(name: 'High Performance System Calibration', price: '+LKR 10,000'),
    ],
  ),
  'Tyre Services': const ServiceDetailData(
    title: 'Tyre Services',
    basePrice: 'LKR 1,200.00',
    description:
        'Professional tyre rotation, computerized wheel balancing, nitrogen filling, '
        'puncture repair, and tread inspection for safety and optimal fuel economy.',
    imagePath: 'assets/service images/Periodic Maintenance.jpg',
    optionsTitle: 'Tyre Options',
    options: [
      ServiceOption(name: 'Wheel Balancing (4 Wheels)', price: '+LKR 2,000'),
      ServiceOption(name: 'Tyre Rotation & Nitrogen Fill', price: '+LKR 1,500'),
    ],
  ),
  'Battery Services': const ServiceDetailData(
    title: 'Battery Services',
    basePrice: 'LKR 1,000.00',
    description:
        'State-of-the-art computerized battery health test, alternator charging rate verification, '
        'terminal cleaning, and replacement with genuine brands.',
    imagePath: 'assets/service images/Electrical & Electronic.jpg',
    optionsTitle: 'Battery Service',
    options: [
      ServiceOption(name: 'Health Check & Terminal Clean', price: 'Free'),
      ServiceOption(name: 'Battery Replacement & Setup', price: '+LKR 22,000'),
    ],
  ),
  'Inspection Reports': const ServiceDetailData(
    title: 'Inspection Reports',
    basePrice: 'LKR 3,500.00',
    description:
        '120-point comprehensive pre-purchase and roadworthiness inspection covering engine, '
        'transmission, brakes, suspension, chassis, and electronic diagnostic scan.',
    imagePath: 'assets/service images/Mulipoint Inspection Report.jpg',
    optionsTitle: 'Inspection Type',
    options: [
      ServiceOption(name: 'Pre-Purchase Vehicle Inspection', price: '+LKR 5,000'),
      ServiceOption(name: 'Periodic Health & Safety Check', price: '+LKR 2,500'),
    ],
  ),
};

/// Resolves a [ServiceDetailData] for the given service title, querying [categories] if available
/// or matching standard service presets.
ServiceDetailData resolveServiceDetail(
  String title, [
  List<ServiceCategoryModel>? categories,
]) {
  // 1. Try to find an exact or close match in loaded categories from backend
  if (categories != null && categories.isNotEmpty) {
    final queryLower = title.toLowerCase().trim();
    ServiceModel? matched;

    for (final cat in categories) {
      for (final s in cat.services) {
        final sNameLower = s.name.toLowerCase().trim();
        if (sNameLower == queryLower ||
            sNameLower.contains(queryLower) ||
            queryLower.contains(sNameLower)) {
          matched = s;
          break;
        }
      }
      if (matched != null) break;
    }

    if (matched != null) {
      final imagePath = _serviceImageMap[matched.name] ??
          _matchImageByKeywords(matched.name);
      return ServiceDetailData(
        title: matched.name,
        basePrice: matched.formattedBasePrice,
        description: matched.description.isNotEmpty
            ? matched.description
            : (_fallbackServiceDetails[matched.name]?.description ??
                'Professional automotive service tailored to your vehicle.'),
        imagePath: imagePath,
        optionsTitle: 'Pricing and Options',
        options: matched.options.isNotEmpty
            ? matched.options
                .map((o) => ServiceOption(name: o.name, price: o.formattedPrice))
                .toList()
            : (_fallbackServiceDetails[matched.name]?.options ?? const []),
      );
    }
  }

  // 2. Check predefined presets
  if (_fallbackServiceDetails.containsKey(title)) {
    return _fallbackServiceDetails[title]!;
  }

  for (final entry in _fallbackServiceDetails.entries) {
    if (entry.key.toLowerCase().contains(title.toLowerCase()) ||
        title.toLowerCase().contains(entry.key.toLowerCase())) {
      return entry.value;
    }
  }

  // 3. Fallback generic service detail
  return ServiceDetailData(
    title: title,
    basePrice: 'LKR 2,500.00',
    description:
        'Professional automotive maintenance and repair service delivered by certified Servio technicians.',
    imagePath: _matchImageByKeywords(title),
    optionsTitle: 'Service Options',
    options: const [
      ServiceOption(name: 'Standard Package', price: 'Included'),
      ServiceOption(name: 'Premium Package', price: '+LKR 2,500'),
    ],
  );
}

/// Resolves a [ServiceDetailData] for a promotional [OfferModel]
ServiceDetailData resolveOfferDetail(
  OfferModel offer, [
  List<ServiceCategoryModel>? categories,
]) {
  // If the offer matches a known service, use that as base
  final targetName = offer.category?.isNotEmpty == true
      ? offer.category!
      : offer.title;

  final baseDetail = resolveServiceDetail(targetName, categories);

  final description = offer.description?.isNotEmpty == true
      ? offer.description!
      : (offer.subtitle?.isNotEmpty == true
          ? offer.subtitle!
          : baseDetail.description);

  final imagePath = (offer.imageUrl != null && offer.imageUrl!.isNotEmpty)
      ? offer.imageUrl!
      : baseDetail.imagePath;

  return ServiceDetailData(
    title: offer.title,
    basePrice: baseDetail.basePrice,
    description: description,
    imagePath: imagePath,
    optionsTitle: baseDetail.optionsTitle,
    options: baseDetail.options,
    discountPercentage: offer.discountPercentage ??
        (offer.discountType?.toUpperCase() == 'PERCENTAGE'
            ? offer.discountValue
            : (offer.discountValue != null && offer.discountValue! <= 100
                ? offer.discountValue
                : null)),
    discountAmount: offer.discountAmount ??
        (offer.discountType?.toUpperCase() == 'FIXED' ||
                offer.discountType?.toUpperCase() == 'AMOUNT'
            ? offer.discountValue
            : (offer.discountValue != null && offer.discountValue! > 100
                ? offer.discountValue
                : null)),
    promoCode: offer.promoCode,
    discountLabel: offer.formattedDiscount.isNotEmpty ? offer.formattedDiscount : null,
  );
}

String _matchImageByKeywords(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('lube') || lower.contains('oil')) {
    return 'assets/service images/Lubricant Service.jpg';
  } else if (lower.contains('wash')) {
    return 'assets/service images/Washing Packages.jpg';
  } else if (lower.contains('detail') || lower.contains('polish')) {
    return 'assets/service images/Exterior Detailing.jpg';
  } else if (lower.contains('tune') || lower.contains('engine') || lower.contains('mechanic')) {
    return 'assets/service images/Mechanical Repair.jpg';
  } else if (lower.contains('tyre') || lower.contains('tire') || lower.contains('wheel')) {
    return 'assets/service images/Periodic Maintenance.jpg';
  } else if (lower.contains('battery') || lower.contains('electric')) {
    return 'assets/service images/Electrical & Electronic.jpg';
  } else if (lower.contains('inspect')) {
    return 'assets/service images/Mulipoint Inspection Report.jpg';
  } else if (lower.contains('paint')) {
    return 'assets/service images/Complete Paint.jpg';
  }
  return 'assets/service images/Lubricant Service.jpg';
}
