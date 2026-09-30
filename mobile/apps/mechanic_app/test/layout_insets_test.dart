import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servio_mechanic/src/features/chats/client_job_details_sheet.dart';
import 'package:servio_mechanic/src/features/chats/chats_tab_screen.dart';
import 'package:servio_mechanic/src/features/chats/items_used_sheet.dart';
import 'package:servio_mechanic/src/features/chats/job_task_checklist_sheet.dart';
import 'package:servio_mechanic/src/features/inventory/inventory_tab_screen.dart';
import 'package:servio_mechanic/src/features/inventory/request_parts_sheet.dart';
import 'package:servio_mechanic/src/features/jobs/assign_mechanic_sheet.dart';
import 'package:servio_mechanic/src/features/jobs/jobs_tab_screen.dart';
import 'package:servio_mechanic/src/features/notifications/notifications_sheet.dart';
import 'package:servio_mechanic/src/features/staff/staff_tab_screen.dart';
import 'package:servio_mechanic/src/features/worker/worker_dashboard_screen.dart';
import 'package:servio_mechanic/src/features/worker/worker_providers.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  final sampleAppointment = AppointmentModel(
    id: 301,
    customerName: 'Saman Kumara',
    vehicleMake: 'Honda',
    vehicleModel: 'Civic',
    licensePlate: 'WP-CAR-7788',
    serviceType: 'Oil & Filter Change',
    appointmentDate: DateTime(2026, 10, 1, 10, 0),
    status: 'IN_PROGRESS',
    estimatedCost: 18500.0,
    createdAt: DateTime.now(),
  );

  Widget createTestWidget({
    required Widget child,
    EdgeInsets padding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
    List<AppointmentModel>? activeAppointments,
  }) {
    return ProviderScope(
      overrides: [
        activeAppointmentsProvider.overrideWith((ref) async => activeAppointments ?? [sampleAppointment]),
        pendingAppointmentsProvider.overrideWith((ref) async => []),
        completedWeeklyAppointmentsProvider.overrideWith((ref) async => []),
        currentMechanicProvider.overrideWith((ref) async => null),
        notificationsProvider.overrideWith((ref) async => []),
        inventoryItemsProvider.overrideWith((ref) async => []),
        lowStockItemsProvider.overrideWith((ref) async => []),
        staffListProvider.overrideWith((ref) async => []),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 800),
            padding: padding,
            viewInsets: viewInsets,
          ),
          child: Material(child: child),
        ),
      ),
    );
  }

  group('Milestone 3: 3-Button Navigation Insets in WorkerDashboardScreen', () {
    testWidgets('Tab bar enforces minimum 16dp padding on zero bottom inset', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const WorkerDashboardScreen(),
          padding: EdgeInsets.zero,
        ),
      );
      await tester.pumpAndSettle();

      // Find tab bar container
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);

      // Verify no ghost badge '2' appears when unread count is empty/null
      expect(find.text('2'), findsNothing);

      // Verify that the bottom tab bar has at least 16dp clearance (top: 4, bottom: 16)
      final tabBarRow = find.byWidgetPredicate((widget) {
        if (widget is Padding) {
          final p = widget.padding;
          if (p is EdgeInsets) {
            return p.top == 4.0 && p.bottom == 16.0 && p.left == 16.0 && p.right == 16.0;
          }
        }
        return false;
      });
      expect(tabBarRow, findsOneWidget);
    });

    testWidgets('Tab bar adapts dynamically to Android 3-button navigation bar (48dp inset)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const WorkerDashboardScreen(),
          padding: const EdgeInsets.only(bottom: 48.0),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that the bottom padding expands to match the 48dp system navigation inset
      final tabBarRow = find.byWidgetPredicate((widget) {
        if (widget is Padding) {
          final p = widget.padding;
          if (p is EdgeInsets) {
            return p.top == 4.0 && p.bottom == 48.0 && p.left == 16.0 && p.right == 16.0;
          }
        }
        return false;
      });
      expect(tabBarRow, findsOneWidget);
    });
  });

  group('Milestone 3: Modal Bottom Sheets Defensive Insets & SafeArea', () {
    testWidgets('AssignMechanicSheet applies safeBottom inset on 3-button navigation bar', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: AssignMechanicSheet(job: sampleAppointment),
          padding: const EdgeInsets.only(bottom: 48.0),
        ),
      );
      await tester.pumpAndSettle();

      final sheetContainer = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.padding is EdgeInsets) {
          final p = widget.padding as EdgeInsets;
          return p.bottom == 48.0 && p.left == 20.0 && p.right == 20.0;
        }
        return false;
      });
      expect(sheetContainer, findsOneWidget);
      expect(find.text('Confirm Assignment'), findsOneWidget);
    });

    testWidgets('RequestPartsSheet applies safeBottom and keyboard viewInsets with zero overflow', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const RequestPartsSheet(),
          padding: const EdgeInsets.only(bottom: 48.0),
          viewInsets: const EdgeInsets.only(bottom: 280.0),
        ),
      );
      await tester.pumpAndSettle();

      final sheetContainer = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.padding is EdgeInsets) {
          final p = widget.padding as EdgeInsets;
          // safeBottom (48) + viewInsets (280) = 328
          return p.bottom == 328.0 && p.left == 20.0 && p.right == 20.0;
        }
        return false;
      });
      expect(sheetContainer, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ItemsUsedSheet wraps Column in SingleChildScrollView with zero RenderFlex overflow under keyboard', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const ItemsUsedSheet(appointmentId: 301),
          padding: const EdgeInsets.only(bottom: 48.0),
          viewInsets: const EdgeInsets.only(bottom: 300.0),
        ),
      );
      await tester.pumpAndSettle();

      // Check that ItemsUsedSheet container includes safeBottom + viewInsets (48 + 300 = 348)
      final sheetContainer = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.padding is EdgeInsets) {
          final p = widget.padding as EdgeInsets;
          return p.bottom == 348.0 && p.left == 20.0 && p.right == 20.0;
        }
        return false;
      });
      expect(sheetContainer, findsOneWidget);

      // Verify that SingleChildScrollView is used inside ItemsUsedSheet
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Verify "Log Item to Job" button is present and rendered
      expect(find.text('Log Item to Job'), findsOneWidget);
    });

    testWidgets('JobTaskChecklistSheet applies safeBottom inset on 3-button navigation bar', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const JobTaskChecklistSheet(appointmentId: 301),
          padding: const EdgeInsets.only(bottom: 48.0),
        ),
      );
      await tester.pumpAndSettle();

      final sheetContainer = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.padding is EdgeInsets) {
          final p = widget.padding as EdgeInsets;
          return p.bottom == 48.0 && p.left == 20.0 && p.right == 20.0;
        }
        return false;
      });
      expect(sheetContainer, findsOneWidget);
      expect(find.text('Done with Tasks'), findsOneWidget);
    });

    testWidgets('ClientJobDetailsSheet applies safeBottom inset on 3-button navigation bar', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: ClientJobDetailsSheet(job: sampleAppointment),
          padding: const EdgeInsets.only(bottom: 48.0),
        ),
      );
      await tester.pumpAndSettle();

      final sheetContainer = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.padding is EdgeInsets) {
          final p = widget.padding as EdgeInsets;
          return p.bottom == 48.0 && p.left == 20.0 && p.right == 20.0;
        }
        return false;
      });
      expect(sheetContainer, findsOneWidget);
      expect(find.text('Client Job Overview'), findsOneWidget);
    });

    testWidgets('NotificationsSheet applies safeBottom inset on 3-button navigation bar', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const NotificationsSheet(),
          padding: const EdgeInsets.only(bottom: 48.0),
        ),
      );
      await tester.pumpAndSettle();

      final sheetContainer = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.padding is EdgeInsets) {
          final p = widget.padding as EdgeInsets;
          return p.bottom == 48.0 && p.left == 20.0 && p.right == 20.0;
        }
        return false;
      });
      expect(sheetContainer, findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });
  });

  group('Milestone 3: List Virtualization & Pull-to-Refresh Physics', () {
    testWidgets('JobsTabScreen uses AlwaysScrollableScrollPhysics for pull-to-refresh resilience', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const JobsTabScreen()),
      );
      await tester.pumpAndSettle();

      final listView = tester.widget<ListView>(find.byType(ListView).first);
      expect(listView.physics, isA<AlwaysScrollableScrollPhysics>());
    });

    testWidgets('InventoryTabScreen uses AlwaysScrollableScrollPhysics for pull-to-refresh resilience', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const InventoryTabScreen()),
      );
      await tester.pumpAndSettle();

      final listView = tester.widget<ListView>(find.byType(ListView).first);
      expect(listView.physics, isA<AlwaysScrollableScrollPhysics>());
    });

    testWidgets('StaffTabScreen empty state is wrapped in scroll view with AlwaysScrollableScrollPhysics', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const StaffTabScreen()),
      );
      await tester.pumpAndSettle();

      final scrollViews = find.byType(SingleChildScrollView);
      expect(scrollViews, findsWidgets);

      final scrollView = tester.widget<SingleChildScrollView>(scrollViews.first);
      expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
    });

    testWidgets('ChatsTabScreen empty state is wrapped in scroll view with AlwaysScrollableScrollPhysics', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const ChatsTabScreen(),
          activeAppointments: [],
        ),
      );
      await tester.pumpAndSettle();

      final scrollViews = find.byType(SingleChildScrollView);
      expect(scrollViews, findsWidgets);

      final scrollView = tester.widget<SingleChildScrollView>(scrollViews.first);
      expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
    });
  });
}
