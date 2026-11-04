import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_item.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/command_palette_dialog.dart';
import '../widgets/create_project_dialog.dart';
import '../widgets/dashboard_top_bar.dart';
import '../widgets/export_dialog.dart';
import 'api_keys_view.dart';
import 'dashboard_overview_view.dart';
import 'event_inbox_view.dart';
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
  List<Project> _allProjects = [];
  int _selectedNavIndex = 0; // 0: Overview, 1: Failures (Inbox), 2: API Keys, 3: Settings
  bool _isSidebarCollapsed = false;
  int _totalFailures = 0;
  final List<NotificationItem> _notifications = NotificationItem.getInitialNotifications();

  void _openCommandPalette() {
    CommandPaletteDialog.show(
      context: context,
      currentProject: _project,
      allProjects: _allProjects,
      onNavigate: (idx) => setState(() => _selectedNavIndex = idx),
      onSelectProject: _onProjectChanged,
      onExport: () => ExportDialog.show(context, _project),
      onToggleSidebar: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
      onRefresh: () {
        _loadProjects();
        _loadFailureCount();
      },
      onCreateProject: () {
        CreateProjectDialog.show(
          context,
          onProjectCreated: (created) {
            setState(() {
              _project = created;
              if (!_allProjects.any((p) => p.id == created.id)) {
                _allProjects = [created, ..._allProjects];
              }
            });
            _loadFailureCount();
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _project = widget.initialProject;
    _allProjects = [_project];
    _loadProjects();
    _loadFailureCount();
  }

  Future<void> _loadProjects() async {
    try {
      final list = await ApiService().getProjects();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _allProjects = list;
          if (!list.any((p) => p.id == _project.id)) {
            _allProjects = [widget.initialProject, ...list];
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFailureCount() async {
    try {
      final res = await ApiService().getEvents(_project.id);
      final events = (res['events'] as List<dynamic>?) ?? [];
      if (mounted) {
        setState(() {
          _totalFailures = events.length;
        });
      }
    } catch (_) {}
  }

  void _onProjectChanged(Project p) {
    setState(() {
      _project = p;
    });
    _loadFailureCount();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isCollapsed = _isSidebarCollapsed;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _openCommandPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _openCommandPalette,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Left: Premium SaaS Sidebar Navigation
            AppSidebar(
              project: _project,
              selectedIndex: _selectedNavIndex,
              onTabSelected: (idx) {
                setState(() => _selectedNavIndex = idx);
              },
              totalFailures: _totalFailures,
              isCollapsed: isCollapsed,
              onToggleCollapse: () {
                setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
              },
              onSignOut: widget.onSignOut,
            ),

            // Right: Content Area with Header
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top SaaS Header with Search & Project Switcher
                  DashboardTopBar(
                    project: _project,
                    allProjects: _allProjects,
                    onProjectSelected: _onProjectChanged,
                    onRefresh: () {
                      _loadProjects();
                      _loadFailureCount();
                    },
                    onSwitchProject: widget.onBackToProjects,
                    onCreateProject: () {
                      CreateProjectDialog.show(
                        context,
                        onProjectCreated: (created) {
                          setState(() {
                            _project = created;
                            if (!_allProjects.any((p) => p.id == created.id)) {
                              _allProjects = [created, ..._allProjects];
                            }
                          });
                          _loadFailureCount();
                        },
                      );
                    },
                    onToggleSidebar: () {
                      setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                    },
                    isSidebarCollapsed: _isSidebarCollapsed,
                    onNavigate: (idx) => setState(() => _selectedNavIndex = idx),
                    notifications: _notifications,
                    onMarkAllNotificationsRead: () {
                      setState(() {
                        for (final n in _notifications) {
                          n.isRead = true;
                        }
                      });
                    },
                    onNotificationTap: (item) {
                      setState(() {
                        item.isRead = true;
                        if (item.severity == NotificationSeverity.critical || item.route != null) {
                          _selectedNavIndex = 1; // jump to Event Inbox
                        }
                      });
                    },
                    onNotificationDismiss: (item) {
                      setState(() {
                        _notifications.removeWhere((n) => n.id == item.id);
                      });
                    },
                    onOpenSearch: _openCommandPalette,
                    onOpenExport: () => ExportDialog.show(context, _project),
                  ),

                  // Main Tab Content with Solid Dark Background
                  Expanded(
                    child: Container(
                      color: AppTheme.background,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.topLeft,
                            children: <Widget>[
                              ...previousChildren,
                              ?currentChild,
                            ],
                          );
                        },
                        child: Container(
                          key: ValueKey<String>('$_selectedNavIndex-${themeMode.name}'),
                          color: AppTheme.background,
                          width: double.infinity,
                          height: double.infinity,
                          child: _buildCurrentView(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
      },
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedNavIndex) {
      case 0:
        return DashboardOverviewView(
          project: _project,
          onViewAllEvents: () {
            setState(() => _selectedNavIndex = 1);
          },
        );
      case 1:
        return EventInboxView(project: _project);
      case 2:
        return ApiKeysView(project: _project);
      case 3:
        return ProjectSettingsView(
          project: _project,
          onProjectDeleted: widget.onBackToProjects,
          onProjectUpdated: (updated) => setState(() => _project = updated),
        );
      default:
        return DashboardOverviewView(
          project: _project,
          onViewAllEvents: () {
            setState(() => _selectedNavIndex = 1);
          },
        );
    }
  }
}
