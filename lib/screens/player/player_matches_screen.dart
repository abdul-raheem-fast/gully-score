import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

class PlayerMatchesScreen extends StatelessWidget {
  const PlayerMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final matches = store.matches.toList();
    final isLoading = store.isLoadingMatches;
    final error = store.matchesLoadError;

    final completed = matches.where((m) => m.status == MatchStatus.completed).toList();
    final live = matches.where((m) => m.status == MatchStatus.live).toList();
    final upcoming = matches.where((m) => m.status == MatchStatus.upcoming).toList();

    return Scaffold(
      backgroundColor: C.bg,
      body: RefreshIndicator(
        color: C.g2,
        onRefresh: () => store.refreshMatches(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: C.white,
              elevation: 0,
              surfaceTintColor: C.white,
              expandedHeight: 110,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Matches',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: C.dark)),
                    Text(
                        '${matches.length} total  •  ${completed.length} completed  •  ${live.length} live',
                        style: const TextStyle(
                            fontSize: 11,
                            color: C.grey,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ),

            // Loading indicator
            if (isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),

            // Error banner
            if (error != null && !isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error,
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800))),
                    ]),
                  ),
                ),
              ),

            // Empty state
            if (!isLoading && matches.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.sports_cricket_outlined, size: 64, color: C.gLight),
                    const SizedBox(height: 16),
                    const Text('No matches yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.grey)),
                    const SizedBox(height: 6),
                    const Text('Start a new match to see it here', style: TextStyle(fontSize: 13, color: C.hint)),
                  ]),
                ),
              ),

            // Live matches
            if (live.isNotEmpty) ...[
              _sectionHeader('Live'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MatchTile(match: live[i]),
                    ),
                    childCount: live.length,
                  ),
                ),
              ),
            ],

            // Completed matches
            if (completed.isNotEmpty) ...[
              _sectionHeader('Completed'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MatchTile(match: completed[i]),
                    ),
                    childCount: completed.length,
                  ),
                ),
              ),
            ],

            // Upcoming matches
            if (upcoming.isNotEmpty) ...[
              _sectionHeader('Upcoming'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MatchTile(match: upcoming[i]),
                    ),
                    childCount: upcoming.length,
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: C.grey,
                  letterSpacing: 0.5)),
        ),
      );
}

class _MatchTile extends StatelessWidget {
  final AdminMatch match;
  const _MatchTile({required this.match});

  @override
  Widget build(BuildContext context) {
    final isCompleted = match.status == MatchStatus.completed;
    final isLive = match.status == MatchStatus.live;
    final dateStr =
        '${_mon(match.date.month)} ${match.date.day}, ${match.date.year}';

    // Status chip styling
    Color chipBg;
    Color chipFg;
    String chipLabel;
    if (isLive) {
      chipBg = const Color(0xFFFFEBEE);
      chipFg = const Color(0xFFD32F2F);
      chipLabel = 'LIVE';
    } else if (isCompleted) {
      chipBg = const Color(0xFFE8F5E9);
      chipFg = C.g2;
      chipLabel = 'DONE';
    } else {
      chipBg = const Color(0xFFF3F4F6);
      chipFg = C.grey;
      chipLabel = 'SOON';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top row: date + status chip
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$dateStr  •  ${match.venue}',
              style: const TextStyle(fontSize: 11.5, color: C.grey)),
          Row(children: [
            if (isLive)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _BlinkDot(),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: chipBg, borderRadius: BorderRadius.circular(8)),
              child: Text(chipLabel,
                  style: TextStyle(
                      color: chipFg,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ]),
        const SizedBox(height: 12),
        // Teams + scores
        Row(children: [
          _chip(_abbr(match.teamA)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${match.teamA}  vs  ${match.teamB}',
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: C.dark)),
                  const SizedBox(height: 2),
                  if (isCompleted || isLive)
                    Text('${match.scoreA}  –  ${match.scoreB}',
                        style: const TextStyle(fontSize: 12, color: C.grey)),
                ]),
          ),
          _chip(_abbr(match.teamB)),
        ]),
        // Result string (winner)
        if (isCompleted && match.result != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.emoji_events, size: 14, color: Color(0xFFFFD700)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(match.result!,
                  style: const TextStyle(
                      color: C.g2,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _chip(String abbr) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: C.gLight,
          shape: BoxShape.circle,
          border: Border.all(color: C.g2.withAlpha(60), width: 1.2),
        ),
        child: Center(
            child: Text(abbr,
                style: const TextStyle(
                    color: C.g2,
                    fontSize: 10,
                    fontWeight: FontWeight.w800))),
      );

  String _abbr(String team) {
    final words = team
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
    if (words.length >= 2) return words;
    final cleaned = team.trim().toUpperCase();
    return cleaned.length >= 2 ? cleaned.substring(0, 2) : cleaned;
  }

  String _mon(int m) =>
      const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
}

class _BlinkDot extends StatefulWidget {
  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _c,
        child: Container(
            width: 7, height: 7,
            decoration: const BoxDecoration(
                color: Color(0xFFD32F2F), shape: BoxShape.circle)),
      );
}
