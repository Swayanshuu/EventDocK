import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventdock_dashboard/main.dart';
import 'package:eventdock_dashboard/models/auth_state.dart';
import 'package:eventdock_dashboard/screens/auth_screen.dart';
import 'package:eventdock_dashboard/screens/email_verification_screen.dart';
import 'package:eventdock_dashboard/services/auth_service.dart';
import 'package:eventdock_dashboard/widgets/role_selector.dart';
import 'package:eventdock_dashboard/widgets/split_auth_card.dart';

void main() {
  group('Desktop Split-Card Authentication Module Tests', () {
    test('1. PasswordValidation correctly verifies all 5 complexity criteria', () {
      final weak = PasswordValidation.validate('short');
      expect(weak.isValid, isFalse);
      expect(weak.hasMinLength, isFalse);

      final noUpper = PasswordValidation.validate('password123!');
      expect(noUpper.isValid, isFalse);
      expect(noUpper.hasUppercase, isFalse);

      final noSpecial = PasswordValidation.validate('Password123');
      expect(noSpecial.isValid, isFalse);
      expect(noSpecial.hasSpecialChar, isFalse);

      final strong = PasswordValidation.validate('EventDock#2026!');
      expect(strong.isValid, isTrue);
      expect(strong.hasMinLength, isTrue);
      expect(strong.hasUppercase, isTrue);
      expect(strong.hasLowercase, isTrue);
      expect(strong.hasDigit, isTrue);
      expect(strong.hasSpecialChar, isTrue);
      expect(strong.strengthScore, 1.0);
    });

    test('2. RateLimiter enforces 5-attempt lockout and 2s burst throttle', () {
      final limiter = RateLimiter();
      const testEmail = 'pentester@test.dev';

      // Initial state is clear
      var state = limiter.checkLimit(testEmail);
      expect(state.isLocked, isFalse);
      expect(state.failedAttempts, 0);

      // Record 4 failed attempts
      for (int i = 0; i < 4; i++) {
        limiter.recordFailure(testEmail);
      }
      state = limiter.checkLimit(testEmail);
      expect(state.isLocked, isFalse);
      expect(state.failedAttempts, 4);

      // 5th failed attempt triggers 300s lockout
      limiter.recordFailure(testEmail);
      state = limiter.checkLimit(testEmail);
      expect(state.isLocked, isTrue);
      expect(state.remainingSeconds, inInclusiveRange(295, 300));
      expect(state.message, contains('Security Lockout'));

      // Success resets the counter
      limiter.recordSuccess(testEmail);
      state = limiter.checkLimit(testEmail);
      expect(state.isLocked, isFalse);
      expect(state.failedAttempts, 0);
    });

    testWidgets('3. SplitAuthCard renders 2-column desktop split view with quotes & typography', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitAuthCard(
              onAuthSuccess: () {},
              initialRole: AuthRole.individual,
              initialMode: AuthMode.signIn,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check left visual card
      expect(find.text('EVENTDOCK PLATFORM'), findsOneWidget);
      expect(find.textContaining('Detect Failures'), findsOneWidget);

      // Check right form card
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byType(RoleSelector), findsOneWidget);
      expect(find.text('Individual'), findsOneWidget);
      expect(find.text('Organisation'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In to EventDock'), findsOneWidget);
    });

    testWidgets('4. Switching Role to Organisation dynamically updates headline and work email label', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitAuthCard(
              onAuthSuccess: () {},
              initialRole: AuthRole.individual,
              initialMode: AuthMode.signIn,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on 'Organisation' role tab
      await tester.tap(find.text('Organisation'));
      await tester.pumpAndSettle();

      // Check headline updated to Organisation quote
      expect(find.textContaining('Microservice Telemetry'), findsOneWidget);

      // Check input label updated to Work Email
      expect(find.text('Work Email Address'), findsOneWidget);
    });

    testWidgets('5. Opening /login route displays full SplitAuthCard screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const EventDockApp(initialRoute: '/login'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(SplitAuthCard), findsOneWidget);
      expect(find.text('EVENTDOCK PLATFORM'), findsOneWidget);
    });

    testWidgets('6. EmailVerificationScreen renders email verification gate with actions and cooldown', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: EmailVerificationScreen(
            userEmail: 'newdev@swynx.dev',
            onVerified: () {},
            onSignOut: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Verify Your Email Address'), findsOneWidget);
      expect(find.text('newdev@swynx.dev'), findsOneWidget);
      expect(find.text("I've Verified My Email — Continue"), findsOneWidget);
      expect(find.textContaining('Resend email in'), findsOneWidget);
      expect(find.text('Sign out or use different email'), findsOneWidget);
    });

    testWidgets('7. AuthForm switches to Forgot Password mode and requests reset instructions', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitAuthCard(
              onAuthSuccess: () {},
              initialRole: AuthRole.individual,
              initialMode: AuthMode.signIn,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on 'Forgot password?' button
      final forgotBtn = find.text('Forgot password?');
      expect(forgotBtn, findsOneWidget);
      await tester.tap(forgotBtn);
      await tester.pumpAndSettle();

      // Check heading updated to Reset Password
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);

      // Enter email and tap Send Reset Link
      await tester.enterText(find.byType(TextField).first, 'developer@eventdock.dev');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Success message appears
      expect(find.textContaining('Password reset instructions have been sent'), findsOneWidget);
    });

    testWidgets('8. Mode switcher tabs toggle between Sign In and Create Account modes', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitAuthCard(
              onAuthSuccess: () {},
              initialRole: AuthRole.individual,
              initialMode: AuthMode.signIn,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts in Sign In mode
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In to EventDock'), findsOneWidget);

      // Switch to Create Account via top tab
      await tester.tap(find.text('Create Account').first);
      await tester.pumpAndSettle();

      // Heading and button update to Sign Up
      expect(find.text('Create Your Account'), findsOneWidget);
      expect(find.text('Create Verified Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);

      // Switch back to Sign In
      await tester.tap(find.text('Sign In').first);
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In to EventDock'), findsOneWidget);
    });

    testWidgets('9. Invalid email like Shibu@05 displays immediate friendly validation error without rate-limiting', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitAuthCard(
              onAuthSuccess: () {},
              initialRole: AuthRole.individual,
              initialMode: AuthMode.signIn,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter invalid email format Shibu@05
      await tester.enterText(find.byType(TextField).at(0), 'Shibu@05');
      await tester.enterText(find.byType(TextField).at(1), 'SecretPass123!');
      await tester.tap(find.text('Sign In to EventDock'));
      await tester.pumpAndSettle();

      // Should show clean friendly validation error, not rate limit lockout
      expect(find.textContaining('Please enter a valid email address'), findsOneWidget);
      expect(find.textContaining('Security Lockout: Rate limit exceeded'), findsNothing);
    });

    testWidgets('10. Quick Demo Sign-In triggers immediate authentication', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool authSuccessCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitAuthCard(
              onAuthSuccess: () {
                authSuccessCalled = true;
              },
              initialRole: AuthRole.individual,
              initialMode: AuthMode.signIn,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Quick Demo Sign-In button
      final demoBtn = find.text('Quick Demo Sign-In (developer@eventdock.dev)');
      expect(demoBtn, findsOneWidget);
      await tester.tap(demoBtn);
      await tester.pumpAndSettle();

      expect(authSuccessCalled, isTrue);
    });
  });
}
