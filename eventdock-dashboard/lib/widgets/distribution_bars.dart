import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DistributionBarsCard extends StatelessWidget {
  final int totalCount;
  final int count5xx;
  final int countDeadlocks;
  final int count4xx;
  final int countOther;

  const DistributionBarsCard({
    super.key,
    this.totalCount = 0,
    this.count5xx = 0,
    this.countDeadlocks = 0,
    this.count4xx = 0,
    this.countOther = 0,
  });

  @override
  Widget build(BuildContext context) {
    final int safeTotal = totalCount > 0 ? totalCount : 1;
    final int p5xx = totalCount > 0 ? (count5xx / safeTotal * 100).round() : 0;
    final int p503 = totalCount > 0 ? (countDeadlocks / safeTotal * 100).round() : 0;
    final int p4xx = totalCount > 0 ? (count4xx / safeTotal * 100).round() : 0;
    final int pOther = totalCount > 0 ? (countOther / safeTotal * 100).round() : 0;

    final double f5xx = totalCount > 0 ? (p5xx / 100.0).clamp(0.12, 0.95) : 0.08;
    final double f503 = totalCount > 0 ? (p503 / 100.0).clamp(0.12, 0.95) : 0.08;
    final double f4xx = totalCount > 0 ? (p4xx / 100.0).clamp(0.12, 0.95) : 0.08;
    final double fOther = totalCount > 0 ? (pOther / 100.0).clamp(0.12, 0.95) : 0.08;

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
              Expanded(
                child: Text(
                  'Failure Distribution',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('HTTP code', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 14, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.cardSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Icon(Icons.bar_chart, size: 14, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // The 4 Geometric Distribution Columns
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBarCol(
                  label: '500 Server',
                  percent: '$p5xx%',
                  heightFraction: f5xx,
                  color: AppTheme.heroCoral,
                ),
                const SizedBox(width: 12),
                _buildBarCol(
                  label: '503 Deadlock',
                  percent: '$p503%',
                  heightFraction: f503,
                  color: const Color(0xFFFACC15),
                ),
                const SizedBox(width: 12),
                _buildBarCol(
                  label: '400 Client',
                  percent: '$p4xx%',
                  heightFraction: f4xx,
                  color: AppTheme.isDark ? Colors.white : const Color(0xFF3B82F6),
                  textColor: AppTheme.isDark ? Colors.black : Colors.white,
                ),
                const SizedBox(width: 12),
                _buildBarCol(
                  label: 'Other',
                  percent: '$pOther%',
                  heightFraction: fOther,
                  color: AppTheme.cardSecondary,
                  isPattern: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarCol({
    required String label,
    required String percent,
    required double heightFraction,
    required Color color,
    Color textColor = Colors.white,
    bool isPattern = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // The block
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: heightFraction,
                widthFactor: 1.0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: isPattern ? Border.all(color: AppTheme.cardBorder) : null,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      percent,
                      style: TextStyle(
                        color: isPattern ? AppTheme.textMuted : textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}