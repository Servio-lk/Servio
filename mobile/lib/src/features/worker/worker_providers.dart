import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'worker_repository.dart';
import '../bookings/models/appointment_model.dart';

final workerRepositoryProvider = Provider<WorkerRepository>(
  (_) => WorkerRepository(),
);

final activeAppointmentsProvider = FutureProvider<List<AppointmentModel>>((
  ref,
) async {
  return ref.read(workerRepositoryProvider).getActiveAppointments();
});
