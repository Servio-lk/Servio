// ─── JOB TASK MODEL (maps to job_tasks and job_card_photos tables) ───

class JobTaskModel {
  final int id;
  final int? jobCardId;
  final int? appointmentId;
  final String? taskNumber;
  final String description;
  final String? instructions;
  final String status; // 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
  final int sequenceOrder;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? completedByName;
  final String? photoUrl;

  const JobTaskModel({
    required this.id,
    this.jobCardId,
    this.appointmentId,
    this.taskNumber,
    required this.description,
    this.instructions,
    this.status = 'PENDING',
    this.sequenceOrder = 0,
    this.startedAt,
    this.completedAt,
    this.completedByName,
    this.photoUrl,
  });

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  factory JobTaskModel.fromJson(Map<String, dynamic> json) {
    return JobTaskModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      jobCardId: (json['jobCardId'] ?? json['job_card_id'] as num?)?.toInt(),
      appointmentId: (json['appointmentId'] ?? json['appointment_id'] as num?)?.toInt(),
      taskNumber: (json['taskNumber'] ?? json['task_number']) as String?,
      description: (json['description'] as String?) ?? 'Task',
      instructions: json['instructions'] as String?,
      status: (json['status'] as String?) ?? 'PENDING',
      sequenceOrder: (json['sequenceOrder'] ?? json['sequence_order'] as num?)?.toInt() ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : (json['started_at'] != null ? DateTime.tryParse(json['started_at'].toString()) : null),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : (json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null),
      completedByName: (json['mechanicName'] ?? json['mechanic_name'] ?? json['completedByName']) as String?,
      photoUrl: (json['photoUrl'] ?? json['photo_url']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (jobCardId != null) 'jobCardId': jobCardId,
      if (appointmentId != null) 'appointmentId': appointmentId,
      if (taskNumber != null) 'taskNumber': taskNumber,
      'description': description,
      if (instructions != null) 'instructions': instructions,
      'status': status,
      'sequenceOrder': sequenceOrder,
      if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (completedByName != null) 'completedByName': completedByName,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  JobTaskModel copyWith({
    int? id,
    int? jobCardId,
    int? appointmentId,
    String? taskNumber,
    String? description,
    String? instructions,
    String? status,
    int? sequenceOrder,
    DateTime? startedAt,
    DateTime? completedAt,
    String? completedByName,
    String? photoUrl,
  }) {
    return JobTaskModel(
      id: id ?? this.id,
      jobCardId: jobCardId ?? this.jobCardId,
      appointmentId: appointmentId ?? this.appointmentId,
      taskNumber: taskNumber ?? this.taskNumber,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      status: status ?? this.status,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      completedByName: completedByName ?? this.completedByName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
