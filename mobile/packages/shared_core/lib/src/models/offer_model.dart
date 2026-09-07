// ─── OFFER MODEL (maps to Spring Boot OfferResponse) ──────────────────────────

class OfferModel {
  final int id;
  final String title;
  final String? subtitle;
  final String? description;
  final double? discountPercentage;
  final double? discountAmount;
  final String? promoCode;
  final String? imageUrl;
  final DateTime? validUntil;
  final bool isActive;

  const OfferModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.discountPercentage,
    this.discountAmount,
    this.promoCode,
    this.imageUrl,
    this.validUntil,
    this.isActive = true,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] as num?)?.toInt() ?? 0;
    final rawDiscount = json['discountPercentage'] ?? json['discount_percentage'];
    final rawAmount = json['discountAmount'] ?? json['discount_amount'];

    DateTime? validDate;
    final rawValid = json['validUntil'] ?? json['valid_until'];
    if (rawValid != null) {
      validDate = DateTime.tryParse(rawValid.toString());
    }

    return OfferModel(
      id: rawId,
      title: (json['title'] as String?) ?? '',
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      discountPercentage: rawDiscount != null ? (rawDiscount as num).toDouble() : null,
      discountAmount: rawAmount != null ? (rawAmount as num).toDouble() : null,
      promoCode: (json['promoCode'] ?? json['promo_code']) as String?,
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String?,
      validUntil: validDate,
      isActive: (json['isActive'] ?? json['is_active'] ?? true) as bool,
    );
  }

  String get formattedDiscount {
    if (discountPercentage != null && discountPercentage! > 0) {
      return '${discountPercentage!.toStringAsFixed(0)}% OFF';
    }
    if (discountAmount != null && discountAmount! > 0) {
      return 'LKR ${discountAmount!.toStringAsFixed(0)} OFF';
    }
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (description != null) 'description': description,
      if (discountPercentage != null) 'discountPercentage': discountPercentage,
      if (discountAmount != null) 'discountAmount': discountAmount,
      if (promoCode != null) 'promoCode': promoCode,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (validUntil != null) 'validUntil': validUntil!.toIso8601String(),
      'isActive': isActive,
    };
  }
}
