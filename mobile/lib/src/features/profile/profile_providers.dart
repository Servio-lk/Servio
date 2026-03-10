import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vehicles_repository.dart';
import 'models/vehicle_model.dart';
final vehiclesRepositoryProvider = Provider<VehiclesRepository>(
  (_) => VehiclesRepository(),
);
final userVehiclesProvider = FutureProvider<List<VehicleModel>>((ref) async {
  return ref.read(vehiclesRepositoryProvider).getUserVehicles();
});
