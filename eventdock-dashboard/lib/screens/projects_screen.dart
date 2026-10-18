import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProjectsScreen extends StatefulWidget {
  final Function(Project) onSelectProject;
  final VoidCallback onSignOut;

  const ProjectsScreen({super.key, required this.onSelectProject, required this.onSignOut});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;
  String? _error;

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
      setState(() {
        _projects = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateProjectDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int retention = 30;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create New Project'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Project Name (e.g. LinkPeer Backend)'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description (optional)'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Event Retention: ', style: TextStyle(color: AppTheme.textMuted)),
                      DropdownButton<int>(
                        value: retention,
                        dropdownColor: AppTheme.card,
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('7 days')),
                          DropdownMenuItem(value: 14, child: Text('14 days')),
                          DropdownMenuItem(value: 30, child: Text('30 days')),
                          DropdownMenuItem(value: 90, child: Text('90 days')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => retention = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  final p = await ApiService().createProject(nameCtrl.text.trim(), descCtrl.text.trim(), retention);
                  if (!mounted) return;
                  _loadProjects();
                  // Automatically generate initial ingestion key for the new project
                  final key = await ApiService().createApiKey(p.id, 'Default App Ingestion Key');
                  if (!mounted) return;
                  _showNewProjectKeyDialog(p, key.rawKey);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              child: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewProjectKeyDialog(Project project, String rawKey) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.status2xx.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppTheme.status2xx, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Project Created!'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your project "${project.name}" is ready. Copy this ingestion key and add it to your Spring Boot application.',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              const Text('Project Ingestion API Key:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.codeBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        rawKey,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: AppTheme.primary),
                      tooltip: 'Copy API Key',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: rawKey));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('API Key copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Paste this in your application.yml:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.codeBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: SelectableText(
                  'eventdock:\n'
                  '  api-key: "$rawKey"\n'
                  '  endpoint: "https://api.eventdock.swynx.dev"\n',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'eventdock-starter will automatically send this key in each request to ingest diagnostic failures.',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSelectProject(project);
            },
            child: const Text('Go to Project Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const EventDockLogo(height: 28),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.cardBorder),
        ),
        actions: [
          if (!isCompact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  AuthService().userEmail ?? '',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20, color: AppTheme.textMuted),
            tooltip: 'Sign Out',
            onPressed: widget.onSignOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(isCompact ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCompact) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Projects',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select a project to inspect failure events and manage replays',
                          style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.9), fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showCreateProjectDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New Project'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Projects',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Select a project to inspect diagnostic failure events and manage replays',
                                style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.9), fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _showCreateProjectDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New Project'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.status5xx.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.status5xx.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.status5xx),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.status5xx))),
                          TextButton(onPressed: _loadProjects, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _projects.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open_rounded, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                                const SizedBox(height: 16),
                                const Text('No projects registered yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                const Text('Create a project to obtain an API key for your Spring Boot application', style: TextStyle(color: AppTheme.textMuted)),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _showCreateProjectDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Project'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: isCompact ? 500 : 380,
                              mainAxisExtent: 180,
                              crossAxisSpacing: isCompact ? 14 : 20,
                              mainAxisSpacing: isCompact ? 14 : 20,
                            ),
                            itemCount: _projects.length,
                            itemBuilder: (context, index) {
                              final p = _projects[index];
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppTheme.cardBorder),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => widget.onSelectProject(p),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p.name,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    p.slug,
                                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontFamily: 'monospace'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                                          ],
                                        ),
                                        Text(
                                          p.description ?? 'No description provided',
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.history_toggle_off_rounded, size: 14, color: AppTheme.textMuted.withValues(alpha: 0.8)),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Retention: ${p.retentionDays} days',
                                              style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.8), fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
