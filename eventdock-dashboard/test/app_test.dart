import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventdock_dashboard/main.dart';
import 'package:eventdock_dashboard/screens/waitlist_screen.dart';
import 'package:eventdock_dashboard/screens/not_found_screen.dart';

void main() {
  group('EventDock Waitlist-Only Website Tests', () {
    testWidgets('1. Opening "/" displays the public waitlist landing page', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const EventDockApp(initialRoute: '/'));
      await tester.pumpAndSettle();

      // Verified waitlist elements
      expect(find.byType(WaitlistScreen), findsOneWidget);
      expect(find.text('Understand. Debug. Fix Faster.'), findsOneWidget);
      expect(find.byKey(const Key('waitlist_email_input')), findsOneWidget);
      expect(find.byKey(const Key('waitlist_submit_button')), findsOneWidget);
      expect(find.text('EARLY ACCESS WAITLIST • SPRING BOOT 3.X'), findsOneWidget);
      expect(find.text('EventDock'), findsWidgets);

      // Verify dashboard is NOT rendered
      expect(find.text('Sign in with Google'), findsNothing);
      expect(find.text('Your Projects'), findsNothing);
    });

    testWidgets('2. Opening "/app" cannot display the dashboard and displays 404', (WidgetTester tester) async {
      await tester.pumpWidget(const EventDockApp(initialRoute: '/app'));
      await tester.pumpAndSettle();

      // Must be 404 NotFoundScreen
      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.byKey(const Key('not_found_screen')), findsOneWidget);
      expect(find.text('404 • ROUTE NOT FOUND'), findsOneWidget);
      expect(find.text('Return to Waitlist →'), findsOneWidget);

      // Dashboard screens must be completely absent
      expect(find.text('Your Projects'), findsNothing);
      expect(find.text('Event Inbox'), findsNothing);
      expect(find.text('Sign in with Google'), findsNothing);
      expect(find.text('API Failure Detection & Reproduction'), findsNothing);
    });

    testWidgets('3. Opening "/app/events" cannot display event data or dashboard screens', (WidgetTester tester) async {
      await tester.pumpWidget(const EventDockApp(initialRoute: '/app/events'));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('404 • ROUTE NOT FOUND'), findsOneWidget);

      // Event table elements must never appear
      expect(find.text('ENDPOINT / ROUTE'), findsNothing);
      expect(find.text('5xx Server Errors'), findsNothing);
      expect(find.text('All Events'), findsNothing);
    });

    testWidgets('4. Direct navigation to every other existing route is blocked', (WidgetTester tester) async {
      final blockedRoutes = [
        '/login',
        '/projects',
        '/settings',
        '/api-keys',
        '/replay',
        '/dashboard',
        '/admin',
      ];

      for (final route in blockedRoutes) {
        await tester.pumpWidget(EventDockApp(initialRoute: route));
        await tester.pumpAndSettle();

        expect(find.byType(NotFoundScreen), findsOneWidget, reason: 'Route $route should be blocked');
        expect(find.text('404 • ROUTE NOT FOUND'), findsOneWidget, reason: 'Route $route should show 404');
        expect(find.text('Your Projects'), findsNothing);
        expect(find.text('Sign in with Google'), findsNothing);
      }
    });

    testWidgets('5. Refreshing a disabled route does not expose protected content', (WidgetTester tester) async {
      // First visit /app
      await tester.pumpWidget(const EventDockApp(initialRoute: '/app'));
      await tester.pumpAndSettle();
      expect(find.byType(NotFoundScreen), findsOneWidget);

      // Simulate browser refresh
      await tester.pumpWidget(const EventDockApp(initialRoute: '/app'));
      await tester.pumpAndSettle();

      // Protected content still absent
      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('Your Projects'), findsNothing);
      expect(find.text('Sign in with Google'), findsNothing);
    });

    testWidgets('6. Unknown routes return 404 page and allow returning to "/"', (WidgetTester tester) async {
      await tester.pumpWidget(const EventDockApp(initialRoute: '/unknown/random/deep/path'));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('404 • ROUTE NOT FOUND'), findsOneWidget);

      // Tap Return to Waitlist button
      await tester.tap(find.byKey(const Key('not_found_return_home_button')));
      await tester.pumpAndSettle();

      // Now at waitlist landing screen
      expect(find.byType(WaitlistScreen), findsOneWidget);
      expect(find.byKey(const Key('waitlist_email_input')), findsOneWidget);
    });

    testWidgets('7. Waitlist registration and confirmation behavior work properly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const EventDockApp(initialRoute: '/'));
      await tester.pumpAndSettle();

      // Enter valid email
      await tester.enterText(find.byKey(const Key('waitlist_email_input')), 'developer@acme.dev');
      await tester.pump();

      // Submit
      await tester.ensureVisible(find.byKey(const Key('waitlist_submit_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('waitlist_submit_button')));
      await tester.pumpAndSettle();

      // Success confirmation banner displays
      expect(find.byKey(const Key('waitlist_success_banner')), findsOneWidget);
      expect(find.text("You're on the Waitlist!"), findsOneWidget);
      expect(find.text('Status: Early Access Queue Priority Active'), findsOneWidget);
    });

    testWidgets('8. Responsive layout renders cleanly on mobile portrait viewport', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const EventDockApp(initialRoute: '/'));
      await tester.pumpAndSettle();

      expect(find.byType(WaitlistScreen), findsOneWidget);
      expect(find.byKey(const Key('waitlist_email_input')), findsOneWidget);
      expect(find.text('Understand. Debug. Fix Faster.'), findsOneWidget);
    });

    testWidgets('9. Submitting a duplicate/already registered email notifies user without duplicate email dispatch', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const EventDockApp(initialRoute: '/'));
      await tester.pumpAndSettle();

      // Enter email and submit first time
      await tester.enterText(find.byKey(const Key('waitlist_email_input')), 'duplicate_test@acme.dev');
      await tester.pump();
      await tester.tap(find.byKey(const Key('waitlist_submit_button')));
      await tester.pumpAndSettle();

      // Tap reset to enter same email again
      await tester.tap(find.text('Register another email →'));
      await tester.pumpAndSettle();

      // Enter same email a second time
      await tester.enterText(find.byKey(const Key('waitlist_email_input')), 'duplicate_test@acme.dev');
      await tester.pump();
      await tester.tap(find.byKey(const Key('waitlist_submit_button')));
      await tester.pumpAndSettle();

      // Must notify that they are already a part of the waitlist!
      expect(find.byKey(const Key('waitlist_success_banner')), findsOneWidget);
      expect(find.text("You're already a part of the waitlist!"), findsOneWidget);
    });
  });
}
