import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'services_repository.dart';

// ─── SERVICES PROVIDERS ──────────────────────────────────────────────────────

final servicesRepositoryProvider = Provider<ServicesRepository>(
  (_) => ServicesRepository(),
);

/// All service categories with nested services & options from Supabase.
/// Uses .autoDispose so it re-fetches when navigating back to the screen.
final serviceCategoriesProvider =
    FutureProvider.autoDispose<List<ServiceCategoryModel>>((ref) async {
      try {
        final result = await ref
            .read(servicesRepositoryProvider)
            .getServiceCategories();
        debugPrint(
          '🟢 [Provider] serviceCategoriesProvider loaded ${result.length} categories',
        );
        return result;
      } catch (e) {
        debugPrint('🔴 [Provider] serviceCategoriesProvider error: $e');
        rethrow;
      }
    });

/// Featured services for the home screen suggestions.
final featuredServicesProvider = FutureProvider.autoDispose<List<ServiceModel>>((
  ref,
) async {
  try {
    final result = await ref
        .read(servicesRepositoryProvider)
        .getFeaturedServices();
    debugPrint(
      '🟢 [Provider] featuredServicesProvider loaded ${result.length} services',
    );
    return result;
  } catch (e) {
    debugPrint('🔴 [Provider] featuredServicesProvider error: $e');
    rethrow;
  }
});
