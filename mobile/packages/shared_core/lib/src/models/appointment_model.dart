// ─── APPOINTMENT MODEL (maps to Supabase 'appointments' table) ───────────────

class AppointmentModel {
  final int id;
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
  final DateTime createdAt;
  final String? assignedMechanicName;

  const AppointmentModel({
    required this.id,
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
    required this.createdAt,
    this.assignedMechanicName,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    // Vehicle may be nested from Supabase join
    final vehicle = json['vehicles'] as Map<String, dynamic>?;

    return AppointmentModel(
      id: json['id'] as int,
      profileId: json['profile_id'] as String?,
      vehicleId: json['vehicle_id'] as int?,
      vehicleMake: vehicle?['make'] as String?,
      vehicleModel: vehicle?['model'] as String?,
      vehicleYear: vehicle?['year'] as int?,
      licensePlate: vehicle?['license_plate'] as String?,
      serviceType: json['service_type'] as String,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      status: (json['status'] as String?) ?? 'PENDING',
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      estimatedCost: json['estimated_cost'] != null
          ? (json['estimated_cost'] as num).toDouble()
          : 0,
      actualCost: json['actual_cost'] != null
          ? (json['actual_cost'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      assignedMechanicName: json['assignedMechanicName'] as String?,
    );
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

  String get statusLabel => switch (status) {
    'CONFIRMED' => 'Confirmed',
    'IN_PROGRESS' => 'In Progress',
    'COMPLETED' => 'Completed',
    'CANCELLED' => 'Cancelled',
    _ => 'Pending',
  };
}
