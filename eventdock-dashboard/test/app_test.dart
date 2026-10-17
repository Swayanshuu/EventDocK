import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventdock_dashboard/main.dart';
import 'package:eventdock_dashboard/screens/project_dashboard_screen.dart';
import 'package:eventdock_dashboard/screens/waitlist_screen.dart';
import 'package:eventdock_dashboard/screens/not_found_screen.dart';
import 'package:eventdock_dashboard/services/auth_service.dart';

void main() {
  group('EventDock Dashboard App Tests', () {
    setUp(() async {
      await AuthService().signInWithGoogle(googleEmail: 'developer@eventdock.dev');
    });

    testWidgets('1. Opening "/" displays the actual FinPoint-style developer dashboard', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const EventDockApp(initialRoute: '/'));
      await tester.pumpAndSettle();

      // Verified dashboard elements
      expect(find.byType(ProjectDashboardScreen), findsOneWidget);
      expect(find.text('Failure Ingestion Velocity'), findsOneWidget);
      expect(find.text('Stability Score'), findsOneWidget);
      expect(find.text('Service Fault Metrics'), findsOneWidget);
      expect(find.text('Failure Distribution'), findsOneWidget);
      expect(find.text('Endpoints'), findsOneWidget);
    });

    testWidgets('2. Opening "/waitlist" displays the waitlist landing page', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const EventDockApp(initialRoute: '/waitlist'));
      await tester.pumpAndSettle();

      expect(find.byType(WaitlistScreen), findsOneWidget);
      expect(find.text('Understand. Debug. Fix Faster.'), findsOneWidget);
      expect(find.byKey(const Key('waitlist_email_input')), findsOneWidget);
    });

    testWidgets('3. Unknown routes display 404 NotFoundScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const EventDockApp(initialRoute: '/unknown/random/route'));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('404 • ROUTE NOT FOUND'), findsOneWidget);
    });

    testWidgets('4. Switching projects from dropdown updates dashboard state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const EventDockApp(initialRoute: '/'));
      await tester.pumpAndSettle();

      // Tap on the project switcher popup menu button
      final projectPill = find.byTooltip('Switch project');
      expect(projectPill, findsOneWidget);
      await tester.tap(projectPill);
      await tester.pumpAndSettle();

      // Check popup menu items
      expect(find.text('PROJECTS'), findsOneWidget);
      expect(find.text('Auth Service'), findsOneWidget);

      // Select 'Auth Service'
      await tester.tap(find.text('Auth Service').last);
      await tester.pumpAndSettle();

      // Assert project name is now Auth Service
      expect(find.text('Auth Service'), findsWidgets);
    });
  });
}

