import 'package:flutter/material.dart';
import '../models/diagnostic_event.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
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

  int? _filterStatus;
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
        statusCode: _filterStatus,
        search: _searchQuery,
        page: _currentPage,
        size: 15,
      );

      setState(() {
        _events = res['events'] as List<DiagnosticEventSummary>;
        _totalPages = res['totalPages'] as int;
        _totalElements = res['totalElements'] as int;
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
      builder: (ctx) => EventDetailModal(eventId: eventId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 800;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Control Bar: Search & Status Filters
          if (isCompact) ...[
            SizedBox(
              height: 42,
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
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill('All Events', null),
                  const SizedBox(width: 8),
                  _buildFilterPill('5xx Errors', 500),
                  const SizedBox(width: 8),
                  _buildFilterPill('4xx Errors', 400),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
                    tooltip: 'Refresh events',
                    onPressed: _fetchEvents,
                  ),
                ],
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
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
                _buildFilterPill('All Events', null),
                _buildFilterPill('5xx Server Errors', 500),
                _buildFilterPill('4xx Client Errors', 400),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
                  tooltip: 'Refresh events',
                  onPressed: _fetchEvents,
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Event Count info
          Text(
            'Showing ${_events.length} of $_totalElements recorded failures',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Content body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 40, color: AppTheme.status5xx),
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: AppTheme.status5xx)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchEvents, child: const Text('Retry')),
                          ],
                        ),
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
                                const Text(
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
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
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

  Widget _buildFilterPill(String label, int? statusCode) {
    final isSelected = _filterStatus == statusCode;
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
          _filterStatus = selected ? statusCode : null;
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
          separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.cardBorder),
          itemBuilder: (context, index) {
            if (index == 0) {
              // Table Header
              return Container(
                color: AppTheme.cardSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: const Row(
                  children: [
                    SizedBox(width: 70, child: Text('STATUS', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    SizedBox(width: 75, child: Text('METHOD', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    Expanded(flex: 3, child: Text('ENDPOINT / ROUTE', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    Expanded(flex: 3, child: Text('ERROR TYPE', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    SizedBox(width: 80, child: Text('DURATION', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    SizedBox(width: 150, child: Text('OCCURRED AT', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                    SizedBox(width: 60, child: Text('ACTION', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
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
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text('${event.durationMs ?? 0} ms', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(
                        event.occurredAt.split('T').join(' ').split('.').first,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 16, color: AppTheme.primary),
                        tooltip: 'Inspect failure',
                        onPressed: () => _openEventDetail(event.id),
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
            side: const BorderSide(color: AppTheme.cardBorder),
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
                      const Spacer(),
                      Text('${event.durationMs ?? 0} ms', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
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
                  Text(
                    event.occurredAt.split('T').join(' ').split('.').first,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
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
