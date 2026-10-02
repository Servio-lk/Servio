import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'worker_repository.dart';

final workerRepositoryProvider = Provider<WorkerRepository>(
  (_) => WorkerRepository(),
);

final activeAppointmentsProvider = FutureProvider<List<AppointmentModel>>((
  ref,
) async {
  return ref.watch(workerRepositoryProvider).getActiveAppointments();
});

final pendingAppointmentsProvider = FutureProvider<List<AppointmentModel>>((
  ref,
) async {
  return ref.watch(workerRepositoryProvider).getPendingAppointments();
});

final completedWeeklyAppointmentsProvider = FutureProvider<List<AppointmentModel>>((
  ref,
) async {
  return ref.watch(workerRepositoryProvider).getCompletedAppointmentsThisWeek();
});

final staffListProvider = FutureProvider<List<MechanicStaffModel>>((
  ref,
) async {
  return ref.watch(workerRepositoryProvider).getStaffList();
});

final inventoryItemsProvider = FutureProvider<List<InventoryItemModel>>((
  ref,
) async {
  return ref.watch(workerRepositoryProvider).getInventoryItems();
});

final lowStockItemsProvider = FutureProvider<List<InventoryItemModel>>((
  ref,
) async {
  return ref.watch(workerRepositoryProvider).getInventoryItems(onlyLowStock: true);
});

final notificationsProvider = FutureProvider<List<NotificationModel>>((
  ref,
) async {
  return ref.watch(workerRepositoryProvider).getNotifications();
});

final currentMechanicProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  return SupabaseService().getCurrentMechanic();
});

final jobTasksProvider = FutureProvider.family<List<JobTaskModel>, int>((
  ref,
  appointmentId,
) async {
  return ref.watch(workerRepositoryProvider).getJobTasks(appointmentId);
});
