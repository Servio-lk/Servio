// ─── APPOINTMENT MODEL (maps to Spring Boot AppointmentDto / appointments table) ───

class AppointmentModel {
  final int id;
  final String? userId;
  final String? profileId;
  final int? vehicleId;
  final String? vehicleMake;
  final String? vehicleModel;
  final int? vehicleYear;
  final String? licensePlate;
  final String serviceType;
  final DateTime appointmentDate;
  final String status; // PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED
  final String? location;
  final String? notes;
  final double estimatedCost;
  final double? actualCost;
  final double? paidAmount;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? assignedMechanicName;

  const AppointmentModel({
    required this.id,
    this.userId,
    this.profileId,
    this.vehicleId,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    this.licensePlate,
    required this.serviceType,
    required this.appointmentDate,
    required this.status,
    this.location,
    this.notes,
    required this.estimatedCost,
    this.actualCost,
    this.paidAmount,
    this.paymentMethod,
    required this.createdAt,
    this.updatedAt,
    this.assignedMechanicName,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicles'] as Map<String, dynamic>?;

    final parsedId = (json['id'] as num?)?.toInt() ?? 0;
    final userVal = (json['userId'] ?? json['user_id'] ?? json['profileId'] ?? json['profile_id'])?.toString();
    final vehicleIdVal = (json['vehicleId'] ?? json['vehicle_id']) as num?;
    
    final vehicleMakeVal = (json['vehicleMake'] ?? vehicle?['make']) as String?;
    final vehicleModelVal = (json['vehicleModel'] ?? vehicle?['model']) as String?;
    final vehicleYearVal = (json['vehicleYear'] ?? vehicle?['year']) as num?;
    final licensePlateVal = (json['licensePlate'] ?? json['license_plate'] ?? vehicle?['license_plate']) as String?;

    final serviceTypeVal = (json['serviceType'] ?? json['service_type'] ?? '') as String;

    DateTime appointmentDateVal;
    final rawAppDate = json['appointmentDate'] ?? json['appointment_date'];
    if (rawAppDate != null) {
      appointmentDateVal = DateTime.parse(rawAppDate.toString());
    } else {
      appointmentDateVal = DateTime.now();
    }

    final statusVal = (json['status'] as String?) ?? 'PENDING';
    final locationVal = json['location'] as String?;
    final notesVal = json['notes'] as String?;

    final rawEstCost = json['estimatedCost'] ?? json['estimated_cost'];
    final estCostVal = rawEstCost != null ? (rawEstCost as num).toDouble() : 0.0;

    final rawActCost = json['actualCost'] ?? json['actual_cost'];
    final actCostVal = rawActCost != null ? (rawActCost as num).toDouble() : null;

    final rawPaidAmount = json['paidAmount'] ?? json['paid_amount'];
    final paidAmountVal = rawPaidAmount != null ? (rawPaidAmount as num).toDouble() : null;

    final paymentMethodVal = (json['paymentMethod'] ?? json['payment_method']) as String?;

    DateTime createdAtVal;
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    if (rawCreatedAt != null) {
      createdAtVal = DateTime.parse(rawCreatedAt.toString());
    } else {
      createdAtVal = DateTime.now();
    }

    DateTime? updatedAtVal;
    final rawUpdatedAt = json['updatedAt'] ?? json['updated_at'];
    if (rawUpdatedAt != null) {
      updatedAtVal = DateTime.parse(rawUpdatedAt.toString());
    }

    final mechNameVal = (json['assignedMechanicName'] ?? json['technicianName']) as String?;

    return AppointmentModel(
      id: parsedId,
      userId: userVal,
      profileId: userVal,
      vehicleId: vehicleIdVal?.toInt(),
      vehicleMake: vehicleMakeVal,
      vehicleModel: vehicleModelVal,
      vehicleYear: vehicleYearVal?.toInt(),
      licensePlate: licensePlateVal,
      serviceType: serviceTypeVal,
      appointmentDate: appointmentDateVal,
      status: statusVal,
      location: locationVal,
      notes: notesVal,
      estimatedCost: estCostVal,
      actualCost: actCostVal,
      paidAmount: paidAmountVal,
      paymentMethod: paymentMethodVal,
      createdAt: createdAtVal,
      updatedAt: updatedAtVal,
      assignedMechanicName: mechNameVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'userId': userId,
      if (profileId != null) 'profileId': profileId,
      if (vehicleId != null) 'vehicleId': vehicleId,
      if (vehicleMake != null) 'vehicleMake': vehicleMake,
      if (vehicleModel != null) 'vehicleModel': vehicleModel,
      if (vehicleYear != null) 'vehicleYear': vehicleYear,
      if (licensePlate != null) 'licensePlate': licensePlate,
      'serviceType': serviceType,
      'appointmentDate': appointmentDate.toIso8601String(),
      'status': status,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      'estimatedCost': estimatedCost,
      if (actualCost != null) 'actualCost': actualCost,
      if (paidAmount != null) 'paidAmount': paidAmount,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (assignedMechanicName != null) 'assignedMechanicName': assignedMechanicName,
    };
  }

  Map<String, dynamic> toCreateRequestJson() {
    return {
      if (vehicleId != null) 'vehicleId': vehicleId,
      'serviceType': serviceType,
      'appointmentDate': appointmentDate.toIso8601String(),
      if (location != null && location!.isNotEmpty) 'location': location,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'estimatedCost': estimatedCost,
    };
  }

  bool get isUpcoming =>
      appointmentDate.isAfter(DateTime.now()) &&
      status != 'CANCELLED' &&
      status != 'COMPLETED';

  String get vehicleDisplay {
    if (vehicleMake != null && vehicleModel != null) {
      final year = vehicleYear;
      return '$vehicleMake $vehicleModel${year != null ? ' $year' : ''}';
    }
    return 'Vehicle';
  }

  String get plateDisplay {
    final plate = licensePlate?.trim();
    return plate == null || plate.isEmpty ? 'JOB-$id' : plate.toUpperCase();
  }

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[appointmentDate.month - 1]} ${appointmentDate.day}';
  }

  String get formattedTime {
    final h = appointmentDate.hour;
    final m = appointmentDate.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'P.M.' : 'A.M.';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  String get formattedCost {
    final cost = actualCost ?? estimatedCost;
    final n = cost.toInt();
    final s = n.toString();
    final buf = StringBuffer('LKR ');
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String get statusLabel => switch (status.toUpperCase()) {
    'CONFIRMED' => 'Confirmed',
    'IN_PROGRESS' => 'In Progress',
    'COMPLETED' => 'Completed',
    'CANCELLED' => 'Cancelled',
    _ => 'Pending',
  };
}
