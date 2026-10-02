import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:servio_mechanic/src/features/jobs/weekly_stats_card.dart';
import 'package:servio_mechanic/src/features/worker/worker_repository.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  group('1. Weekly Stats Card Widget Tests', () {
    testWidgets('WeeklyStatsCard displays correct metric numbers and titles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeeklyStatsCard(
              jobsDoneCount: 14,
              ongoingJobsCount: 5,
              pendingJobsCount: 3,
            ),
          ),
        ),
      );

      // Verify header and badge
      expect(find.text('Weekly Performance'), findsOneWidget);
      expect(find.text('Current Week'), findsOneWidget);

      // Verify stat values
      expect(find.text('14'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Verify stat labels
      expect(find.text('Jobs Done'), findsOneWidget);
      expect(find.text('On-going'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });
  });

  group('2. Inventory & Low Stock Detection Tests', () {
    test('InventoryItemModel identifies low stock and stock deficit correctly', () {
      final lowStockItem = InventoryItemModel(
        id: 101,
        partNumber: 'OIL-SYN-5W30',
        name: 'Castrol Edge 5W-30 Full Synthetic 4L',
        category: 'Fluids & Lubricants',
        currentStock: 3.0,
        minimumStock: 10.0,
        unit: 'cans',
        costPerUnit: 14500.0,
        sellingPricePerUnit: 17200.0,
      );

      final adequateStockItem = InventoryItemModel(
        id: 102,
        partNumber: 'PLUG-NGK-IRID',
        name: 'NGK Iridium Spark Plug',
        category: 'Ignition',
        currentStock: 48.0,
        minimumStock: 16.0,
        unit: 'units',
        costPerUnit: 3200.0,
        sellingPricePerUnit: 4200.0,
      );

      expect(lowStockItem.isLowStock, isTrue);
      expect(lowStockItem.currentStock < lowStockItem.minimumStock, isTrue);

      expect(adequateStockItem.isLowStock, isFalse);
      expect(adequateStockItem.currentStock >= adequateStockItem.minimumStock, isTrue);
    });

    test('PartRequestModel serializes to JSON payload properly', () {
      final request = PartRequestModel(
        id: 1,
        partName: 'Front Brake Pads Ceramic',
        partNumber: 'BRK-BP-TOY-PR4',
        quantity: 2,
        urgency: 'HIGH',
        notes: 'Required for ongoing Job #42 brake overhaul',
        appointmentId: 42,
        createdAt: DateTime(2026, 9, 29, 10, 0),
      );

      final json = request.toJson();

      expect(json['partName'], 'Front Brake Pads Ceramic');
      expect(json['partNumber'], 'BRK-BP-TOY-PR4');
      expect(json['quantity'], 2);
      expect(json['urgency'], 'HIGH');
      expect(json['appointmentId'], 42);
      expect(json['notes'], contains('Job #42'));
    });
  });

  group('3. Mechanic Staff & Attendance Tests', () {
    test('MechanicStaffModel correctly categorizes attendance and assigned jobs', () {
      final onDutyStaff = MechanicStaffModel(
        id: 1,
        fullName: 'Kasun Bandara',
        employeeCode: 'MEC-101',
        specialization: 'Brakes & Suspension',
        attendanceStatus: 'ON_DUTY',
        assignedJobs: [
          AppointmentModel(
            id: 21,
            serviceType: 'Brake Disc Replacement',
            appointmentDate: DateTime.now(),
            status: 'IN_PROGRESS',
            estimatedCost: 28000.0,
            licensePlate: 'WP-CAD-1020',
            vehicleMake: 'Toyota',
            vehicleModel: 'Prius',
            createdAt: DateTime.now(),
          ),
        ],
      );

      final onLeaveStaff = MechanicStaffModel(
        id: 2,
        fullName: 'Nuwan Perera',
        employeeCode: 'MEC-102',
        specialization: 'Auto Electrical & Hybrid',
        attendanceStatus: 'ON_LEAVE',
        leaveReason: 'Medical Leave - Sick note submitted',
        assignedJobs: [],
      );

      expect(onDutyStaff.isOnDuty, isTrue);
      expect(onDutyStaff.isOnLeave, isFalse);
      expect(onDutyStaff.assignedJobs.length, 1);
      expect(onDutyStaff.assignedJobs.first.licensePlate, 'WP-CAD-1020');

      expect(onLeaveStaff.isOnDuty, isFalse);
      expect(onLeaveStaff.isOnLeave, isTrue);
      expect(onLeaveStaff.leaveReason, contains('Medical Leave'));
    });
  });

  group('4. Job Tasks Checklist & Activity Timeline Sync Tests', () {
    test('JobTaskModel toggles completion status correctly', () {
      final task = JobTaskModel(
        id: 5,
        appointmentId: 21,
        description: 'Inspect brake caliper sliders & lubricate pins',
        status: 'PENDING',
        sequenceOrder: 1,
      );

      expect(task.isCompleted, isFalse);

      final completedTask = task.copyWith(
        status: 'COMPLETED',
        completedAt: DateTime(2026, 9, 29, 14, 30),
      );

      expect(completedTask.isCompleted, isTrue);
      expect(completedTask.completedAt, isNotNull);
      expect(completedTask.completedAt?.hour, 14);
    });

    test('JobTaskModel serializes and deserializes cleanly', () {
      final json = {
        'id': 7,
        'jobCardId': 15,
        'appointmentId': 33,
        'description': 'Torque wheel nuts to specification',
        'status': 'COMPLETED',
        'completedAt': '2026-09-29T15:00:00.000Z',
        'sequenceOrder': 4,
      };

      final model = JobTaskModel.fromJson(json);

      expect(model.id, 7);
      expect(model.jobCardId, 15);
      expect(model.appointmentId, 33);
      expect(model.description, 'Torque wheel nuts to specification');
      expect(model.isCompleted, isTrue);
      expect(model.completedAt, isNotNull);
    });
  });

  group('5. Notification Model & Unread Filtering Tests', () {
    test('NotificationModel checks unread status and formatted timestamps', () {
      final unreadNotification = NotificationModel(
        id: 1,
        title: 'New Part Requisition Approved',
        message: 'Toyota Oil Filter (FLT-OIL-TY01) has been issued by stores.',
        type: 'INVENTORY',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );

      final readNotification = NotificationModel(
        id: 2,
        title: 'Job Assigned',
        message: 'You have been assigned to Job #88: Hybrid Inverter Inspection.',
        type: 'JOB_ASSIGNED',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      );

      expect(unreadNotification.isRead, isFalse);
      expect(readNotification.isRead, isTrue);

      final notifications = [unreadNotification, readNotification];
      final unreadCount = notifications.where((n) => !n.isRead).length;

      expect(unreadCount, 1);
    });
  });

  group('6. WorkerRepository Extended API Endpoints with MockClient', () {
    test('getPendingAppointments fetches appointments with PENDING status', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/appointments/status/PENDING');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 55,
                'serviceType': 'Wheel Alignment & Balancing',
                'appointmentDate': '2026-09-30T10:00:00',
                'status': 'PENDING',
                'vehicleMake': 'Mazda',
                'vehicleModel': 'Axela',
                'licensePlate': 'WP-CAA-5566',
                'estimatedCost': 12000.0,
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3001/api');
      final repo = WorkerRepository(apiClient: apiClient);

      final pending = await repo.getPendingAppointments();

      expect(pending.length, 1);
      expect(pending.first.id, 55);
      expect(pending.first.licensePlate, 'WP-CAA-5566');
    });

    test('assignMechanic sends POST to /admin/appointments/{id}/assign-mechanic', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/admin/appointments/55/assign-mechanic');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['mechanicId'], 101);

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Mechanic assigned successfully',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3001/api');
      final repo = WorkerRepository(apiClient: apiClient);

      final success = await repo.assignMechanic(55, 101);
      expect(success, isTrue);
    });

    test('requestParts sends POST requisition and completes', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/admin/inventory/requests');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['partName'], 'Oil Filter C-110');
        expect(body['quantity'], 5);

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Part request submitted successfully',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3001/api');
      final repo = WorkerRepository(apiClient: apiClient);

      final request = PartRequestModel(
        id: 0,
        partName: 'Oil Filter C-110',
        partNumber: 'FLT-C110',
        quantity: 5,
        urgency: 'HIGH',
        createdAt: DateTime.now(),
      );

      final success = await repo.requestPart(request);
      expect(success, isTrue);
    });

    test('logPartUsed logs parts used in repair job', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/repairs/10/parts');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['partName'], 'Dot 4 Brake Fluid 1L');
        expect(body['quantity'], 2);
        expect(body['unitCost'], 3500.0);
        expect(body['status'], 'INSTALLED');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Part logged successfully',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3001/api');
      final repo = WorkerRepository(apiClient: apiClient);

      final success = await repo.logPartUsed(
        appointmentId: 10,
        partName: 'Dot 4 Brake Fluid 1L',
        quantity: 2,
        unitCost: 3500.0,
      );
      expect(success, isTrue);
    });

    test('getStaffList returns list of mechanics', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/admin/staff');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 1,
                'fullName': 'Saman Kumara',
                'attendanceStatus': 'ON_DUTY',
                'specialization': 'Transmission Specialist',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3001/api');
      final repo = WorkerRepository(apiClient: apiClient);

      final staff = await repo.getStaffList();
      expect(staff.length, 1);
      expect(staff.first.fullName, 'Saman Kumara');
      expect(staff.first.isOnDuty, isTrue);
    });
  });
}
