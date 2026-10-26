import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/create_project_dialog.dart';
import '../widgets/dashboard_top_bar.dart';
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
  int _totalFailures = 4;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final isCollapsed = _isSidebarCollapsed;

    return Scaffold(
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
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: Container(
                          key: ValueKey<int>(_selectedNavIndex),
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
    );
  }

  Widget _buildMobileTab(int index, String label, IconData icon) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedNavIndex = index),
      borderRadius: BorderRadius.circular(999),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: AppTheme.cardSecondary.withValues(alpha: 0.5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cardSecondary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: isSelected ? Border.all(color: AppTheme.cardBorder) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppTheme.heroOrange : AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
