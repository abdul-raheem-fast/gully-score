import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

/// Team management screen for admin.
class AdminTeamsScreen extends StatefulWidget {
  const AdminTeamsScreen({super.key});

  @override
  State<AdminTeamsScreen> createState() => _AdminTeamsScreenState();
}

class _AdminTeamsScreenState extends State<AdminTeamsScreen> {
  String _query = '';

  List<AdminTeam> _filterTeams(List<AdminTeam> teams) {
    if (_query.isEmpty) return teams;
    final q = _query.toLowerCase();
    return teams.where((team) {
      return team.name.toLowerCase().contains(q) || team.abbreviation.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final teams = _filterTeams(store.teams);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Teams'),
        backgroundColor: C.adminBlue,
        foregroundColor: C.white,
        actions: [
          IconButton(
            onPressed: () async {
              await store.refreshTeams();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Teams refreshed')),
              );
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh from backend',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search teams',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (store.isLoadingTeams) const LinearProgressIndicator(minHeight: 2),
          if (store.teamsLoadError != null)
            Container(
              width: double.infinity,
              color: Colors.orange.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                store.teamsLoadError!,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: teams.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final team = teams[index];
                return _teamCard(context, team);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: C.adminBlue,
        foregroundColor: C.white,
        onPressed: () => _showAddPlayerDialog(context, teams),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Player'),
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context, List<AdminTeam> teams) {
    if (teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No teams available yet')),
      );
      return;
    }
    final store = AppStore.of(context);
    final nameCtrl = TextEditingController();
    String selectedTeam = teams.first.name;
    bool isCaptain = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add player to team'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedTeam,
                    items: teams
                        .map(
                          (team) => DropdownMenuItem(
                            value: team.name,
                            child: Text(team.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedTeam = value);
                    },
                    decoration: const InputDecoration(labelText: 'Team'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Player name'),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    value: isCaptain,
                    onChanged: (value) =>
                        setDialogState(() => isCaptain = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Set as captain'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await store.addPlayerToTeam(
                      teamName: selectedTeam,
                      playerName: nameCtrl.text,
                      isCaptain: isCaptain,
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Player synced with backend'),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _teamCard(BuildContext context, AdminTeam team) {
    final gradient = LinearGradient(
      colors: [C.g2.withOpacity(0.9), C.g1.withOpacity(0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Open details for ${team.name}')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: C.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  team.abbreviation,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Captain: ${team.captain}', style: TextStyle(color: C.grey, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statChip('${team.playerCount}', 'Players'),
                      const SizedBox(width: 8),
                      _statChip('${team.matchCount}', 'Matches'),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: C.grey),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: C.gLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$value $label',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.g1),
      ),
    );
  }
}
