import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/organization.dart';
import '../models/workspace_member.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/create_project_dialog.dart';

class ProjectsScreen extends StatefulWidget {
  final Function(Project) onSelectProject;
  final VoidCallback onSignOut;

  const ProjectsScreen({
    super.key,
    required this.onSelectProject,
    required this.onSignOut,
  });

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  int _selectedTabIndex = 0; // 0: Overview, 1: Projects, 2: Members, 3: Settings
  List<Project> _projects = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name' or 'date'

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ApiService().getProjects();
      if (mounted) {
        setState(() {
          _projects = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _openCreateProjectModal() {
    CreateProjectDialog.show(
      context,
      onProjectCreated: (newProj) {
        _loadProjects();
        widget.onSelectProject(newProj);
      },
    );
  }

  void _showInviteMemberModal() {
    final emailCtrl = TextEditingController();
    String role = 'Member';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.cardBorder)),
          title: const Text('Invite Team Member', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Teammate Email Address', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  decoration: const InputDecoration(hintText: 'colleague@company.com'),
                ),
                const SizedBox(height: 14),
                const Text('Workspace Role', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: role,
                  dropdownColor: AppTheme.cardSecondary,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin (Can create projects and invite members)')),
                    DropdownMenuItem(value: 'Member', child: Text('Member (Can inspect telemetry and keys)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => role = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.heroOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final email = emailCtrl.text.trim();
                if (email.contains('@')) {
                  AuthService().inviteMember(AuthService().currentOrganization.id, email, role);
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invitation sent to $email')),
                  );
                }
              },
              child: const Text('Send Invitation', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteProjectConfirmation(Project project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.cardBorder)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.status5xx, size: 20),
            const SizedBox(width: 8),
            Text('Delete ${project.name}?', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${project.name}"? All associated diagnostic events, keys, and metrics will be purged.',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.status5xx,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService().deleteProject(project.id);
              _loadProjects();
            },
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAccountSettingsModal() {
    final nameCtrl = TextEditingController(text: AuthService().fullName);
    final roleCtrl = TextEditingController(text: AuthService().roleTitle);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.cardBorder)),
        title: const Text('Account Profile Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${AuthService().userEmail ?? ""}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              const Text('Full Name', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 14),
              const Text('Job Title / Role', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: roleCtrl,
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.heroOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              AuthService().updateProfile(
                fullName: nameCtrl.text.trim(),
                roleTitle: roleCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  List<Project> get _filteredProjects {
    var list = List<Project>.from(_projects);
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q) || p.slug.toLowerCase().contains(q)).toList();
    }
    if (_sortBy == 'name') {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 800;
    final currentOrg = AuthService().currentOrganization;
    final orgs = AuthService().organizations;
    final isOrg = currentOrg.type == 'organization';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.sidebar,
        title: Row(
          children: [
            const EventDockLogo(height: 28, fontSize: 18),
            const SizedBox(width: 16),
            Container(height: 18, width: 1, color: AppTheme.cardBorder),
            const SizedBox(width: 16),

            // Workspace Switcher Dropdown
            PopupMenuButton<Organization>(
              tooltip: 'Switch workspace',
              color: AppTheme.card,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.cardBorder),
              ),
              onSelected: (org) {
                setState(() {
                  AuthService().switchOrganization(org);
                });
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem<Organization>(
                  enabled: false,
                  height: 26,
                  child: Text(
                    'WORKSPACES',
                    style: TextStyle(color: AppTheme.textSubtle, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                  ),
                ),
                const PopupMenuDivider(height: 1),
                ...orgs.map((o) {
                  final isCurrent = o.id == currentOrg.id;
                  return PopupMenuItem<Organization>(
                    value: o,
                    child: Row(
                      children: [
                        Icon(
                          o.type == 'organization' ? Icons.business_rounded : Icons.person_rounded,
                          size: 16,
                          color: isCurrent ? AppTheme.heroOrange : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            o.name,
                            style: TextStyle(
                              color: isCurrent ? AppTheme.heroOrange : AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          const Icon(Icons.check, size: 14, color: AppTheme.heroOrange),
                      ],
                    ),
                  );
                }),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.cardSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOrg ? Icons.business_rounded : Icons.person_rounded,
                      size: 14,
                      color: AppTheme.heroOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentOrg.name,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.cardBorder),
        ),
        actions: [
          // Account Profile & Menu
          PopupMenuButton<String>(
            tooltip: 'Account Settings',
            color: AppTheme.card,
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.cardBorder)),
            onSelected: (action) {
              if (action == 'settings') {
                _showAccountSettingsModal();
              } else if (action == 'signout') {
                widget.onSignOut();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AuthService().fullName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(AuthService().userEmail ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: AppTheme.textMuted),
                    SizedBox(width: 8),
                    Text('Account Settings', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 16, color: AppTheme.status5xx),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(fontSize: 12, color: AppTheme.status5xx)),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: AppTheme.heroOrange.withValues(alpha: 0.2),
                    child: Text(
                      AuthService().fullName.isNotEmpty ? AuthService().fullName.substring(0, 1).toUpperCase() : 'D',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.heroOrange),
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 8),
                    Text(
                      AuthService().fullName,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.textMuted),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.heroOrange))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 40, vertical: 28),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Workspace Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      currentOrg.name,
                                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardSecondary,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.cardBorder),
                                      ),
                                      child: Text(
                                        currentOrg.plan,
                                        style: const TextStyle(color: AppTheme.heroOrange, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isOrg
                                      ? 'Organisation workspace • ${_projects.length} microservices active'
                                      : 'Individual workspace • Solo developer telemetry pipeline',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _openCreateProjectModal,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('New Project', style: TextStyle(fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.heroOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Navigation Tabs (Overview, Projects, Members, Settings)
                      _buildWorkspaceTabs(isOrg),
                      const SizedBox(height: 24),

                      // Tab Views
                      if (_selectedTabIndex == 0) _buildOverviewTab(),
                      if (_selectedTabIndex == 1) _buildProjectsTab(),
                      if (_selectedTabIndex == 2 && isOrg) _buildMembersTab(currentOrg.id),
                      if (_selectedTabIndex == 3 || (_selectedTabIndex == 2 && !isOrg)) _buildSettingsTab(currentOrg),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWorkspaceTabs(bool isOrg) {
    final tabs = [
      {'idx': 0, 'title': 'Overview', 'icon': Icons.space_dashboard_outlined},
      {'idx': 1, 'title': 'Projects', 'icon': Icons.folder_outlined},
      if (isOrg) {'idx': 2, 'title': 'Members', 'icon': Icons.people_outline_rounded},
      {'idx': isOrg ? 3 : 2, 'title': 'Settings', 'icon': Icons.tune_rounded},
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
      ),
      child: Row(
        children: tabs.map((t) {
          final idx = t['idx'] as int;
          final isSelected = _selectedTabIndex == idx;

          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = idx),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppTheme.heroOrange : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      size: 16,
                      color: isSelected ? AppTheme.heroOrange : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t['title'] as String,
                      style: TextStyle(
                        color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final currentOrg = AuthService().currentOrganization;
    final members = AuthService().getMembers(currentOrg.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metric Cards Strip
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Projects',
                value: '${_projects.length}',
                subtitle: 'Active ingestion pipelines',
                icon: Icons.folder_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricCard(
                title: 'Workspace Scope',
                value: currentOrg.type == 'organization' ? 'Organisation' : 'Individual',
                subtitle: currentOrg.plan,
                icon: Icons.business_rounded,
              ),
            ),
            if (currentOrg.type == 'organization') ...[
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricCard(
                  title: 'Team Members',
                  value: '${members.length}',
                  subtitle: 'Collaborators in workspace',
                  icon: Icons.people_rounded,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 28),

        // Recent Projects Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Projects',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedTabIndex = 1),
              child: const Text('View all projects', style: TextStyle(color: AppTheme.heroOrange, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_projects.isEmpty)
          _buildEmptyProjectsState()
        else
          Column(
            children: _projects.take(3).map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => widget.onSelectProject(p),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.folder_outlined, color: AppTheme.heroOrange, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(p.slug, style: const TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.cardSecondary, borderRadius: BorderRadius.circular(6)),
                          child: Text('${p.retentionDays}d retention', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.heroOrange),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildProjectsTab() {
    final projects = _filteredProjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter & Sort Row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cardSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Search projects by name or slug...',
                          hintStyle: TextStyle(color: AppTheme.textSubtle, fontSize: 13),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: DropdownButton<String>(
                value: _sortBy,
                underline: const SizedBox(),
                dropdownColor: AppTheme.cardSecondary,
                style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                  DropdownMenuItem(value: 'date', child: Text('Sort by Recent')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _sortBy = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (projects.isEmpty)
          _buildEmptyProjectsState()
        else
          LayoutBuilder(
            builder: (ctx, constraints) {
              final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 210,
                ),
                itemCount: projects.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == projects.length) return _buildNewProjectDashedCard();
                  final p = projects[i];
                  return _buildProjectCard(p);
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildMembersTab(String orgId) {
    final members = AuthService().getMembers(orgId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Organisation Members', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Manage access permissions and role-based actions for ${AuthService().currentOrganization.name}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showInviteMemberModal,
              icon: const Icon(Icons.person_add_alt_1, size: 16),
              label: const Text('Invite Member', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.heroOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Compact Data Table
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
                ),
                child: Row(
                  children: const [
                    Expanded(flex: 3, child: Text('MEMBER', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('ROLE', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('STATUS', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.bold))),
                    SizedBox(width: 40),
                  ],
                ),
              ),

              // Rows
              ...members.map((m) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
                  ),
                  child: Row(
                    children: [
                      // Avatar & Info
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.heroOrange.withValues(alpha: 0.15),
                              child: Text(
                                m.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: AppTheme.heroOrange, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(m.email, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Role with Selector
                      Expanded(
                        flex: 2,
                        child: m.role == 'Owner'
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppTheme.cardSecondary, borderRadius: BorderRadius.circular(6)),
                                child: const Text('Owner', style: TextStyle(color: AppTheme.heroOrange, fontWeight: FontWeight.bold, fontSize: 11)),
                              )
                            : DropdownButton<String>(
                                value: m.role,
                                underline: const SizedBox(),
                                dropdownColor: AppTheme.cardSecondary,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                items: const [
                                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                                  DropdownMenuItem(value: 'Member', child: Text('Member')),
                                ],
                                onChanged: (newRole) {
                                  if (newRole != null) {
                                    AuthService().updateMemberRole(orgId, m.id, newRole);
                                    setState(() {});
                                  }
                                },
                              ),
                      ),

                      // Status Badge
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: m.status == 'Active' ? AppTheme.status2xx.withValues(alpha: 0.12) : AppTheme.status4xx.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m.status,
                                style: TextStyle(
                                  color: m.status == 'Active' ? AppTheme.status2xx : AppTheme.status4xx,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Actions Overflow
                      if (m.role != 'Owner')
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 16, color: AppTheme.textMuted),
                          tooltip: 'Remove member',
                          onPressed: () {
                            AuthService().removeMember(orgId, m.id);
                            setState(() {});
                          },
                        )
                      else
                        const SizedBox(width: 40),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(Organization org) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Workspace Settings', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Manage workspace name, slug, and subscription plan tier.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 20),

          Text('Workspace Name: ${org.name}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Slug: ${org.slug}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontFamily: 'monospace')),
          const SizedBox(height: 12),
          Text('Plan: ${org.plan}', style: const TextStyle(color: AppTheme.heroOrange, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Icon(icon, size: 16, color: AppTheme.heroOrange),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return InkWell(
      onTap: () => widget.onSelectProject(project),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, size: 18, color: AppTheme.textMuted),
                      color: AppTheme.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppTheme.cardBorder)),
                      onSelected: (act) {
                        if (act == 'open') widget.onSelectProject(project);
                        if (act == 'delete') _showDeleteProjectConfirmation(project);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'open', child: Text('Open Project', style: TextStyle(fontSize: 12))),
                        const PopupMenuItem(value: 'delete', child: Text('Delete Project', style: TextStyle(fontSize: 12, color: AppTheme.status5xx))),
                      ],
                    ),
                  ],
                ),
                Text(
                  project.slug,
                  style: const TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                Text(
                  project.description?.isNotEmpty == true ? project.description! : 'Diagnostic telemetry pipeline active',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.cardSecondary, borderRadius: BorderRadius.circular(4)),
                  child: Text('${project.retentionDays}d retention', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ),
                Row(
                  children: const [
                    Text('Open', style: TextStyle(color: AppTheme.heroOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.heroOrange),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewProjectDashedCard() {
    return InkWell(
      onTap: _openCreateProjectModal,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardSecondary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.heroOrange.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.add, color: AppTheme.heroOrange, size: 20),
            ),
            const SizedBox(height: 10),
            const Text('New Project', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            const Text('Provision API keys & diagnostic pipeline', style: TextStyle(color: AppTheme.textSubtle, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProjectsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.heroOrange.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.folder_open_rounded, color: AppTheme.heroOrange, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Your workspace is ready', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Create your first project to connect your Spring Boot application and ingest diagnostic faults.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openCreateProjectModal,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create your first project', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.heroOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
