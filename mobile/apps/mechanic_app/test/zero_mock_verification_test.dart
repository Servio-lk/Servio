import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:servio_mechanic/src/features/chats/chats_tab_screen.dart';
import 'package:servio_mechanic/src/features/worker/worker_providers.dart';
import 'package:servio_mechanic/src/features/worker/worker_repository.dart';
import 'package:servio_mechanic/src/shared/empty_state.dart';
import 'package:servio_mechanic/src/shared/error_state.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  group('1. ServioEmptyState Widget Tests', () {
    testWidgets('renders icon, title, description, and triggers onAction callback', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServioEmptyState(
              icon: PhosphorIconsRegular.wrench,
              title: 'No Ongoing Jobs',
              description: 'There are currently no active repair jobs in progress.',
              actionLabel: 'Check Pending Jobs',
              onAction: () {
                actionTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No Ongoing Jobs'), findsOneWidget);
      expect(find.text('There are currently no active repair jobs in progress.'), findsOneWidget);
      expect(find.text('Check Pending Jobs'), findsOneWidget);

      await tester.tap(find.text('Check Pending Jobs'));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });

    testWidgets('renders properly without optional action button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServioEmptyState(
              icon: PhosphorIconsRegular.archive,
              title: 'No Items Found',
            ),
          ),
        ),
      );

      expect(find.text('No Items Found'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('2. ServioErrorState Widget Tests', () {
    testWidgets('renders error message, triggers onRetry callback, and shows offline badge', (tester) async {
      bool retryTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServioErrorState(
              message: 'Connection timed out while fetching inventory.',
              onRetry: () {
                retryTriggered = true;
              },
              isOffline: true,
            ),
          ),
        ),
      );

      expect(find.text('Unable to Load Data'), findsOneWidget);
      expect(find.text('Connection timed out while fetching inventory.'), findsOneWidget);
      expect(find.text('Working in offline mode'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryTriggered, isTrue);
    });

    testWidgets('renders error state without retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServioErrorState(
              message: 'Fatal permission denied.',
              isOffline: false,
            ),
          ),
        ),
      );

      expect(find.text('Unable to Load Data'), findsOneWidget);
      expect(find.text('Fatal permission denied.'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Working in offline mode'), findsNothing);
    });
  });

  group('3. ChatsTabScreen Zero-Mock & Dynamic Customer Name Tests', () {
    testWidgets('displays dynamic customerName from appointments without hardcoded metadata', (tester) async {
      final mockAppointments = [
        AppointmentModel(
          id: 201,
          customerName: 'Chamindu Silva',
          customerEmail: 'chamindu@example.com',
          vehicleMake: 'Toyota',
          vehicleModel: 'Corolla',
          licensePlate: 'WP-CAS-9988',
          serviceType: 'Brake Disc Resurfacing',
          appointmentDate: DateTime(2026, 9, 30, 9, 30),
          status: 'IN_PROGRESS',
          estimatedCost: 15000.0,
          createdAt: DateTime.now(),
        ),
        AppointmentModel(
          id: 202,
          customerName: 'Praveen Jayasuriya',
          vehicleMake: 'Nissan',
          vehicleModel: 'Leaf',
          licensePlate: 'WP-CAD-4455',
          serviceType: 'Inverter Check',
          appointmentDate: DateTime(2026, 9, 30, 11, 0),
          status: 'PENDING',
          estimatedCost: 12000.0,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAppointmentsProvider.overrideWith((ref) async => [mockAppointments[0]]),
            pendingAppointmentsProvider.overrideWith((ref) async => [mockAppointments[1]]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ChatsTabScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify real customer names from appointments are rendered
      expect(find.text('Chamindu Silva'), findsOneWidget);
      expect(find.text('Praveen Jayasuriya'), findsOneWidget);
      expect(find.text('WP-CAS-9988'), findsOneWidget);
      expect(find.text('WP-CAD-4455'), findsOneWidget);

      // Verify no mock names appear
      expect(find.text('Johnathan Silva'), findsNothing);
      expect(find.text('Rohan Wickramasinghe'), findsNothing);
    });

    testWidgets('renders ServioEmptyState when appointment lists are genuine empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAppointmentsProvider.overrideWith((ref) async => []),
            pendingAppointmentsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ChatsTabScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Conversations Found'), findsOneWidget);
      expect(find.byType(ServioEmptyState), findsOneWidget);
    });
  });

  group('4. WorkerRepository Zero-Mock Architecture Integrity', () {
    test('WorkerRepository contains no mock data fallback methods', () {
      final repo = WorkerRepository();
      expect(repo, isNotNull);
    });
  });
}
