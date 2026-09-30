// ─── INVENTORY MODEL (maps to inventory_items and stock_transactions tables) ───

class InventoryItemModel {
  final int id;
  final String? partNumber;
  final String name;
  final String category;
  final String unit;
  final double currentStock;
  final double minimumStock;
  final double? costPerUnit;
  final double? sellingPricePerUnit;
  final String? serviceType;
  final String? supplier;
  final String? location;

  const InventoryItemModel({
    required this.id,
    this.partNumber,
    required this.name,
    required this.category,
    this.unit = 'Unit',
    required this.currentStock,
    required this.minimumStock,
    this.costPerUnit,
    this.sellingPricePerUnit,
    this.serviceType,
    this.supplier,
    this.location,
  });

  bool get isLowStock => currentStock <= minimumStock;

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      partNumber: (json['partNumber'] ?? json['part_number']) as String?,
      name: (json['name'] as String?) ?? 'Unnamed Item',
      category: (json['category'] as String?) ?? 'GENERAL',
      unit: (json['unit'] as String?) ?? 'Unit',
      currentStock: (json['currentStock'] ?? json['current_stock'] ?? json['quantity'] as num?)?.toDouble() ?? 0.0,
      minimumStock: (json['minimumStock'] ?? json['minimum_stock'] ?? json['min_quantity'] as num?)?.toDouble() ?? 0.0,
      costPerUnit: (json['costPerUnit'] ?? json['cost_per_unit'] as num?)?.toDouble(),
      sellingPricePerUnit: (json['sellingPricePerUnit'] ?? json['selling_price_per_unit'] ?? json['unit_price'] as num?)?.toDouble(),
      serviceType: (json['serviceType'] ?? json['service_type']) as String?,
      supplier: json['supplier'] as String?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (partNumber != null) 'partNumber': partNumber,
      'name': name,
      'category': category,
      'unit': unit,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      if (costPerUnit != null) 'costPerUnit': costPerUnit,
      if (sellingPricePerUnit != null) 'sellingPricePerUnit': sellingPricePerUnit,
      if (serviceType != null) 'serviceType': serviceType,
      if (supplier != null) 'supplier': supplier,
      if (location != null) 'location': location,
    };
  }
}

class PartRequestModel {
  final int id;
  final String partName;
  final String? partNumber;
  final int quantity;
  final String urgency; // STANDARD, HIGH, URGENT
  final int? appointmentId;
  final String? vehicleDisplay;
  final String? notes;
  final String status; // PENDING, APPROVED, REJECTED, ORDERED
  final DateTime createdAt;

  const PartRequestModel({
    required this.id,
    required this.partName,
    this.partNumber,
    required this.quantity,
    this.urgency = 'STANDARD',
    this.appointmentId,
    this.vehicleDisplay,
    this.notes,
    this.status = 'PENDING',
    required this.createdAt,
  });

  factory PartRequestModel.fromJson(Map<String, dynamic> json) {
    return PartRequestModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      partName: (json['partName'] ?? json['part_name'] as String?) ?? 'Part Request',
      partNumber: (json['partNumber'] ?? json['part_number']) as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      urgency: (json['urgency'] as String?) ?? 'STANDARD',
      appointmentId: (json['appointmentId'] ?? json['appointment_id'] as num?)?.toInt(),
      vehicleDisplay: (json['vehicleDisplay'] ?? json['vehicle_display']) as String?,
      notes: json['notes'] as String?,
      status: (json['status'] as String?) ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partName': partName,
      if (partNumber != null) 'partNumber': partNumber,
      'quantity': quantity,
      'urgency': urgency,
      if (appointmentId != null) 'appointmentId': appointmentId,
      if (vehicleDisplay != null) 'vehicleDisplay': vehicleDisplay,
      if (notes != null) 'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
