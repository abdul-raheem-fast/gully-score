import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../models/player_models.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _PlayerRow {
  final nameCtrl = TextEditingController();
  String role = 'Batsman';
  void dispose() => nameCtrl.dispose();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _abbrCtrl = TextEditingController();
  final List<_PlayerRow> _playerRows = [_PlayerRow()];

  bool _creating = false;
  String? _error;
  String? _existingTeam;
  List<Map<String, dynamic>> _availablePlayers = [];
  bool _loadingPlayers = false;
  final Set<String> _invitedUserIds = {};

  @override
  void initState() {
    super.initState();
    _checkExistingTeam();
  }

  Future<void> _checkExistingTeam() async {
    final teamName = await SupabaseService.checkIfUserInTeam();
    if (!mounted) return;
    if (teamName != null) {
      setState(() => _existingTeam = teamName);
      _showConfirmDialog(teamName);
    }
    _loadAvailablePlayers();
  }

  Future<void> _loadAvailablePlayers() async {
    setState(() => _loadingPlayers = true);
    try {
      final players = await SupabaseService.fetchTeamlessPlayers();
      if (!mounted) return;
      setState(() => _availablePlayers = players);
    } catch (_) {}
    if (mounted) setState(() => _loadingPlayers = false);
  }

  void _showConfirmDialog(String teamName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Already in a Team',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'You are currently a member of "$teamName". Creating a new team will not remove you from your current team, but you will become the Captain of this new team. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back', style: TextStyle(color: C.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: C.g2,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Create New'),
          ),
        ],
      ),
    );
  }

  // Auto-derive abbreviation from team name
  void _onNameChanged(String val) {
    final words = val.trim().split(RegExp(r'\s+'));
    final initials = words
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .toList()
        .join();
    final fallback = val.trim().toUpperCase().characters.take(2).toList().join();
    _abbrCtrl.text = initials.length >= 2 ? initials : fallback;
  }

  void _addPlayerField() {
    setState(() => _playerRows.add(_PlayerRow()));
  }

  void _removePlayerField(int index) {
    setState(() {
      _playerRows[index].dispose();
      _playerRows.removeAt(index);
    });
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final captainName = SupabaseService.getCurrentUserName() ??
          SupabaseService.currentUser?.email ??
          'Captain';
      
      final roster = _playerRows
          .where((r) => r.nameCtrl.text.trim().isNotEmpty)
          .map((r) => TeamPlayerDetail(
                name: r.nameCtrl.text.trim(),
                role: r.role,
              ))
          .toList();

      // Add captain to roster if not already there
      if (!roster.any((p) => p.name == captainName)) {
        roster.insert(0, TeamPlayerDetail(name: captainName, role: 'All-rounder', isCaptain: true));
      }

      await SupabaseService.createTeam(
        name: _nameCtrl.text.trim(),
        abbreviation: _abbrCtrl.text.trim(),
        captainName: captainName,
        roster: roster,
      );

      // Send invitations to selected players
      for (final pId in _invitedUserIds) {
        final p = _availablePlayers.firstWhere((pl) => pl['id'] == pId);
        await SupabaseService.invitePlayerToTeam(
          teamName: _nameCtrl.text.trim(),
          teamAbbreviation: _abbrCtrl.text.trim(),
          targetUserId: pId,
          targetPlayerName: p['name']?.toString() ?? 'Player',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🏏 "${_nameCtrl.text.trim()}" created successfully!'),
            backgroundColor: C.g2,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true); // return true = team was created
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        setState(() {
          if (msg.contains('duplicate') || msg.contains('23505') ||
              msg.contains('unique')) {
            if (msg.contains('team_players_player_name_key')) {
              _error = 'One or more players already belong to another team.';
            } else {
              _error = 'A team with this name already exists.';
            }
          } else if (msg.contains('relation') || msg.contains('does not exist') ||
              msg.contains('42P01')) {
            _error =
                'Database tables missing.\n\nPlease run the SQL migration:\nsupabase/migrations/20260501_teams_table.sql\nin your Supabase SQL Editor.';
          } else if (msg.contains('row-level') || msg.contains('policy') ||
              msg.contains('RLS') || msg.contains('violates')) {
            _error = 'Permission denied. Make sure you are signed in.';
          } else {
            // Show the real error for debugging
            _error = 'Error: $msg';
          }
        });
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }


  @override
  void dispose() {
    _nameCtrl.dispose();
    _abbrCtrl.dispose();
    for (final r in _playerRows) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ───────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            expandedHeight: 110,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Text('Create Team',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // ── Form body ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Team Info card ──────────────────────────
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel('TEAM DETAILS'),
                          const SizedBox(height: 14),
                          // Team name
                          _Field(
                            controller: _nameCtrl,
                            label: 'Team Name',
                            hint: 'e.g. Alpha Blasters',
                            icon: Icons.emoji_flags_outlined,
                            onChanged: _onNameChanged,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Team name is required';
                              }
                              if (v.trim().length < 3) {
                                return 'Name must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          // Abbreviation
                          _Field(
                            controller: _abbrCtrl,
                            label: 'Abbreviation',
                            hint: 'e.g. AB',
                            icon: Icons.short_text_rounded,
                            maxLength: 4,
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Abbreviation is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Captain Info card ───────────────────────
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel('CAPTAIN'),
                          const SizedBox(height: 12),
                          Row(children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2E7D32),
                                    Color(0xFF1B5E20)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.star_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      SupabaseService.getCurrentUserName() ??
                                          'You',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: C.dark),
                                    ),
                                    const Text('Team Captain (that\'s you!)',
                                        style: TextStyle(
                                            fontSize: 12, color: C.grey)),
                                  ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: C.g2.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: C.g2.withAlpha(50)),
                              ),
                              child: const Text('Captain',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: C.g2)),
                            ),
                          ]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Players card ────────────────────────────
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Expanded(
                                child: _SectionLabel('PLAYERS IN TEAM')),
                            _AddPlayerButton(onTap: _addPlayerField),
                          ]),
                          const SizedBox(height: 4),
                          const Text(
                            'Add your team members and assign their roles.',
                            style: TextStyle(fontSize: 12, color: C.grey),
                          ),
                          const SizedBox(height: 14),
                          ...List.generate(_playerRows.length, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(children: [
                                Expanded(
                                  flex: 3,
                                  child: _Field(
                                    controller: _playerRows[i].nameCtrl,
                                    label: 'Player ${i + 1} Name',
                                    hint: 'e.g. Usman Shahid',
                                    icon: Icons.person_outline,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: C.gLight.withAlpha(60),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _playerRows[i].role,
                                        isExpanded: true,
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: C.g2, size: 18),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.dark),
                                        onChanged: (v) {
                                          if (v != null) setState(() => _playerRows[i].role = v);
                                        },
                                        items: ['Batsman', 'Bowler', 'All-rounder']
                                            .map((role) => DropdownMenuItem(
                                                  value: role,
                                                  child: Text(role),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_playerRows.length > 1)
                                  _RemoveButton(
                                      onTap: () => _removePlayerField(i)),
                              ]),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Error ───────────────────────────────────
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade600, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.red.shade700)),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Submit ──────────────────────────────────
                    _CreateButton(
                      loading: _creating,
                      onTap: _creating ? null : _createTeam,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small helpers ────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: child,
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: C.grey,
          letterSpacing: 1.1));
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLength,
    this.textCapitalization = TextCapitalization.words,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: C.g2, size: 20),
          filled: true,
          fillColor: C.gLight.withAlpha(60),
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.g2, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );
}

