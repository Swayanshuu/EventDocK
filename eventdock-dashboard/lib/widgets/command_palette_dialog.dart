import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';

enum CommandPaletteItemType {
  navigation,
  project,
  endpoint,
  action,
}

class CommandPaletteItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? category;
  final IconData icon;
  final CommandPaletteItemType type;
  final VoidCallback onSelect;
  final String? badge;

  const CommandPaletteItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.category,
    required this.icon,
    required this.type,
    required this.onSelect,
    this.badge,
  });
}

class CommandPaletteDialog extends StatefulWidget {
  final Project currentProject;
  final List<Project> allProjects;
  final ValueChanged<int> onNavigate;
  final ValueChanged<Project> onSelectProject;
  final VoidCallback onExport;
  final VoidCallback onToggleSidebar;
  final VoidCallback onRefresh;
  final VoidCallback? onCreateProject;
  final List<String>? monitoredEndpoints;

  const CommandPaletteDialog({
    super.key,
    required this.currentProject,
    required this.allProjects,
    required this.onNavigate,
    required this.onSelectProject,
    required this.onExport,
    required this.onToggleSidebar,
    required this.onRefresh,
    this.onCreateProject,
    this.monitoredEndpoints,
  });

  static Future<void> show({
    required BuildContext context,
    required Project currentProject,
    required List<Project> allProjects,
    required ValueChanged<int> onNavigate,
    required ValueChanged<Project> onSelectProject,
    required VoidCallback onExport,
    required VoidCallback onToggleSidebar,
    required VoidCallback onRefresh,
    VoidCallback? onCreateProject,
    List<String>? monitoredEndpoints,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => CommandPaletteDialog(
        currentProject: currentProject,
        allProjects: allProjects,
        onNavigate: onNavigate,
        onSelectProject: onSelectProject,
        onExport: onExport,
        onToggleSidebar: onToggleSidebar,
        onRefresh: onRefresh,
        onCreateProject: onCreateProject,
        monitoredEndpoints: monitoredEndpoints,
      ),
    );
  }

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  List<CommandPaletteItem> _buildAllItems() {
    final items = <CommandPaletteItem>[];

    // Navigation
    items.add(
      CommandPaletteItem(
        id: 'nav_overview',
        title: 'Dashboard Overview',
        subtitle: 'Failure velocity, stability score, fault metrics',
        category: 'Navigation',
        icon: Icons.dashboard_outlined,
        type: CommandPaletteItemType.navigation,
        badge: 'Tab 1',
        onSelect: () => widget.onNavigate(0),
      ),
    );
    items.add(
      CommandPaletteItem(
        id: 'nav_inbox',
        title: 'Event Inbox & Failures',
        subtitle: 'Live diagnostic events, stack traces & replays',
        category: 'Navigation',
        icon: Icons.inbox_outlined,
        type: CommandPaletteItemType.navigation,
        badge: 'Tab 2',
        onSelect: () => widget.onNavigate(1),
      ),
    );
    items.add(
      CommandPaletteItem(
        id: 'nav_api_keys',
        title: 'API Keys & Ingestion',
        subtitle: 'Manage client credentials & webhook routing',
        category: 'Navigation',
        icon: Icons.key_outlined,
        type: CommandPaletteItemType.navigation,
        badge: 'Tab 3',
        onSelect: () => widget.onNavigate(2),
      ),
    );
    items.add(
      CommandPaletteItem(
        id: 'nav_settings',
        title: 'Project Settings',
        subtitle: 'Retention duration, alerts, ingestion keys & danger zone',
        category: 'Navigation',
        icon: Icons.settings_outlined,
        type: CommandPaletteItemType.navigation,
        badge: 'Tab 4',
        onSelect: () => widget.onNavigate(3),
      ),
    );

    // Actions
    items.add(
      CommandPaletteItem(
        id: 'act_export',
        title: 'Export Telemetry Data',
        subtitle: 'Download project metrics & events as JSON or CSV',
        category: 'Actions',
        icon: Icons.download_rounded,
        type: CommandPaletteItemType.action,
        badge: 'Export',
        onSelect: widget.onExport,
      ),
    );
    if (widget.onCreateProject != null) {
      items.add(
        CommandPaletteItem(
          id: 'act_new_project',
          title: 'Create New Project',
          subtitle: 'Initialize a new monitored application domain',
          category: 'Actions',
          icon: Icons.add_circle_outline_rounded,
          type: CommandPaletteItemType.action,
          onSelect: widget.onCreateProject!,
        ),
      );
    }
    items.add(
      CommandPaletteItem(
        id: 'act_toggle_sidebar',
        title: 'Toggle Navigation Sidebar',
        subtitle: 'Switch between collapsed and expanded sidebar states',
        category: 'Actions',
        icon: Icons.view_sidebar_outlined,
        type: CommandPaletteItemType.action,
        onSelect: widget.onToggleSidebar,
      ),
    );
    items.add(
      CommandPaletteItem(
        id: 'act_refresh',
        title: 'Refresh Dashboard',
        subtitle: 'Re-sync active telemetry metrics and failure counts',
        category: 'Actions',
        icon: Icons.refresh_rounded,
        type: CommandPaletteItemType.action,
        onSelect: widget.onRefresh,
      ),
    );

    // Switch Projects
    for (final p in widget.allProjects) {
      final isCurrent = p.id == widget.currentProject.id;
      items.add(
        CommandPaletteItem(
          id: 'project_${p.id}',
          title: 'Switch to "${p.name}"',
          subtitle: 'Slug: ${p.slug}',
          category: 'Projects',
          icon: Icons.folder_open_rounded,
          type: CommandPaletteItemType.project,
          badge: isCurrent ? 'Active' : null,
          onSelect: () => widget.onSelectProject(p),
        ),
      );
    }

    // Monitored Endpoints (only if present in telemetry)
    if (widget.monitoredEndpoints != null) {
      for (final ep in widget.monitoredEndpoints!) {
        items.add(
          CommandPaletteItem(
            id: 'ep_$ep',
            title: ep,
            subtitle: 'Monitored endpoint • View in event inbox',
            category: 'Endpoints',
            icon: Icons.link_rounded,
            type: CommandPaletteItemType.endpoint,
            onSelect: () => widget.onNavigate(1),
          ),
        );
      }
    }

    return items;
  }

