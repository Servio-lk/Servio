import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

// ─── APPOINTMENTS REPOSITORY (communicates with Spring Boot REST API) ────────

class AppointmentsRepository {
  final ApiClient _apiClient;

  AppointmentsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetches all appointments for the current authenticated user via GET /api/appointments/my.
  Future<List<AppointmentModel>> getUserAppointments({
    String? profileId,
  }) async {
    try {
      final response = await _apiClient.get<List<AppointmentModel>>(
        '/appointments/my',
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
      debugPrint('Error fetching user appointments from backend: $e');
      rethrow;
    }
  }

  /// Creates a new appointment for the current user via POST /api/appointments.
  Future<AppointmentModel> createAppointment({
    int? vehicleId,
    required String serviceType,
    required DateTime appointmentDate,
    String? location,
    String? notes,
    required double estimatedCost,
  }) async {
    final payload = <String, dynamic>{
      if (vehicleId != null) 'vehicleId': vehicleId,
      'serviceType': serviceType,
      'appointmentDate': appointmentDate.toIso8601String(),
      if (location != null && location.isNotEmpty) 'location': location,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'estimatedCost': estimatedCost,
    };

    try {
      final response = await _apiClient.post<AppointmentModel>(
        '/appointments',
        body: payload,
        fromJson: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
      );

      if (response.data != null) {
        return response.data!;
      }
      throw ApiException(response.message ?? 'Failed to create appointment');
    } catch (e) {
      debugPrint('Error creating appointment via backend: $e');
      rethrow;
    }
  }

  /// Fetches a list of booked time slots (as "HH:mm" strings) for a specific date via GET /api/appointments/booked-slots?date=YYYY-MM-DD.
  Future<List<String>> getBookedSlotsForDate(
    DateTime date,
    String serviceType,
  ) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final response = await _apiClient.get<List<String>>(
        '/appointments/booked-slots',
        queryParameters: {'date': dateStr},
        fromJson: (data) {
          if (data is List) {
            final result = <String>[];
            for (final item in data) {
              if (item is String) {
                // If it's already "HH:mm" format (e.g. "09:00")
                if (item.contains(':') && item.length <= 5) {
                  result.add(item);
                } else {
                  // If ISO timestamp format
                  final dt = DateTime.tryParse(item)?.toLocal();
                  if (dt != null) {
                    final h = dt.hour.toString().padLeft(2, '0');
                    final m = dt.minute.toString().padLeft(2, '0');
                    result.add('$h:$m');
                  } else {
                    result.add(item);
                  }
                }
              }
            }
            return result;
          }
          return <String>[];
        },
      );

      return response.data ?? <String>[];
    } catch (e) {
      debugPrint('Error fetching booked slots from backend: $e');
      return [];
    }
  }

  /// Cancels an appointment via POST /api/appointments/{id}/cancel.
  Future<AppointmentModel> cancelAppointment(int appointmentId) async {
    try {
      final response = await _apiClient.post<AppointmentModel>(
        '/appointments/$appointmentId/cancel',
        fromJson: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
      );

      if (response.data != null) {
        return response.data!;
      }
      throw ApiException(response.message ?? 'Failed to cancel appointment');
    } catch (e) {
      debugPrint('Error cancelling appointment: $e');
      rethrow;
    }
  }
}
