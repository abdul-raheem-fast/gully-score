import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  int _filter = 0; // 0=All, 1=Open, 2=Resolved

  final _items = <_ReportItem>[
    _ReportItem(
      id: 'RPT-247',
      title: 'Match flagged for review',
      subtitle: 'SS vs GW — suspicious extras count',
      severity: _Severity.high,
      status: _Status.open,
      timeAgo: '3h ago',
    ),
    _ReportItem(
      id: 'RPT-251',
      title: 'User misconduct',
      subtitle: 'Umpire report on player behavior',
      severity: _Severity.medium,
      status: _Status.open,
      timeAgo: '6h ago',
    ),
    _ReportItem(
      id: 'RPT-232',
      title: 'Duplicate team created',
      subtitle: 'Two teams with same name “Street Stars”',
      severity: _Severity.low,
      status: _Status.resolved,
      timeAgo: '2d ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final flaggedMatches = store.matches.where((m) => m.flagged).toList();
    final filtered = _items.where((e) {
      if (_filter == 1) return e.status == _Status.open;
      if (_filter == 2) return e.status == _Status.resolved;
      return true;
    }).toList();

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
          if (flaggedMatches.isNotEmpty) ...[
            Text('Flagged matches', style: TextStyle(fontSize: 16, color: C.adminBlue, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...flaggedMatches.map((match) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${match.teamA} vs ${match.teamB}', style: const TextStyle(fontWeight: FontWeight.w600))),
                  const Icon(Icons.flag, color: Colors.red, size: 18),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],
          _filters(),
          const SizedBox(height: 12),
          ...filtered.map(_card),
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
                onPressed: () {},
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

