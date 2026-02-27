import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/appointment_model.dart';

// ─── APPOINTMENTS REPOSITORY (queries Supabase directly) ─────────────────────

class AppointmentsRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Fetches all appointments for the current authenticated user.
  /// Joins with vehicles table to get make/model.
  Future<List<AppointmentModel>> getUserAppointments() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('appointments')
        .select('''
          id, profile_id, vehicle_id, service_type, appointment_date,
          status, location, notes, estimated_cost, actual_cost, created_at,
          vehicles ( make, model )
        ''')
        .eq('profile_id', user.id)
        .order('appointment_date', ascending: false);

    final data = response as List<dynamic>;
    return data
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new appointment for the current user.
  Future<AppointmentModel> createAppointment({
    int? vehicleId,
    required String serviceType,
    required DateTime appointmentDate,
    String? location,
    String? notes,
    required double estimatedCost,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final payload = <String, dynamic>{
      'profile_id': user.id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      'service_type': serviceType,
      'appointment_date': appointmentDate.toIso8601String(),
      'status': 'PENDING',
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      'estimated_cost': estimatedCost,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _client.from('appointments').insert(payload).select(
      '''
          id, profile_id, vehicle_id, service_type, appointment_date,
          status, location, notes, estimated_cost, actual_cost, created_at,
          vehicles ( make, model )
        ''',
    ).single();

    return AppointmentModel.fromJson(response);
  }

  /// Fetches a list of booked time slots (as "HH:mm" strings) for a specific date.
  /// Ignores appointments with status 'CANCELLED'.
  Future<List<String>> getBookedSlotsForDate(
    DateTime date,
    String serviceType,
  ) async {
    // 1. Compute start and end of the given date (in local time)
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final response = await _client
          .from('appointments')
          .select('appointment_date')
          .gte('appointment_date', startOfDay.toUtc().toIso8601String())
          .lt('appointment_date', endOfDay.toUtc().toIso8601String())
          .eq('service_type', serviceType)
          .neq('status', 'CANCELLED');

      final data = response as List<dynamic>;

      final bookedSlots = <String>[];
      for (final row in data) {
        final dateStr = row['appointment_date'] as String?;
        if (dateStr != null) {
          final dt = DateTime.parse(dateStr).toLocal();
          // Format as "HH:mm"
          final h = dt.hour.toString().padLeft(2, '0');
          final m = dt.minute.toString().padLeft(2, '0');
          bookedSlots.add('$h:$m');
        }
      }

      return bookedSlots;
    } catch (e) {
      debugPrint('Error fetching booked slots: $e');
      return [];
    }
  }
}
