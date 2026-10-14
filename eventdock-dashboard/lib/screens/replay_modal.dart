import 'package:flutter/material.dart';
import '../models/diagnostic_event.dart';
import '../models/replay_attempt.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ReplayModal extends StatefulWidget {
  final DiagnosticEventDetail event;

  const ReplayModal({super.key, required this.event});

  @override
  State<ReplayModal> createState() => _ReplayModalState();
}

class _ReplayModalState extends State<ReplayModal> {
  final _targetUrlController = TextEditingController(text: 'http://localhost:8081');
  bool _confirmUnsafe = false;
  bool _isExecuting = false;
  ReplayAttempt? _latestResult;
  String? _errorMessage;

  List<ReplayAttempt> _history = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final list = await ApiService().getReplays(widget.event.id);
      if (mounted) {
        setState(() {
          _history = list;
          _loadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _triggerReplay() async {
    setState(() {
      _isExecuting = true;
      _errorMessage = null;
      _latestResult = null;
    });

    try {
      final result = await ApiService().executeReplay(
        widget.event.id,
        _targetUrlController.text.trim(),
        _confirmUnsafe,
      );
      setState(() {
        _latestResult = result;
        _history.insert(0, result);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 700;
    final isUnsafeMethod = {'POST', 'PUT', 'DELETE', 'PATCH'}.contains(widget.event.httpMethod.toUpperCase());

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 16 : 24,
      ),
      child: Container(
        width: isMobile ? screenSize.width * 0.95 : 780,
        height: isMobile ? screenSize.height * 0.92 : 700,
        padding: EdgeInsets.all(isMobile ? 18 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.replay_rounded, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Replay Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        'Reproduce request safely against local or staging environment',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: isMobile ? 11 : 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.cardBorder),
            const SizedBox(height: 16),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target details
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          MethodBadge(method: widget.event.httpMethod),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.event.requestUri,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Destination URL field
                    TextField(
                      controller: _targetUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Destination Base URL',
                        hintText: 'e.g. http://localhost:8081 or http://127.0.0.1:8081',
                        prefixIcon: Icon(Icons.link_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SSRF protection enforced. Only approved local/staging destinations are permitted.',
                      style: TextStyle(color: AppTheme.textMuted.withOpacity(0.8), fontSize: 11),
                    ),
                    const SizedBox(height: 16),

                    // State-changing method warning
                    if (isUnsafeMethod) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.status4xx.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.status4xx.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.status4xx),
                                const SizedBox(width: 8),
                                Text(
                                  'State-changing HTTP ${widget.event.httpMethod}',
                                  style: const TextStyle(color: AppTheme.status4xx, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Replaying this request may alter records or trigger side effects on the destination server.',
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              activeColor: AppTheme.primary,
                              title: const Text('I confirm executing this state-changing replay', style: TextStyle(fontSize: 12)),
                              value: _confirmUnsafe,
                              onChanged: (val) => setState(() => _confirmUnsafe = val ?? false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isExecuting || (isUnsafeMethod && !_confirmUnsafe) ? null : _triggerReplay,
                        icon: _isExecuting
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(_isExecuting ? 'Replaying...' : 'Execute Replay Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error callout
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.status5xx.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.status5xx.withOpacity(0.3)),
                        ),
                        child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.status5xx, fontSize: 13)),
                      ),

                    // Latest Replay Result
                    if (_latestResult != null) ...[
                      const Text('LATEST REPLAY RESULT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.codeBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (_latestResult!.responseStatus != null)
                                  StatusBadge(statusCode: _latestResult!.responseStatus!),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _latestResult!.outcome == 'SUCCESS'
                                        ? AppTheme.status2xx.withOpacity(0.2)
                                        : AppTheme.status5xx.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _latestResult!.outcome,
                                    style: TextStyle(
                                      color: _latestResult!.outcome == 'SUCCESS' ? AppTheme.status2xx : AppTheme.status5xx,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text('${_latestResult!.durationMs ?? 0} ms', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                            if (_latestResult!.safeErrorSummary != null) ...[
                              const SizedBox(height: 8),
                              Text('Error: ${_latestResult!.safeErrorSummary!}', style: const TextStyle(color: AppTheme.status4xx, fontSize: 12)),
                            ],
                            if (_latestResult!.responseSnippet != null) ...[
                              const SizedBox(height: 10),
                              const Text('Response:', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                              const SizedBox(height: 4),
                              SelectableText(
                                _latestResult!.responseSnippet!,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.textPrimary),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Replay History
                    const Text('PREVIOUS REPLAY ATTEMPTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    if (_loadingHistory)
                      const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                    else if (_history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No replay attempts recorded for this event yet.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _history.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final h = _history[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardSecondary,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Row(
                              children: [
                                if (h.responseStatus != null)
                                  StatusBadge(statusCode: h.responseStatus!)
                                else
                                  const StatusBadge(statusCode: 0),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    h.destinationUrl,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${h.durationMs ?? 0}ms • ${h.outcome}',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
