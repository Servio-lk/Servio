import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

class WorkerRepository {
  final ApiClient _apiClient;

  WorkerRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetches all active appointments across the shop for the supervisor/mechanic dashboard via Spring Boot REST API.
  Future<List<AppointmentModel>> getActiveAppointments() async {
    try {
      final inProgressFuture = _apiClient.get<List<AppointmentModel>>(
        '/appointments/status/IN_PROGRESS',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <AppointmentModel>[];
        },
      );

      final confirmedFuture = _apiClient.get<List<AppointmentModel>>(
        '/appointments/status/CONFIRMED',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <AppointmentModel>[];
        },
      );

      final results = await Future.wait([inProgressFuture, confirmedFuture]);
      final inProgressList = results[0].data ?? <AppointmentModel>[];
      final confirmedList = results[1].data ?? <AppointmentModel>[];

      final combined = [...inProgressList, ...confirmedList];
      // Sort by appointment date ascending
      combined.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      return combined;
    } catch (e) {
      debugPrint('Error fetching active mechanic appointments from backend: $e');
      // If status endpoint fails, try fetching recent/all appointments
      try {
        final fallbackResponse = await _apiClient.get<List<AppointmentModel>>(
          '/appointments',
          fromJson: (data) {
            if (data is List) {
              return data
                  .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
                  .where((a) => a.status == 'IN_PROGRESS' || a.status == 'CONFIRMED')
                  .toList();
            }
            return <AppointmentModel>[];
          },
        );
        return fallbackResponse.data ?? <AppointmentModel>[];
      } catch (fallbackError) {
        debugPrint('Fallback appointment fetch failed: $fallbackError');
        return <AppointmentModel>[];
      }
    }
  }

  /// Fetches pending appointments awaiting assignment or start.
  Future<List<AppointmentModel>> getPendingAppointments() async {
    try {
      final response = await _apiClient.get<List<AppointmentModel>>(
        '/appointments/status/PENDING',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <AppointmentModel>[];
        },
      );
      return response.data ?? <AppointmentModel>[];
    } catch (e) {
      debugPrint('Error fetching pending appointments: $e');
      return <AppointmentModel>[];
    }
  }

  /// Fetches appointments completed in the current week.
  Future<List<AppointmentModel>> getCompletedAppointmentsThisWeek() async {
    try {
      final response = await _apiClient.get<List<AppointmentModel>>(
        '/appointments/status/COMPLETED',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <AppointmentModel>[];
        },
      );
      return response.data ?? <AppointmentModel>[];
    } catch (e) {
      debugPrint('Error fetching completed appointments: $e');
      return <AppointmentModel>[];
    }
  }

  /// Updates the status of an appointment via PATCH /api/appointments/{id}/status?status={newStatus}.
  Future<bool> updateAppointmentStatus(
    int appointmentId,
    String newStatus,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/appointments/$appointmentId/status',
        queryParameters: {'status': newStatus},
      );
      return response.success;
    } catch (e) {
      debugPrint('Error updating appointment status via backend: $e');
      return false;
    }
  }

  /// Scans customer appointment QR code and transitions status to IN_PROGRESS.
  Future<AppointmentModel?> scanAppointmentQr(String qrData) async {
    try {
      final response = await _apiClient.post<AppointmentModel>(
        '/appointments/scan-qr',
        body: {'qrData': qrData},
        fromJson: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
      );
      return response.data;
    } catch (e) {
      debugPrint('Error checking in via QR scan: $e');
      rethrow;
    }
  }

  /// Assigns a mechanic to an appointment via /api/admin/appointments/{id}/assign-mechanic.
  Future<bool> assignMechanic(int appointmentId, int mechanicId) async {
    try {
      final response = await _apiClient.post(
        '/admin/appointments/$appointmentId/assign-mechanic',
        body: {'mechanicId': mechanicId},
      );
      return response.success;
    } catch (e) {
      debugPrint('Error assigning mechanic to appointment: $e');
      return false;
    }
  }

  /// Fetches staff mechanics with attendance and assigned jobs.
  Future<List<MechanicStaffModel>> getStaffList() async {
    try {
      final response = await _apiClient.get<List<MechanicStaffModel>>(
        '/admin/staff',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => MechanicStaffModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <MechanicStaffModel>[];
        },
      );
      return response.data ?? <MechanicStaffModel>[];
    } catch (e) {
      debugPrint('Error fetching staff list: $e');
      return <MechanicStaffModel>[];
    }
  }

  /// Fetches inventory items, optionally filtering for low stock.
  Future<List<InventoryItemModel>> getInventoryItems({bool onlyLowStock = false}) async {
    final path = onlyLowStock ? '/admin/inventory/low-stock' : '/admin/inventory';
    try {
      final response = await _apiClient.get<List<InventoryItemModel>>(
        path,
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => InventoryItemModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <InventoryItemModel>[];
        },
      );
      return response.data ?? <InventoryItemModel>[];
    } catch (e) {
      debugPrint('Error fetching inventory items: $e');
      return <InventoryItemModel>[];
    }
  }

  /// Submits a part request.
  Future<bool> requestPart(PartRequestModel request) async {
    try {
      final response = await _apiClient.post(
        '/admin/inventory/requests',
        body: request.toJson(),
      );
      return response.success;
    } catch (e) {
      debugPrint('Error submitting part request: $e');
      return false;
    }
  }

  /// Fetches default and active tasks for an appointment/job.
  Future<List<JobTaskModel>> getJobTasks(int appointmentId) async {
    try {
      final response = await _apiClient.get<List<JobTaskModel>>(
        '/admin/job-tasks/appointment/$appointmentId',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => JobTaskModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <JobTaskModel>[];
        },
      );
      return response.data ?? <JobTaskModel>[];
    } catch (e) {
      debugPrint('Error fetching job tasks: $e');
      return <JobTaskModel>[];
    }
  }

  /// Updates job task status (e.g. COMPLETED / PENDING).
  Future<bool> updateJobTaskStatus(int taskId, String status) async {
    try {
      final response = await _apiClient.patch(
        '/admin/job-tasks/$taskId/status/$status',
      );
      return response.success;
    } catch (e) {
      debugPrint('Error updating job task status: $e');
      return false;
    }
  }

  /// Logs a part used on a job.
  Future<bool> logPartUsed({
    required int appointmentId,
    required String partName,
    required int quantity,
    required double unitCost,
  }) async {
    try {
      final response = await _apiClient.post(
        '/repairs/$appointmentId/parts',
        body: {
          'partName': partName,
          'quantity': quantity,
          'unitCost': unitCost,
          'totalCost': unitCost * quantity,
          'status': 'INSTALLED',
        },
      );
      return response.success;
    } catch (e) {
      debugPrint('Error logging part used: $e');
      return false;
    }
  }

  /// Uploads a service photo taken by the camera.
  Future<String?> uploadServicePhoto(int appointmentId, File photoFile, String caption) async {
    try {
      final response = await _apiClient.uploadMultipart<Map<String, dynamic>>(
        path: '/repairs/$appointmentId/photos',
        file: photoFile,
        fileParamName: 'file',
        fields: {
          'description': caption,
          'photoType': 'WORK_IN_PROGRESS',
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );
      return response.data?['photoUrl'] as String?;
    } catch (e) {
      debugPrint('Error uploading service photo: $e');
      return null;
    }
  }

  /// Fetches notifications for the mechanic.
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _apiClient.get<List<NotificationModel>>(
        '/notifications',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <NotificationModel>[];
        },
      );
      return response.data ?? <NotificationModel>[];
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return <NotificationModel>[];
    }
  }
}
