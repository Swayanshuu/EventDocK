import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/api_key.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ApiKeysView extends StatefulWidget {
  final Project project;

  const ApiKeysView({super.key, required this.project});

  @override
  State<ApiKeysView> createState() => _ApiKeysViewState();
}

class _ApiKeysViewState extends State<ApiKeysView> {
  List<ApiKeySummary> _keys = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchKeys();
  }

  Future<void> _fetchKeys() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ApiService().getApiKeys(widget.project.id);
      setState(() {
        _keys = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showGenerateKeyDialog() {
    final nameCtrl = TextEditingController(text: 'Application Ingestion Key');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate API Key'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This key will allow your Spring Boot application (eventdock-starter) to securely deliver diagnostic events to EventDock.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Key Description / Name',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.heroOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                final generated = await ApiService().createApiKey(
                  widget.project.id,
                  nameCtrl.text.trim(),
                );
                if (!mounted) return;
                _fetchKeys();
                _showKeyCreatedDialog(generated.rawKey);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              }
            },
            child: const Text('Generate Key'),
          ),
        ],
      ),
    );
  }

  void _showKeyCreatedDialog(String rawKey) {
    final ymlSnippet =
        'eventdock:\n'
        '  enabled: true\n'
        '  api-key: "$rawKey"\n'
        '  service-name: "${widget.project.slug}"\n'
        '  endpoint: "${ApiService().baseUrl.replaceAll('/api/v1', '')}"';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.status2xx),
            const SizedBox(width: 8),
            const Text('Real Ingestion Key Generated'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copy your key now. For security purposes, EventDock stores a SHA-256 hash in PostgreSQL and cannot reveal this secret again.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
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
                          color: AppTheme.heroOrange,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        size: 16,
                        color: AppTheme.heroOrange,
                      ),
                      tooltip: 'Copy Raw Key',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: rawKey));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied API Key to clipboard!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Spring Boot application.yml Configuration:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: ymlSnippet));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Copied application.yml config to clipboard!',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 13),
                    label: const Text(
                      'Copy YAML',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
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
                  ymlSnippet,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.heroOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I have stored this key securely'),
          ),
        ],
      ),
    );
  }

  void _revokeKey(ApiKeySummary key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke API Key?'),
        content: Text(
          'Are you sure you want to revoke "${key.name}"? Ingestion requests using this key will immediately fail.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.status5xx,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().revokeApiKey(widget.project.id, key.id);
                if (!mounted) return;
                _fetchKeys();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              }
            },
            child: const Text('Revoke Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 750;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API Keys',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage credentials for eventdock-starter ingestion in ${widget.project.name}',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showGenerateKeyDialog,
                    icon: const Icon(Icons.key, size: 16),
                    label: const Text('Generate New Key'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.heroOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                        'API Keys',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage credentials for eventdock-starter ingestion in ${widget.project.name}',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showGenerateKeyDialog,
                  icon: const Icon(Icons.key, size: 16),
                  label: const Text('Generate New Key'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.heroOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.status5xx),
                    ),
                  )
                : _keys.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.vpn_key_outlined,
                          size: 50,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No API keys generated yet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Generate a key to connect your Spring Boot application',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showGenerateKeyDialog,
                          child: const Text('Generate Key'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _keys.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final k = _keys[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: k.revoked
                                    ? AppTheme.status5xx.withValues(alpha: 0.12)
                                    : AppTheme.status2xx.withValues(
                                        alpha: 0.12,
                                      ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.key_rounded,
                                size: 18,
                                color: k.revoked
                                    ? AppTheme.status5xx
                                    : AppTheme.status2xx,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        k.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: k.revoked
                                              ? AppTheme.status5xx.withValues(
                                                  alpha: 0.2,
                                                )
                                              : AppTheme.status2xx.withValues(
                                                  alpha: 0.2,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          k.revoked ? 'REVOKED' : 'ACTIVE',
                                          style: TextStyle(
                                            color: k.revoked
                                                ? AppTheme.status5xx
                                                : AppTheme.status2xx,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Prefix: ${k.keyPrefix}••••••••  •  Created: ${k.createdAt.split('T').first}',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!k.revoked)
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.status5xx,
                                ),
                                onPressed: () => _revokeKey(k),
                                child: const Text('Revoke'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}