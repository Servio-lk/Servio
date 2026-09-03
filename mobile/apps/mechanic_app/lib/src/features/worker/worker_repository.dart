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
        rethrow;
      }
    }
  }

  /// Updates the status of an appointment via PATCH /api/appointments/{id}/status?status={newStatus}.
  Future<void> updateAppointmentStatus(
    int appointmentId,
    String newStatus,
  ) async {
    try {
      await _apiClient.patch(
        '/appointments/$appointmentId/status',
        queryParameters: {'status': newStatus},
      );
    } catch (e) {
      debugPrint('Error updating appointment status via backend: $e');
      rethrow;
    }
  }
}
