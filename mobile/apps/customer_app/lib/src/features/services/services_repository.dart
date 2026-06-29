import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_core/shared_core.dart';

// ─── SERVICES REPOSITORY (queries Supabase directly) ─────────────────────────

class ServicesRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Fetches all active service categories with their active services and options.
  Future<List<ServiceCategoryModel>> getServiceCategories() async {
    try {
      debugPrint(
        '🔵 [ServicesRepo] Fetching service categories from Supabase...',
      );
      debugPrint('🔵 [ServicesRepo] Supabase URL: ${_client.rest.url}');

      // Step 1: Try a simple count first to verify table access
      try {
        final testResponse = await _client
            .from('service_categories')
            .select('id')
            .limit(1);
        debugPrint('🟡 [ServicesRepo] Test query result: $testResponse');
      } catch (testErr) {
        debugPrint('🔴 [ServicesRepo] Test query FAILED: $testErr');
        debugPrint(
          '🔴 This means RLS policies are blocking access or table does not exist.',
        );
      }

      // Step 2: Fetch categories with nested services
      final response = await _client
          .from('service_categories')
          .select('*, services(*, service_options(*))')
          .eq('is_active', true)
          .order('display_order', ascending: true);

      final data = response as List<dynamic>;
      debugPrint(
        '🟢 [ServicesRepo] Got ${data.length} categories from Supabase',
      );

      if (data.isEmpty) {
        debugPrint('🟡 [ServicesRepo] No categories found! Check:');
        debugPrint('   1. Does the service_categories table have data?');
        debugPrint('   2. Is is_active = true for any rows?');
        debugPrint('   3. Are RLS policies allowing SELECT for anon role?');
        return [];
      }

      debugPrint('🟢 [ServicesRepo] First category raw: ${data[0]}');

      final categories = data
          .map((e) => ServiceCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint('🟢 [ServicesRepo] Parsed ${categories.length} categories');
      for (final cat in categories) {
        debugPrint('   📁 ${cat.name}: ${cat.services.length} services');
      }

      return categories;
    } catch (e, stackTrace) {
      debugPrint('🔴 [ServicesRepo] Error fetching categories: $e');
      debugPrint('🔴 [ServicesRepo] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fetches featured services for the home screen suggestions.
  Future<List<ServiceModel>> getFeaturedServices() async {
    try {
      debugPrint('🔵 [ServicesRepo] Fetching featured services...');

      final response = await _client
          .from('services')
          .select('*, service_options(*)')
          .eq('is_active', true)
          .eq('is_featured', true);

      final data = response as List<dynamic>;
      debugPrint('🟢 [ServicesRepo] Got ${data.length} featured services');

      if (data.isEmpty) {
        debugPrint('🟡 [ServicesRepo] No featured services found.');
        debugPrint('   Check: are any services marked is_featured = true?');
      }

      return data
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('🔴 [ServicesRepo] Error fetching featured: $e');
      debugPrint('🔴 [ServicesRepo] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
