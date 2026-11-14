import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventdock_dashboard/main.dart';
import 'package:eventdock_dashboard/services/auth_service.dart';
import 'package:eventdock_dashboard/theme/app_theme.dart';
import 'package:eventdock_dashboard/widgets/common_widgets.dart';

void main() {
  group('Dual Theme System Tests (Black & Orange vs. White & Orange)', () {
    setUp(() async {
      AppTheme.setThemeMode(ThemeMode.dark);
      await AuthService().signInWithGoogle(googleEmail: 'developer@eventdock.dev');
    });

    tearDown(() {
      AppTheme.setThemeMode(ThemeMode.dark);
    });

    test('1. Dark Theme tokens match Black & Orange specifications', () {
      AppTheme.setThemeMode(ThemeMode.dark);

      expect(AppTheme.isDark, isTrue);
      expect(AppTheme.heroOrange, const Color(0xFFFF5500));
      expect(AppTheme.background, const Color(0xFF090A0D));
      expect(AppTheme.sidebar, const Color(0xFF0C0D12));
      expect(AppTheme.shell, const Color(0xFF101117));
      expect(AppTheme.card, const Color(0xFF161820));
      expect(AppTheme.cardBorder, const Color(0xFF262936));
      expect(AppTheme.textPrimary, const Color(0xFFF6F7FA));
      expect(AppTheme.textMuted, const Color(0xFF8B92A2));
    });

    test('2. Light Theme tokens match White & Orange specifications', () {
      AppTheme.setThemeMode(ThemeMode.light);

      expect(AppTheme.isDark, isFalse);
      expect(AppTheme.heroOrange, const Color(0xFFFF5500));
      expect(AppTheme.background, const Color(0xFFFFFFFF));
      expect(AppTheme.sidebar, const Color(0xFFF8F9FB));
      expect(AppTheme.shell, const Color(0xFFF3F4F7));
      expect(AppTheme.card, const Color(0xFFFFFFFF));
      expect(AppTheme.cardBorder, const Color(0xFFE2E4E9));
      expect(AppTheme.textPrimary, const Color(0xFF0F1115));
      expect(AppTheme.textMuted, const Color(0xFF64748B));
    });

    test('3. toggleThemeMode switches between Dark and Light mode seamlessly', () {
      AppTheme.setThemeMode(ThemeMode.dark);
      expect(AppTheme.isDark, isTrue);

      AppTheme.toggleThemeMode();
      expect(AppTheme.isDark, isFalse);
      expect(AppTheme.background, const Color(0xFFFFFFFF));

      AppTheme.toggleThemeMode();
      expect(AppTheme.isDark, isTrue);
      expect(AppTheme.background, const Color(0xFF090A0D));
    });

    testWidgets('4. Tapping Theme Toggle button in Dashboard TopBar re-renders entire UI', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      AppTheme.setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(const EventDockApp(initialRoute: '/'));
      await tester.pumpAndSettle();

      // Find the Theme Toggle tooltip
      final lightModeTooltipFinder = find.byTooltip('Switch to Light Mode (White & Orange)');
      expect(lightModeTooltipFinder, findsOneWidget);

      // Tap Theme Mode button to switch to Light Mode
      await tester.tap(lightModeTooltipFinder);
      await tester.pumpAndSettle();

      // Verify theme switched to Light
      expect(AppTheme.isDark, isFalse);
      expect(find.byTooltip('Switch to Dark Mode (Black & Orange)'), findsOneWidget);

      // Verify Scaffold background is pure white in Light Mode
      final lightScaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(lightScaffold.backgroundColor, equals(const Color(0xFFFFFFFF)));

      // Tap again to switch back to Dark Mode
      await tester.tap(find.byTooltip('Switch to Dark Mode (Black & Orange)'));
      await tester.pumpAndSettle();

      expect(AppTheme.isDark, isTrue);
      expect(find.byTooltip('Switch to Light Mode (White & Orange)'), findsOneWidget);

      // Verify Scaffold background is matte black in Dark Mode
      final darkScaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(darkScaffold.backgroundColor, equals(const Color(0xFF090A0D)));
    });

    testWidgets('5. EventDockLogo renders EventDock-LOGO-BLACK for light theme and EventDock-LOGO-WHITE for dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const Scaffold(body: EventDockLogo()),
        ),
      );
      await tester.pumpAndSettle();

      final lightImageFinder = find.byType(Image);
      expect(lightImageFinder, findsOneWidget);
      final lightImage = tester.widget<Image>(lightImageFinder);
      expect((lightImage.image as AssetImage).assetName, 'assets/EventDock-LOGO-BLACK.png');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: EventDockLogo()),
        ),
      );
      await tester.pumpAndSettle();

      final darkImageFinder = find.byType(Image);
      expect(darkImageFinder, findsOneWidget);
      final darkImage = tester.widget<Image>(darkImageFinder);
      expect((darkImage.image as AssetImage).assetName, 'assets/EventDock-LOGO-WHITE.png');
    });
  });
}

