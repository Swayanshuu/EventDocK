import 'package:flutter/material.dart';
import '../models/diagnostic_event.dart';
import '../theme/app_theme.dart';

class EndpointTickerStrip extends StatelessWidget {
  final List<DiagnosticEventSummary> events;
  final String defaultServiceName;

  const EndpointTickerStrip({
    super.key,
    this.events = const [],
    this.defaultServiceName = 'service',
  });

  @override
  Widget build(BuildContext context) {
    // Group events by route
    final Map<String, DiagnosticEventSummary> latestByRoute = {};
    for (final e in events) {
      final key = e.routeTemplate ?? e.requestUri;
      latestByRoute.putIfAbsent(key, () => e);
    }

    final items = latestByRoute.values.toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          // Left Label
          Text(
            'Endpoints',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 28, color: AppTheme.cardBorder),
          const SizedBox(width: 16),

          // Horizontal list of endpoints
          Expanded(
            child: items.isEmpty
                ? Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.status2xx.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 14, color: AppTheme.status2xx),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'All endpoints healthy · No active failure traces recorded',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: items.map((e) {
                        final is5xx = e.statusCode >= 500;
                        final color = is5xx ? AppTheme.status5xx : AppTheme.status4xx;
                        final route = '${e.httpMethod} ${e.routeTemplate ?? e.requestUri}';
                        final latency = '${e.durationMs ?? 0}ms';

                        return Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: _buildEndpointItem(
                            icon: is5xx ? Icons.warning_amber_rounded : Icons.info_outline,
                            service: e.serviceName ?? defaultServiceName,
                            route: route,
                            status: '${e.statusCode}',
                            latency: latency,
                            color: color,
                            sparklinePoints: [
                              0.3,
                              (e.statusCode >= 500 ? 0.8 : 0.4),
                              0.5,
                              (e.durationMs != null && e.durationMs! > 200 ? 0.9 : 0.6),
                              0.7,
                              (e.statusCode >= 500 ? 0.95 : 0.5),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),

          const SizedBox(width: 12),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.cardSecondary,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointItem({
    required IconData icon,
    required String service,
    required String route,
    required String status,
    required String latency,
    required Color color,
    required List<double> sparklinePoints,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              service,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    route,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$status · $latency',
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Mini sparkline
        SizedBox(
          width: 44,
          height: 18,
          child: CustomPaint(
            painter: _SparklinePainter(points: sparklinePoints, color: color),
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final path = Path();
    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height * (1.0 - points[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => false;
}