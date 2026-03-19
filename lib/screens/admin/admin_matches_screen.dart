import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

/// Match management screen for admin.
class AdminMatchesScreen extends StatefulWidget {
  const AdminMatchesScreen({super.key});

  @override
  State<AdminMatchesScreen> createState() => _AdminMatchesScreenState();
}

class _AdminMatchesScreenState extends State<AdminMatchesScreen> {

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

  void _showEditMatchDialog(BuildContext context, AdminMatch match) {
    final store = AppStore.of(context);
    final teamACtrl = TextEditingController(text: match.teamA);
    final teamBCtrl = TextEditingController(text: match.teamB);
    final scoreACtrl = TextEditingController(text: match.scoreA);
    final scoreBCtrl = TextEditingController(text: match.scoreB);
    final venueCtrl = TextEditingController(text: match.venue);
    MatchStatus selectedStatus = match.status;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Match'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: teamACtrl, decoration: const InputDecoration(labelText: 'Team A')),
                TextField(controller: teamBCtrl, decoration: const InputDecoration(labelText: 'Team B')),
                TextField(controller: scoreACtrl, decoration: const InputDecoration(labelText: 'Score A')),
                TextField(controller: scoreBCtrl, decoration: const InputDecoration(labelText: 'Score B')),
                TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: 'Venue')),
                DropdownButtonFormField<MatchStatus>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: MatchStatus.values.map((status) {
                    return DropdownMenuItem(value: status, child: Text(_statusLabel(status)));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedStatus = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final newTeamA = teamACtrl.text.trim();
                final newTeamB = teamBCtrl.text.trim();
                final newScoreA = scoreACtrl.text.trim();
                final newScoreB = scoreBCtrl.text.trim();
                final newVenue = venueCtrl.text.trim();

                if (newTeamA.isEmpty || newTeamB.isEmpty || newVenue.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Team names and venue cannot be empty')),
                  );
                  return;
                }

                final updated = match.copyWith(
                  teamA: newTeamA,
                  teamB: newTeamB,
                  scoreA: newScoreA,
                  scoreB: newScoreB,
                  venue: newVenue,
                  status: selectedStatus,
                );

                store.updateMatch(updated);

                final existingTeamA = store.teams.where((t) => t.name == match.teamA).toList();
                if (existingTeamA.isNotEmpty && existingTeamA.first.name != newTeamA) {
                  store.updateTeam(existingTeamA.first.copyWith(name: newTeamA, abbreviation: _getAbbreviation(newTeamA)));
                }

                final existingTeamB = store.teams.where((t) => t.name == match.teamB).toList();
                if (existingTeamB.isNotEmpty && existingTeamB.first.name != newTeamB) {
                  store.updateTeam(existingTeamB.first.copyWith(name: newTeamB, abbreviation: _getAbbreviation(newTeamB)));
                }

                Navigator.of(context).pop();
                setState(() {}); // Force rebuild after edit
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Match updated successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _getAbbreviation(String teamName) {
    final words = teamName.split(' ').where((element) => element.isNotEmpty).toList();
    if (words.isNotEmpty) {
      final letters = words.take(2).map((word) => word[0].toUpperCase()).join();
      return letters.length == 1 ? '${letters}A' : letters;
    }
    if (teamName.length >= 2) {
      return teamName.substring(0, 2).toUpperCase();
    }
    return teamName.toUpperCase();
  }

  void _showFlagMatchDialog(BuildContext context, AdminMatch match) {
    final store = AppStore.of(context);
    final reasonCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Flag Match'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Flag match: ${match.teamA} vs ${match.teamB} for review.'),
              const SizedBox(height: 10),
              TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason (optional)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                store.flagMatch(match.id, reason: reasonCtrl.text.trim());
                Navigator.of(context).pop();
                setState(() {}); // Force rebuild after flag
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Match flagged for review')),
                );
              },
              child: const Text('Flag'),
            ),
          ],
        );
      },
    );
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
          bottom: const TabBar(
            indicatorColor: C.white,
            indicatorWeight: 3,
            tabs: [
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
      return const Center(
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
              if (match.flagged) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('FLAGGED', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text('Score: ${match.scoreA} vs ${match.scoreB}', style: const TextStyle(color: C.g1, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: C.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(match.venue, style: const TextStyle(color: C.grey, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: C.grey),
              const SizedBox(width: 6),
              Text(_formatDate(match.date), style: const TextStyle(color: C.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditMatchDialog(context, match),
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
                  onPressed: () => _showFlagMatchDialog(context, match),
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
