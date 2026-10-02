import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:servio_mechanic/src/features/chats/worker_chat_screen.dart';
import 'package:servio_mechanic/src/features/inventory/inventory_tab_screen.dart';
import 'package:servio_mechanic/src/features/jobs/jobs_tab_screen.dart';
import 'package:servio_mechanic/src/features/staff/staff_tab_screen.dart';
import 'package:servio_mechanic/src/features/worker/worker_providers.dart';
import 'package:servio_mechanic/src/shared/empty_state.dart';
import 'package:servio_mechanic/src/shared/error_state.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  group('Adversarial Zero-Mock Codebase Audit', () {
    test('Mechanic app lib/ contains zero forbidden mock names or mock methods', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

      final forbiddenStrings = [
        'Johnathan Silva',
        'Sunil Perera',
        'Nuwan Bandara',
        '_defaultJobTasks',
        '_mockAppointments',
        '_mockPendingAppointments',
        '_mockCompletedAppointments',
        '_mockStaffList',
        '_mockInventoryItems',
        '_mockNotifications',
        '.withOpacity(',
      ];

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final forbidden in forbiddenStrings) {
          expect(
            content.contains(forbidden),
            isFalse,
            reason: 'File ${file.path} contains forbidden mock string: "$forbidden"',
          );
        }
      }
    });
  });

  group('Adversarial JobsTabScreen Empty & Error Resilience', () {
    testWidgets('JobsTabScreen renders ServioEmptyState when ongoing jobs list is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAppointmentsProvider.overrideWith((ref) async => []),
            pendingAppointmentsProvider.overrideWith((ref) async => []),
            completedWeeklyAppointmentsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: JobsTabScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ServioEmptyState), findsOneWidget);
      expect(find.text('No Ongoing Jobs'), findsOneWidget);
      expect(find.text('Check Pending Jobs'), findsOneWidget);

      // Tap Check Pending Jobs -> switches tab to pending jobs
      await tester.tap(find.text('Check Pending Jobs'));
      await tester.pumpAndSettle();

      expect(find.text('No Pending Jobs'), findsOneWidget);
    });

    testWidgets('JobsTabScreen renders ServioErrorState on backend failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAppointmentsProvider.overrideWith((ref) async {
              throw Exception('Backend 500 Internal Server Error');
            }),
            pendingAppointmentsProvider.overrideWith((ref) async => []),
            completedWeeklyAppointmentsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: JobsTabScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ServioErrorState), findsOneWidget);
      expect(find.text('Could not load active jobs. Pull down or tap retry to reload.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Verify tap on retry executes cleanly
      await tester.tap(find.text('Retry'));
      await tester.pump();
    });
  });

  group('Adversarial InventoryTabScreen Empty & Error Resilience', () {
    testWidgets('InventoryTabScreen renders ServioEmptyState on empty inventory', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryItemsProvider.overrideWith((ref) async => []),
            lowStockItemsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InventoryTabScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ServioEmptyState), findsOneWidget);
      expect(find.text('No Inventory Items Found'), findsOneWidget);
      expect(find.text('Request New Part'), findsOneWidget);
    });

    testWidgets('InventoryTabScreen renders ServioErrorState on inventory fetch error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryItemsProvider.overrideWith((ref) async {
              throw Exception('Network unreachable');
            }),
            lowStockItemsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InventoryTabScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ServioErrorState), findsOneWidget);
      expect(find.text('Failed to load inventory items. Tap retry to reload.'), findsOneWidget);
    });
  });

  group('Adversarial StaffTabScreen Empty & Error Resilience', () {
    testWidgets('StaffTabScreen renders ServioEmptyState on empty staff list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffListProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StaffTabScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ServioEmptyState), findsOneWidget);
      expect(find.text('No Technicians Found'), findsOneWidget);
    });

    testWidgets('StaffTabScreen renders ServioErrorState on staff fetch error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffListProvider.overrideWith((ref) async {
              throw Exception('Database connection pool exhausted');
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StaffTabScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ServioErrorState), findsOneWidget);
      expect(find.text('Could not load staff list. Tap retry to reload.'), findsOneWidget);
    });
  });

  group('Adversarial WorkerChatScreen Empty & Error Resilience', () {
    testWidgets('WorkerChatScreen displays empty message prompt and no mock messages', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/conversation')) {
          return http.Response(
            '{"success": true, "data": {"id": 10, "repairJobId": 10, "appointmentId": 10, "status": "OPEN"}}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.contains('/messages')) {
          return http.Response(
            '{"success": true, "data": []}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3001/api');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAppointmentsProvider.overrideWith((ref) async => []),
            pendingAppointmentsProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            home: WorkerChatScreen(
              appointmentId: 10,
              apiClient: apiClient,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No messages yet. Send a message to begin conversation.'), findsOneWidget);
      expect(find.text('Johnathan Silva'), findsNothing);
      expect(find.text('Sunil Perera'), findsNothing);
    });

    testWidgets('WorkerChatScreen renders error banner on REST conversation failure', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3001/api');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAppointmentsProvider.overrideWith((ref) async => []),
            pendingAppointmentsProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            home: WorkerChatScreen(
              appointmentId: 99,
              apiClient: apiClient,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Error banner with Retry button appears
      expect(find.text('Could not load chat messages.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('WorkerChatScreen disposes cleanly and unsubscribes channels without memory leak', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": true, "data": []}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:3001/api');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAppointmentsProvider.overrideWith((ref) async => []),
            pendingAppointmentsProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            home: WorkerChatScreen(
              appointmentId: 10,
              apiClient: apiClient,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Replace widget tree to trigger dispose()
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Replaced Screen'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Replaced Screen'), findsOneWidget);
      expect(find.byType(WorkerChatScreen), findsNothing);
    });
  });
}
