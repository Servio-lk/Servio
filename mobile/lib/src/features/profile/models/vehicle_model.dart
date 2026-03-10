// ─── VEHICLE MODEL (maps to Supabase 'vehicles' table) ──────────────────────

class VehicleModel {
  final int id;
  final String? profileId;
  final String make;
  final String model;
  final int? year;
  final String? licensePlate;
  final String? vin;
  final DateTime? createdAt;

  const VehicleModel({
    required this.id,
    this.profileId,
    required this.make,
    required this.model,
    this.year,
    this.licensePlate,
    this.vin,
    this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as int,
      profileId: json['profile_id'] as String?,
      make: (json['make'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      year: json['year'] as int?,
      licensePlate: json['license_plate'] as String?,
      vin: json['vin'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson(String profileId) {
    return {
      'profile_id': profileId,
      'make': make,
      'model': model,
      if (year != null) 'year': year,
      if (licensePlate != null) 'license_plate': licensePlate,
      if (vin != null && vin!.isNotEmpty) 'vin': vin,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'make': make,
      'model': model,
      if (year != null) 'year': year,
      'license_plate': licensePlate,
      if (vin != null) 'vin': vin,
    };
  }

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
    String? profileId,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    String? vin,
    DateTime? createdAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

