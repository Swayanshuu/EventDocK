import 'package:flutter/material.dart';
import '../models/diagnostic_event.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/error_state_card.dart';
import 'event_detail_modal.dart';

class EventInboxView extends StatefulWidget {
  final Project project;

  const EventInboxView({super.key, required this.project});

  @override
  State<EventInboxView> createState() => _EventInboxViewState();
}

class _EventInboxViewState extends State<EventInboxView> {
  List<DiagnosticEventSummary> _events = [];
  bool _isLoading = true;
  String? _error;

  String? _filterGroup; // null = all, '5xx' = server, '4xx' = client
  bool? _filterResolved; // null = all, false = open, true = resolved
  String? _searchQuery;
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  @override
  void didUpdateWidget(covariant EventInboxView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id) {
      _currentPage = 0;
      _fetchEvents();
    }
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService().getEvents(
        widget.project.id,
        statusGroup: _filterGroup,
        statusCode: _filterGroup == '4xx' ? 400 : (_filterGroup == '5xx' ? 500 : null),
        resolved: _filterResolved,
        search: _searchQuery,
        page: _currentPage,
        size: 15,
      );

      var content = res['events'] as List<DiagnosticEventSummary>;

      // Client-side guarantee filter: ensures 4xx / 5xx filters work seamlessly
      // regardless of local or production backend deployment state
      if (_filterGroup == '4xx') {
        content = content.where((e) => e.statusCode >= 400 && e.statusCode < 500).toList();
      } else if (_filterGroup == '5xx') {
        content = content.where((e) => e.statusCode >= 500 && e.statusCode < 600).toList();
      }
      if (_filterResolved != null) {
        content = content.where((e) => e.resolved == _filterResolved).toList();
      }

