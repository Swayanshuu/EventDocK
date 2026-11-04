import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  final Function(Project project) onComplete;
  final VoidCallback onSignOut;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
    required this.onSignOut,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Step 0: Profile, Step 1: Workspace Type, Step 2: Workspace Setup (Individual or Org with optional invites), Step 3: Completion
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 0: Personal Profile
  late final TextEditingController _nameController;
  final _roleTitleController = TextEditingController(text: 'Lead Architect');

  // Step 1: Workspace Type Selection
  String _workspaceType = 'individual'; // 'individual' or 'organization'

  // Step 2: Workspace Configuration
  final _workspaceNameController = TextEditingController(text: 'Personal Workspace');
  final _workspaceSlugController = TextEditingController(text: 'personal');
  String _industryType = 'SaaS & Cloud Services';
  String _teamSize = '1-10 members';

  // Optional Team Invitations for Organisation
  final List<Map<String, String>> _invitations = [];
  final _inviteEmailController = TextEditingController();
  String _inviteRole = 'Member';

  // Step 3: Created Project & Workspace
  Project? _initialProject;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: AuthService().fullName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleTitleController.dispose();
    _workspaceNameController.dispose();
    _workspaceSlugController.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteOnboarding() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Update personal profile
      AuthService().updateProfile(
        fullName: _nameController.text.trim(),
        roleTitle: _roleTitleController.text.trim(),
      );

      // 2. Provision Workspace
      final orgName = _workspaceNameController.text.trim().isEmpty
          ? (_workspaceType == 'organization' ? 'Engineering Team' : 'Personal Workspace')
          : _workspaceNameController.text.trim();

      final createdOrg = AuthService().createOrganization(
        name: orgName,
        type: _workspaceType,
        plan: _workspaceType == 'organization' ? 'Team Pro' : 'Free Developer',
      );

      // 3. Process any team invitations
      for (final inv in _invitations) {
        AuthService().inviteMember(createdOrg.id, inv['email']!, inv['role']!);
      }

      // 4. Create default starter project for the workspace
      final project = await ApiService().createProject(
        '${createdOrg.name} Core Service',
        'Main microservice telemetry and failure pipeline',
        30,
      );

      // 5. Generate initial API key for the project
      await ApiService().createApiKey(project.id, 'Default Ingestion Key');

      setState(() {
        _initialProject = project;
        _currentStep = 3; // Move to Completion step
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 700;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 16 : 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.sidebar,
                    border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
                  ),
                  child: Row(
                    children: [
                      const EventDockLogo(height: 28, fontSize: 18),
                      const Spacer(),
                      Tooltip(
                        message: isDark ? 'Switch to Light Mode (White & Orange)' : 'Switch to Dark Mode (Black & Orange)',
                        child: InkWell(
                          onTap: () {
                            AppTheme.toggleThemeMode();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 36,
                            height: 36,
                            margin: EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardSecondary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Center(
                              child: Icon(
                                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                                size: 16,
                                color: AppTheme.heroOrange,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        AuthService().userEmail ?? '',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                  SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: widget.onSignOut,
                    icon: Icon(Icons.logout_rounded, size: 14, color: AppTheme.textMuted),
                    label: Text('Sign Out', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ),
                ],
              ),
            ),

            // Stepper & Container
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 16 : 32,
                  vertical: 32,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStepperHeader(),
                        const SizedBox(height: 32),

                        if (_errorMessage != null) ...[
                          Container(
                            margin: EdgeInsets.only(bottom: 20),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.status5xx.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.status5xx.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: AppTheme.status5xx, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(_errorMessage!, style: TextStyle(color: AppTheme.status5xx, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_currentStep == 0) _buildStep0Profile(),
                        if (_currentStep == 1) _buildStep1WorkspaceType(),
                        if (_currentStep == 2) _buildStep2WorkspaceSetup(),
                        if (_currentStep == 3) _buildStep3Completion(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildStepperHeader() {
    final steps = [
      {'num': '1', 'title': 'Profile'},
      {'num': '2', 'title': 'Workspace Type'},
      {'num': '3', 'title': 'Setup'},
      {'num': '4', 'title': 'Complete'},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.status2xx
                        : (isCurrent ? AppTheme.heroOrange : AppTheme.cardSecondary),
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? Icon(Icons.check, size: 14, color: Colors.black)
                      : Text(
                          steps[index]['num']!,
                          style: TextStyle(
                            color: isCurrent ? Colors.white : AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    steps[index]['title']!,
                    style: TextStyle(
                      color: isCurrent ? AppTheme.textPrimary : AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (index < steps.length - 1)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right, size: 14, color: AppTheme.textSubtle),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep0Profile() {
    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal profile',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Tell us your name and engineering role to customize your workspace telemetry experience.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Avatar display
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.heroOrange.withValues(alpha: 0.15),
                child: Text(
                  _nameController.text.isNotEmpty ? _nameController.text.substring(0, 1).toUpperCase() : 'D',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.heroOrange),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AuthService().userEmail ?? 'developer@eventdock.dev',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2),
                  Text('Personal profile avatar', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11)),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),

          Text('Full Name', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          TextField(
            controller: _nameController,
            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'e.g. Alex Rivera'),
            onChanged: (v) => setState(() {}),
          ),
          SizedBox(height: 16),

          Text('Job Title / Role (optional)', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          TextField(
            controller: _roleTitleController,
            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'e.g. Staff Backend Engineer / SRE Lead'),
          ),
          const SizedBox(height: 28),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) {
                  setState(() => _errorMessage = 'Please enter your name.');
                  return;
                }
                setState(() {
                  _errorMessage = null;
                  _currentStep = 1;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.heroOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Text('Continue to Workspace', style: TextStyle(fontWeight: FontWeight.w700)),
              label: const Icon(Icons.arrow_forward_rounded, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1WorkspaceType() {
    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your workspace type',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Select whether this workspace is for your solo projects or for an engineering team.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildChoiceCard(
                  type: 'individual',
                  title: 'Individual Workspace',
                  subtitle: 'Private personal workspace for solo projects, testing, and debugging. No organisation setup required.',
                  badge: 'Free Tier • 50k events/mo',
                  icon: Icons.person_rounded,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildChoiceCard(
                  type: 'organization',
                  title: 'Organisation Workspace',
                  subtitle: 'For engineering teams, startups, and fleets. Supports team member invites, shared projects, and roles.',
                  badge: 'Team Tier • Multi-member',
                  icon: Icons.business_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() => _currentStep = 0),
                child: Text('Back to Profile', style: TextStyle(color: AppTheme.textMuted)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    if (_workspaceType == 'organization' && _workspaceNameController.text == 'Personal Workspace') {
                      _workspaceNameController.text = 'Engineering Team';
                      _workspaceSlugController.text = 'engineering-team';
                    }
                    _currentStep = 2;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.heroOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Text('Continue to Setup', style: TextStyle(fontWeight: FontWeight.w700)),
                label: const Icon(Icons.arrow_forward_rounded, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required String type,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
  }) {
    final isSelected = _workspaceType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _workspaceType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.heroOrange.withValues(alpha: 0.08) : AppTheme.cardSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.heroOrange : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.heroOrange.withValues(alpha: 0.2) : AppTheme.card,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: isSelected ? AppTheme.heroOrange : AppTheme.textMuted),
                ),
                Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.heroOrange),
              ],
            ),
            SizedBox(height: 12),
            Text(title, style: TextStyle(color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text(subtitle, style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4)),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.heroOrange.withValues(alpha: 0.15) : AppTheme.card,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: isSelected ? AppTheme.heroOrange : AppTheme.textSubtle,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2WorkspaceSetup() {
    final isOrg = _workspaceType == 'organization';

    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isOrg ? 'Organisation workspace setup' : 'Individual workspace setup',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            isOrg
                ? 'Configure your organisation profile and optionally invite team members.'
                : 'Configure your private personal workspace.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          SizedBox(height: 24),

          Text(
            isOrg ? 'Organisation Name' : 'Workspace Name',
            style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          TextField(
            controller: _workspaceNameController,
            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: isOrg ? 'e.g. Acme Microservices' : 'Personal Workspace',
            ),
            onChanged: (val) {
              _workspaceSlugController.text = val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
            },
          ),
          SizedBox(height: 16),

          Text('Workspace Slug', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          TextField(
            controller: _workspaceSlugController,
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted, fontFamily: 'monospace'),
            decoration: const InputDecoration(
              prefixText: 'eventdock.dev/org/',
            ),
          ),
          const SizedBox(height: 16),

          if (isOrg) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Industry / Type', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.w700)),
                      SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _industryType,
                        dropdownColor: AppTheme.cardSecondary,
                        style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                        items: const [
                          DropdownMenuItem(value: 'SaaS & Cloud Services', child: Text('SaaS & Cloud Services')),
                          DropdownMenuItem(value: 'Fintech & Banking', child: Text('Fintech & Banking')),
                          DropdownMenuItem(value: 'E-commerce & Retail', child: Text('E-commerce & Retail')),
                          DropdownMenuItem(value: 'Healthcare & Biotech', child: Text('Healthcare & Biotech')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _industryType = v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Team Size', style: TextStyle(color: AppTheme.textSubtle, fontSize: 11, fontWeight: FontWeight.w700)),
                      SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _teamSize,
                        dropdownColor: AppTheme.cardSecondary,
                        style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                        items: const [
                          DropdownMenuItem(value: '1-10 members', child: Text('1-10 members')),
                          DropdownMenuItem(value: '11-50 members', child: Text('11-50 members')),
                          DropdownMenuItem(value: '50+ members', child: Text('50+ members')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _teamSize = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Optional Team Invitations Section
            Text(
              'Invite Team Members (Optional)',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Add team members now or invite them later from Organisation settings.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _inviteEmailController,
                    style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    decoration: const InputDecoration(hintText: 'teammate@company.com'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _inviteRole,
                    dropdownColor: AppTheme.cardSecondary,
                    style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                    items: const [
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'Member', child: Text('Member')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _inviteRole = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final email = _inviteEmailController.text.trim();
                    if (email.contains('@')) {
                      setState(() {
                        _invitations.add({'email': email, 'role': _inviteRole});
                        _inviteEmailController.clear();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardSecondary,
                    foregroundColor: AppTheme.textPrimary,
                    side: BorderSide(color: AppTheme.cardBorder),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),

            if (_invitations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _invitations.map((inv) {
                  return Chip(
                    backgroundColor: AppTheme.cardSecondary,
                    side: BorderSide(color: AppTheme.cardBorder),
                    avatar: Icon(Icons.mail_outline, size: 14, color: AppTheme.heroOrange),
                    label: Text('${inv['email']} (${inv['role']})', style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                    deleteIcon: Icon(Icons.close, size: 14, color: AppTheme.textMuted),
                    onDeleted: () {
                      setState(() {
                        _invitations.remove(inv);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() => _currentStep = 1),
                child: Text('Back', style: TextStyle(color: AppTheme.textMuted)),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCompleteOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.heroOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        isOrg ? 'Create Organisation Workspace' : 'Create Individual Workspace',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Completion() {
    final currentOrg = AuthService().currentOrganization;
    final project = _initialProject;

    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.status2xx.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: AppTheme.status2xx, size: 28),
          ),
          SizedBox(height: 16),
          Text(
            'Your workspace is ready!',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            '${currentOrg.name} (${currentOrg.type == "organization" ? "Organisation" : "Individual"}) is configured with ${currentOrg.plan}.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),

          if (project != null)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.heroOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.folder_outlined, color: AppTheme.heroOrange, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('Initial starter project provisioned with 30-day retention', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.status2xx),
                ],
              ),
            ),

          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: () {
              AuthService().completeOnboarding();
              if (project != null) {
                widget.onComplete(project);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.heroOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Text('Go to Dashboard', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            label: const Icon(Icons.arrow_forward_rounded, size: 16),
          ),
        ],
      ),
    );
  }
}