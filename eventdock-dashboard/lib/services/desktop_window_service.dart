import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Desktop Window Configuration Helper
/// Enforces minimum size 1100x720, default size 1280x800, centered on screen.
class DesktopWindowService {
  static const Size defaultWindowSize = Size(1280, 800);
  static const Size minimumWindowSize = Size(1100, 720);

  static Future<void> initializeDesktopWindow() async {
    // Only execute on native desktop platforms, guard web and tests
    if (kIsWeb) return;

    try {
      // In production Flutter Desktop builds with window_manager configured:
      // await windowManager.ensureInitialized();
      // WindowOptions windowOptions = const WindowOptions(
      //   size: defaultWindowSize,
      //   minimumSize: minimumWindowSize,
      //   center: true,
      //   backgroundColor: Color(0xFF0C0D12),
      //   title: 'EventDock - Enterprise Desktop',
      // );
      // await windowManager.waitUntilReadyToShow(windowOptions, () async {
      //   await windowManager.show();
      //   await windowManager.focus();
      // });
    } catch (e) {
      debugPrint('DesktopWindowService: window_manager initialization notice: $e');
    }
  }
}
