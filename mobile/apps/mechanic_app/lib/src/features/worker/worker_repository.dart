import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_core/shared_core.dart';

class WorkerRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Fetches appointments assigned to the signed-in mechanic.
  Future<List<AppointmentModel>> getActiveAppointments() async {
    final mechanic = await SupabaseService().getCurrentMechanic();
    if (mechanic == null) {
      throw Exception(
        'No active mechanic profile was found for this email. Ask HR to register or reactivate your staff record.',
      );
    }

    final mechanicId = mechanic['id'];
    final repairsResponse = await _client
        .from('repair_jobs')
        .select('appointment_id')
        .eq('assigned_technician_id', mechanicId)
        .not('appointment_id', 'is', null);

    final appointmentIds = (repairsResponse as List<dynamic>)
        .map((repair) => repair as Map<String, dynamic>)
        .map((repair) => repair['appointment_id'])
        .whereType<num>()
        .map((id) => id.toInt())
        .toSet()
        .toList();

    if (appointmentIds.isEmpty) return [];

    final response = await _client
        .from('appointments')
        .select('''
          id, profile_id, vehicle_id, service_type, appointment_date,
          status, location, notes, estimated_cost, actual_cost, created_at,
          vehicles ( make, model, year, license_plate )
        ''')
        .inFilter('id', appointmentIds)
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
