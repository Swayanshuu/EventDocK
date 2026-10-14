import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'event_inbox_view.dart';
import 'api_keys_view.dart';
import 'project_settings_view.dart';

class ProjectDashboardScreen extends StatefulWidget {
  final Project initialProject;
  final VoidCallback onBackToProjects;
  final VoidCallback onSignOut;

  const ProjectDashboardScreen({
    super.key,
    required this.initialProject,
    required this.onBackToProjects,
    required this.onSignOut,
  });

  @override
  State<ProjectDashboardScreen> createState() => _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen> {
  late Project _project;
  int _selectedNavIndex = 0; // 0: Inbox, 1: API Keys, 2: Settings

  @override
  void initState() {
    super.initState();
    _project = widget.initialProject;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(_project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: AppTheme.cardBorder),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'All Projects',
                  onPressed: widget.onBackToProjects,
                ),
              ],
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppTheme.surface,
              child: _buildSidebarContent(isDrawer: true),
            ),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(right: BorderSide(color: AppTheme.cardBorder)),
              ),
              child: _buildSidebarContent(isDrawer: false),
            ),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent({required bool isDrawer}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // App / Project Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EventDockLogo(height: 28),
              const SizedBox(height: 20),
              InkWell(
                onTap: widget.onBackToProjects,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _project.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.unfold_more, size: 16, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.cardBorder),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            children: [
              _buildNavItem(0, 'Event Inbox', Icons.inbox_rounded),
              _buildNavItem(1, 'API Keys', Icons.vpn_key_rounded),
              _buildNavItem(2, 'Project Settings', Icons.settings_rounded),
            ],
          ),
        ),

        const Divider(height: 1, color: AppTheme.cardBorder),

        // User profile footer
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.cardSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Text(
                  (AuthService().userEmail ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AuthService().userEmail ?? '',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.textMuted),
                tooltip: 'Sign Out',
                onPressed: widget.onSignOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedNavIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isSelected,
        selectedTileColor: AppTheme.primary.withOpacity(0.12),
        leading: Icon(icon, size: 18, color: isSelected ? AppTheme.primary : AppTheme.textMuted),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        dense: true,
        onTap: () {
          setState(() => _selectedNavIndex = index);
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedNavIndex) {
      case 0:
        return EventInboxView(project: _project);
      case 1:
        return ApiKeysView(project: _project);
      case 2:
        return ProjectSettingsView(
          project: _project,
          onProjectDeleted: widget.onBackToProjects,
          onProjectUpdated: (updated) => setState(() => _project = updated),
        );
      default:
        return EventInboxView(project: _project);
    }
  }
}
