import 'package:supabase_flutter/supabase_flutter.dart';
import '../bookings/models/appointment_model.dart';

class WorkerRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Fetches all upcoming and ongoing appointments for the worker to see.
  /// Gets appointments that are not CANCELLED or COMPLETED.
  Future<List<AppointmentModel>> getActiveAppointments() async {
    final response = await _client
        .from('appointments')
        .select('''
          id, profile_id, vehicle_id, service_type, appointment_date,
          status, location, notes, estimated_cost, actual_cost, created_at,
          vehicles ( make, model )
        ''')
        .neq('status', 'CANCELLED')
        .neq('status', 'COMPLETED')
        .order('appointment_date', ascending: true);

    final data = response as List<dynamic>;
    return data
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates the status of an appointment.
  Future<void> updateAppointmentStatus(
    int appointmentId,
    String newStatus,
  ) async {
    await _client
        .from('appointments')
        .update({
          'status': newStatus,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', appointmentId);
  }
}
