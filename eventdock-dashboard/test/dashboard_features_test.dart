import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventdock_dashboard/main.dart';
import 'package:eventdock_dashboard/services/auth_service.dart';
import 'package:eventdock_dashboard/widgets/command_palette_dialog.dart';
import 'package:eventdock_dashboard/widgets/export_dialog.dart';
import 'package:eventdock_dashboard/widgets/notifications_panel.dart';

void main() {
  group('Interactive SaaS Dashboard Features Tests', () {
    setUp(() async {
      await AuthService().signInWithGoogle(googleEmail: 'developer@eventdock.dev');
    });

    testWidgets('1. Clicking TopBar Search triggers Command Palette Dialog with full search capabilities', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const EventDockApp(initialRoute: '/'));
      await tester.pumpAndSettle();

      // Tap on search bar
      final searchBarFinder = find.text('Search anything... (⌘K / Ctrl+K)');
      expect(searchBarFinder, findsOneWidget);
      await tester.tap(searchBarFinder);
      await tester.pumpAndSettle();

      // Verify CommandPaletteDialog opened
      expect(find.byType(CommandPaletteDialog), findsOneWidget);
      expect(find.text('Search pages, endpoints, projects, actions...'), findsOneWidget);
      expect(find.text('Dashboard Overview'), findsOneWidget);
      expect(find.text('Event Inbox & Failures'), findsOneWidget);
      expect(find.text('Export Telemetry Data'), findsOneWidget);

      // Type in search query to filter
      await tester.enterText(find.byType(TextField), 'inbox');
      await tester.pumpAndSettle();

      expect(find.text('Event Inbox & Failures'), findsOneWidget);

      // Tap on Event Inbox item to navigate
      await tester.tap(find.text('Event Inbox & Failures'));
      await tester.pumpAndSettle();

      // Command palette should dismiss
      expect(find.byType(CommandPaletteDialog), findsNothing);
    });

    testWidgets('2. Export Button opens ExportDialog with format selector and telemetry scope options', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const EventDockApp(initialRoute: '/'));
      await tester.pumpAndSettle();

      // Tap on the Export button in TopBar
      final exportBtn = find.widgetWithText(ElevatedButton, 'Export');
      expect(exportBtn, findsOneWidget);
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      // Verify ExportDialog opened
      expect(find.byType(ExportDialog), findsOneWidget);
      expect(find.text('Export Telemetry Data'), findsOneWidget);
      expect(find.text('JSON Document'), findsOneWidget);
      expect(find.text('CSV Spreadsheet'), findsOneWidget);

      // Select CSV format
      await tester.tap(find.text('CSV Spreadsheet'));
      await tester.pumpAndSettle();

      // Click Export Telemetry
      final exportActionBtn = find.widgetWithText(ElevatedButton, 'Export Telemetry');
      expect(exportActionBtn, findsOneWidget);
      await tester.tap(exportActionBtn);
      await tester.pumpAndSettle();

      // Dialog should close after export
      expect(find.byType(ExportDialog), findsNothing);
    });

    testWidgets('3. Notification Bell opens NotificationsPanel with unread count and filters', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const EventDockApp(initialRoute: '/'));
      await tester.pumpAndSettle();

      // Tap on Notification Bell (has tooltip 'Notifications' when no unread)
      final notifTooltip = find.byTooltip('Notifications');
      expect(notifTooltip, findsOneWidget);
      await tester.tap(notifTooltip);
      await tester.pumpAndSettle();

      // Verify NotificationsPanel opened
      expect(find.byType(NotificationsPanel), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All caught up'), findsOneWidget);

      // Tap 'Unread' filter
      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();
      expect(find.text('All caught up'), findsOneWidget);
    });
  });
}
