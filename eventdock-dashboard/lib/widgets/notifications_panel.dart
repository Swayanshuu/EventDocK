import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../theme/app_theme.dart';

class NotificationsPanel extends StatefulWidget {
  final List<NotificationItem> notifications;
  final VoidCallback onMarkAllRead;
  final ValueChanged<NotificationItem> onNotificationTap;
  final ValueChanged<NotificationItem> onNotificationDismiss;
  final VoidCallback? onViewAllEvents;

  const NotificationsPanel({
    super.key,
    required this.notifications,
    required this.onMarkAllRead,
    required this.onNotificationTap,
    required this.onNotificationDismiss,
    this.onViewAllEvents,
  });

  static Future<void> show({
    required BuildContext context,
    required List<NotificationItem> notifications,
    required VoidCallback onMarkAllRead,
    required ValueChanged<NotificationItem> onNotificationTap,
    required ValueChanged<NotificationItem> onNotificationDismiss,
    VoidCallback? onViewAllEvents,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.only(top: 72, right: 28, bottom: 24),
        child: NotificationsPanel(
          notifications: notifications,
          onMarkAllRead: onMarkAllRead,
          onNotificationTap: (item) {
            Navigator.of(ctx).pop();
            onNotificationTap(item);
          },
          onNotificationDismiss: onNotificationDismiss,
          onViewAllEvents: () {
            Navigator.of(ctx).pop();
            onViewAllEvents?.call();
          },
        ),
      ),
    );
  }

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  int _selectedFilter = 0; // 0: All, 1: Unread, 2: Critical

  @override
  Widget build(BuildContext context) {
    final unreadCount = widget.notifications.where((n) => !n.isRead).length;
    final criticalCount = widget.notifications.where((n) => n.severity == NotificationSeverity.critical).length;

    final filteredList = widget.notifications.where((n) {
      if (_selectedFilter == 1) return !n.isRead;
      if (_selectedFilter == 2) return n.severity == NotificationSeverity.critical;
      return true;
    }).toList();

    return Container(
      width: 440,
      constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.02,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppTheme.heroOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.heroOrange.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$unreadCount new',
                      style: const TextStyle(
                        color: AppTheme.heroOrange,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (unreadCount > 0)
                  InkWell(
                    onTap: () {
                      setState(() {
                        for (final n in widget.notifications) {
                          n.isRead = true;
                        }
                      });
                      widget.onMarkAllRead();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Text(
                        'Mark read',
                        style: TextStyle(
                          color: AppTheme.textSubtle,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips (Scrollable horizontally)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(0, 'All', widget.notifications.length),
                  const SizedBox(width: 8),
                  _buildFilterChip(1, 'Unread', unreadCount),
                  const SizedBox(width: 8),
                  _buildFilterChip(2, 'Critical', criticalCount),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: AppTheme.cardBorder),

          // Notifications List
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredList.length,
                    separatorBuilder: (ctx, idx) => Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.cardBorder,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildNotificationRow(item);
                    },
                  ),
          ),

          Divider(height: 1, thickness: 1, color: AppTheme.cardBorder),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.notifications.length} tracked events',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onViewAllEvents != null)
                  InkWell(
                    onTap: widget.onViewAllEvents,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Event inbox',
                            style: TextStyle(
                              color: AppTheme.heroOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded, size: 11, color: AppTheme.heroOrange),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, int count) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cardSecondary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.cardBorder : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.sidebar : AppTheme.cardSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? AppTheme.textSubtle : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.cardSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 22,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'All caught up',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No new alerts matching the selected filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationRow(NotificationItem item) {
    return InkWell(
      onTap: () => widget.onNotificationTap(item),
      hoverColor: AppTheme.cardSecondary.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Icon with Tinted Container
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: item.backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: item.borderColor),
              ),
              child: Icon(item.icon, size: 16, color: item.color),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: item.isRead ? AppTheme.textSubtle : AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.timeAgo,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      if (!item.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.heroOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  if (item.route != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.sidebar,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Text(
                        item.route!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: AppTheme.textSubtle,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Dismiss Button
            IconButton(
              onPressed: () => widget.onNotificationDismiss(item),
              icon: Icon(Icons.close_rounded, size: 14, color: AppTheme.textMuted),
              splashRadius: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}