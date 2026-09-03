// ─── REPAIR MODELS (maps to Spring Boot Repair DTOs) ─────────────────────────

class RepairJobModel {
  final int id;
  final int appointmentId;
  final int? vehicleId;
  final String? userId;
  final String title;
  final String? description;
  final String status;
  final String? priority;
  final double? estimatedDurationHours;
  final double? actualDurationHours;
  final double? estimatedCost;
  final double? actualCost;
  final double? partsCost;
  final double? laborCost;
  final int? assignedTechnicianId;
  final String? assignedTechnicianName;
  final DateTime? startDate;
  final DateTime? completionDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RepairJobModel({
    required this.id,
    required this.appointmentId,
    this.vehicleId,
    this.userId,
    required this.title,
    this.description,
    required this.status,
    this.priority,
    this.estimatedDurationHours,
    this.actualDurationHours,
    this.estimatedCost,
    this.actualCost,
    this.partsCost,
    this.laborCost,
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    this.startDate,
    this.completionDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory RepairJobModel.fromJson(Map<String, dynamic> json) {
    final rawAppId = json['appointmentId'] ?? json['appointment_id'];
    final rawEstDur = json['estimatedDurationHours'] ?? json['estimated_duration_hours'];
    final rawActDur = json['actualDurationHours'] ?? json['actual_duration_hours'];
    final rawEstCost = json['estimatedCost'] ?? json['estimated_cost'];
    final rawActCost = json['actualCost'] ?? json['actual_cost'];
    final rawPartsCost = json['partsCost'] ?? json['parts_cost'];
    final rawLaborCost = json['laborCost'] ?? json['labor_cost'];
    final rawTechId = json['assignedTechnicianId'] ?? json['assigned_technician_id'];
    final rawTechName = json['assignedTechnicianName'] ?? json['technicianName'];

    DateTime? parseDate(dynamic v) => v != null ? DateTime.tryParse(v.toString()) : null;

    return RepairJobModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      appointmentId: (rawAppId as num?)?.toInt() ?? 0,
      vehicleId: (json['vehicleId'] ?? json['vehicle_id'] as num?)?.toInt(),
      userId: (json['userId'] ?? json['user_id'])?.toString(),
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      status: (json['status'] as String?) ?? 'PENDING',
      priority: json['priority'] as String?,
      estimatedDurationHours: rawEstDur != null ? (rawEstDur as num).toDouble() : null,
      actualDurationHours: rawActDur != null ? (rawActDur as num).toDouble() : null,
      estimatedCost: rawEstCost != null ? (rawEstCost as num).toDouble() : null,
      actualCost: rawActCost != null ? (rawActCost as num).toDouble() : null,
      partsCost: rawPartsCost != null ? (rawPartsCost as num).toDouble() : null,
      laborCost: rawLaborCost != null ? (rawLaborCost as num).toDouble() : null,
      assignedTechnicianId: rawTechId != null ? (rawTechId as num).toInt() : null,
      assignedTechnicianName: rawTechName as String?,
      startDate: parseDate(json['startDate'] ?? json['start_date']),
      completionDate: parseDate(json['completionDate'] ?? json['completion_date']),
      notes: json['notes'] as String?,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      if (vehicleId != null) 'vehicleId': vehicleId,
      if (userId != null) 'userId': userId,
      'title': title,
      if (description != null) 'description': description,
      'status': status,
      if (priority != null) 'priority': priority,
      if (estimatedDurationHours != null) 'estimatedDurationHours': estimatedDurationHours,
      if (actualDurationHours != null) 'actualDurationHours': actualDurationHours,
      if (estimatedCost != null) 'estimatedCost': estimatedCost,
      if (actualCost != null) 'actualCost': actualCost,
      if (partsCost != null) 'partsCost': partsCost,
      if (laborCost != null) 'laborCost': laborCost,
      if (assignedTechnicianId != null) 'assignedTechnicianId': assignedTechnicianId,
      if (assignedTechnicianName != null) 'assignedTechnicianName': assignedTechnicianName,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (completionDate != null) 'completionDate': completionDate!.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

class RepairConversationModel {
  final int id;
  final int? conversationId;
  final int? repairId;
  final int? appointmentId;
  final String? realtimeChannel;
  final bool isReadOnly;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RepairConversationModel({
    required this.id,
    this.conversationId,
    this.repairId,
    this.appointmentId,
    this.realtimeChannel,
    this.isReadOnly = false,
    this.createdAt,
    this.updatedAt,
  });

  factory RepairConversationModel.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] as num?)?.toInt() ?? 0;
    final convId = (json['conversationId'] ?? json['conversation_id'] ?? rawId) as num?;
    final repId = (json['repairId'] ?? json['repair_id'] ?? json['repairJobId'] ?? json['repair_job_id']) as num?;
    final appId = (json['appointmentId'] ?? json['appointment_id']) as num?;

    DateTime? parseDate(dynamic v) => v != null ? DateTime.tryParse(v.toString()) : null;

    return RepairConversationModel(
      id: rawId,
      conversationId: convId?.toInt(),
      repairId: repId?.toInt(),
      appointmentId: appId?.toInt(),
      realtimeChannel: (json['realtimeChannel'] ?? json['realtime_channel']) as String?,
      isReadOnly: (json['isReadOnly'] ?? json['is_read_only'] ?? false) as bool,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  int get repairJobId => repairId ?? id;
  bool get isOpen => !isReadOnly;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (conversationId != null) 'conversationId': conversationId,
      if (repairId != null) 'repairId': repairId,
      if (appointmentId != null) 'appointmentId': appointmentId,
      if (realtimeChannel != null) 'realtimeChannel': realtimeChannel,
      'isReadOnly': isReadOnly,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

class RepairMessageModel {
  final int id;
  final int? conversationId;
  final int? repairId;
  final String? senderId;
  final String senderRole;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  const RepairMessageModel({
    required this.id,
    this.conversationId,
    this.repairId,
    this.senderId,
    required this.senderRole,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  factory RepairMessageModel.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] as num?)?.toInt() ?? 0;
    final convId = (json['conversationId'] ?? json['conversation_id']) as num?;
    final repId = (json['repairId'] ?? json['repair_id'] ?? json['repairJobId'] ?? json['repair_job_id']) as num?;
    final sId = (json['senderId'] ?? json['sender_id'])?.toString();
    final role = (json['senderRole'] ?? json['sender_role'] ?? 'CUSTOMER').toString();
    final msgBody = (json['body'] as String?) ?? '';

    DateTime createdAtVal;
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    if (rawCreatedAt != null) {
      createdAtVal = DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now();
    } else {
      createdAtVal = DateTime.now();
    }

    DateTime? readAtVal;
    final rawReadAt = json['readAt'] ?? json['read_at'];
    if (rawReadAt != null) {
      readAtVal = DateTime.tryParse(rawReadAt.toString());
    }

    return RepairMessageModel(
      id: rawId,
      conversationId: convId?.toInt(),
      repairId: repId?.toInt(),
      senderId: sId,
      senderRole: role,
      body: msgBody,
      createdAt: createdAtVal,
      readAt: readAtVal,
    );
  }

  int get repairJobId => repairId ?? 0;
  bool get isMechanic => senderRole.toUpperCase() == 'MECHANIC';
  bool get isAdmin => senderRole.toUpperCase() == 'ADMIN';
  bool get isCustomer => senderRole.toUpperCase() == 'CUSTOMER';
  bool get isMechanicSender => isMechanic;
  bool get isAdminSender => isAdmin;
  bool get isCustomerSender => isCustomer;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (conversationId != null) 'conversationId': conversationId,
      if (repairId != null) 'repairId': repairId,
      if (senderId != null) 'senderId': senderId,
      'senderRole': senderRole,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
    };
  }
}
