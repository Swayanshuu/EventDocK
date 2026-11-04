import 'package:flutter/material.dart';
import '../models/auth_state.dart';
import '../theme/app_theme.dart';
import 'auth_form.dart';

class SplitAuthCard extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  final AuthRole initialRole;
  final AuthMode initialMode;

  const SplitAuthCard({
    super.key,
    required this.onAuthSuccess,
    this.initialRole = AuthRole.individual,
    this.initialMode = AuthMode.signIn,
  });

  @override
  State<SplitAuthCard> createState() => _SplitAuthCardState();
}

class _SplitAuthCardState extends State<SplitAuthCard> {
  late AuthRole _activeRole;

  @override
  void initState() {
    super.initState();
    _activeRole = widget.initialRole;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    // Keep between few px from top and bottom (16px margins)
    const verticalMargin = 16.0;
    final targetCardHeight = (screenHeight - (verticalMargin * 2)).clamp(640.0, 1200.0);

    return Container(
      color: AppTheme.background,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: verticalMargin,
          ),
          child: Container(
            height: isDesktop ? targetCardHeight : null,
            constraints: BoxConstraints(
              maxWidth: 1360,
              minHeight: isDesktop ? targetCardHeight : 620,
              maxHeight: isDesktop ? targetCardHeight : double.infinity,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.cardBorder,
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 36,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Visual Card (50%)
                      Expanded(
                        child: _buildLeftVisualCard(),
                      ),

                      // Panel dividing border
                      Container(
                        width: 1,
                        color: const Color(0xFFE5E7EB),
                      ),

                      // Right Form Card (50%)
                      Expanded(
                        child: AuthForm(
                          initialRole: _activeRole,
                          initialMode: widget.initialMode,
                          onRoleChanged: (newRole) {
                            setState(() => _activeRole = newRole);
                          },
                          onAuthSuccess: widget.onAuthSuccess,
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 240,
                          width: double.infinity,
                          child: _buildLeftVisualCard(isCompact: true),
                        ),
                        AuthForm(
                          initialRole: _activeRole,
                          initialMode: widget.initialMode,
                          onRoleChanged: (newRole) {
                            setState(() => _activeRole = newRole);
                          },
                          onAuthSuccess: widget.onAuthSuccess,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftVisualCard({bool isCompact = false}) {
    final isIndividual = _activeRole == AuthRole.individual;

    final headline = isIndividual
        ? 'Prove Your Skills.\nShip With Precision.'
        : 'Hire Verified Talent.\nBenchmark Teams.';

    final subtitle = isIndividual
        ? 'Empirical developer benchmarking and automated failure reproduction. Prove competence with verified performance.'
        : 'Streamline technical evaluation with deterministic reproduction pipelines and verified performance baselines.';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF090A0E), // Deep black background
      ),
      child: Stack(
        children: [
          // Background Illustration / Artwork
          Positioned.fill(
            child: Image.asset(
              'assets/auth_mascot.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFF090A0E));
              },
            ),
          ),

          // Geometric Dark Radial/Gradient Overlay for Legibility
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xD9090A0E), // Soft dark tint at the top
                    Color(0x73090A0E), // Clear center showing the vibrant mascot artwork
                    Color(0xF2090A0E), // Deep solid obsidian at the bottom for crisp headline text
                  ],
                  stops: [0.0, 0.45, 0.82],
                ),
              ),
            ),
          ),

          // Architectural Grid Lines Background
          Positioned.fill(
            child: CustomPaint(
              painter: _ArchitecturalGridPainter(),
            ),
          ),

          // Foreground Content
          Padding(
            padding: EdgeInsets.all(isCompact ? 24 : 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag: PLATFORM with Divider
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'EVENTDOCK PLATFORM',
                        style: TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Center Typography: Large Serif Headline & Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: Text(
                        headline,
                        key: ValueKey<String>(headline),
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF9FAFB),
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: Text(
                        subtitle,
                        key: ValueKey<String>(subtitle),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchitecturalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x0CFFFFFF)
      ..strokeWidth = 1;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
