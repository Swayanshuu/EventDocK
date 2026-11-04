import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AppSidebar extends StatelessWidget {
  final Project project;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final int totalFailures;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onSignOut;

  const AppSidebar({
    super.key,
    required this.project,
    required this.selectedIndex,
    required this.onTabSelected,
    this.totalFailures = 0,
    this.isCollapsed = false,
    required this.onToggleCollapse,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed ? 68.0 : 256.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.sidebar,
        border: Border(
          right: BorderSide(color: AppTheme.cardBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Brand Header & Toggle
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 14 : 16,
            ),
            child: isCollapsed
                ? Center(
                    child: Tooltip(
                      message: 'Expand sidebar',
                      child: InkWell(
                        onTap: onToggleCollapse,
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: AppTheme.cardSecondary,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.cardSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.view_sidebar_rounded,
                              size: 18,
                              color: AppTheme.heroOrange,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppTheme.heroOrange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.radar_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'EventDock',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: 'Collapse sidebar',
                        child: InkWell(
                          onTap: onToggleCollapse,
                          borderRadius: BorderRadius.circular(8),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: AppTheme.cardSecondary,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppTheme.cardSecondary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.view_sidebar_outlined,
                                size: 15,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 8),

          // 2. Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 10 : 12),
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Dashboard',
                  icon: Icons.grid_view_rounded,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Failures',
                  icon: Icons.error_outline_rounded,
                  badgeText: totalFailures > 0 ? '$totalFailures' : null,
                  badgeColor: totalFailures > 0
                      ? AppTheme.heroOrange.withValues(alpha: 0.18)
                      : const Color(0xFF22C55E).withValues(alpha: 0.18),
                  badgeTextColor:
                      totalFailures > 0 ? AppTheme.heroOrange : const Color(0xFF22C55E),
                ),
                _buildNavItem(
                  index: 2,
                  label: 'API Keys',
                  icon: Icons.vpn_key_outlined,
                ),
                _buildNavItem(
                  index: 3,
                  label: 'Settings',
                  icon: Icons.tune_rounded,
                ),
              ],
            ),
          ),

          // 3. Bottom User Profile
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.cardBorder, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                Tooltip(
                  message: '${AuthService().userEmail ?? "developer"} (${AuthService().currentOrganization.name})',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.heroOrange.withValues(alpha: 0.2),
                            child: const Text(
                              'ED',
                              style: TextStyle(
                                color: AppTheme.heroOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.sidebar, width: 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isCollapsed) ...[
                        const SizedBox(width: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AuthService().userEmail ?? 'developer',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                AuthService().currentOrganization.name,
                                style: const TextStyle(
                                  color: AppTheme.heroOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isCollapsed)
                  IconButton(
                    icon: Icon(Icons.logout_rounded, size: 16, color: AppTheme.textMuted),
                    tooltip: 'Sign out',
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: AppTheme.cardSecondary.withValues(alpha: 0.6),
                    onPressed: onSignOut,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    final isSelected = selectedIndex == index;

    final navContent = Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: isSelected
            ? AppTheme.cardSecondary
            : AppTheme.cardSecondary.withValues(alpha: 0.5),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 0 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.cardSecondary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: AppTheme.cardBorder) : null,
          ),
          child: Row(
            mainAxisAlignment:
                isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? AppTheme.heroOrange : AppTheme.textMuted,
                  ),
                  if (isCollapsed && badgeText != null)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: badgeTextColor ?? AppTheme.heroOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor ?? AppTheme.cardSecondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeTextColor ?? AppTheme.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 200),
        child: navContent,
      );
    }
    return navContent;
  }
}