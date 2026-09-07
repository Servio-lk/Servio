import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:servio_customer/src/features/bookings/appointments_repository.dart';
import 'package:servio_customer/src/features/profile/vehicles_repository.dart';
import 'package:servio_customer/src/features/services/services_repository.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  group('AppointmentsRepository REST API Tests', () {
    test('getUserAppointments fetches and parses user appointments from backend', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/appointments/my');
        expect(request.headers['Authorization'], 'Bearer test-jwt-token');

        final responseBody = {
          'success': true,
          'message': 'My appointments retrieved successfully',
          'data': [
            {
              'id': 101,
              'userId': '550e8400-e29b-41d4-a716-446655440000',
              'vehicleId': 1,
              'vehicleMake': 'Toyota',
              'vehicleModel': 'Aqua',
              'vehicleYear': 2018,
              'licensePlate': 'CAB-1234',
              'serviceType': 'Lubricant Service',
              'appointmentDate': '2026-09-02T10:00:00',
              'status': 'CONFIRMED',
              'location': 'Colombo Service Bay 1',
              'notes': 'Use 0W-20 synthetic oil',
              'estimatedCost': 15500.0,
              'actualCost': null,
              'createdAt': '2026-09-01T12:00:00',
            }
          ]
        };

        return http.Response(
          jsonEncode(responseBody),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
        tokenProvider: () => 'test-jwt-token',
      );

      final repo = AppointmentsRepository(apiClient: apiClient);
      final appointments = await repo.getUserAppointments();

      expect(appointments.length, 1);
      expect(appointments[0].id, 101);
      expect(appointments[0].serviceType, 'Lubricant Service');
      expect(appointments[0].vehicleDisplay, 'Toyota Aqua 2018');
      expect(appointments[0].plateDisplay, 'CAB-1234');
      expect(appointments[0].status, 'CONFIRMED');
      expect(appointments[0].statusLabel, 'Confirmed');
      expect(appointments[0].estimatedCost, 15500.0);
    });

    test('createAppointment sends POST /api/appointments and parses response', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/appointments');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['serviceType'], 'General Collision Repair');
        expect(body['estimatedCost'], 45000.0);

        final responseBody = {
          'success': true,
          'message': 'Appointment created successfully',
          'data': {
            'id': 202,
            'serviceType': 'General Collision Repair',
            'appointmentDate': '2026-09-03T14:30:00',
            'status': 'PENDING',
            'estimatedCost': 45000.0,
            'createdAt': '2026-09-01T12:00:00',
          }
        };

        return http.Response(
          jsonEncode(responseBody),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
        tokenProvider: () => 'test-jwt-token',
      );

      final repo = AppointmentsRepository(apiClient: apiClient);
      final appointment = await repo.createAppointment(
        serviceType: 'General Collision Repair',
        appointmentDate: DateTime(2026, 9, 3, 14, 30),
        estimatedCost: 45000.0,
      );

      expect(appointment.id, 202);
      expect(appointment.serviceType, 'General Collision Repair');
      expect(appointment.status, 'PENDING');
      expect(appointment.estimatedCost, 45000.0);
    });

    test('getBookedSlotsForDate fetches and formats slots from backend', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/appointments/booked-slots');
        expect(request.url.queryParameters['date'], '2026-09-05');

        final responseBody = {
          'success': true,
          'data': ['09:00', '11:30', '14:00']
        };

        return http.Response(
          jsonEncode(responseBody),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
      );

      final repo = AppointmentsRepository(apiClient: apiClient);
      final slots = await repo.getBookedSlotsForDate(
        DateTime(2026, 9, 5),
        'Washing Packages',
      );

      expect(slots, ['09:00', '11:30', '14:00']);
    });

    test('cancelAppointment sends POST /api/appointments/{id}/cancel', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/appointments/101/cancel');

        final responseBody = {
          'success': true,
          'message': 'Appointment cancelled successfully',
          'data': {
            'id': 101,
            'serviceType': 'Washing Packages',
            'appointmentDate': '2026-09-02T10:00:00',
            'status': 'CANCELLED',
            'estimatedCost': 5000.0,
            'createdAt': '2026-09-01T12:00:00',
          }
        };

        return http.Response(
          jsonEncode(responseBody),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
      );

      final repo = AppointmentsRepository(apiClient: apiClient);
      final cancelled = await repo.cancelAppointment(101);

      expect(cancelled.id, 101);
      expect(cancelled.status, 'CANCELLED');
    });
  });

  group('VehiclesRepository REST API Tests', () {
    test('getUserVehicles fetches and parses user vehicles from backend', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/vehicles/my');

        final responseBody = {
          'success': true,
          'message': 'My vehicles retrieved successfully',
          'data': [
            {
              'id': 1,
              'userId': '550e8400-e29b-41d4-a716-446655440000',
              'make': 'Honda',
              'model': 'Civic',
              'year': 2021,
              'licensePlate': 'WP-CBA-9988',
              'vin': 'JH4DA92500S000001',
              'createdAt': '2026-08-15T09:00:00',
            }
          ]
        };

        return http.Response(
          jsonEncode(responseBody),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
      );

      final repo = VehiclesRepository(apiClient: apiClient);
      final vehicles = await repo.getUserVehicles();

      expect(vehicles.length, 1);
      expect(vehicles[0].id, 1);
      expect(vehicles[0].displayName, 'Honda Civic');
      expect(vehicles[0].detailLine, 'WP-CBA-9988 · 2021');
      expect(vehicles[0].vin, 'JH4DA92500S000001');
    });

    test('createVehicle, updateVehicle, deleteVehicle execute correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/api/vehicles/my') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 2,
                'make': 'Nissan',
                'model': 'Leaf',
                'year': 2022,
                'licensePlate': 'WP-CAR-7711',
              }
            }),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.method == 'PUT' && request.url.path == '/api/vehicles/2') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 2,
                'make': 'Nissan',
                'model': 'Leaf e+',
                'year': 2022,
                'licensePlate': 'WP-CAR-7711',
              }
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.method == 'DELETE' && request.url.path == '/api/vehicles/2') {
          return http.Response(
            jsonEncode({'success': true, 'message': 'Vehicle deleted'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
      );

      final repo = VehiclesRepository(apiClient: apiClient);

      final created = await repo.createVehicle(
        make: 'Nissan',
        model: 'Leaf',
        year: 2022,
        licensePlate: 'WP-CAR-7711',
      );
      expect(created.id, 2);
      expect(created.model, 'Leaf');

      final updated = await repo.updateVehicle(
        vehicleId: 2,
        make: 'Nissan',
        model: 'Leaf e+',
        year: 2022,
        licensePlate: 'WP-CAR-7711',
      );
      expect(updated.model, 'Leaf e+');

      await expectLater(repo.deleteVehicle(2), completes);
    });
  });

  group('ServicesRepository REST API Tests', () {
    test('getServiceCategories and getFeaturedServices parse correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/services/categories') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 1,
                  'name': 'Maintenance & Oil',
                  'description': 'Periodic maintenance packages',
                  'displayOrder': 1,
                  'services': [
                    {
                      'id': 10,
                      'categoryId': 1,
                      'name': 'Full Synthetic Lube',
                      'description': 'Engine oil & filter replacement',
                      'basePrice': 12500.0,
                      'isFeatured': true,
                      'options': [
                        {
                          'id': 100,
                          'name': 'Engine Flush',
                          'description': 'Removes deposits',
                          'priceAdjustment': 2500.0,
                          'isDefault': false,
                          'displayOrder': 1,
                        }
                      ]
                    }
                  ]
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.url.path == '/api/services/featured') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 10,
                  'categoryId': 1,
                  'name': 'Full Synthetic Lube',
                  'description': 'Engine oil & filter replacement',
                  'basePrice': 12500.0,
                  'isFeatured': true,
                  'options': []
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
      );

      final repo = ServicesRepository(apiClient: apiClient);
      final categories = await repo.getServiceCategories();
      expect(categories.length, 1);
      expect(categories[0].name, 'Maintenance & Oil');
      expect(categories[0].services.length, 1);
      expect(categories[0].services[0].formattedBasePrice, 'LKR 12,500.00');
      expect(categories[0].services[0].options[0].formattedPrice, '+LKR 2,500');

      final featured = await repo.getFeaturedServices();
      expect(featured.length, 1);
      expect(featured[0].name, 'Full Synthetic Lube');
    });
  });
}
