import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/vehicle_model.dart';

class VehiclesRepository {
  SupabaseClient get _client => Supabase.instance.client;
  Future<List<VehicleModel>> getUserVehicles({String? profileId}) async {
    final activeProfileId = profileId ?? _client.auth.currentUser?.id;
    if (activeProfileId == null) return [];
    try {
      final response = await _client
          .from('vehicles')
          .select()
          .eq('profile_id', activeProfileId)
          .order('created_at', ascending: false);
      final data = response as List<dynamic>;
      return data
          .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      rethrow;
    }
  }

  Future<VehicleModel> createVehicle({
    required String make,
    required String model,
    int? year,
    String? licensePlate,
    String? vin,
  }) async {
    final user = _client.auth.currentUser;
    final session = _client.auth.currentSession;
    if (user == null) throw Exception('User not authenticated');
    if (session == null) {
      throw Exception(
        'No active session. Please verify your email and sign in again.',
      );
    }
    final payload = <String, dynamic>{
      'profile_id': user.id,
      'make': make,
      'model': model,
      if (year != null) 'year': year,
      if (licensePlate != null && licensePlate.isNotEmpty)
        'license_plate': licensePlate,
      if (vin != null && vin.isNotEmpty) 'vin': vin,
    };
    try {
      final response = await _client
          .from('vehicles')
          .insert(payload)
          .select()
          .single();
      return VehicleModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating vehicle: $e');
      rethrow;
    }
  }

  Future<VehicleModel> updateVehicle({
    required int vehicleId,
    required String make,
    required String model,
    int? year,
    String? licensePlate,
    String? vin,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final payload = <String, dynamic>{
      'make': make,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
      'vin': vin,
    };
    try {
      final response = await _client
          .from('vehicles')
          .update(payload)
          .eq('id', vehicleId)
          .eq('profile_id', user.id)
          .select()
          .single();
      return VehicleModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
      rethrow;
    }
  }

  Future<void> deleteVehicle(int vehicleId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    try {
      await _client
          .from('vehicles')
          .delete()
          .eq('id', vehicleId)
          .eq('profile_id', user.id);
    } catch (e) {
      debugPrint('Error deleting vehicle: $e');
      rethrow;
    }
  }
}
