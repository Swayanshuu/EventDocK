import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/diagnostic_event.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'replay_modal.dart';

class EventDetailModal extends StatefulWidget {
  final String eventId;

  const EventDetailModal({super.key, required this.eventId});

  @override
  State<EventDetailModal> createState() => _EventDetailModalState();
}

class _EventDetailModalState extends State<EventDetailModal> {
  DiagnosticEventDetail? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await ApiService().getEventDetail(widget.eventId);
      setState(() {
        _detail = detail;
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

  void _openReplayModal() {
    if (_detail == null) return;
    showDialog(
      context: context,
      builder: (ctx) => ReplayModal(event: _detail!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 700;

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
        width: isMobile ? screenSize.width * 0.95 : 900,
        height: isMobile ? screenSize.height * 0.92 : 750,
        padding: EdgeInsets.all(isMobile ? 16 : 28),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.status5xx),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: AppTheme.status5xx)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchDetail, child: const Text('Retry')),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      if (isMobile) ...[
                        Row(
                          children: [
                            StatusBadge(statusCode: _detail!.statusCode),
                            const SizedBox(width: 8),
                            MethodBadge(method: _detail!.httpMethod),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppTheme.textMuted),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _detail!.requestUri,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openReplayModal,
                            icon: const Icon(Icons.replay_rounded, size: 16),
                            label: const Text('Replay Request'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            StatusBadge(statusCode: _detail!.statusCode),
                            const SizedBox(width: 10),
                            MethodBadge(method: _detail!.httpMethod),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _detail!.requestUri,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _openReplayModal,
                              icon: const Icon(Icons.replay_rounded, size: 16),
                              label: const Text('Replay Request'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppTheme.textMuted),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Correlation ID & Meta Row
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Request ID: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                      Expanded(
                                        child: SelectableText(
                                          _detail!.requestId,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppTheme.primary,
                                          ),
                                          maxLines: 1,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.textMuted),
                                        tooltip: 'Copy Request ID',
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: _detail!.requestId));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Request ID copied!'), duration: Duration(seconds: 1)),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_detail!.durationMs ?? 0} ms • ${_detail!.serviceName ?? "app"} • ${_detail!.occurredAt}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const Text('Request ID: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                  SelectableText(
                                    _detail!.requestId,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.textMuted),
                                    tooltip: 'Copy Request ID',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: _detail!.requestId));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Request ID copied!'), duration: Duration(seconds: 1)),
                                      );
                                    },
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Duration: ${_detail!.durationMs ?? 0} ms  •  Service: ${_detail!.serviceName ?? "app"}  •  ${_detail!.occurredAt}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Scrollable Details
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Error Callout
                              if (_detail!.errorType != null)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.status5xx.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.status5xx.withValues(alpha: 0.25)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _detail!.errorType!,
                                        style: const TextStyle(
                                          color: AppTheme.status5xx,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _detail!.sanitizedErrorMessage ?? 'No message provided',
                                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),

                              // Stack Trace
                              const Text('SANITIZED STACK TRACE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              CodeSnippetBox(
                                content: _detail!.stackTrace ?? '(No stack trace captured for this failure)',
                                label: 'Java Stack Trace',
                              ),
                              const SizedBox(height: 20),

                              // Request Headers & Metadata
                              const Text('REQUEST METADATA & HEADERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              CodeSnippetBox(
                                content: _detail!.metadataJson ?? '{}',
                                label: 'Headers & Query Params (Sensitive keys redacted)',
                              ),

                              if (_detail!.requestBody != null) ...[
                                const SizedBox(height: 20),
                                const Text('CAPTURED REQUEST BODY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                                const SizedBox(height: 8),
                                CodeSnippetBox(
                                  content: _detail!.requestBody!,
                                  label: 'Redacted JSON Body',
                                ),
                              ],
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
