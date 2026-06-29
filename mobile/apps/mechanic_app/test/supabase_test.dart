// Quick test to verify Supabase connection and service_categories query
// Run with: flutter test test/supabase_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Query service_categories from Supabase', () async {
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://szgvnurzdglflmdabjol.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6Z3ZudXJ6ZGdsZmxtZGFiam9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4OTc3NTgsImV4cCI6MjA4NDQ3Mzc1OH0.MeQsJIGJ-Fy9GLrcHg3M1rM-eEIpmKKsRsrVYPI6U6E',
    );

    final client = Supabase.instance.client;

    print('--- Test 1: Simple select ---');
    try {
      final result = await client
          .from('service_categories')
          .select('id, name')
          .limit(5);
      print('Result: $result');
      print('Count: ${(result as List).length}');
    } catch (e) {
      print('ERROR: $e');
    }

    print('\n--- Test 2: Nested select with services ---');
    try {
      final result = await client
          .from('service_categories')
          .select('*, services(*, service_options(*))')
          .eq('is_active', true)
          .order('display_order', ascending: true);
      print('Categories count: ${(result as List).length}');
      for (final cat in result) {
        final services = cat['services'] as List;
        print('  ${cat['name']}: ${services.length} services');
      }
    } catch (e) {
      print('ERROR: $e');
    }
  });
}
