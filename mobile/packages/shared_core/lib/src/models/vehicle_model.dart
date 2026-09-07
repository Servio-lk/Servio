// ─── VEHICLE MODEL (maps to Spring Boot VehicleDto / vehicles table) ──────────

class VehicleModel {
  final int id;
  final String? userId;
  final String? profileId;
  final String? ownerName;
  final String make;
  final String model;
  final int? year;
  final String? licensePlate;
  final String? vin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VehicleModel({
    required this.id,
    this.userId,
    this.profileId,
    this.ownerName,
    required this.make,
    required this.model,
    this.year,
    this.licensePlate,
    this.vin,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    final parsedId = (json['id'] as num?)?.toInt() ?? 0;
    final userVal = (json['userId'] ?? json['user_id'] ?? json['profileId'] ?? json['profile_id'])?.toString();
    final ownerVal = (json['ownerName'] ?? json['owner_name']) as String?;
    final makeVal = (json['make'] as String?) ?? '';
    final modelVal = (json['model'] as String?) ?? '';
    final yearVal = (json['year'] as num?)?.toInt();
    final licensePlateVal = (json['licensePlate'] ?? json['license_plate']) as String?;
    final vinVal = json['vin'] as String?;

    DateTime? createdAtVal;
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    if (rawCreatedAt != null) {
      createdAtVal = DateTime.tryParse(rawCreatedAt.toString());
    }

    DateTime? updatedAtVal;
    final rawUpdatedAt = json['updatedAt'] ?? json['updated_at'];
    if (rawUpdatedAt != null) {
      updatedAtVal = DateTime.tryParse(rawUpdatedAt.toString());
    }

    return VehicleModel(
      id: parsedId,
      userId: userVal,
      profileId: userVal,
      ownerName: ownerVal,
      make: makeVal,
      model: modelVal,
      year: yearVal,
      licensePlate: licensePlateVal,
      vin: vinVal,
      createdAt: createdAtVal,
      updatedAt: updatedAtVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'userId': userId,
      if (profileId != null) 'profileId': profileId,
      if (ownerName != null) 'ownerName': ownerName,
      'make': make,
      'model': model,
      if (year != null) 'year': year,
      if (licensePlate != null) 'licensePlate': licensePlate,
      if (vin != null) 'vin': vin,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateRequestJson() {
    return {
      'make': make,
      'model': model,
      if (year != null) 'year': year,
      if (licensePlate != null && licensePlate!.isNotEmpty) 'licensePlate': licensePlate,
      if (vin != null && vin!.isNotEmpty) 'vin': vin,
    };
  }

  Map<String, dynamic> toUpdateRequestJson() {
    return {
      'make': make,
      'model': model,
      if (year != null) 'year': year,
      if (licensePlate != null) 'licensePlate': licensePlate,
      if (vin != null) 'vin': vin,
    };
  }

  // Backwards compatibility helpers
  Map<String, dynamic> toRequestMap() => toCreateRequestJson();
  Map<String, dynamic> toInsertJson(String profileId) => toCreateRequestJson();
  Map<String, dynamic> toUpdateJson() => toUpdateRequestJson();

  String get displayName => '$make $model';

  String get detailLine {
    final parts = <String>[];
    if (licensePlate != null && licensePlate!.isNotEmpty) {
      parts.add(licensePlate!);
    }
    if (year != null) parts.add(year.toString());
    return parts.join(' · ');
  }

  VehicleModel copyWith({
    int? id,
    String? userId,
    String? profileId,
    String? ownerName,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    String? vin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      profileId: profileId ?? this.profileId,
      ownerName: ownerName ?? this.ownerName,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
