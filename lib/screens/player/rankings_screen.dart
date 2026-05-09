import 'package:flutter/material.dart';

import '../../models/player_models.dart';
import '../../services/supabase_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

enum _RankingCategory { runs, average, strikeRate, wickets, rating }

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  _RankingCategory _category = _RankingCategory.runs;
  List<PlayerRanking> _players = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rankings = await SupabaseService.fetchPlayerRankings();
      if (!mounted) return;
      setState(() {
        _players = rankings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load rankings.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final currentUserName = store.userName;
    final sorted = _sortByCategory(_players, _category);
    final top3 = sorted.take(3).toList();

    return Scaffold(
      backgroundColor: C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: C.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: C.dark,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HeaderCard(
                      currentUserName: currentUserName,
                      totalPlayers: _players.length,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Category chips ───────────────────────────────────
          if (!_isLoading && _error == null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _CategoryChips(
                  selected: _category,
                  onSelected: (c) => setState(() => _category = c),
                ),
              ),
            ),

          // ── Loading ──────────────────────────────────────────
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(color: C.g2),
                ),
              ),
            ),

          // ── Error ────────────────────────────────────────────
          if (_error != null && !_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: C.grey, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: C.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _load,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.g2,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // ── Empty ──────────────────────────────────────────────
          if (!_isLoading && _error == null && _players.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 80, 24, 0),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, color: C.hint, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'No players found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: C.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // ── Top 3 podium ─────────────────────────────────────
          if (top3.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _Podium(top3: top3, category: _category),
              ),
            ),

          // ── List header ──────────────────────────────────────
          if (!_isLoading && _error == null && _players.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                child: Row(
                  children: [
                    const Text(
                      'All Rankings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: C.dark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _categoryLabel(_category),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: C.g2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Player list ──────────────────────────────────────
          if (!_isLoading && _error == null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final player = sorted[i];
                  final rank = i + 1;
                  final isMe = player.name.trim().toLowerCase() ==
                      currentUserName.trim().toLowerCase();
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16, 0, 16, i == sorted.length - 1 ? 28 : 8),
                    child: _PlayerListTile(
                      rank: rank,
                      player: player,
                      category: _category,
                      isMe: isMe,
                    ),
                  );
                },
                childCount: sorted.length,
              ),
            ),
        ],
      ),
    );
  }

  List<PlayerRanking> _sortByCategory(
    List<PlayerRanking> list,
    _RankingCategory cat,
  ) {
    final copy = List<PlayerRanking>.from(list);
    switch (cat) {
      case _RankingCategory.runs:
        copy.sort((a, b) => b.runs.compareTo(a.runs));
      case _RankingCategory.average:
        copy.sort((a, b) => b.average.compareTo(a.average));
      case _RankingCategory.strikeRate:
        copy.sort((a, b) => b.strikeRate.compareTo(a.strikeRate));
      case _RankingCategory.wickets:
        copy.sort((a, b) => b.wickets.compareTo(a.wickets));
      case _RankingCategory.rating:
        copy.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return copy;
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final t = name.trim();
    if (t.length >= 2) return t.substring(0, 2).toUpperCase();
    return t.isEmpty ? '?' : t[0].toUpperCase();
  }

  static String _categoryLabel(_RankingCategory cat) {
    switch (cat) {
      case _RankingCategory.runs:
        return 'Runs';
      case _RankingCategory.average:
        return 'Average';
      case _RankingCategory.strikeRate:
        return 'Strike Rate';
      case _RankingCategory.wickets:
        return 'Wickets';
      case _RankingCategory.rating:
        return 'Rating';
    }
  }
}

