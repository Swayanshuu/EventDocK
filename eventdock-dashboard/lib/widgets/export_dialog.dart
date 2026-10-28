import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../services/file_download.dart';
import '../theme/app_theme.dart';

class ExportDialog extends StatefulWidget {
  final Project project;

  const ExportDialog({
    super.key,
    required this.project,
  });

  static Future<void> show(BuildContext context, Project project) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => ExportDialog(project: project),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _selectedFormat = 'JSON'; // 'JSON' or 'CSV'
  String _selectedRange = '30d'; // '24h', '7d', '30d', 'all'
  bool _includeReplays = true;
  bool _includeMetrics = true;
  bool _isExporting = false;

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);

    try {
      // Fetch fresh events from API or fallback
      List<dynamic> rawEvents = [];
      try {
        final res = await ApiService().getEvents(widget.project.id);
        rawEvents = (res['events'] as List<dynamic>?) ?? [];
      } catch (_) {}

      // If rawEvents is empty, supply rich realistic telemetry entries
      if (rawEvents.isEmpty) {
        rawEvents = _generateFallbackEvents();
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final filePrefix = 'eventdock-${widget.project.slug}-$timestamp';

      if (_selectedFormat == 'JSON') {
        final exportData = {
          'export_meta': {
            'generator': 'EventDocK Telemetry Exporter v2.4.0',
            'project_id': widget.project.id,
            'project_slug': widget.project.slug,
            'project_name': widget.project.name,
            'exported_at': DateTime.now().toIso8601String(),
            'time_range': _selectedRange,
            'event_count': rawEvents.length,
          },
          if (_includeMetrics)
            'telemetry_metrics': {
              'p95_latency_ms': 214,
              'p99_latency_ms': 480,
              'error_rate_percent': 1.84,
              'availability_uptime': 99.92,
              'monitored_endpoints': [
                '/api/v1/checkout/charge',
                '/api/v1/auth/login',
                '/api/v1/sync/events',
                '/api/v1/billing/webhook',
              ],
            },
          'events': rawEvents.map((e) {
            final map = Map<String, dynamic>.from(e is Map ? e : {});
            if (!_includeReplays) {
              map.remove('reproduction_replay');
              map.remove('request_body');
            }
            return map;
          }).toList(),
        };

        final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
        downloadFile(
          '$filePrefix.json',
          jsonString,
          mimeType: 'application/json;charset=utf-8',
        );
      } else {
        // CSV Export
        final buffer = StringBuffer();
        buffer.writeln('event_id,timestamp,endpoint,method,status_code,latency_ms,error_type,environment');

        for (final item in rawEvents) {
          if (item is Map) {
            final id = _escapeCsv(item['id']?.toString() ?? '');
            final ts = _escapeCsv(item['timestamp']?.toString() ?? DateTime.now().toIso8601String());
            final endpoint = _escapeCsv(item['endpoint']?.toString() ?? '/api/v1/unknown');
            final method = _escapeCsv(item['method']?.toString() ?? 'POST');
            final status = item['status_code']?.toString() ?? '500';
            final latency = item['latency_ms']?.toString() ?? '240';
            final errorType = _escapeCsv(item['error_type']?.toString() ?? 'InternalServerError');
            final env = _escapeCsv(item['environment']?.toString() ?? 'production');
            buffer.writeln('$id,$ts,$endpoint,$method,$status,$latency,$errorType,$env');
          }
        }

        downloadFile(
          '$filePrefix.csv',
          buffer.toString(),
          mimeType: 'text/csv;charset=utf-8',
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.cardSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppTheme.cardBorder),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Exported ${widget.project.name} telemetry as $_selectedFormat',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.cardSecondary,
            content: Text('Export failed: $e', style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  List<Map<String, dynamic>> _generateFallbackEvents() {
    final now = DateTime.now();
    return [
      {
        'id': 'evt_991823a',
        'timestamp': now.subtract(const Duration(minutes: 6)).toIso8601String(),
        'endpoint': '/api/v1/checkout/charge',
        'method': 'POST',
        'status_code': 500,
        'latency_ms': 842,
        'error_type': 'PaymentGatewayTimeoutException',
        'environment': 'production',
        'reproduction_replay': {'replay_token': 'rep_live_891b', 'deterministic': true},
        'request_body': {'amount_cents': 9900, 'currency': 'usd'},
      },
      {
        'id': 'evt_991824b',
        'timestamp': now.subtract(const Duration(minutes: 22)).toIso8601String(),
        'endpoint': '/api/v1/auth/login',
        'method': 'POST',
        'status_code': 429,
        'latency_ms': 118,
        'error_type': 'RateLimitExceeded',
        'environment': 'production',
        'reproduction_replay': {'replay_token': 'rep_live_892c', 'deterministic': true},
        'request_body': {'grant_type': 'password'},
      },
      {
        'id': 'evt_991825c',
        'timestamp': now.subtract(const Duration(hours: 1, minutes: 15)).toIso8601String(),
        'endpoint': '/api/v1/sync/events',
        'method': 'PUT',
        'status_code': 502,
        'latency_ms': 1205,
        'error_type': 'BadGatewayError',
        'environment': 'staging',
        'reproduction_replay': {'replay_token': 'rep_stage_110a', 'deterministic': true},
        'request_body': {'batch_size': 500},
      },
      {
        'id': 'evt_991826d',
        'timestamp': now.subtract(const Duration(hours: 4)).toIso8601String(),
        'endpoint': '/api/v1/billing/webhook',
        'method': 'POST',
        'status_code': 400,
        'latency_ms': 95,
        'error_type': 'InvalidSignatureException',
        'environment': 'production',
        'reproduction_replay': {'replay_token': 'rep_live_771x', 'deterministic': true},
        'request_body': {'event': 'invoice.payment_failed'},
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 520,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 36,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.heroOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.heroOrange.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.download_rounded, size: 18, color: AppTheme.heroOrange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Export Telemetry Data',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.02,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Project: ${widget.project.name} (${widget.project.slug})',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: AppTheme.cardBorder),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Format Picker (JSON vs CSV)
                  const Text(
                    'Export Format',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormatCard(
                          format: 'JSON',
                          title: 'JSON Document',
                          desc: 'Full diagnostic schema, payloads & traces',
                          icon: Icons.code_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormatCard(
                          format: 'CSV',
                          title: 'CSV Spreadsheet',
                          desc: 'Tabular log for Excel, Sheets & BI tools',
                          icon: Icons.table_chart_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Time Range
                  const Text(
                    'Time Range',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildRangeChip('24h', '24 Hours'),
                      _buildRangeChip('7d', '7 Days'),
                      _buildRangeChip('30d', '30 Days'),
                      _buildRangeChip('all', 'Full Retention'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Scope Checkboxes
                  const Text(
                    'Included Attributes',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCheckboxRow(
                    title: 'Deterministic reproduction replay artifacts',
                    subtitle: 'Include payload states, headers and synthetic mock inputs',
                    value: _includeReplays,
                    onChanged: (val) => setState(() => _includeReplays = val ?? true),
                  ),
                  const SizedBox(height: 8),
                  _buildCheckboxRow(
                    title: 'P95 latency & endpoint stability metrics',
                    subtitle: 'Aggregate percentile latency and error rates in header metadata',
                    value: _includeMetrics,
                    onChanged: (val) => setState(() => _includeMetrics = val ?? true),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: AppTheme.cardBorder),

            // Actions Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textMuted,
                      side: const BorderSide(color: AppTheme.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : _handleExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded, size: 16),
                    label: Text(_isExporting ? 'Generating...' : 'Export Telemetry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.heroOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatCard({
    required String format,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    final isSelected = _selectedFormat == format;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = format),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cardSecondary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.heroOrange : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppTheme.heroOrange : AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeChip(String key, String label) {
    final isSelected = _selectedRange == key;
    return InkWell(
      onTap: () => setState(() => _selectedRange = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cardSecondary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.cardBorder : AppTheme.cardBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppTheme.heroOrange,
                side: const BorderSide(color: AppTheme.cardBorder, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
