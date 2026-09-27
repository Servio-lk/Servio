import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_core/src/core/security/secure_local_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeAndroidOptions extends Fake implements AndroidOptions {}
class FakeIOSOptions extends Fake implements IOSOptions {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureLocalStorage secureLocalStorage;

  setUpAll(() {
    registerFallbackValue(FakeAndroidOptions());
    registerFallbackValue(FakeIOSOptions());
  });

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureLocalStorage = SecureLocalStorage(mockStorage);
  });

  group('SecureLocalStorage Tests', () {
    test('hasAccessToken returns true when token exists', () async {
      when(() => mockStorage.containsKey(
            key: supabasePersistSessionKey,
            aOptions: any(named: 'aOptions'),
            iOptions: any(named: 'iOptions'),
          )).thenAnswer((_) async => true);

      final result = await secureLocalStorage.hasAccessToken();
      expect(result, isTrue);
    });

    test('hasAccessToken returns false when token does not exist', () async {
      when(() => mockStorage.containsKey(
            key: supabasePersistSessionKey,
            aOptions: any(named: 'aOptions'),
            iOptions: any(named: 'iOptions'),
          )).thenAnswer((_) async => false);

      final result = await secureLocalStorage.hasAccessToken();
      expect(result, isFalse);
    });

    test('accessToken returns stored token', () async {
      const storedToken = 'my_secure_token_123';
      when(() => mockStorage.read(
            key: supabasePersistSessionKey,
            aOptions: any(named: 'aOptions'),
            iOptions: any(named: 'iOptions'),
          )).thenAnswer((_) async => storedToken);

      final result = await secureLocalStorage.accessToken();
      expect(result, equals(storedToken));
    });

    test('persistSession writes token to storage', () async {
      const sessionString = 'new_session_data';
      when(() => mockStorage.write(
            key: supabasePersistSessionKey,
            value: sessionString,
            aOptions: any(named: 'aOptions'),
            iOptions: any(named: 'iOptions'),
          )).thenAnswer((_) async {});

      await secureLocalStorage.persistSession(sessionString);
      
      verify(() => mockStorage.write(
            key: supabasePersistSessionKey,
            value: sessionString,
            aOptions: any(named: 'aOptions'),
            iOptions: any(named: 'iOptions'),
          )).called(1);
    });

    test('removePersistedSession deletes token from storage', () async {
      when(() => mockStorage.delete(
            key: supabasePersistSessionKey,
            aOptions: any(named: 'aOptions'),
            iOptions: any(named: 'iOptions'),
          )).thenAnswer((_) async {});

      await secureLocalStorage.removePersistedSession();
      
      verify(() => mockStorage.delete(
            key: supabasePersistSessionKey,
            aOptions: any(named: 'aOptions'),
            iOptions: any(named: 'iOptions'),
          )).called(1);
    });
  });
}
