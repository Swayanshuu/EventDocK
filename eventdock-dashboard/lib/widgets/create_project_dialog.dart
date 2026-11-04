import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/project.dart';
import '../models/organization.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class CreateProjectDialog {
  static Future<void> show(
    BuildContext context, {
    required Function(Project createdProject) onProjectCreated,
  }) async {
    int currentStep = 0; // 0: Details, 1: Config, 2: Review, 3: Progress, 4: Created
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int retentionDays = 30;
    String region = 'us-east-1';
    String environment = 'Production';
    Organization selectedOrg = AuthService().currentOrganization;
    String? errorMessage;
    Project? finalProject;
    String? generatedKey;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final orgs = AuthService().organizations;

          return Dialog(
            backgroundColor: AppTheme.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.cardBorder),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modal Header with Step Pills
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.heroOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_box_outlined, color: AppTheme.heroOrange, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create a New Project',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Workspace: ${selectedOrg.name}',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (currentStep < 3)
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                    ],
                  ),

                  if (currentStep < 3) ...[
                    const SizedBox(height: 16),
                    _buildStepIndicator(currentStep),
                  ],

                  const SizedBox(height: 20),

                  if (errorMessage != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.status5xx.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.status5xx.withValues(alpha: 0.3)),
                      ),
                      child: Text(errorMessage!, style: const TextStyle(color: AppTheme.status5xx, fontSize: 12)),
                    ),
                  ],

                  // Step Views
                  if (currentStep == 0) ...[
                    // Step 1: Project Details
                    Text('Workspace', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<Organization>(
                      initialValue: selectedOrg,
                      dropdownColor: AppTheme.cardSecondary,
                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                      items: orgs.map((o) => DropdownMenuItem(value: o, child: Text(o.name))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => selectedOrg = v);
                      },
                    ),
                    const SizedBox(height: 14),

                    Text('Project Name', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(hintText: 'e.g. Payments Microservice'),
                    ),
                    const SizedBox(height: 14),

                    Text('Description (optional)', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(hintText: 'Short description of this service'),
                    ),
                  ],

                  if (currentStep == 1) ...[
                    // Step 2: Configuration
                    Text('Cloud Region', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: region,
                      dropdownColor: AppTheme.cardSecondary,
                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                      items: const [
                        DropdownMenuItem(value: 'us-east-1', child: Text('AWS us-east-1 (N. Virginia)')),
                        DropdownMenuItem(value: 'eu-central-1', child: Text('AWS eu-central-1 (Frankfurt)')),
                        DropdownMenuItem(value: 'ap-south-1', child: Text('AWS ap-south-1 (Mumbai)')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => region = v);
                      },
                    ),
                    const SizedBox(height: 14),

                    Text('Deployment Environment', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: environment,
                      dropdownColor: AppTheme.cardSecondary,
                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                      items: const [
                        DropdownMenuItem(value: 'Production', child: Text('Production')),
                        DropdownMenuItem(value: 'Staging', child: Text('Staging')),
                        DropdownMenuItem(value: 'Development', child: Text('Development')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => environment = v);
                      },
                    ),
                    const SizedBox(height: 14),

                    Text('Diagnostic Retention Policy', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Row(
                      children: [7, 14, 30, 90].map((days) {
                        final isSelected = retentionDays == days;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () => setState(() => retentionDays = days),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.heroOrange.withValues(alpha: 0.12) : AppTheme.cardSecondary,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.heroOrange : AppTheme.cardBorder,
                                  ),
                                ),
                                child: Text(
                                  '$days d',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppTheme.heroOrange : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  if (currentStep == 2) ...[
                    // Step 3: Review
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildReviewRow('Project Name', nameCtrl.text.trim()),
                          _buildReviewRow('Workspace', selectedOrg.name),
                          _buildReviewRow('Environment', environment),
                          _buildReviewRow('Cloud Region', region),
                          _buildReviewRow('Retention Policy', '$retentionDays days'),
                          if (descCtrl.text.trim().isNotEmpty)
                            _buildReviewRow('Description', descCtrl.text.trim()),
                        ],
                      ),
                    ),
                  ],

                  if (currentStep == 3) ...[
                    // Step 4: Progress
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          CircularProgressIndicator(strokeWidth: 2, color: AppTheme.heroOrange),
                          SizedBox(height: 18),
                          Text(
                            'Provisioning project & generating ingestion keys...',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Allocating telemetry buffer and configuring Spring Boot starter endpoints',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (currentStep == 4 && finalProject != null) ...[
                    // Step 5: Created Success
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.status2xx.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: AppTheme.status2xx, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${finalProject!.name} is Ready!',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                            ),
                            Text(
                              'Workspace: ${selectedOrg.name}',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Dedicated Ingestion API Key:',
                      style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.codeBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              generatedKey ?? 'ed_live_example12345',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.heroOrange,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.heroOrange),
                            tooltip: 'Copy key',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: generatedKey ?? ''));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('API Key copied to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Actions
                  if (currentStep < 3)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (currentStep > 0)
                          TextButton(
                            onPressed: () => setState(() => currentStep--),
                            child: Text('Back', style: TextStyle(color: AppTheme.textMuted)),
                          )
                        else
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                          ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.heroOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            if (currentStep == 0) {
                              if (nameCtrl.text.trim().isEmpty) {
                                setState(() => errorMessage = 'Please enter a project name.');
                                return;
                              }
                              setState(() {
                                errorMessage = null;
                                currentStep = 1;
                              });
                            } else if (currentStep == 1) {
                              setState(() => currentStep = 2);
                            } else if (currentStep == 2) {
                              // Perform creation
                              setState(() => currentStep = 3);
                              try {
                                final p = await ApiService().createProject(
                                  nameCtrl.text.trim(),
                                  descCtrl.text.trim(),
                                  retentionDays,
                                );
                                final key = await ApiService().createApiKey(p.id, 'Default App Ingestion Key');
                                setState(() {
                                  finalProject = p;
                                  generatedKey = key.rawKey;
                                  currentStep = 4;
                                });
                              } catch (e) {
                                setState(() {
                                  errorMessage = e.toString().replaceFirst('Exception: ', '');
                                  currentStep = 2;
                                });
                              }
                            }
                          },
                          child: Text(
                            currentStep == 2 ? 'Create Project' : 'Continue',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),

                  if (currentStep == 4)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.heroOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (finalProject != null) {
                          onProjectCreated(finalProject!);
                        }
                      },
                      child: const Text('Open Project Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildStepIndicator(int currentStep) {
    final titles = ['Details', 'Configuration', 'Review'];
    return Row(
      children: List.generate(titles.length, (idx) {
        final isPassed = idx < currentStep;
        final isCurrent = idx == currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isPassed
                      ? AppTheme.status2xx
                      : (isCurrent ? AppTheme.heroOrange : AppTheme.cardSecondary),
                  shape: BoxShape.circle,
                ),
                child: isPassed
                    ? const Icon(Icons.check, size: 12, color: Colors.black)
                    : Text(
                        '${idx + 1}',
                        style: TextStyle(
                          color: isCurrent ? Colors.white : AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  titles[idx],
                  style: TextStyle(
                    color: isCurrent ? AppTheme.textPrimary : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (idx < titles.length - 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right, size: 14, color: AppTheme.textSubtle),
                ),
            ],
          ),
        );
      }),
    );
  }

  static Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          Text(value, style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}