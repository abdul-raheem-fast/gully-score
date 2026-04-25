import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../services/supabase_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  int _filter = 0; // 0=All, 1=Open, 2=Resolved
  Future<_BackendReportMetrics>? _metricsFuture;
  late Future<List<_ReportItem>> _reportsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _metricsFuture ??= _loadMetrics(AppStore.of(context).matches);
    _reportsFuture = _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: C.adminBlue,
        foregroundColor: C.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<_BackendReportMetrics>(
            future: _metricsFuture,
            builder: (context, snapshot) {
              final metrics = snapshot.data;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: LinearProgressIndicator(minHeight: 2),
                );
              }
              if (metrics == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: C.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _pill(
                        'Innings: ${metrics.inningsCount}',
                        C.gLight,
                        C.g1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _pill(
                        'Ball Events: ${metrics.ballEventCount}',
                        const Color(0xFFE3F2FD),
                        C.adminBlue,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          _filters(),
          const SizedBox(height: 12),
          FutureBuilder<List<_ReportItem>>(
            future: _reportsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data ?? const <_ReportItem>[];
              final filtered = data.where((e) {
                if (_filter == 1) return e.status == _Status.open;
                if (_filter == 2) return e.status == _Status.resolved;
                return true;
              }).toList();
              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    'No reports found',
                    style: TextStyle(color: C.grey),
                  ),
                );
              }
              return Column(children: filtered.map(_card).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    final tabs = const ['All', 'Open', 'Resolved'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == _filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filter = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? C.adminBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? C.white : C.grey,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _card(_ReportItem r) {
    final sevColor = switch (r.severity) {
      _Severity.high => Colors.red.shade700,
      _Severity.medium => C.orange,
      _Severity.low => C.g2,
    };

    final statusColor = r.status == _Status.open ? Colors.red.shade700 : C.g2;
    final statusBg = r.status == _Status.open ? const Color(0xFFFFEBEE) : C.gLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.id, style: TextStyle(fontSize: 11, color: C.grey, fontWeight: FontWeight.w600)),
              Text(r.timeAgo, style: TextStyle(fontSize: 11, color: C.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(r.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(r.subtitle, style: TextStyle(fontSize: 12, color: C.grey)),
          const SizedBox(height: 12),
          Row(
            children: [
              _pill('Severity: ${r.severity.name.toUpperCase()}', sevColor.withOpacity(0.12), sevColor),
              const SizedBox(width: 8),
              _pill(r.status == _Status.open ? 'OPEN' : 'RESOLVED', statusBg, statusColor),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('View'),
              ),
              TextButton(
                onPressed: () async {
                  await SupabaseService.updateReportStatus(
                    reportId: r.id,
                    status: r.status == _Status.open ? 'resolved' : 'open',
                  );
                  if (!mounted) return;
                  setState(() {
                    _reportsFuture = _loadReports();
                  });
                },
                style: TextButton.styleFrom(foregroundColor: r.status == _Status.open ? C.g2 : C.grey),
                child: Text(r.status == _Status.open ? 'Resolve' : 'Resolved'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Future<_BackendReportMetrics> _loadMetrics(List<AdminMatch> matches) async {
    if (matches.isEmpty) {
      return const _BackendReportMetrics(inningsCount: 0, ballEventCount: 0);
    }
    final innings = await SupabaseService.fetchInnings(matches.first.id);
    var eventsCount = 0;
    for (final row in innings) {
      final inningsId = row['id']?.toString();
      if (inningsId == null || inningsId.isEmpty) continue;
      final events = await SupabaseService.fetchBallEvents(inningsId);
      eventsCount += events.length;
    }
    return _BackendReportMetrics(
      inningsCount: innings.length,
      ballEventCount: eventsCount,
    );
  }

  Future<List<_ReportItem>> _loadReports() async {
    final rows = await SupabaseService.fetchReports();
    return rows.map((row) {
      final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
      return _ReportItem(
        id: row['id']?.toString() ?? 'N/A',
        title: (row['title'] as String?) ?? 'Report',
        subtitle: (row['description'] as String?) ?? '',
        severity: _severityFromDb((row['severity'] as String?) ?? 'medium'),
        status: _statusFromDb((row['status'] as String?) ?? 'open'),
        timeAgo: _timeAgo(createdAt),
      );
    }).toList();
  }

  _Severity _severityFromDb(String value) {
    switch (value) {
      case 'high':
        return _Severity.high;
      case 'low':
        return _Severity.low;
      default:
        return _Severity.medium;
    }
  }

  _Status _statusFromDb(String value) {
    if (value == 'resolved') return _Status.resolved;
    return _Status.open;
  }

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'now';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'now';
  }
}

enum _Severity { low, medium, high }

enum _Status { open, resolved }

class _ReportItem {
  final String id;
  final String title;
  final String subtitle;
  final _Severity severity;
  final _Status status;
  final String timeAgo;

  const _ReportItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.status,
    required this.timeAgo,
  });
}

class _BackendReportMetrics {
  final int inningsCount;
  final int ballEventCount;

  const _BackendReportMetrics({
    required this.inningsCount,
    required this.ballEventCount,
  });
}