// ── Header card ─────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final String currentUserName;
  final int totalPlayers;
  const _HeaderCard({
    required this.currentUserName,
    required this.totalPlayers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withAlpha(70),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Player Rankings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalPlayers players ranked',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentUserName.isEmpty
                        ? 'Sign in to see your rank'
                        : 'Signed in as $currentUserName',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category chips ──────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final _RankingCategory selected;
  final ValueChanged<_RankingCategory> onSelected;
  const _CategoryChips({required this.selected, required this.onSelected});

  static const _items = [
    (_RankingCategory.runs, 'Runs'),
    (_RankingCategory.average, 'Avg'),
    (_RankingCategory.strikeRate, 'SR'),
    (_RankingCategory.wickets, 'Wkts'),
    (_RankingCategory.rating, 'Rating'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _items.map((item) {
          final isSelected = selected == item.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? C.g1 : C.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? C.white : C.dark,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Podium (top 3) ────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<PlayerRanking> top3;
  final _RankingCategory category;
  const _Podium({required this.top3, required this.category});

  String _value(PlayerRanking p) {
    switch (category) {
      case _RankingCategory.runs:
        return '${p.runs}';
      case _RankingCategory.average:
        return p.average.toStringAsFixed(1);
      case _RankingCategory.strikeRate:
        return p.strikeRate.toStringAsFixed(1);
      case _RankingCategory.wickets:
        return '${p.wickets}';
      case _RankingCategory.rating:
        return p.rating.toStringAsFixed(1);
    }
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // gold
      case 2:
        return const Color(0xFFC0C0C0); // silver
      case 3:
        return const Color(0xFFCD7F32); // bronze
      default:
        return C.g2;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Order visually: 2nd, 1st, 3rd
    final order = <int>[];
    if (top3.length >= 2) order.add(1);
    if (top3.isNotEmpty) order.add(0);
    if (top3.length >= 3) order.add(2);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: order.map((idx) {
        final player = top3[idx];
        final rank = idx + 1;
        final isFirst = rank == 1;
        return Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 0.92,
              child: Transform.scale(
                scale: isFirst ? 1.0 : 0.95,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                  decoration: BoxDecoration(
                    color: C.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rank badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _rankColor(rank).withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _rankColor(rank),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: C.gLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _rankColor(rank).withAlpha(80),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            player.initials,
                            style: const TextStyle(
                              color: C.g2,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        player.name.split(' ').first,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: C.dark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        player.teamName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: C.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _value(player),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _rankColor(rank),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Player list tile ──────────────────────────────────────

class _PlayerListTile extends StatelessWidget {
  final int rank;
  final PlayerRanking player;
  final _RankingCategory category;
  final bool isMe;
  const _PlayerListTile({
    required this.rank,
    required this.player,
    required this.category,
    required this.isMe,
  });

  String _value() {
    switch (category) {
      case _RankingCategory.runs:
        return '${player.runs}';
      case _RankingCategory.average:
        return player.average.toStringAsFixed(1);
      case _RankingCategory.strikeRate:
        return player.strikeRate.toStringAsFixed(1);
      case _RankingCategory.wickets:
        return '${player.wickets}';
      case _RankingCategory.rating:
        return player.rating.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFE8F5E9) : C.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isMe
            ? Border.all(color: C.g2.withAlpha(80), width: 1.2)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: C.grey,
              ),
            ),
          ),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: C.gLight,
              shape: BoxShape.circle,
              border: Border.all(color: C.g2.withAlpha(50), width: 1.2),
            ),
            child: Center(
              child: Text(
                player.initials,
                style: const TextStyle(
                  color: C.g2,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + team
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isMe ? C.g1 : C.dark,
                        ),
                      ),
                    ),
                    if (isMe)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: C.g2.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: C.g2,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.teamName} • ${player.matches} matches',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: C.grey,
                  ),
                ),
              ],
            ),
          ),
          // Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _value(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: C.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _unitLabel(),
                style: const TextStyle(
                  fontSize: 10,
                  color: C.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _unitLabel() {
    switch (category) {
      case _RankingCategory.runs:
        return 'runs';
      case _RankingCategory.average:
        return 'avg';
      case _RankingCategory.strikeRate:
        return 'SR';
      case _RankingCategory.wickets:
        return 'wkts';
      case _RankingCategory.rating:
        return 'pts';
    }
  }
}
