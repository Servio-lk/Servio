import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

class VehiclesRepository {
  final ApiClient _apiClient;

  VehiclesRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetches vehicles for the authenticated user via GET /api/vehicles/my
  Future<List<VehicleModel>> getUserVehicles({String? profileId}) async {
    try {
      final response = await _apiClient.get<List<VehicleModel>>(
        '/vehicles/my',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <VehicleModel>[];
        },
      );

      return response.data ?? <VehicleModel>[];
    } catch (e) {
      debugPrint('Error fetching vehicles from backend: $e');
      rethrow;
    }
  }

  /// Creates a vehicle for the authenticated user via POST /api/vehicles/my
  Future<VehicleModel> createVehicle({
    required String make,
    required String model,
    int? year,
    String? licensePlate,
    String? vin,
  }) async {
    final payload = <String, dynamic>{
      'make': make,
      'model': model,
      if (year != null) 'year': year,
      if (licensePlate != null && licensePlate.isNotEmpty)
        'licensePlate': licensePlate,
      if (vin != null && vin.isNotEmpty) 'vin': vin,
    };

    try {
      final response = await _apiClient.post<VehicleModel>(
        '/vehicles/my',
        body: payload,
        fromJson: (data) => VehicleModel.fromJson(data as Map<String, dynamic>),
      );

      if (response.data != null) {
        return response.data!;
      }
      throw ApiException(response.message ?? 'Failed to create vehicle');
    } catch (e) {
      debugPrint('Error creating vehicle via backend: $e');
      rethrow;
    }
  }

  /// Updates a vehicle via PUT /api/vehicles/{id}
  Future<VehicleModel> updateVehicle({
    required int vehicleId,
    required String make,
    required String model,
    int? year,
    String? licensePlate,
    String? vin,
  }) async {
    final payload = <String, dynamic>{
      'make': make,
      'model': model,
      if (year != null) 'year': year,
      if (licensePlate != null && licensePlate.isNotEmpty)
        'licensePlate': licensePlate,
      if (vin != null && vin.isNotEmpty) 'vin': vin,
    };

    try {
      final response = await _apiClient.put<VehicleModel>(
        '/vehicles/$vehicleId',
        body: payload,
        fromJson: (data) => VehicleModel.fromJson(data as Map<String, dynamic>),
      );

      if (response.data != null) {
        return response.data!;
      }
      throw ApiException(response.message ?? 'Failed to update vehicle');
    } catch (e) {
      debugPrint('Error updating vehicle via backend: $e');
      rethrow;
    }
  }

  /// Deletes a vehicle via DELETE /api/vehicles/{id}
  Future<void> deleteVehicle(int vehicleId) async {
    try {
      await _apiClient.delete('/vehicles/$vehicleId');
    } catch (e) {
      debugPrint('Error deleting vehicle via backend: $e');
      rethrow;
    }
  }
}
