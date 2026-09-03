// ─── SERVICE MODELS (maps to Spring Boot catalog REST schemas) ─────────────────

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
    final rawServices = (json['services'] ?? json['serviceList']) as List<dynamic>? ?? [];
    return ServiceCategoryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      displayOrder: (json['displayOrder'] ?? json['display_order'] ?? 0) as int,
      services: rawServices
          .map((s) => ServiceModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'displayOrder': displayOrder,
      'services': services.map((s) => s.toJson()).toList(),
    };
  }
}

class ServiceModel {
  final int id;
  final int categoryId;
  final String? categoryName;
  final String name;
  final String description;
  final double? basePrice;
  final String? priceRange;
  final int? durationMinutes;
  final String? imageUrl;
  final String? iconUrl;
  final bool warrantyIncluded;
  final bool isFeatured;
  final List<String> includedItems;
  final List<ServiceOptionModel> options;

  const ServiceModel({
    required this.id,
    required this.categoryId,
    this.categoryName,
    required this.name,
    required this.description,
    this.basePrice,
    this.priceRange,
    this.durationMinutes,
    this.imageUrl,
    this.iconUrl,
    this.warrantyIncluded = false,
    required this.isFeatured,
    this.includedItems = const [],
    required this.options,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] ?? json['service_options'] ?? json['serviceOptions']) as List<dynamic>? ?? [];
    final bp = json['basePrice'] ?? json['base_price'];
    final rawIncluded = json['includedItems'] ?? json['included_items'];
    final List<String> includedList = rawIncluded is List
        ? rawIncluded.map((e) => e.toString()).toList()
        : const [];

    return ServiceModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      categoryId: (json['categoryId'] ?? json['category_id'] ?? 0) as int,
      categoryName: (json['categoryName'] ?? json['category_name']) as String?,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      basePrice: bp != null ? (bp as num).toDouble() : null,
      priceRange: (json['priceRange'] ?? json['price_range']) as String?,
      durationMinutes: (json['durationMinutes'] ?? json['duration_minutes'] as num?)?.toInt(),
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String?,
      iconUrl: (json['iconUrl'] ?? json['icon_url']) as String?,
      warrantyIncluded: (json['warrantyIncluded'] ?? json['warranty_included'] ?? false) as bool,
      isFeatured: (json['isFeatured'] ?? json['is_featured'] ?? false) as bool,
      includedItems: includedList,
      options: rawOptions
          .map((o) => ServiceOptionModel.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      if (categoryName != null) 'categoryName': categoryName,
      'name': name,
      'description': description,
      if (basePrice != null) 'basePrice': basePrice,
      if (priceRange != null) 'priceRange': priceRange,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (iconUrl != null) 'iconUrl': iconUrl,
      'warrantyIncluded': warrantyIncluded,
      'isFeatured': isFeatured,
      'includedItems': includedItems,
      'options': options.map((o) => o.toJson()).toList(),
    };
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
    final pa = json['priceAdjustment'] ?? json['price_adjustment'];
    return ServiceOptionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      priceAdjustment: pa != null ? (pa as num).toDouble() : 0.0,
      isDefault: (json['isDefault'] ?? json['is_default'] ?? false) as bool,
      displayOrder: (json['displayOrder'] ?? json['display_order'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'priceAdjustment': priceAdjustment,
      'isDefault': isDefault,
      'displayOrder': displayOrder,
    };
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
