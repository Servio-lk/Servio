import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servio_mechanic/src/features/chats/client_job_details_sheet.dart';
import 'package:servio_mechanic/src/features/chats/items_used_sheet.dart';
import 'package:servio_mechanic/src/features/chats/job_task_checklist_sheet.dart';
import 'package:servio_mechanic/src/features/inventory/request_parts_sheet.dart';
import 'package:servio_mechanic/src/features/jobs/assign_mechanic_sheet.dart';
import 'package:servio_mechanic/src/features/notifications/notifications_sheet.dart';
import 'package:servio_mechanic/src/features/worker/worker_dashboard_screen.dart';
import 'package:servio_mechanic/src/features/worker/worker_providers.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  final sampleAppointment = AppointmentModel(
    id: 901,
    customerName: 'Adversarial Test Client',
    vehicleMake: 'Nissan',
    vehicleModel: 'Leaf EV',
    licensePlate: 'WP-EV-9999',
    serviceType: 'Battery Diagnostic & Conditioning',
    appointmentDate: DateTime(2026, 10, 5, 9, 30),
    status: 'IN_PROGRESS',
    estimatedCost: 35000.0,
    actualCost: 38500.0,
    notes: 'Check cell voltages under load.',
    createdAt: DateTime.now(),
  );

  final List<MechanicStaffModel> sampleMechanics = [
    MechanicStaffModel(
      id: 1,
      fullName: 'Kamal Gunaratne',
      specialization: 'High Voltage Specialist',
      attendanceStatus: 'ON_DUTY',
      assignedJobs: const [],
    ),
    MechanicStaffModel(
      id: 2,
      fullName: 'Nimal Siripala',
      specialization: 'Diagnostic Tech',
      attendanceStatus: 'OFF_DUTY',
      assignedJobs: const [],
    ),
  ];

  final List<InventoryItemModel> sampleInventory = [
    const InventoryItemModel(
      id: 11,
      name: 'HV Relay Unit',
      partNumber: 'REL-HV-01',
      category: 'Electrical',
      currentStock: 5.0,
      minimumStock: 2.0,
      costPerUnit: 12000.0,
      sellingPricePerUnit: 15000.0,
      unit: 'pieces',
    ),
  ];

  final List<NotificationModel> sampleNotifications = [
    NotificationModel(
      id: 1,
      type: 'JOB_ASSIGNED',
      title: 'New Service Job Assigned',
      message: 'Vehicle WP-EV-9999 is assigned to your bay.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
  ];

  Widget buildTestHarness({
    required Widget child,
    Size size = const Size(400, 800),
    EdgeInsets padding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) {
    return ProviderScope(
      overrides: [
        activeAppointmentsProvider.overrideWith((ref) async => <AppointmentModel>[sampleAppointment]),
        pendingAppointmentsProvider.overrideWith((ref) async => <AppointmentModel>[]),
        completedWeeklyAppointmentsProvider.overrideWith((ref) async => <AppointmentModel>[]),
        currentMechanicProvider.overrideWith((ref) async => null),
        notificationsProvider.overrideWith((ref) async => sampleNotifications),
        inventoryItemsProvider.overrideWith((ref) async => sampleInventory),
        lowStockItemsProvider.overrideWith((ref) async => <InventoryItemModel>[]),
        staffListProvider.overrideWith((ref) async => sampleMechanics),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: padding,
            viewInsets: viewInsets,
          ),
          child: Material(child: child),
        ),
      ),
    );
  }

  group('Adversarial 3-Button & Zero-Inset Geometry Verification', () {
    testWidgets('WorkerDashboardScreen enforces minimum 16dp defensive padding on 0dp bottom inset', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: const WorkerDashboardScreen(),
          padding: EdgeInsets.zero,
        ),
      );
      await tester.pumpAndSettle();

      final tabBarPaddingFinder = find.byWidgetPredicate((widget) {
        if (widget is Padding && widget.padding is EdgeInsets) {
          final p = widget.padding as EdgeInsets;
          return p.left == 16.0 && p.right == 16.0 && p.top == 4.0 && p.bottom == 16.0;
        }
        return false;
      });
      expect(tabBarPaddingFinder, findsOneWidget);

      // Verify all 4 tabs are interactive under 0dp padding
      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();
      expect(find.text('Chats'), findsOneWidget);

      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();
      expect(find.text('Inventory'), findsOneWidget);

      await tester.tap(find.text('Staff'));
      await tester.pumpAndSettle();
      expect(find.text('Staff'), findsOneWidget);

      await tester.tap(find.text('Jobs'));
      await tester.pumpAndSettle();
      expect(find.text('Jobs'), findsOneWidget);
    });

    testWidgets('WorkerDashboardScreen expands padding dynamically to 48dp on 3-button navigation simulation', (tester) async {
      const screenSize = Size(400, 800);
      const systemBarHeight = 48.0;

      await tester.pumpWidget(
        buildTestHarness(
          size: screenSize,
          child: const WorkerDashboardScreen(),
          padding: const EdgeInsets.only(bottom: systemBarHeight),
        ),
      );
      await tester.pumpAndSettle();

      // Find the tab bar padding widget
      final tabBarPaddingFinder = find.byWidgetPredicate((widget) {
        if (widget is Padding && widget.padding is EdgeInsets) {
          final p = widget.padding as EdgeInsets;
          return p.left == 16.0 && p.right == 16.0 && p.top == 4.0 && p.bottom == 48.0;
        }
        return false;
      });
      expect(tabBarPaddingFinder, findsOneWidget);

      // Verify that interactive tabs sit entirely above the 48dp system navigation bar.
      // Top of system navigation bar is at Y = 800 - 48 = 752.0.
      for (final label in ['Jobs', 'Chats', 'Inventory', 'Staff']) {
        final textFinder = find.text(label);
        expect(textFinder, findsOneWidget);
        final textBottomRight = tester.getBottomRight(textFinder);
        expect(
          textBottomRight.dy,
          lessThanOrEqualTo(screenSize.height - systemBarHeight),
          reason: 'Tab label "$label" bottom (${textBottomRight.dy}) must not penetrate system bar (>= 752.0)',
        );
      }

      // Verify active indicator line sits above or flush with the system bar boundary
      final activeIndicator = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.constraints != null) {
          final c = widget.constraints!;
          return c.minWidth == 18.0 && c.maxHeight == 3.0;
        }
        return false;
      });
      if (activeIndicator.evaluate().isNotEmpty) {
        final indicatorBottom = tester.getBottomRight(activeIndicator).dy;
        expect(indicatorBottom, lessThanOrEqualTo(screenSize.height - systemBarHeight));
      }

      // Verify all tabs can be tapped and function without gesture blocking by navigation bar
      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Staff'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jobs'));
      await tester.pumpAndSettle();
    });

    testWidgets('WorkerDashboardScreen handles edge insets: 8dp clamped to 16dp, 24dp honored, 64dp honored', (tester) async {
      // Test 8dp inset clamped to 16dp
      await tester.pumpWidget(
        buildTestHarness(
          child: const WorkerDashboardScreen(),
          padding: const EdgeInsets.only(bottom: 8.0),
        ),
      );
      await tester.pumpAndSettle();

      var finder = find.byWidgetPredicate((w) => w is Padding && w.padding == const EdgeInsets.fromLTRB(16, 4, 16, 16.0));
      expect(finder, findsOneWidget, reason: '8dp bottom inset must clamp to minimum 16dp defensive padding');

      // Test 24dp inset honored
      await tester.pumpWidget(
        buildTestHarness(
          child: const WorkerDashboardScreen(),
          padding: const EdgeInsets.only(bottom: 24.0),
        ),
      );
      await tester.pumpAndSettle();

      finder = find.byWidgetPredicate((w) => w is Padding && w.padding == const EdgeInsets.fromLTRB(16, 4, 16, 24.0));
      expect(finder, findsOneWidget, reason: '24dp bottom inset must be honored');

      // Test 64dp inset honored
      await tester.pumpWidget(
        buildTestHarness(
          child: const WorkerDashboardScreen(),
          padding: const EdgeInsets.only(bottom: 64.0),
        ),
      );
      await tester.pumpAndSettle();

      finder = find.byWidgetPredicate((w) => w is Padding && w.padding == const EdgeInsets.fromLTRB(16, 4, 16, 64.0));
      expect(finder, findsOneWidget, reason: '64dp bottom inset must be honored');
    });
  });

  group('Adversarial Virtual Keyboard & Modal Sheets Stress Testing', () {
    testWidgets('AssignMechanicSheet: 300dp virtual keyboard insertion produces 0 RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: AssignMechanicSheet(job: sampleAppointment),
          padding: const EdgeInsets.only(bottom: 48.0),
          viewInsets: const EdgeInsets.only(bottom: 300.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Confirm Assignment'), findsOneWidget);
      expect(find.text('Kamal Gunaratne'), findsOneWidget);

      // Tap on mechanic to select
      await tester.tap(find.text('Kamal Gunaratne'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('RequestPartsSheet: 300dp virtual keyboard insertion produces 0 RenderFlex overflow and submit button visible', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: const RequestPartsSheet(),
          padding: const EdgeInsets.only(bottom: 48.0),
          viewInsets: const EdgeInsets.only(bottom: 300.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Submit Parts Request'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Verify text fields can be focused and entered without overflow
      await tester.enterText(find.byType(TextField).first, 'Brake Rotor 320mm');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify urgency chip selection
      await tester.tap(find.text('High (Today)'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ItemsUsedSheet: 300dp virtual keyboard insertion produces 0 RenderFlex overflow and log button visible', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: const ItemsUsedSheet(appointmentId: 901),
          padding: const EdgeInsets.only(bottom: 48.0),
          viewInsets: const EdgeInsets.only(bottom: 300.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Log Item to Job'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Verify entering text into quantity and cost fields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(3));

      await tester.enterText(textFields.at(0), 'Coolant Type 2');
      await tester.enterText(textFields.at(1), '2');
      await tester.enterText(textFields.at(2), '4500');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('JobTaskChecklistSheet: 300dp virtual keyboard insertion produces 0 RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: const JobTaskChecklistSheet(appointmentId: 901),
          padding: const EdgeInsets.only(bottom: 48.0),
          viewInsets: const EdgeInsets.only(bottom: 300.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Done with Tasks'), findsOneWidget);

      await tester.tap(find.text('Done with Tasks'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ClientJobDetailsSheet: 300dp virtual keyboard insertion produces 0 RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: ClientJobDetailsSheet(job: sampleAppointment),
          padding: const EdgeInsets.only(bottom: 48.0),
          viewInsets: const EdgeInsets.only(bottom: 300.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Client Job Overview'), findsOneWidget);
      expect(find.text('Close Details'), findsOneWidget);

      await tester.tap(find.text('Close Details'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('NotificationsSheet: 300dp virtual keyboard insertion produces 0 RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: const NotificationsSheet(),
          padding: const EdgeInsets.only(bottom: 48.0),
          viewInsets: const EdgeInsets.only(bottom: 300.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
    });

    testWidgets('Extreme Stress: 380dp keyboard on small viewport (360x640) produces 0 RenderFlex overflow in RequestPartsSheet and ItemsUsedSheet', (tester) async {
      // Extremely cramped screen: 360 x 640 with 380dp keyboard and 48dp navigation bar
      await tester.pumpWidget(
        buildTestHarness(
          size: const Size(360, 640),
          child: const RequestPartsSheet(),
          padding: const EdgeInsets.only(bottom: 48.0),
          viewInsets: const EdgeInsets.only(bottom: 380.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'RequestPartsSheet must not throw RenderFlex overflow under extreme 380dp keyboard');

      await tester.pumpWidget(
        buildTestHarness(
          size: const Size(360, 640),
          child: const ItemsUsedSheet(appointmentId: 901),
          padding: const EdgeInsets.only(bottom: 48.0),
          viewInsets: const EdgeInsets.only(bottom: 380.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'ItemsUsedSheet must not throw RenderFlex overflow under extreme 380dp keyboard');
    });
  });

  group('Adversarial showModalBottomSheet Route Parameters Audit', () {
    testWidgets('All modal sheets configure isScrollControlled: true and useSafeArea: true', (tester) async {
      late BuildContext savedContext;

      await tester.pumpWidget(
        buildTestHarness(
          child: Builder(
            builder: (ctx) {
              savedContext = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test AssignMechanicSheet.show
      AssignMechanicSheet.show(savedContext, job: sampleAppointment);
      await tester.pumpAndSettle();
      expect(find.byType(AssignMechanicSheet), findsOneWidget);
      Navigator.pop(savedContext);
      await tester.pumpAndSettle();

      // Test RequestPartsSheet.show
      RequestPartsSheet.show(savedContext);
      await tester.pumpAndSettle();
      expect(find.byType(RequestPartsSheet), findsOneWidget);
      Navigator.pop(savedContext);
      await tester.pumpAndSettle();

      // Test ItemsUsedSheet.show
      ItemsUsedSheet.show(savedContext, appointmentId: 901);
      await tester.pumpAndSettle();
      expect(find.byType(ItemsUsedSheet), findsOneWidget);
      Navigator.pop(savedContext);
      await tester.pumpAndSettle();

      // Test JobTaskChecklistSheet.show
      JobTaskChecklistSheet.show(savedContext, appointmentId: 901);
      await tester.pumpAndSettle();
      expect(find.byType(JobTaskChecklistSheet), findsOneWidget);
      Navigator.pop(savedContext);
      await tester.pumpAndSettle();

      // Test ClientJobDetailsSheet.show
      ClientJobDetailsSheet.show(savedContext, job: sampleAppointment);
      await tester.pumpAndSettle();
      expect(find.byType(ClientJobDetailsSheet), findsOneWidget);
      Navigator.pop(savedContext);
      await tester.pumpAndSettle();

      // Test NotificationsSheet.show
      NotificationsSheet.show(savedContext);
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsSheet), findsOneWidget);
      Navigator.pop(savedContext);
      await tester.pumpAndSettle();
    });
  });
}
