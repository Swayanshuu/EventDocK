import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descController = TextEditingController(text: widget.project.description ?? '');
    _retentionDays = widget.project.retentionDays;
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final updated = await ApiService().updateProject(
        widget.project.id,
        _nameController.text.trim(),
        _descController.text.trim(),
        _retentionDays,
      );
      widget.onProjectUpdated(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project settings updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text(
          'Are you sure you want to delete "${widget.project.name}"? All associated diagnostic events, replay logs, and API keys will be permanently deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.status5xx, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().deleteProject(widget.project.id);
                widget.onProjectDeleted();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
              }
            },
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Project Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Configure data retention policies and project metadata', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 24),

          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Project Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 20),
                const Text('Data Retention Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                const Text(
                  'Events older than this threshold will be pruned during scheduled maintenance.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                DropdownButton<int>(
                  value: _retentionDays,
                  dropdownColor: AppTheme.cardSecondary,
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 days')),
                    DropdownMenuItem(value: 14, child: Text('14 days')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                    DropdownMenuItem(value: 90, child: Text('90 days')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _retentionDays = val);
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Danger Zone
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.status5xx.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.status5xx.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Danger Zone', style: TextStyle(color: AppTheme.status5xx, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                const Text(
                  'Deleting this project removes all diagnostic events, stack traces, and API keys. This action cannot be undone.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.status5xx, foregroundColor: Colors.white),
                  onPressed: _confirmDelete,
                  child: const Text('Delete Project'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
