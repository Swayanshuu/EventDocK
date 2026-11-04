import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StabilityGaugeCard extends StatelessWidget {
  final double score; // 0.0 to 100.0
  final int count5xx;
  final int count4xx;

  const StabilityGaugeCard({
    super.key,
    this.score = 100.0,
    this.count5xx = 0,
    this.count4xx = 0,
  });

  @override
  Widget build(BuildContext context) {
    Color gaugeColor;
    if (score >= 80) {
      gaugeColor = const Color(0xFF22C55E);
    } else if (score >= 50) {
      gaugeColor = const Color(0xFFFACC15);
    } else {
      gaugeColor = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stability Score',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.cardSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Icon(Icons.arrow_outward, size: 14, color: AppTheme.textMuted),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Big Score Reading
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${score.toInt()}',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/100',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Gauge Canvas
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.8,
                child: CustomPaint(
                  painter: _RadialGaugePainter(
                    fraction: (score / 100.0).clamp(0.0, 1.0),
                    activeColor: gaugeColor,
                    isDark: AppTheme.isDark,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Center(
            child: Text(
              score >= 95
                  ? 'All endpoints healthy · 0 critical errors'
                  : '$count5xx server errors (5xx) · $count4xx client errors (4xx)',
              style: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  final double fraction;
  final Color activeColor;
  final bool isDark;

  _RadialGaugePainter({
    required this.fraction,
    this.activeColor = const Color(0xFF22C55E),
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = math.min(size.width * 0.44, size.height * 0.88);
    const strokeWidth = 14.0;

    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // Background track arc
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF262632) : const Color(0xFFE2E4E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active Arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * fraction,
      false,
      activePaint,
    );

    // Knob indicator at the tip
    final currentAngle = startAngle + (sweepAngle * fraction);
    final knobX = center.dx + radius * math.cos(currentAngle);
    final knobY = center.dy + radius * math.sin(currentAngle);

    final knobOuter = Paint()..color = isDark ? Colors.white : const Color(0xFF0F1115);
    final knobInner = Paint()..color = isDark ? const Color(0xFF0C0C0E) : Colors.white;

    canvas.drawCircle(Offset(knobX, knobY), strokeWidth * 0.58, knobOuter);
    canvas.drawCircle(Offset(knobX, knobY), strokeWidth * 0.28, knobInner);
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter old) {
    return old.fraction != fraction || old.activeColor != activeColor || old.isDark != isDark;
  }
}