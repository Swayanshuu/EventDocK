import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HeroFailureChart extends StatefulWidget {
  final List<double>? dataPoints;
  final int totalFailures;
  final int count5xx;
  final int count4xx;

  const HeroFailureChart({
    super.key,
    this.dataPoints,
    this.totalFailures = 0,
    this.count5xx = 0,
    this.count4xx = 0,
  });

  @override
  State<HeroFailureChart> createState() => _HeroFailureChartState();
}

class _HeroFailureChartState extends State<HeroFailureChart> with SingleTickerProviderStateMixin {
  int _selectedTimeframeIndex = 4; // '1Y' active by default
  final List<String> _timeframes = ['1D', '1W', '1M', '3M', '1Y', 'All'];

  final List<String> _months = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  double? _hoverFraction; // 0.0 to 1.0
  late AnimationController _animController;
  late Animation<double> _anim;

  List<double> get _effectivePoints {
    if (widget.dataPoints != null && widget.dataPoints!.isNotEmpty) {
      return widget.dataPoints!;
    }
    if (widget.totalFailures == 0) {
      return List.filled(12, 0.05);
    }
    return const [
      0.18, 0.20, 0.22, 0.28, 0.35, 0.38, 0.42, 0.50, 0.72, 0.85, 0.65, 0.58,
      0.70, 0.62, 0.48, 0.52, 0.45, 0.38, 0.42, 0.35, 0.38, 0.32, 0.28, 0.25,
    ];
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant HeroFailureChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalFailures != widget.totalFailures ||
        oldWidget.count5xx != widget.count5xx ||
        oldWidget.count4xx != widget.count4xx) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = _effectivePoints;

