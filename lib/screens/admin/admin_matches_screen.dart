import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

/// Match management screen for admin.
class AdminMatchesScreen extends StatelessWidget {
  const AdminMatchesScreen({super.key});

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _monthName(int m) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m];
  }

  Color _statusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.live:
        return Colors.red.shade600;
      case MatchStatus.upcoming:
        return Colors.orange.shade700;
      case MatchStatus.completed:
        return Colors.green.shade600;
    }
  }

  String _statusLabel(MatchStatus status) {
    switch (status) {
      case MatchStatus.live:
        return 'Live';
      case MatchStatus.upcoming:
        return 'Upcoming';
      case MatchStatus.completed:
        return 'Completed';
    }
  }

  List<AdminMatch> _filterMatches(List<AdminMatch> all, MatchStatus? status) {
    if (status == null) return all;
    return all.where((m) => m.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final matches = store.matches;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(
          title: const Text('Matches'),
          backgroundColor: C.adminBlue,
          foregroundColor: C.white,
          bottom: TabBar(
            indicatorColor: C.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Live'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _matchList(context, matches, null),
            _matchList(context, matches, MatchStatus.live),
            _matchList(context, matches, MatchStatus.upcoming),
            _matchList(context, matches, MatchStatus.completed),
          ],
        ),
      ),
    );
  }

  Widget _matchList(BuildContext context, List<AdminMatch> allMatches, MatchStatus? filter) {
    final matches = _filterMatches(allMatches, filter);
    if (matches.isEmpty) {
      return Center(
        child: Text(
          'No matches found',
          style: TextStyle(color: C.grey, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final match = matches[index];
        return _matchCard(context, match);
      },
    );
  }

  Widget _matchCard(BuildContext context, AdminMatch match) {
    return Container(
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${match.teamA} vs ${match.teamB}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(match.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel(match.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(match.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Score: ${match.scoreA} vs ${match.scoreB}', style: TextStyle(color: C.g1, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: C.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(match.venue, style: TextStyle(color: C.grey, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: C.grey),
              const SizedBox(width: 6),
              Text(_formatDate(match.date), style: TextStyle(color: C.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit action not implemented yet')),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.adminBlue,
                    side: const BorderSide(color: C.adminBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Flag action not implemented yet')),
                    );
                  },
                  icon: const Icon(Icons.flag, size: 18),
                  label: const Text('Flag'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.orange,
                    side: BorderSide(color: C.orange.withOpacity(0.6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
