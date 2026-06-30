import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_core/shared_core.dart';

class WorkerRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Fetches all active appointments across the shop for the supervisor dashboard.
  Future<List<AppointmentModel>> getActiveAppointments() async {
    final mechanic = await SupabaseService().getCurrentMechanic();
    if (mechanic == null) {
      throw Exception(
        'No active staff profile was found for this email. Ask HR to register or reactivate your staff record.',
      );
    }

    // 1. Fetch all appointments that are IN_PROGRESS or CONFIRMED
    final response = await _client
        .from('appointments')
        .select('''
          id, profile_id, vehicle_id, service_type, appointment_date,
          status, location, notes, estimated_cost, actual_cost, created_at,
          vehicles ( make, model, year, license_plate )
        ''')
        .inFilter('status', ['IN_PROGRESS', 'CONFIRMED'])
        .order('appointment_date', ascending: true);

    final appointmentsData = response as List<dynamic>;
    if (appointmentsData.isEmpty) return [];

    final appointmentIds = appointmentsData
        .map((e) => e['id'] as int)
        .toList();

    // 2. Fetch repair jobs for these appointments to get assigned_technician_id
    final repairsResponse = await _client
        .from('repair_jobs')
        .select('appointment_id, assigned_technician_id')
        .inFilter('appointment_id', appointmentIds)
        .not('assigned_technician_id', 'is', null);

    final Map<int, int> appointmentToMechanicId = {};
    for (final repair in repairsResponse as List<dynamic>) {
      final appId = repair['appointment_id'] as int;
      final mechId = repair['assigned_technician_id'] as int;
      appointmentToMechanicId[appId] = mechId;
    }

    // 3. Fetch mechanic names
    final mechanicIds = appointmentToMechanicId.values.toSet().toList();
    final Map<int, String> mechanicIdToName = {};
    if (mechanicIds.isNotEmpty) {
      final mechanicsResponse = await _client
          .from('mechanics')
          .select('id, full_name')
          .inFilter('id', mechanicIds);
      
      for (final mech in mechanicsResponse as List<dynamic>) {
        final id = mech['id'] as int;
        final name = mech['full_name'] as String;
        mechanicIdToName[id] = name;
      }
    }

    // 4. Map the data back to AppointmentModel
    return appointmentsData.map((e) {
      final json = Map<String, dynamic>.from(e as Map<String, dynamic>);
      final appId = json['id'] as int;
      final mechId = appointmentToMechanicId[appId];
      if (mechId != null) {
        json['assignedMechanicName'] = mechanicIdToName[mechId];
      }
      return AppointmentModel.fromJson(json);
    }).toList();
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
