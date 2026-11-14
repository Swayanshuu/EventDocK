import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'connection_status_badge.dart';

/// Reusable, user-friendly error card that formats backend failures, network timeouts,
/// and connection issues with helpful actionable recovery steps.
class ErrorStateCard extends StatelessWidget {
  final String rawError;
  final VoidCallback onRetry;
  final String? title;
  final bool isCompact;

  const ErrorStateCard({
    super.key,
    required this.rawError,
    required this.onRetry,
    this.title,
    this.isCompact = false,
  });

  bool get _isConnectionError {
    final lower = rawError.toLowerCase();
    return lower.contains('unable to reach') ||
        lower.contains('cannot reach') ||
        lower.contains('connection refused') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('timed out') ||
        lower.contains('network error') ||
        lower.contains('offline');
  }

  bool get _isAuthError {
    final lower = rawError.toLowerCase();
    return lower.contains('unauthorized') ||
        lower.contains('forbidden') ||
        lower.contains('401') ||
        lower.contains('403') ||
        lower.contains('jwt');
  }

  String get _friendlyTitle {
    if (title != null && title!.isNotEmpty) return title!;
    if (_isConnectionError) return 'Backend Service Offline';
    if (_isAuthError) return 'Authentication Required';
    return 'Unable to Complete Request';
  }

  String get _friendlyMessage {
    if (_isConnectionError) {
      if (ApiService().isUsingLocalhost) {
        return 'Could not connect to your local EventDock backend at ${ApiService().baseUrl}. If your Spring Boot server is booting up, please wait a moment and tap Retry.';
      }
      return 'Could not reach the EventDock cloud endpoint at ${ApiService().baseUrl}. Check your internet connection or switch to localhost:8080 for local development.';
    }
    if (_isAuthError) {
      return 'Your authentication session expired or credentials need verification. Please sign in again or verify your account.';
    }
    return rawError.replaceAll('Exception: ', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = _isConnectionError ? const Color(0xFFF59E0B) : AppTheme.status5xx;

    final content = Container(
      constraints: const BoxConstraints(maxWidth: 580),
      padding: EdgeInsets.all(isCompact ? 20 : 28),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppTheme.isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isConnectionError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              color: badgeColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            _friendlyTitle,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Message
          Text(
            _friendlyMessage,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Target URL Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.sidebar,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ApiService().isUsingLocalhost ? Icons.laptop_chromebook_rounded : Icons.cloud_outlined,
                  size: 13,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  ApiService().baseUrl,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.heroOrange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.heroOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => ConnectionStatusBadge.showConnectionDialog(context),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Configure Backend', style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: BorderSide(color: AppTheme.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isCompact) {
      return Center(child: content);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: content,
      ),
    );
  }
}
