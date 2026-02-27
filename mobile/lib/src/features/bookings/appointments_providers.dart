import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'appointments_repository.dart';
import 'models/appointment_model.dart';

// ─── APPOINTMENTS PROVIDERS ──────────────────────────────────────────────────

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>(
  (_) => AppointmentsRepository(),
);

/// All appointments for the current authenticated user.
final userAppointmentsProvider = FutureProvider<List<AppointmentModel>>((
  ref,
) async {
  return ref.read(appointmentsRepositoryProvider).getUserAppointments();
});
