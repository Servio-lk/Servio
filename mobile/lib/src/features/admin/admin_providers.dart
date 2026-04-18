import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (_) => AdminRepository(),
);

final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((
  ref,
) async {
  return ref.read(adminRepositoryProvider).getDashboardStats();
});