    return Container(
      padding: const EdgeInsets.all(24),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Failure Ingestion Velocity',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text(
                          widget.totalFailures == 0
                              ? '0 Errors'
                              : '${widget.totalFailures} Failures',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.cardSecondary,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.totalFailures == 0 ? Icons.check_circle_outline : Icons.error_outline,
                                color: widget.totalFailures == 0 ? const Color(0xFF22C55E) : AppTheme.heroCoral,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.totalFailures == 0
                                    ? 'Healthy'
                                    : '${widget.count5xx} (5xx) · ${widget.count4xx} (4xx)',
                                style: TextStyle(
                                  color: widget.totalFailures == 0 ? const Color(0xFF22C55E) : AppTheme.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Segmented Timeframe Controls
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.pillBackground,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.pillBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_timeframes.length, (idx) {
                    final isSelected = _selectedTimeframeIndex == idx;
                    final label = _timeframes[idx];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTimeframeIndex = idx;
                          _hoverFraction = null;
                        });
                        _animController.forward(from: 0.0);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.cardSecondary : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: isSelected ? Border.all(color: AppTheme.cardBorderLight) : null,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Custom Spline Chart Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MouseRegion(
                  onHover: (e) {
                    setState(() {
                      _hoverFraction = (e.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _hoverFraction = null;
                    });
                  },
                  child: GestureDetector(
                    onHorizontalDragUpdate: (e) {
                      setState(() {
                        _hoverFraction = (e.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                      });
                    },
                    child: Stack(
                      children: [
                        // Background guide labels
                        Positioned(
                          top: 8,
                          left: 0,
                          child: Text(
                            widget.totalFailures == 0 ? '0' : '100%',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Positioned(
                          top: constraints.maxHeight * 0.45,
                          left: 0,
                          child: Text(
                            widget.totalFailures == 0 ? '0' : '50%',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),

                        // The Interactive Curve Canvas
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _anim,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: _SplineChartPainter(
                                  points: points,
                                  progress: _anim.value,
                                  hoverFraction: _hoverFraction,
                                ),
                              );
                            },
                          ),
                        ),

                        // Floating Dark Tooltip Card on Hover
                        if (_hoverFraction != null && widget.totalFailures > 0)
                          _buildHoverTooltip(constraints.maxWidth, constraints.maxHeight, points),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // X-Axis Month Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _months.map((m) {
              return Text(
                m,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHoverTooltip(double maxWidth, double maxHeight, List<double> points) {
    final x = (maxWidth * _hoverFraction!).clamp(60.0, maxWidth - 80.0);
    final idx = ((points.length - 1) * _hoverFraction!).round().clamp(0, points.length - 1);
    final val = (points[idx] * (widget.totalFailures > 0 ? widget.totalFailures : 10)).round();

    return Positioned(
      left: x - 60,
      top: 10,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.shell,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Failures',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
                Text(
                  '$val',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: (val > 0 ? AppTheme.status5xx : const Color(0xFF22C55E)).withOpacity(0.16),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                val > 0 ? 'Critical' : 'Healthy',
                style: TextStyle(
                  color: val > 0 ? AppTheme.status5xx : const Color(0xFF22C55E),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplineChartPainter extends CustomPainter {
  final List<double> points;
  final double progress;
  final double? hoverFraction;

  _SplineChartPainter({
    required this.points,
    required this.progress,
    required this.hoverFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final leftOffset = 28.0;
    final w = size.width - leftOffset;
    final h = size.height - 16;
    final top = 8.0;

    // Subtle horizontal dashed guide lines
    final guidePaint = Paint()
      ..color = AppTheme.cardBorder.withOpacity(0.65)
      ..strokeWidth = 1.0;

    const dashWidth = 4.0;
    const dashSpace = 4.0;

    for (final ratio in [0.15, 0.5, 0.85]) {
      final y = top + h * ratio;
      double startX = leftOffset;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(math.min(startX + dashWidth, size.width), y),
          guidePaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    // Build Spline Path
    final path = Path();
    final fillPath = Path();

    final stepX = w / (points.length - 1);
    final coords = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final x = leftOffset + i * stepX;
      final y = top + h * (1.0 - (points[i] * progress));
      coords.add(Offset(x, y));
    }

    path.moveTo(coords[0].dx, coords[0].dy);
    fillPath.moveTo(coords[0].dx, top + h);
    fillPath.lineTo(coords[0].dx, coords[0].dy);

    for (int i = 0; i < coords.length - 1; i++) {
      final p0 = i > 0 ? coords[i - 1] : coords[i];
      final p1 = coords[i];
      final p2 = coords[i + 1];
      final p3 = i < coords.length - 2 ? coords[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      fillPath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    fillPath.lineTo(coords.last.dx, top + h);
    fillPath.close();

    // 1. Draw smooth vertical gradient under the spline
    final fillGradient = ui.Gradient.linear(
      Offset(0, top),
      Offset(0, top + h),
      [
        AppTheme.heroCoral.withOpacity(0.22),
        AppTheme.heroCoral.withOpacity(0.01),
      ],
    );
    final fillPaint = Paint()
      ..shader = fillGradient
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 2. Stroke the vivid coral curve
    final linePaint = Paint()
      ..color = AppTheme.heroCoral
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // 3. Hover Scrubber
    if (hoverFraction != null) {
      final hx = (leftOffset + w * hoverFraction!).clamp(leftOffset, size.width);

      // Light highlight pillar behind scrubber
      final pillarPaint = Paint()..color = Colors.white.withOpacity(0.04);
      canvas.drawRect(Rect.fromLTWH(hx - 12, top, 24, h), pillarPaint);

      // Vertical dashed line
      final scrubberPaint = Paint()
        ..color = AppTheme.textMuted.withOpacity(0.5)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(hx, top), Offset(hx, top + h), scrubberPaint);

      // Dot on curve
      final idx = ((coords.length - 1) * hoverFraction!).round().clamp(0, coords.length - 1);
      final dotPos = coords[idx];

      final outerDot = Paint()..color = Colors.white;
      final innerDot = Paint()..color = AppTheme.heroCoral;

      canvas.drawCircle(dotPos, 5, outerDot);
      canvas.drawCircle(dotPos, 2.5, innerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _SplineChartPainter old) {
    return old.progress != progress || old.hoverFraction != hoverFraction || old.points != points;
  }
}