class _AddPlayerButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddPlayerButton({required this.onTap});
  @override
  State<_AddPlayerButton> createState() => _AddPlayerButtonState();
}

class _AddPlayerButtonState extends State<_AddPlayerButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _hovered ? C.g2 : C.g2.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: C.g2.withAlpha(60)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add, size: 14, color: _hovered ? C.white : C.g2),
              const SizedBox(width: 4),
              Text('Add Player',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _hovered ? C.white : C.g2)),
            ]),
          ),
        ),
      );
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RemoveButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Icon(Icons.remove_rounded,
              color: Colors.red.shade400, size: 18),
        ),
      );
}

class _CreateButton extends StatefulWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _CreateButton({required this.loading, required this.onTap});
  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: widget.onTap != null ? (_) => _c.forward() : null,
          onTapUp: widget.onTap != null
              ? (_) {
                  _c.reverse();
                  widget.onTap!();
                }
              : null,
          onTapCancel: () => _c.reverse(),
          child: ScaleTransition(
            scale: _scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _hovered && !widget.loading
                      ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                      : [const Color(0xFF2E7D32), const Color(0xFF388E3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: _hovered && !widget.loading
                    ? [
                        BoxShadow(
                            color: C.g2.withAlpha(80),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ]
                    : [],
              ),
              child: Center(
                child: widget.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sports_cricket_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('Create Team',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
}

