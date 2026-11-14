import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class AppTopNav extends StatelessWidget {
  final Project project;
  final List<Project> allProjects;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<Project>? onProjectSelected;
  final VoidCallback onSwitchProject;
  final VoidCallback onSignOut;

  const AppTopNav({
    super.key,
    required this.project,
    this.allProjects = const [],
    required this.selectedIndex,
    required this.onTabSelected,
    this.onProjectSelected,
    required this.onSwitchProject,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 960;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.shell,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand Logo & Project Switcher Dropdown
          Row(
            children: [
              const EventDockLogo(height: 26, fontSize: 15),

              const SizedBox(width: 14),
              PopupMenuButton<Project>(
                tooltip: 'Switch project',
                color: AppTheme.card,
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.cardBorder),
                ),
                offset: const Offset(0, 44),
                onSelected: (p) {
                  if (onProjectSelected != null) {
                    onProjectSelected!(p);
                  }
                },
                itemBuilder: (context) {
                  final projectsList = allProjects.isNotEmpty ? allProjects : [project];
                  return [
                    PopupMenuItem<Project>(
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
                              color: isCurrent ? AppTheme.heroCoral : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                p.name,
                                style: TextStyle(
                                  color: isCurrent ? AppTheme.heroCoral : AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrent)
                              const Icon(
                                Icons.check,
                                size: 16,
                                color: AppTheme.heroCoral,
                              ),
                          ],
                        ),
                      );
                    }),
                    PopupMenuDivider(height: 1),
                    PopupMenuItem<Project>(
                      enabled: true,
                      onTap: onSwitchProject,
                      child: Row(
                        children: [
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
                  ];
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSecondary,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_outlined, size: 14, color: AppTheme.heroCoral),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isCompact ? 100 : 140),
                        child: Text(
                          project.name,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.unfold_more, size: 14, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Center: Segmented Navigation Pills
          if (!isCompact)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.pillBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.pillBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavPill(0, 'Dashboard'),
                  _buildNavPill(1, 'Failures'),
                  _buildNavPill(2, 'API Keys'),
                  _buildNavPill(3, 'Settings'),
                ],
              ),
            ),

          // Right Controls: Search, Bell, Profile
          Row(
            children: [
              _buildCircleButton(
                icon: Icons.search,
                tooltip: 'Search endpoints & stack traces',
                onTap: () => onTabSelected(1),
              ),
              const SizedBox(width: 8),
              Stack(
                children: [
                  _buildCircleButton(
                    icon: Icons.notifications_none,
                    tooltip: 'Incident alerts',
                    onTap: () {},
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.heroCoral,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                color: AppTheme.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.cardBorder),
                ),
                offset: const Offset(0, 42),
                onSelected: (val) {
                  if (val == 'projects') onSwitchProject();
                  if (val == 'signout') onSignOut();
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'user',
                    enabled: false,
                    child: Text(
                      AuthService().userEmail ?? 'developer@eventdock.dev',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'projects',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 16, color: AppTheme.textPrimary),
                        SizedBox(width: 8),
                        Text('All Projects', style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'signout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 16, color: AppTheme.status5xx),
                        SizedBox(width: 8),
                        Text('Sign Out', style: TextStyle(fontSize: 13, color: AppTheme.status5xx)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.cardSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Center(
                    child: Text(
                      (AuthService().userEmail ?? 'D').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.heroCoral,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavPill(int index, String label) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.pillActive : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.pillActiveText : AppTheme.textMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Icon(icon, size: 16, color: AppTheme.textMuted),
      ),
    );
  }
}