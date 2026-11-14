import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Interactive SaaS Connection Status Badge that displays live backend status
/// (Live API, Localhost :8080, Connecting, or Offline).
///
/// Tapping the badge opens the Backend Connection Dialog allowing developers
/// to inspect latency, test connection roundtrips, and toggle between
/// Localhost and Production Cloud endpoints.
class ConnectionStatusBadge extends StatelessWidget {
  final bool compact;

  const ConnectionStatusBadge({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ConnectionStatus>(
      valueListenable: ApiService.statusNotifier,
      builder: (context, status, _) {
        final Color dotColor;
        if (status.isConnecting) {
          dotColor = const Color(0xFFF59E0B); // Amber
        } else if (!status.isConnected) {
          dotColor = const Color(0xFFEF4444); // Red
        } else if (status.isLocalhost) {
          dotColor = const Color(0xFF06B6D4); // Cyan
        } else {
          dotColor = const Color(0xFF10B981); // Emerald
        }

        final tooltipMessage = status.isConnecting
            ? 'Testing connection to ${status.baseUrl}...'
            : status.isConnected
                ? 'Connected to ${status.baseUrl}${status.latencyMs != null ? " (${status.latencyMs}ms)" : ""}\nClick to manage backend connection'
                : 'Disconnected from ${status.baseUrl}\nClick to troubleshoot or switch endpoint';

        return Tooltip(
          message: tooltipMessage,
          waitDuration: const Duration(milliseconds: 300),
          child: InkWell(
            onTap: () => showConnectionDialog(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 38,
              padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
              decoration: BoxDecoration(
                color: AppTheme.cardSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: !status.isConnected
                      ? AppTheme.status5xx.withValues(alpha: 0.3)
                      : AppTheme.cardBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 8),
                    Text(
                      status.isConnecting
                          ? 'Connecting...'
                          : status.statusLabel,
                      style: TextStyle(
                        color: !status.isConnected
                            ? AppTheme.status5xx
                            : AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void showConnectionDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const _BackendConnectionDialog(),
    );
  }
}

class _BackendConnectionDialog extends StatefulWidget {
  const _BackendConnectionDialog();

  @override
  State<_BackendConnectionDialog> createState() => _BackendConnectionDialogState();
}

class _BackendConnectionDialogState extends State<_BackendConnectionDialog> {
  final TextEditingController _customUrlCtrl = TextEditingController();
  bool _isPinging = false;
  String? _pingResult;
  bool? _pingSuccess;

  @override
  void initState() {
    super.initState();
    _customUrlCtrl.text = ApiService().baseUrl;
    _runPing();
  }

  @override
  void dispose() {
    _customUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _runPing([String? url]) async {
    setState(() {
      _isPinging = true;
      _pingResult = null;
    });

    try {
      final status = await ApiService().ping(targetUrl: url);
      if (mounted) {
        setState(() {
          _isPinging = false;
          _pingSuccess = status.isConnected;
          if (status.isConnected) {
            _pingResult = 'Connection successful (${status.latencyMs ?? 0}ms response time)';
          } else {
            _pingResult = 'Cannot reach endpoint at ${status.baseUrl}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPinging = false;
          _pingSuccess = false;
          _pingResult = 'Ping error: $e';
        });
      }
    }
  }

  void _applyUrl(String url) {
    ApiService().setBaseUrl(url);
    _customUrlCtrl.text = url;
    _runPing(url);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.heroOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.dns_rounded, color: AppTheme.heroOrange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backend Connection',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure the Spring Boot telemetry server endpoint',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Live Status Card
              ValueListenableBuilder<ConnectionStatus>(
                valueListenable: ApiService.statusNotifier,
                builder: (context, status, _) {
                  final isOnline = status.isConnected;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOnline
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : AppTheme.status5xx.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOnline
                                  ? (status.isLocalhost ? 'Local Development Server (Connected)' : 'Production Cloud API (Connected)')
                                  : 'Backend Unreachable (Offline)',
                              style: TextStyle(
                                color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            if (_isPinging)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.heroOrange),
                              )
                            else
                              InkWell(
                                onTap: () => _runPing(status.baseUrl),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.refresh_rounded, size: 13, color: AppTheme.heroOrange),
                                      SizedBox(width: 4),
                                      Text(
                                        'Ping',
                                        style: TextStyle(
                                          color: AppTheme.heroOrange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          status.baseUrl,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.heroOrange,
                          ),
                        ),
                        if (_pingResult != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _pingResult!,
                            style: TextStyle(
                              color: _pingSuccess == true ? AppTheme.textSubtle : const Color(0xFFEF4444),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),

              // Quick Switch Presets
              Text(
                'QUICK SWITCH PRESETS',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _applyUrl('http://localhost:8080/api/v1'),
                      icon: const Icon(Icons.laptop_chromebook_rounded, size: 15),
                      label: const Text('Localhost :8080', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: BorderSide(
                          color: ApiService().isUsingLocalhost ? AppTheme.heroOrange : AppTheme.cardBorder,
                          width: ApiService().isUsingLocalhost ? 1.5 : 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _applyUrl('https://api.eventdock.swynx.dev/api/v1'),
                      icon: const Icon(Icons.cloud_outlined, size: 15),
                      label: const Text('Cloud Production', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: BorderSide(
                          color: !ApiService().isUsingLocalhost ? AppTheme.heroOrange : AppTheme.cardBorder,
                          width: !ApiService().isUsingLocalhost ? 1.5 : 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Custom Endpoint Input
              Text(
                'CUSTOM ENDPOINT URL',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customUrlCtrl,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'http://localhost:8080/api/v1',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.cardBorder),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _applyUrl(_customUrlCtrl.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.heroOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Localhost Tip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.sidebar,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.heroOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'To start your local backend: run "mvn spring-boot:run" in the eventdock-api folder. The dashboard automatically discovers and routes traffic to it.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Done', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
