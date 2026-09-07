import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:servio_mechanic/src/features/worker/worker_repository.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  group('WorkerRepository REST API Tests', () {
    test('getActiveAppointments fetches and merges IN_PROGRESS and CONFIRMED appointments', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        if (request.url.path == '/api/appointments/status/IN_PROGRESS') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 10,
                  'serviceType': 'Engine Diagnostics',
                  'appointmentDate': '2026-09-02T09:00:00',
                  'status': 'IN_PROGRESS',
                  'vehicleMake': 'Toyota',
                  'vehicleModel': 'Prius',
                  'licensePlate': 'WP-CAD-1020',
                  'estimatedCost': 18000.0,
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.url.path == '/api/appointments/status/CONFIRMED') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 11,
                  'serviceType': 'Brake Pad Replacement',
                  'appointmentDate': '2026-09-02T11:00:00',
                  'status': 'CONFIRMED',
                  'vehicleMake': 'Honda',
                  'vehicleModel': 'Vezel',
                  'licensePlate': 'WP-CBF-3344',
                  'estimatedCost': 24000.0,
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

      final repo = WorkerRepository(apiClient: apiClient);
      final active = await repo.getActiveAppointments();

      expect(active.length, 2);
      expect(active[0].id, 10);
      expect(active[0].status, 'IN_PROGRESS');
      expect(active[0].vehicleDisplay, 'Toyota Prius');
      expect(active[1].id, 11);
      expect(active[1].status, 'CONFIRMED');
      expect(active[1].vehicleDisplay, 'Honda Vezel');
    });

    test('updateAppointmentStatus sends PATCH request with new status', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/appointments/10/status');
        expect(request.url.queryParameters['status'], 'COMPLETED');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Appointment status updated to COMPLETED',
            'data': {
              'id': 10,
              'status': 'COMPLETED',
            }
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'http://localhost:3001/api',
      );

      final repo = WorkerRepository(apiClient: apiClient);
      await expectLater(
        repo.updateAppointmentStatus(10, 'COMPLETED'),
        completes,
      );
    });
  });

  group('Worker Chat Models & API Tests', () {
    test('parses RepairConversationModel and RepairMessageModel properly', () async {
      final convJson = {
        'id': 50,
        'repairJobId': 100,
        'appointmentId': 10,
        'status': 'OPEN',
        'createdAt': '2026-09-01T08:00:00',
      };

      final conversation = RepairConversationModel.fromJson(convJson);
      expect(conversation.id, 50);
      expect(conversation.repairJobId, 100);
      expect(conversation.appointmentId, 10);
      expect(conversation.isOpen, true);

      final msgJson = {
        'id': 501,
        'conversationId': 50,
        'repairJobId': 100,
        'senderId': 'c3b5d840-0018-47e3-a700-7ba5cc2258d0',
        'senderRole': 'MECHANIC',
        'body': 'Oil change complete. Inspecting brake rotors now.',
        'createdAt': '2026-09-01T09:15:00',
      };

      final msg = RepairMessageModel.fromJson(msgJson);
      expect(msg.id, 501);
      expect(msg.isMechanicSender, true);
      expect(msg.body, 'Oil change complete. Inspecting brake rotors now.');
    });
  });
}