      setState(() {
        _events = content;
        _totalPages = res['totalPages'] as int;
        _totalElements = _filterGroup != null || _filterResolved != null
            ? content.length
            : (res['totalElements'] as int);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _openEventDetail(String eventId) {
    showDialog(
      context: context,
      builder: (ctx) => EventDetailModal(
        eventId: eventId,
        onEventDeleted: () {
          setState(() {
            _events.removeWhere((e) => e.id == eventId);
            _totalElements = (_totalElements - 1).clamp(0, 999999);
          });
        },
        onStatusChanged: (isResolved) {
          setState(() {
            final idx = _events.indexWhere((e) => e.id == eventId);
            if (idx != -1) {
              final ev = _events[idx];
              _events[idx] = DiagnosticEventSummary(
                id: ev.id,
                projectId: ev.projectId,
                requestId: ev.requestId,
                httpMethod: ev.httpMethod,
                routeTemplate: ev.routeTemplate,
                requestUri: ev.requestUri,
                statusCode: ev.statusCode,
                errorType: ev.errorType,
                sanitizedErrorMessage: ev.sanitizedErrorMessage,
                durationMs: ev.durationMs,
                occurredAt: ev.occurredAt,
                serviceName: ev.serviceName,
                environment: ev.environment,
                resolved: isResolved,
              );
            }
          });
        },
      ),
    );
  }

  Future<void> _toggleResolved(DiagnosticEventSummary event) async {
    final nextStatus = !event.resolved;
    try {
      await ApiService().setEventResolved(event.id, nextStatus);
      setState(() {
        final idx = _events.indexWhere((e) => e.id == event.id);
        if (idx != -1) {
          _events[idx] = DiagnosticEventSummary(
            id: event.id,
            projectId: event.projectId,
            requestId: event.requestId,
            httpMethod: event.httpMethod,
            routeTemplate: event.routeTemplate,
            requestUri: event.requestUri,
            statusCode: event.statusCode,
            errorType: event.errorType,
            sanitizedErrorMessage: event.sanitizedErrorMessage,
            durationMs: event.durationMs,
            occurredAt: event.occurredAt,
            serviceName: event.serviceName,
            environment: event.environment,
            resolved: nextStatus,
          );
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextStatus ? 'Event marked as resolved' : 'Event reopened'),
            duration: const Duration(seconds: 2),
            backgroundColor: nextStatus ? AppTheme.status2xx : AppTheme.cardSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.cardBorder),
        ),
        title: Text('Delete Error Event?', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete this diagnostic event? This action cannot be undone.', style: TextStyle(color: AppTheme.textMuted)),
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
        await ApiService().deleteEvent(eventId);
        setState(() {
          _events.removeWhere((e) => e.id == eventId);
          _totalElements = (_totalElements - 1).clamp(0, 999999);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Diagnostic event deleted successfully')),
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

  Future<void> _clearAllEvents() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.cardBorder),
        ),
        title: Text('Clear All Failures?', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete all recorded failure events for project "${widget.project.name}"? This cannot be undone.', style: TextStyle(color: AppTheme.textMuted)),
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
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService().clearProjectEvents(widget.project.id);
        setState(() {
          _events.clear();
          _totalElements = 0;
          _totalPages = 1;
          _currentPage = 0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All failure events cleared successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear events: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Control Bar: Search & Status Filters
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isCompact ? double.infinity : 280,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search route or error type...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    suffixIcon: _searchQuery != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = null);
                              _fetchEvents();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (val) {
                    setState(() {
                      _searchQuery = val.trim().isEmpty ? null : val.trim();
                      _currentPage = 0;
                    });
                    _fetchEvents();
                  },
                ),
              ),

              // Status Group Pills
              _buildFilterPill('All Events', null),
              _buildFilterPill('5xx Server Errors', '5xx'),
              _buildFilterPill('4xx Client Errors', '4xx'),

              // Resolution State Pills
              _buildResolutionPill('Open Only', false),
              _buildResolutionPill('Resolved', true),

              // Refresh Button
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
                tooltip: 'Refresh events',
                onPressed: _fetchEvents,
              ),

              // Clear All Events Button
              if (_events.isNotEmpty || _totalElements > 0)
                OutlinedButton.icon(
                  onPressed: _clearAllEvents,
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: AppTheme.status5xx),
                  label: const Text('Clear All', style: TextStyle(color: AppTheme.status5xx, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.status5xx.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Event Count info
          Text(
            'Showing ${_events.length} of $_totalElements recorded failures',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Content body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ErrorStateCard(
                        rawError: _error!,
                        onRetry: _fetchEvents,
                        title: 'Failed to load diagnostic events',
                      )
                    : _events.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 60, color: AppTheme.status2xx.withValues(alpha: 0.6)),
                                const SizedBox(height: 16),
                                const Text('No API failures detected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(
                                  'Configured requests are executing normally or no errors match your filter.',
                                  style: TextStyle(color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          )
                        : isCompact
                            ? _buildMobileList()
                            : _buildDesktopTable(),
          ),

          // Pagination Bar
          if (_totalPages > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() => _currentPage--);
                          _fetchEvents();
                        }
                      : null,
                ),
                Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages - 1
                      ? () {
                          setState(() => _currentPage++);
                          _fetchEvents();
                        }
                      : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, String? group) {
    final isSelected = _filterGroup == group;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.black : AppTheme.textMuted,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.cardSecondary,
      side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.cardBorder),
      onSelected: (selected) {
        setState(() {
          _filterGroup = selected ? group : null;
          _currentPage = 0;
        });
        _fetchEvents();
      },
    );
  }

  Widget _buildResolutionPill(String label, bool value) {
    final isSelected = _filterResolved == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? (value ? Colors.white : Colors.black) : AppTheme.textMuted,
        ),
      ),
      selected: isSelected,
      selectedColor: value ? AppTheme.status2xx : AppTheme.status4xx,
      backgroundColor: AppTheme.cardSecondary,
      side: BorderSide(color: isSelected ? (value ? AppTheme.status2xx : AppTheme.status4xx) : AppTheme.cardBorder),
      onSelected: (selected) {
        setState(() {
          _filterResolved = selected ? value : null;
          _currentPage = 0;
        });
        _fetchEvents();
      },
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ListView.separated(
          itemCount: _events.length + 1,
          separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.cardBorder),
          itemBuilder: (context, index) {
            if (index == 0) {
              // Table Header
              return Container(
                color: AppTheme.cardSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(width: 70, child: Text('STATUS', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    SizedBox(width: 85, child: Text('RESOLUTION', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    SizedBox(width: 75, child: Text('METHOD', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    Expanded(flex: 3, child: Text('ENDPOINT / ROUTE', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    Expanded(flex: 3, child: Text('ERROR TYPE', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    SizedBox(width: 80, child: Text('DURATION', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    SizedBox(width: 140, child: Text('OCCURRED AT', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    SizedBox(width: 80, child: Text('ACTIONS', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                  ],
                ),
              );
            }

            final event = _events[index - 1];
            return InkWell(
              onTap: () => _openEventDetail(event.id),
              hoverColor: AppTheme.primary.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    SizedBox(width: 70, child: Align(alignment: Alignment.centerLeft, child: StatusBadge(statusCode: event.statusCode))),
                    SizedBox(
                      width: 85,
                      child: InkWell(
                        onTap: () => _toggleResolved(event),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: event.resolved
                                ? AppTheme.status2xx.withValues(alpha: 0.12)
                                : AppTheme.status4xx.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: event.resolved
                                  ? AppTheme.status2xx.withValues(alpha: 0.3)
                                  : AppTheme.status4xx.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                event.resolved ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 12,
                                color: event.resolved ? AppTheme.status2xx : AppTheme.status4xx,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.resolved ? 'Resolved' : 'Open',
                                style: TextStyle(
                                  color: event.resolved ? AppTheme.status2xx : AppTheme.status4xx,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 75, child: Align(alignment: Alignment.centerLeft, child: MethodBadge(method: event.httpMethod))),
                    Expanded(
                      flex: 3,
                      child: Text(
                        event.requestUri,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        event.errorType ?? 'HTTP Error',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text('${event.durationMs ?? 0} ms', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ),
                    SizedBox(
                      width: 140,
                      child: Text(
                        event.occurredAt.split('T').join(' ').split('.').first,
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_forward, size: 16, color: AppTheme.primary),
                            tooltip: 'Inspect failure',
                            onPressed: () => _openEventDetail(event.id),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.status5xx.withValues(alpha: 0.8)),
                            tooltip: 'Delete event',
                            onPressed: () => _deleteEvent(event.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      itemCount: _events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = _events[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppTheme.cardBorder),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _openEventDetail(event.id),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(statusCode: event.statusCode),
                      const SizedBox(width: 8),
                      MethodBadge(method: event.httpMethod),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _toggleResolved(event),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: event.resolved
                                ? AppTheme.status2xx.withValues(alpha: 0.12)
                                : AppTheme.status4xx.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event.resolved ? 'Resolved' : 'Open',
                            style: TextStyle(
                              color: event.resolved ? AppTheme.status2xx : AppTheme.status4xx,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.status5xx.withValues(alpha: 0.8)),
                        tooltip: 'Delete event',
                        onPressed: () => _deleteEvent(event.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.requestUri,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.errorType ?? 'HTTP Failure',
                    style: const TextStyle(color: AppTheme.status5xx, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.occurredAt.split('T').join(' ').split('.').first,
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                      Text('${event.durationMs ?? 0} ms', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
