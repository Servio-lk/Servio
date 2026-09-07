import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  group('ApiClient Core Network Tests', () {
    test('GET request attaches Authorization header and unwraps payload', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://localhost:3001/api/profile');
        expect(request.headers['Authorization'], 'Bearer jwt-abc-123');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Profile retrieved',
            'data': {'id': 'user-1', 'email': 'user@servio.lk'},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final client = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api/',
        tokenProvider: () => 'jwt-abc-123',
      );

      final response = await client.get<Map<String, dynamic>>(
        '/profile',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      expect(response.success, true);
      expect(response.data?['email'], 'user@servio.lk');
    });

    test('POST request serializes JSON body and returns typed response', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'http://localhost:3001/api/sync');
        final decoded = jsonDecode(request.body) as Map<String, dynamic>;
        expect(decoded['name'], 'Chamindu');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Synced',
            'data': {'status': 'OK'},
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final client = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
      );

      final response = await client.post<Map<String, dynamic>>(
        '/sync',
        body: {'name': 'Chamindu'},
      );

      expect(response.success, true);
      expect(response.data?['status'], 'OK');
    });

    test('Throws UnauthorizedException on 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Token expired',
            'statusCode': 401,
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
      );

      expect(
        () => client.get('/protected'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('Throws ForbiddenException on 403', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Access denied'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
      );

      expect(
        () => client.get('/admin/only'),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('Throws ResourceNotFoundException on 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
      );

      expect(
        () => client.get('/missing'),
        throwsA(isA<ResourceNotFoundException>()),
      );
    });

    test('Throws ConflictException on 409', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Slot already booked'}),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
      );

      expect(
        () => client.post('/appointments', body: {}),
        throwsA(isA<ConflictException>()),
      );
    });

    test('Throws ValidationException on 400', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Invalid input',
            'validationErrors': {'email': 'Must be valid'},
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
      );

      expect(
        () => client.post('/submit', body: {}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Throws ServerException on 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Internal database failure'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
      );

      expect(
        () => client.get('/crash'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
