// ─── OFFER MODEL (maps to Spring Boot OfferResponse) ──────────────────────────

class OfferModel {
  final int id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? discountType;
  final double? discountValue;
  final double? discountPercentage;
  final double? discountAmount;
  final String? promoCode;
  final String? imageUrl;
  final String? category;
  final DateTime? validUntil;
  final bool isActive;

  const OfferModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.discountType,
    this.discountValue,
    this.discountPercentage,
    this.discountAmount,
    this.promoCode,
    this.imageUrl,
    this.category,
    this.validUntil,
    this.isActive = true,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] as num?)?.toInt() ?? 0;
    final discountType = (json['discountType'] ?? json['discount_type']) as String?;
    final rawDiscountValue = json['discountValue'] ?? json['discount_value'];
    final discountVal = rawDiscountValue != null ? (rawDiscountValue as num).toDouble() : null;

    double? discountPercentage = (json['discountPercentage'] ?? json['discount_percentage']) != null
        ? ((json['discountPercentage'] ?? json['discount_percentage']) as num).toDouble()
        : null;
    double? discountAmount = (json['discountAmount'] ?? json['discount_amount']) != null
        ? ((json['discountAmount'] ?? json['discount_amount']) as num).toDouble()
        : null;

    if (discountVal != null) {
      final typeUpper = discountType?.toUpperCase();
      if (typeUpper == 'PERCENTAGE') {
        discountPercentage ??= discountVal;
      } else if (typeUpper == 'FIXED' || typeUpper == 'AMOUNT') {
        discountAmount ??= discountVal;
      } else {
        if (discountVal <= 100) {
          discountPercentage ??= discountVal;
        } else {
          discountAmount ??= discountVal;
        }
      }
    }

    DateTime? validDate;
    final rawValid = json['validUntil'] ?? json['valid_until'];
    if (rawValid != null) {
      validDate = DateTime.tryParse(rawValid.toString());
    }

    final rawActive = json['isActive'] ?? json['is_active'];
    final isExpired = json['expired'] == true;
    final isActive = rawActive != null ? (rawActive as bool) : !isExpired;

    return OfferModel(
      id: rawId,
      title: (json['title'] as String?) ?? '',
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      discountType: discountType,
      discountValue: discountVal,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      promoCode: (json['promoCode'] ?? json['promo_code']) as String?,
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String?,
      category: (json['category'] as String?),
      validUntil: validDate,
      isActive: isActive,
    );
  }

  String get formattedDiscount {
    if (discountPercentage != null && discountPercentage! > 0) {
      return '${discountPercentage!.toStringAsFixed(0)}% OFF';
    }
    if (discountAmount != null && discountAmount! > 0) {
      return 'LKR ${discountAmount!.toStringAsFixed(0)} OFF';
    }
    if (discountValue != null && discountValue! > 0) {
      if (discountType?.toUpperCase() == 'FIXED' || discountValue! > 100) {
        return 'LKR ${discountValue!.toStringAsFixed(0)} OFF';
      }
      return '${discountValue!.toStringAsFixed(0)}% OFF';
    }
    if (subtitle != null && subtitle!.trim().isNotEmpty) {
      return subtitle!.trim();
    }
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (description != null) 'description': description,
      if (discountType != null) 'discountType': discountType,
      if (discountValue != null) 'discountValue': discountValue,
      if (discountPercentage != null) 'discountPercentage': discountPercentage,
      if (discountAmount != null) 'discountAmount': discountAmount,
      if (promoCode != null) 'promoCode': promoCode,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (category != null) 'category': category,
      if (validUntil != null) 'validUntil': validUntil!.toIso8601String(),
      'isActive': isActive,
    };
  }
}
