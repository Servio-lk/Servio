// ─── SERVICE MODELS (maps to Supabase tables) ───────────────────────────────

class ServiceCategoryModel {
  final int id;
  final String name;
  final String description;
  final int displayOrder;
  final List<ServiceModel> services;

  const ServiceCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.displayOrder,
    required this.services,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'] as List<dynamic>? ?? [];
    return ServiceCategoryModel(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      displayOrder: (json['display_order'] as int?) ?? 0,
      services: rawServices
          .map((s) => ServiceModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ServiceModel {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final double? basePrice;
  final String? priceRange;
  final int? durationMinutes;
  final String? imageUrl;
  final bool isFeatured;
  final List<ServiceOptionModel> options;

  const ServiceModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    this.basePrice,
    this.priceRange,
    this.durationMinutes,
    this.imageUrl,
    required this.isFeatured,
    required this.options,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['service_options'] as List<dynamic>? ?? [];
    final bp = json['base_price'];
    return ServiceModel(
      id: json['id'] as int,
      categoryId: (json['category_id'] as int?) ?? 0,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      basePrice: bp != null ? (bp as num).toDouble() : null,
      priceRange: json['price_range'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      imageUrl: json['image_url'] as String?,
      isFeatured: (json['is_featured'] as bool?) ?? false,
      options: rawOptions
          .map((o) => ServiceOptionModel.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Format base price as "LKR X,XXX.00" or fall back to priceRange
  String get formattedBasePrice {
    if (basePrice != null && basePrice! > 0) {
      return 'LKR ${_formatNumber(basePrice!.toInt())}.00';
    }
    if (priceRange != null && priceRange!.isNotEmpty) return priceRange!;
    return 'Price varies';
  }
}

class ServiceOptionModel {
  final int id;
  final String name;
  final String description;
  final double priceAdjustment;
  final bool isDefault;
  final int displayOrder;

  const ServiceOptionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.priceAdjustment,
    required this.isDefault,
    required this.displayOrder,
  });

  factory ServiceOptionModel.fromJson(Map<String, dynamic> json) {
    final pa = json['price_adjustment'];
    return ServiceOptionModel(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      priceAdjustment: pa != null ? (pa as num).toDouble() : 0,
      isDefault: (json['is_default'] as bool?) ?? false,
      displayOrder: (json['display_order'] as int?) ?? 0,
    );
  }

  /// Format as "+LKR X,XXX"
  String get formattedPrice {
    if (priceAdjustment == 0) return 'Included';
    final prefix = priceAdjustment >= 0 ? '+LKR ' : '-LKR ';
    return '$prefix${_formatNumber(priceAdjustment.toInt().abs())}';
  }
}

// ─── Shared number formatter ─────────────────────────────────────────────────

String _formatNumber(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
