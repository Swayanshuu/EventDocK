import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProjectSettingsView extends StatefulWidget {
  final Project project;
  final VoidCallback onProjectDeleted;
  final Function(Project) onProjectUpdated;

  const ProjectSettingsView({
    super.key,
    required this.project,
    required this.onProjectDeleted,
    required this.onProjectUpdated,
  });

  @override
  State<ProjectSettingsView> createState() => _ProjectSettingsViewState();
}

class _ProjectSettingsViewState extends State<ProjectSettingsView> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late int _retentionDays;
  bool _isSaving = false;
  bool _hasChanges = false;

  final List<Map<String, dynamic>> _retentionOptions = [
    {
      'days': 7,
      'label': '7 Days',
      'desc': 'Quick triage',
      'badge': 'Dev',
    },
    {
      'days': 14,
      'label': '14 Days',
      'desc': 'Standard retention',
      'badge': 'Recommended',
    },
    {
      'days': 30,
      'label': '30 Days',
      'desc': 'Extended audit',
      'badge': 'Pro',
    },
    {
      'days': 90,
      'label': '90 Days',
      'desc': 'Compliance archive',
      'badge': 'Enterprise',
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descController = TextEditingController(text: widget.project.description ?? '');
    _retentionDays = widget.project.retentionDays;

    _nameController.addListener(_checkChanges);
    _descController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final changed = _nameController.text.trim() != widget.project.name ||
        _descController.text.trim() != (widget.project.description ?? '') ||
        _retentionDays != widget.project.retentionDays;
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  void _resetChanges() {
    setState(() {
      _nameController.text = widget.project.name;
      _descController.text = widget.project.description ?? '';
      _retentionDays = widget.project.retentionDays;
      _hasChanges = false;
    });
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project name cannot be empty'),
          backgroundColor: AppTheme.status5xx,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await ApiService().updateProject(
        widget.project.id,
        name,
        _descController.text.trim(),
        _retentionDays,
      );
      widget.onProjectUpdated(updated);
      if (mounted) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project settings updated successfully'),
            backgroundColor: AppTheme.status2xx,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update project: $e'),
            backgroundColor: AppTheme.status5xx,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.cardBorder),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.status5xx, size: 22),
            SizedBox(width: 10),
            Text(
              'Delete Project',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete "${widget.project.name}"?',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All recorded failures, stack traces, replay attempts, and API keys associated with this service will be permanently erased. This operation cannot be undone.',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textMuted,
              side: BorderSide(color: AppTheme.cardBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.status5xx,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().deleteProject(widget.project.id);
                if (!mounted) return;
                widget.onProjectDeleted();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delete failed: $e'),
                      backgroundColor: AppTheme.status5xx,
                    ),
                  );
                }
              }
            },
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 32,
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project Settings',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configure telemetry ingestion, retention rules, and metadata for ${widget.project.name}',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasChanges)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: _resetChanges,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textMuted,
                            side: BorderSide(color: AppTheme.cardBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Discard', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.heroOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Section 1: General Information
              _buildCardContainer(
                title: 'General Information',
                icon: Icons.tune_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project ID / Slug row
                    _buildLabel('PROJECT SLUG'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.project.slug,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _copyToClipboard(widget.project.slug, 'Project Slug'),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppTheme.card,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Icon(Icons.copy_rounded, size: 13, color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Project Name
                    _buildLabel('PROJECT NAME'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.cardSecondary,
                        hintText: 'e.g. Auth Service',
                        hintStyle: TextStyle(color: AppTheme.textSubtle, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.heroOrange, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Description
                    _buildLabel('DESCRIPTION'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.cardSecondary,
                        hintText: 'Brief summary of the microservice or API cluster',
                        hintStyle: TextStyle(color: AppTheme.textSubtle, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.heroOrange, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: Data Retention & Compliance
              _buildCardContainer(
                title: 'Data Retention & Pruning',
                icon: Icons.history_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select how long failure diagnostics, traces, and replay snapshots are stored before automatic purging.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 16),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = constraints.maxWidth >= 600
                            ? (constraints.maxWidth - 36) / 4
                            : (constraints.maxWidth - 12) / 2;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _retentionOptions.map((opt) {
                            final days = opt['days'] as int;
                            final isSelected = _retentionDays == days;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _retentionDays = days;
                                  _checkChanges();
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: itemWidth,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.heroOrange.withValues(alpha: 0.12)
                                      : AppTheme.cardSecondary,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.heroOrange : AppTheme.cardBorder,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          opt['label'] as String,
                                          style: TextStyle(
                                            color: isSelected ? AppTheme.textPrimary : AppTheme.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppTheme.heroOrange
                                                : AppTheme.cardBorder,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            opt['badge'] as String,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : AppTheme.textMuted,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      opt['desc'] as String,
                                      style: TextStyle(
                                        color: isSelected ? AppTheme.heroOrange : AppTheme.textSubtle,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 3: Telemetry Ingestion Endpoint
              _buildCardContainer(
                title: 'Ingestion Endpoint',
                icon: Icons.alt_route_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forward diagnostic events from your service via HTTP POST to this ingestion URL.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.heroOrange.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'POST',
                              style: TextStyle(
                                color: AppTheme.heroOrange,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'http://localhost:8080/api/v1/projects/${widget.project.id}/events',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _copyToClipboard(
                              'http://localhost:8080/api/v1/projects/${widget.project.id}/events',
                              'Ingestion URL',
                            ),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppTheme.card,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Icon(Icons.copy_rounded, size: 13, color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 4: Danger Zone
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.status5xx.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.status5xx.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: AppTheme.status5xx, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Danger Zone',
                          style: TextStyle(
                            color: AppTheme.status5xx,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Permanently remove this project, all diagnostic failure records, stack frames, replay logs, and project API keys. This action cannot be reversed.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.status5xx,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: _confirmDelete,
                      child: const Text(
                        'Delete Project',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Bottom Save Bar if has changes
              if (_hasChanges)
                Center(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.heroOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save Settings',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.heroOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppTheme.heroOrange),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.textSubtle,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}