  List<CommandPaletteItem> _getFilteredItems() {
    final all = _buildAllItems();
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return all;

    return all.where((item) {
      final titleMatch = item.title.toLowerCase().contains(query);
      final subMatch = item.subtitle?.toLowerCase().contains(query) ?? false;
      final catMatch = item.category?.toLowerCase().contains(query) ?? false;
      return titleMatch || subMatch || catMatch;
    }).toList();
  }

  void _executeItem(CommandPaletteItem item) {
    Navigator.of(context).pop();
    item.onSelect();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredItems();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 24),
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (filtered.isNotEmpty) {
                setState(() {
                  _selectedIndex = (_selectedIndex + 1) % filtered.length;
                });
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (filtered.isNotEmpty) {
                setState(() {
                  _selectedIndex = (_selectedIndex - 1 + filtered.length) % filtered.length;
                });
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.enter) {
              if (filtered.isNotEmpty && _selectedIndex < filtered.length) {
                _executeItem(filtered[_selectedIndex]);
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          width: 620,
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x77000000),
                blurRadius: 40,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Input Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 20, color: AppTheme.heroOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search pages, endpoints, projects, actions...',
                          hintStyle: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: () => _searchController.clear(),
                        icon: Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                        splashRadius: 14,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.sidebar,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Text(
                        'ESC',
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

              Divider(height: 1, thickness: 1, color: AppTheme.cardBorder),

              // Filtered Results List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 28, color: AppTheme.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No results for "${_searchController.text}"',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try searching for overview, inbox, export, or endpoint path.',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSelected = index == _selectedIndex;

                          return InkWell(
                            onTap: () => _executeItem(item),
                            onHover: (hovering) {
                              if (hovering && _selectedIndex != index) {
                                setState(() => _selectedIndex = index);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.cardSecondary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? Border.all(color: AppTheme.cardBorder) : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.heroOrange.withValues(alpha: 0.15)
                                          : AppTheme.sidebar,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.heroOrange.withValues(alpha: 0.3)
                                            : AppTheme.cardBorder,
                                      ),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 15,
                                      color: isSelected ? AppTheme.heroOrange : AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            color: isSelected ? AppTheme.textPrimary : AppTheme.textSubtle,
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.subtitle != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.subtitle!,
                                            style: TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (item.category != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.sidebar,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.category!,
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (item.badge != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.badge == 'Critical'
                                            ? const Color(0x22EF4444)
                                            : item.badge == 'Warning'
                                                ? const Color(0x22F59E0B)
                                                : AppTheme.heroOrange.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: item.badge == 'Critical'
                                              ? const Color(0x44EF4444)
                                              : item.badge == 'Warning'
                                                  ? const Color(0x44F59E0B)
                                                  : AppTheme.heroOrange.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        item.badge!,
                                        style: TextStyle(
                                          color: item.badge == 'Critical'
                                              ? const Color(0xFFEF4444)
                                              : item.badge == 'Warning'
                                                  ? const Color(0xFFF59E0B)
                                                  : AppTheme.heroOrange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.keyboard_return_rounded,
                                      size: 14,
                                      color: AppTheme.textMuted,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              Divider(height: 1, thickness: 1, color: AppTheme.cardBorder),

              // Footer Shortcut Hints
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.sidebar,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Navigation',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                    SizedBox(width: 14),
                    Text(
                      '↑↓  Navigate',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: AppTheme.textSubtle,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(
                      '↵  Select',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: AppTheme.textSubtle,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(
                      'ESC  Close',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: AppTheme.textSubtle,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}