import 'package:flutter/material.dart';

enum NotificationSeverity {
  critical,
  warning,
  resolved,
  info,
  system,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationSeverity severity;
  final String? route;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.severity,
    this.route,
    this.isRead = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  IconData get icon {
    switch (severity) {
      case NotificationSeverity.critical:
        return Icons.error_rounded;
      case NotificationSeverity.warning:
        return Icons.warning_amber_rounded;
      case NotificationSeverity.resolved:
        return Icons.check_circle_rounded;
      case NotificationSeverity.info:
        return Icons.info_outline_rounded;
      case NotificationSeverity.system:
        return Icons.dns_rounded;
    }
  }

  Color get color {
    switch (severity) {
      case NotificationSeverity.critical:
        return const Color(0xFFEF4444); // Red
      case NotificationSeverity.warning:
        return const Color(0xFFF59E0B); // Amber
      case NotificationSeverity.resolved:
        return const Color(0xFF10B981); // Emerald
      case NotificationSeverity.info:
        return const Color(0xFF3B82F6); // Blue
      case NotificationSeverity.system:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  Color get backgroundColor {
    switch (severity) {
      case NotificationSeverity.critical:
        return const Color(0x1AEF4444);
      case NotificationSeverity.warning:
        return const Color(0x1AF59E0B);
      case NotificationSeverity.resolved:
        return const Color(0x1A10B981);
      case NotificationSeverity.info:
        return const Color(0x1A3B82F6);
      case NotificationSeverity.system:
        return const Color(0x1A8B5CF6);
    }
  }

  Color get borderColor {
    switch (severity) {
      case NotificationSeverity.critical:
        return const Color(0x33EF4444);
      case NotificationSeverity.warning:
        return const Color(0x33F59E0B);
      case NotificationSeverity.resolved:
        return const Color(0x3310B981);
      case NotificationSeverity.info:
        return const Color(0x333B82F6);
      case NotificationSeverity.system:
        return const Color(0x338B5CF6);
    }
  }

  static List<NotificationItem> getInitialNotifications() {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: 'notif_1',
        title: 'Critical Failure Rate Spike',
        message: 'Endpoint /api/v1/checkout/charge returned 14 consecutive 500 errors.',
        timestamp: now.subtract(const Duration(minutes: 4)),
        severity: NotificationSeverity.critical,
        route: '/api/v1/checkout/charge',
        isRead: false,
      ),
      NotificationItem(
        id: 'notif_2',
        title: 'P95 Latency Threshold Exceeded',
        message: 'Overall latency reached 412ms, exceeding baseline threshold of 350ms.',
        timestamp: now.subtract(const Duration(minutes: 24)),
        severity: NotificationSeverity.warning,
        isRead: false,
      ),
      NotificationItem(
        id: 'notif_3',
        title: 'Ingestion Pool Recovered',
        message: 'Upstream connection pool restored; /api/v1/auth/login recovered to 99.9% uptime.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 12)),
        severity: NotificationSeverity.resolved,
        route: '/api/v1/auth/login',
        isRead: true,
      ),
      NotificationItem(
        id: 'notif_4',
        title: 'Reproduction Replay Generated',
        message: 'Deterministic bug reproduction artifact generated for incident #INC-4920.',
        timestamp: now.subtract(const Duration(hours: 3)),
        severity: NotificationSeverity.info,
        isRead: true,
      ),
      NotificationItem(
        id: 'notif_5',
        title: 'Team Member Access Granted',
        message: 'Sarah Connor accepted invitation to collaborate on Acme Cloud Platform.',
        timestamp: now.subtract(const Duration(days: 1)),
        severity: NotificationSeverity.system,
        isRead: true,
      ),
    ];
  }
}
