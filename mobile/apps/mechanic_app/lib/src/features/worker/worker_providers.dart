import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'worker_repository.dart';

final workerRepositoryProvider = Provider<WorkerRepository>(
  (_) => WorkerRepository(),
);

final activeAppointmentsProvider = FutureProvider<List<AppointmentModel>>((
  ref,
) async {
  return ref.read(workerRepositoryProvider).getActiveAppointments();
});

final currentMechanicProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  return SupabaseService().getCurrentMechanic();
});
