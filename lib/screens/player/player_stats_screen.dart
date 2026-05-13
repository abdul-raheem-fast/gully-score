import 'package:flutter/material.dart';
import '../../models/player_models.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../route_paths.dart';

/// Player analytics from database values only.
class PlayerStatsScreen extends StatefulWidget {
  const PlayerStatsScreen({super.key});

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  late Future<PlayerStatsSnapshot> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = SupabaseService.fetchCurrentPlayerStats();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final name = store.userName.isEmpty ? 'Player' : store.userName;
    final initials = _initials(name);
    final teamName = _primaryTeamName(store);
    final roleLine = _roleSubtitle();

    return Scaffold(
      backgroundColor: C.bg,
      body: FutureBuilder<PlayerStatsSnapshot>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5, color: C.g2),
            );
          }
          final stats = snapshot.data ??
              const PlayerStatsSnapshot(
                matches: 0,
                runs: 0,
                average: 0,
                strikeRate: 0,
                wickets: 0,
                overallRating: 0,
                battingImpact: 0,
                consistency: 0,
                fielding: 0,
                sportsmanship: 0,
                recentFormRuns: <int>[],
              );
          final ratingMetrics = <_RatingMetric>[
            _RatingMetric(
              'Batting Impact',
              stats.battingImpact,
              _RatingTone.greenDark,
            ),
            _RatingMetric('Consistency', stats.consistency, _RatingTone.greenMid),
            _RatingMetric('Fielding', stats.fielding, _RatingTone.orange),
            _RatingMetric(
              'Sportsmanship',
              stats.sportsmanship,
              _RatingTone.greenMid,
            ),
          ];
          final formValues =
              stats.recentFormRuns.isEmpty ? const <int>[0] : stats.recentFormRuns;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushReplacementNamed(RoutePaths.home),
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
                        _ProfileHeaderCard(
                          initials: initials,
                          name: name,
                          roleLine: roleLine,
                          teamName: teamName,
                          runs: stats.runs,
                          average: stats.average,
                          strikeRate: stats.strikeRate,
                          matches: stats.matches,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _PerformanceRatingCard(
                    overall: stats.overallRating,
                    metrics: ratingMetrics,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: _RecentFormCard(values: formValues),
                ),
              ),
            ],
          );
        },
      ),
    );
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

  static String _primaryTeamName(AppStoreState store) {
    for (final m in store.myMemberships) {
      if (m.status == MembershipStatus.approved && m.teamName.isNotEmpty) {
        return m.teamName;
      }
    }
    return '—';
  }

  static String _roleSubtitle() {
    final raw =
        SupabaseService.currentUser?.userMetadata?['playing_role']?.toString();
    final role = raw?.trim();
    if (role != null && role.isNotEmpty) {
      return '$role • Right Handed';
    }
    return 'Player • Right Handed';
  }
}

// ── Profile header (gradient card) ─────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final String initials;
  final String name;
  final String roleLine;
  final String teamName;
  final int runs;
  final double average;
  final double strikeRate;
  final int matches;

  const _ProfileHeaderCard({
    required this.initials,
    required this.name,
    required this.roleLine,
    required this.teamName,
    required this.runs,
    required this.average,
    required this.strikeRate,
    required this.matches,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(36),
                  border: Border.all(color: Colors.white30, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roleLine,
                      style: TextStyle(
                        color: Colors.white.withAlpha(230),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      teamName == '—' ? 'No primary team' : teamName,
                      style: TextStyle(
                        color: Colors.white.withAlpha(140),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _HeadlineStat(value: '$runs', label: 'Runs'),
              ),
              Expanded(
                child: _HeadlineStat(
                  value: average.toStringAsFixed(
                    average == average.roundToDouble() ? 0 : 1,
                  ),
                  label: 'Average',
                ),
              ),
              Expanded(
                child: _HeadlineStat(
                  value: strikeRate == strikeRate.roundToDouble()
                      ? '${strikeRate.toInt()}'
                      : strikeRate.toStringAsFixed(1),
                  label: 'Strike Rate',
                ),
              ),
              Expanded(
                child: _HeadlineStat(value: '$matches', label: 'Matches'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeadlineStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeadlineStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(160),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Performance rating ─────────────────────────────────────────

enum _RatingTone { greenDark, greenMid, orange }

class _RatingMetric {
  final String label;
  final double value;
  final _RatingTone tone;
  const _RatingMetric(this.label, this.value, this.tone);
}

class _PerformanceRatingCard extends StatelessWidget {
  final double overall;
  final List<_RatingMetric> metrics;
  const _PerformanceRatingCard({
    required this.overall,
    required this.metrics,
  });

  Color _toneColor(_RatingTone t) {
    switch (t) {
      case _RatingTone.greenDark:
        return const Color(0xFF1B5E20);
      case _RatingTone.greenMid:
        return const Color(0xFF43A047);
      case _RatingTone.orange:
        return const Color(0xFFFF8F00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Performance Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: C.dark,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  overall.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...metrics.map((m) {
            final color = _toneColor(m.tone);
            final frac = (m.value / 10).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        m.label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: C.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        m.value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: C.dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Recent form bar chart ──────────────────────────────────────

class _RecentFormCard extends StatelessWidget {
  final List<int> values;
  const _RecentFormCard({required this.values});

  Color _barColor(int index, int value, int maxV) {
    if (index == values.length - 1) return const Color(0xFFFF8F00);
    if (maxV <= 0) return const Color(0xFFC8E6C9);
    final t = value / maxV;
    if (t >= 0.85) return const Color(0xFF1B5E20);
    if (t >= 0.55) return const Color(0xFF43A047);
    if (t >= 0.35) return const Color(0xFF81C784);
    return const Color(0xFFA5D6A7);
  }

  @override
  Widget build(BuildContext context) {
    final maxV = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    const chartHeight = 132.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Form',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: C.dark,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (i) {
                final v = values[i];
                if (v == -1) {
                  // Placeholder for match not played yet
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 18),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 12,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '-',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final hFrac = maxV > 0 ? (v / maxV) : 0.0;
                final color = _barColor(i, v, maxV);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$v',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: hFrac.clamp(0.1, 1.0),
                              widthFactor: 0.6, // Thinner bars for better look
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'M${i + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: C.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
