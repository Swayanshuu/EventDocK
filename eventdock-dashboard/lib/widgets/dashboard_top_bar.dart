import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';
import 'command_palette_dialog.dart';
import 'export_dialog.dart';
import 'notifications_panel.dart';

class DashboardTopBar extends StatelessWidget {
  final Project project;
  final List<Project> allProjects;
  final ValueChanged<Project> onProjectSelected;
  final VoidCallback onRefresh;
  final VoidCallback? onSwitchProject;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onCreateProject;
  final bool isSidebarCollapsed;
  final ValueChanged<int>? onNavigate;
  final List<NotificationItem>? notifications;
  final VoidCallback? onMarkAllNotificationsRead;
  final ValueChanged<NotificationItem>? onNotificationTap;
  final ValueChanged<NotificationItem>? onNotificationDismiss;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenExport;
  final VoidCallback? onOpenNotifications;

  const DashboardTopBar({
    super.key,
    required this.project,
    required this.allProjects,
    required this.onProjectSelected,
    required this.onRefresh,
    this.onSwitchProject,
    this.onToggleSidebar,
    this.onCreateProject,
    this.isSidebarCollapsed = false,
    this.onNavigate,
    this.notifications,
    this.onMarkAllNotificationsRead,
    this.onNotificationTap,
    this.onNotificationDismiss,
    this.onOpenSearch,
    this.onOpenExport,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final isTablet = screenWidth >= 768 && screenWidth < 1100;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : 16,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.sidebar,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorder, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sidebar Toggle Button (Linear / Stripe style)
          if (onToggleSidebar != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: isSidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                child: InkWell(
                  onTap: onToggleSidebar,
                  borderRadius: BorderRadius.circular(10),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: AppTheme.cardSecondary.withValues(alpha: 0.6),
                  child: Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.cardSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Icon(
                      isSidebarCollapsed
                          ? Icons.view_sidebar_rounded
                          : Icons.view_sidebar_outlined,
                      size: 18,
                      color: isSidebarCollapsed
                          ? AppTheme.heroOrange
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ),

          // Left: Interactive Search Bar & Command Palette Trigger
          Expanded(
            flex: isDesktop ? 5 : 4,
            child: Tooltip(
              message: 'Search pages, projects, endpoints (⌘K / Ctrl+K)',
              child: InkWell(
                onTap: () {
                  if (onOpenSearch != null) {
                    onOpenSearch!();
                  } else {
                    CommandPaletteDialog.show(
                      context: context,
                      currentProject: project,
                      allProjects: allProjects,
                      onNavigate: onNavigate ?? (_) {},
                      onSelectProject: onProjectSelected,
                      onExport: () => ExportDialog.show(context, project),
                      onToggleSidebar: onToggleSidebar ?? () {},
                      onRefresh: onRefresh,
                      onCreateProject: onCreateProject,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                hoverColor: AppTheme.cardSecondary.withValues(alpha: 0.8),
                child: Container(
                  height: 42,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 18, color: AppTheme.heroOrange),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Search anything... (⌘K / Ctrl+K)',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.sidebar,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: const Text(
                          '⌘K',
                          style: TextStyle(
                            color: AppTheme.textSubtle,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Right Controls: Date Pill + Project Switcher + Export Button + Notification
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date Filter Pill (like in Shopeers)
              if (isDesktop) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.textMuted),
                      SizedBox(width: 8),
                      Text(
                        'Last 30 days',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Project Selector Dropdown (with tooltip 'Switch project' for test compliance)
              PopupMenuButton<Project>(
                tooltip: 'Switch project',
                color: AppTheme.card,
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.cardBorder),
                ),
                offset: const Offset(0, 48),
                onSelected: onProjectSelected,
                itemBuilder: (context) {
                  final projectsList = allProjects.isNotEmpty ? allProjects : [project];
                  return [
                    const PopupMenuItem<Project>(
                      enabled: false,
                      height: 28,
                      child: Text(
                        'PROJECTS',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    ...projectsList.map((p) {
                      final isCurrent = p.id == project.id;
                      return PopupMenuItem<Project>(
                        value: p,
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 16,
                              color: isCurrent ? AppTheme.heroOrange : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                p.name,
                                style: TextStyle(
                                  color: isCurrent ? AppTheme.heroOrange : AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrent)
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppTheme.heroOrange,
                              ),
                          ],
                        ),
                      );
                    }),
                    if (onCreateProject != null) ...[
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem<Project>(
                        enabled: true,
                        onTap: onCreateProject,
                        child: Row(
                          children: const [
                            Icon(Icons.add_rounded, size: 16, color: AppTheme.heroOrange),
                            SizedBox(width: 10),
                            Text(
                              'New Project...',
                              style: TextStyle(
                                color: AppTheme.heroOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (onSwitchProject != null) ...[
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem<Project>(
                        enabled: true,
                        onTap: onSwitchProject,
                        child: Row(
                          children: const [
                            Icon(Icons.dashboard_customize_outlined, size: 16, color: AppTheme.textMuted),
                            SizedBox(width: 10),
                            Text(
                              'All Projects...',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ];
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_rounded, size: 14, color: AppTheme.heroOrange),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isTablet ? 110 : 150),
                        child: Text(
                          project.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.unfold_more_rounded, size: 14, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Export Button (Downloads real JSON/CSV telemetry file)
              ElevatedButton.icon(
                onPressed: () {
                  if (onOpenExport != null) {
                    onOpenExport!();
                  } else {
                    ExportDialog.show(context, project);
                  }
                },
                icon: const Icon(Icons.download_rounded, size: 14),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.heroOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),

              const SizedBox(width: 10),

              // Notification Icon Button with Live Unread Badge & Interactive Panel
              Builder(
                builder: (notifContext) {
                  final activeNotifs = notifications ?? [];
                  final unreadCount = activeNotifs.where((n) => !n.isRead).length;

                  return Tooltip(
                    message: unreadCount > 0 ? 'Notifications ($unreadCount unread)' : 'Notifications',
                    child: InkWell(
                      onTap: () {
                        if (onOpenNotifications != null) {
                          onOpenNotifications!();
                        } else {
                          NotificationsPanel.show(
                            context: notifContext,
                            notifications: activeNotifs,
                            onMarkAllRead: onMarkAllNotificationsRead ?? () {},
                            onNotificationTap: onNotificationTap ?? (_) {},
                            onNotificationDismiss: onNotificationDismiss ?? (_) {},
                            onViewAllEvents: () => onNavigate?.call(1),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: AppTheme.cardSecondary.withValues(alpha: 0.8),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.cardSecondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Center(
                              child: Icon(Icons.notifications_none_rounded, size: 18, color: AppTheme.textMuted),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.heroOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
