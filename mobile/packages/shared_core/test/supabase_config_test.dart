import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  group('SupabaseConfig Tests', () {
    test('validate() throws StateError when environment variables are not supplied', () {
      // In normal test execution without --dart-define, SUPABASE_URL and SUPABASE_ANON_KEY are empty
      if (SupabaseConfig.supabaseUrl.isEmpty || SupabaseConfig.supabaseAnonKey.isEmpty) {
        expect(
          () => SupabaseConfig.validate(),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Missing required environment configuration'),
          )),
        );
      }
    });
  });
}
