import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/diagnostic_event.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'replay_modal.dart';

class EventDetailModal extends StatefulWidget {
  final String eventId;
  final VoidCallback? onEventDeleted;
  final ValueChanged<bool>? onStatusChanged;

  const EventDetailModal({
    super.key,
    required this.eventId,
    this.onEventDeleted,
    this.onStatusChanged,
  });

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

  Future<void> _toggleResolved() async {
    if (_detail == null) return;
    final nextStatus = !_detail!.resolved;
    try {
      final updated = await ApiService().setEventResolved(_detail!.id, nextStatus);
      setState(() {
        _detail = updated;
      });
      widget.onStatusChanged?.call(nextStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextStatus ? 'Marked as resolved' : 'Reopened event'),
            duration: const Duration(seconds: 2),
            backgroundColor: nextStatus ? AppTheme.status2xx : AppTheme.cardSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update resolution: $e')),
        );
      }
    }
  }

  Future<void> _deleteEvent() async {
    if (_detail == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.cardBorder),
        ),
        title: Text('Delete Error Event?', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete this diagnostic event? This cannot be undone.', style: TextStyle(color: AppTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.status5xx,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService().deleteEvent(_detail!.id);
        widget.onEventDeleted?.call();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Diagnostic event deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete event: $e')),
          );
        }
      }
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
        side: BorderSide(color: AppTheme.cardBorder),
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
                              icon: Icon(Icons.close, color: AppTheme.textMuted),
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _openReplayModal,
                              icon: const Icon(Icons.replay_rounded, size: 16),
                              label: const Text('Replay Request'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _toggleResolved,
                              icon: Icon(
                                _detail!.resolved ? Icons.radio_button_unchecked_rounded : Icons.check_circle_rounded,
                                size: 16,
                                color: _detail!.resolved ? AppTheme.status4xx : AppTheme.status2xx,
                              ),
                              label: Text(
                                _detail!.resolved ? 'Reopen' : 'Mark Resolved',
                                style: TextStyle(color: _detail!.resolved ? AppTheme.status4xx : AppTheme.status2xx),
                              ),
                            ),
                            IconButton(
                              onPressed: _deleteEvent,
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.status5xx, size: 20),
                              tooltip: 'Delete Event',
                            ),
                          ],
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
                            OutlinedButton.icon(
                              onPressed: _toggleResolved,
                              icon: Icon(
                                _detail!.resolved ? Icons.radio_button_unchecked_rounded : Icons.check_circle_rounded,
                                size: 16,
                                color: _detail!.resolved ? AppTheme.status4xx : AppTheme.status2xx,
                              ),
                              label: Text(
                                _detail!.resolved ? 'Reopen' : 'Mark Resolved',
                                style: TextStyle(
                                  color: _detail!.resolved ? AppTheme.status4xx : AppTheme.status2xx,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _detail!.resolved
                                      ? AppTheme.status4xx.withValues(alpha: 0.5)
                                      : AppTheme.status2xx.withValues(alpha: 0.5),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.status5xx),
                              tooltip: 'Delete this event',
                              onPressed: _deleteEvent,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.close, color: AppTheme.textMuted),
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
                                      Text('Request ID: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
                                        icon: Icon(Icons.copy_rounded, size: 14, color: AppTheme.textMuted),
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
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Text('Request ID: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
                                    icon: Icon(Icons.copy_rounded, size: 14, color: AppTheme.textMuted),
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
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
                                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
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