import 'appointment_model.dart';

// ─── STAFF MODEL (maps to mechanics, mechanic_staff_details, and mechanic_unavailable_blocks) ───

class MechanicStaffModel {
  final int id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? specialization;
  final int? experienceYears;
  final String? employeeCode;
  final String? profilePhotoUrl;
  final String attendanceStatus; // 'ON_DUTY', 'ON_LEAVE', 'OFF_DUTY'
  final String? leaveReason;
  final DateTime? leaveUntil;
  final List<AppointmentModel> assignedJobs;

  const MechanicStaffModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.specialization,
    this.experienceYears,
    this.employeeCode,
    this.profilePhotoUrl,
    this.attendanceStatus = 'ON_DUTY',
    this.leaveReason,
    this.leaveUntil,
    this.assignedJobs = const [],
  });

  bool get isOnDuty => attendanceStatus.toUpperCase() == 'ON_DUTY';
  bool get isOnLeave => attendanceStatus.toUpperCase() == 'ON_LEAVE';
  bool get isOffDuty => attendanceStatus.toUpperCase() == 'OFF_DUTY';

  factory MechanicStaffModel.fromJson(Map<String, dynamic> json, {List<AppointmentModel> jobs = const []}) {
    final status = (json['attendanceStatus'] ?? json['status'] ?? 'ON_DUTY').toString().toUpperCase();
    final normalizedStatus = status == 'AVAILABLE' || status == 'ACTIVE' || status == 'ON_DUTY'
        ? 'ON_DUTY'
        : (status == 'ON_LEAVE' || status == 'LEAVE' ? 'ON_LEAVE' : 'OFF_DUTY');

    return MechanicStaffModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: (json['fullName'] ?? json['full_name']) as String? ?? 'Mechanic',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      specialization: json['specialization'] as String?,
      experienceYears: (json['experienceYears'] ?? json['experience_years'] as num?)?.toInt(),
      employeeCode: (json['employeeCode'] ?? json['employee_code']) as String?,
      profilePhotoUrl: (json['profilePhotoUrl'] ?? json['profile_photo_url']) as String?,
      attendanceStatus: normalizedStatus,
      leaveReason: (json['leaveReason'] ?? json['leave_reason'] ?? json['rejection_reason']) as String?,
      leaveUntil: json['leaveUntil'] != null
          ? DateTime.tryParse(json['leaveUntil'].toString())
          : null,
      assignedJobs: jobs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (specialization != null) 'specialization': specialization,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (employeeCode != null) 'employeeCode': employeeCode,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      'attendanceStatus': attendanceStatus,
      if (leaveReason != null) 'leaveReason': leaveReason,
      if (leaveUntil != null) 'leaveUntil': leaveUntil!.toIso8601String(),
    };
  }

  MechanicStaffModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    String? specialization,
    int? experienceYears,
    String? employeeCode,
    String? profilePhotoUrl,
    String? attendanceStatus,
    String? leaveReason,
    DateTime? leaveUntil,
    List<AppointmentModel>? assignedJobs,
  }) {
    return MechanicStaffModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      experienceYears: experienceYears ?? this.experienceYears,
      employeeCode: employeeCode ?? this.employeeCode,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      leaveReason: leaveReason ?? this.leaveReason,
      leaveUntil: leaveUntil ?? this.leaveUntil,
      assignedJobs: assignedJobs ?? this.assignedJobs,
    );
  }
}
