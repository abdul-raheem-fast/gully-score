import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_models.dart';
import '../models/player_models.dart';
import '../models/scoring_models.dart';
import '../state/app_store.dart';
import 'supabase_service.dart';

class AiChatMessage {
  final String role;
  final String content;

  const AiChatMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class AiChatService {
  const AiChatService._();

  static Future<String> ask({
    required String question,
    required AppStoreState store,
    required List<AiChatMessage> history,
    bool isAdminView = false,
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty)
      return 'Ask me about a player, team, match, or form trend.';

    final context = await _buildContext(store);
    try {
      final response = await SupabaseService.client.functions.invoke(
        'gully-ai-chat',
        body: {
          'question': trimmed,
          'history': history.map((m) => m.toJson()).toList(),
          'viewer_mode': isAdminView ? 'admin' : 'player',
          'client_context': {
            'user_name': store.userName,
            'matches_count': store.matches.length,
            'teams_count': store.teams.length,
            'memberships_count': store.myMemberships.length,
          },
        },
      );
      final data = response.data;
      if (data is Map && data['answer'] is String) {
        final answer = (data['answer'] as String).trim();
        if (answer.isNotEmpty) return answer;
      }
    } on FunctionException catch (_) {
      // The Edge Function may not be deployed during local development.
    } catch (_) {}

    return _localAnswer(trimmed, context);
  }

  static Future<_AiContext> _buildContext(AppStoreState store) async {
    final matches = store.matches.toList();
    final teams = store.teams.toList();
    var catalog = <TeamInfo>[];
    try {
      catalog = await SupabaseService.fetchTeamsCatalog();
    } catch (_) {}
    return _AiContext(
      userName: store.userName,
      matches: matches,
      teams: teams,
      catalog: catalog,
      memberships: store.myMemberships.toList(),
      activeSession: store.activeLiveSession,
    );
  }

  static String _localAnswer(String question, _AiContext context) {
    final q = question.toLowerCase();
    if (q.contains('predict') ||
        q.contains('future') ||
        q.contains('form') ||
        q.contains('performance')) {
      return _predictionAnswer(q, context);
    }
    if (q.contains('team') || _mentionsAnyTeam(q, context)) {
      return _teamAnswer(q, context);
    }
    if (q.contains('player') || q.contains(context.userName.toLowerCase())) {
      return _playerAnswer(q, context);
    }
    if (q.contains('live') || q.contains('match') || q.contains('score')) {
      return _matchAnswer(context);
    }
    return _overviewAnswer(context);
  }

  static bool _mentionsAnyTeam(String q, _AiContext context) {
    for (final team in context.allTeamNames) {
      if (team.isNotEmpty && q.contains(team.toLowerCase())) return true;
    }
    return false;
  }

  static String _overviewAnswer(_AiContext c) {
    final completed =
        c.matches.where((m) => m.status == MatchStatus.completed).length;
    final live = c.matches.where((m) => m.status == MatchStatus.live).length;
    final upcoming =
        c.matches.where((m) => m.status == MatchStatus.upcoming).length;
    final best = _bestTeam(c);
    return [
      'Broskie AI can help with your GullyScore database: teams, matches, score trends, and simple future-performance predictions.',
      'Right now I see ${c.matches.length} matches: $completed completed, $live live, and $upcoming upcoming.',
      if (best != null)
        'The strongest current team signal is ${best.name}, with ${best.wins} wins from ${best.matches} completed matches.',
      'Try asking: "predict my next performance", "which team is strongest?", or "summarize live matches".',
    ].join('\n\n');
  }

  static String _matchAnswer(_AiContext c) {
    final active = c.activeSession;
    if (active != null && !active.isCompleted) {
      final current = active.currentInnings;
      final score = current == null
          ? '0/0'
          : '${current.totalRuns}/${current.totalWickets} in ${current.oversText} overs';
      return '${active.setup.teamA} vs ${active.setup.teamB} is live. ${current?.battingTeam ?? active.setup.battingFirst} are $score. Current run rate: ${current?.runRate.toStringAsFixed(2) ?? '0.00'}.';
    }
    final live = c.matches.where((m) => m.status == MatchStatus.live).toList();
    if (live.isNotEmpty) {
      return live
          .map((m) =>
              '${m.teamA} ${m.scoreA} vs ${m.teamB} ${m.scoreB} at ${m.venue}.')
          .join('\n');
    }
    if (c.matches.isEmpty)
      return 'No matches are loaded yet. Start scoring a match and I will use that data here.';
    final latest = c.matches.first;
    return 'Latest match: ${latest.teamA} ${latest.scoreA} vs ${latest.teamB} ${latest.scoreB} at ${latest.venue}. ${latest.result ?? 'Result is not final yet.'}';
  }

  static String _teamAnswer(String q, _AiContext c) {
    final standings = _teamRecords(c);
    if (standings.isEmpty) {
      return 'I do not see enough team match data yet. Add teams and complete matches so I can compare form.';
    }
    final mentioned =
        standings.where((r) => q.contains(r.name.toLowerCase())).toList();
    if (mentioned.isNotEmpty) {
      final r = mentioned.first;
      final rate = r.matches == 0 ? 0 : (r.wins / r.matches) * 100;
      return '${r.name} have ${r.wins} wins from ${r.matches} completed matches (${rate.toStringAsFixed(0)}% win rate). Recent signal: ${r.netRuns >= 0 ? '+' : ''}${r.netRuns} run differential. ${_teamVerdict(r)}';
    }
    final top = standings.first;
    return 'Based on completed matches, ${top.name} are leading: ${top.wins} wins from ${top.matches} matches with ${top.netRuns >= 0 ? '+' : ''}${top.netRuns} run differential. Next best: ${standings.skip(1).take(2).map((r) => '${r.name} (${r.wins}W)').join(', ')}.';
  }

  static String _playerAnswer(String q, _AiContext c) {
    final user = c.userName.trim().isEmpty ? 'this player' : c.userName.trim();
    final teams = c.memberships
        .where((m) => m.status == MembershipStatus.approved)
        .map((m) => m.teamName)
        .where((t) => t.isNotEmpty)
        .toList();
    final matches = c.matches.length;
    final completed =
        c.matches.where((m) => m.status == MatchStatus.completed).length;
    final teamLine = teams.isEmpty
        ? 'No approved team is linked yet.'
        : 'Linked team: ${teams.join(', ')}.';
    return '$user has database context from $matches matches, including $completed completed matches. $teamLine For deeper batting and bowling predictions, store striker, bowler, and wicket-player names on each ball consistently; the AI function is already designed to use that richer data when available.';
  }

  static String _predictionAnswer(String q, _AiContext c) {
    final records = _teamRecords(c);
    final mentioned =
        records.where((r) => q.contains(r.name.toLowerCase())).toList();
    if (mentioned.isNotEmpty) {
      final r = mentioned.first;
      final confidence = min(82, 52 + (r.wins * 8) + max(0, r.netRuns ~/ 20));
      return 'Prediction for ${r.name}: ${_teamVerdict(r)} If they keep the same scoring trend, I would rate their next-match outlook around $confidence/100. This is a form estimate from your database, not a guarantee.';
    }
    final active = c.activeSession;
    if (active != null && !active.isCompleted) {
      final inn = active.currentInnings;
      if (inn != null) {
        final projected = inn.legalBalls == 0
            ? 0
            : (inn.runRate * active.setup.overs).round();
        return '${inn.battingTeam} are trending toward about $projected runs at the current rate of ${inn.runRate.toStringAsFixed(2)}. Wickets lost (${inn.totalWickets}) will heavily affect the final 3-over push.';
      }
    }
    final best = records.isEmpty ? null : records.first;
    if (best == null) {
      return 'I need completed matches before I can make a useful prediction. Once matches are scored, I will update from the database automatically.';
    }
    return 'Best current prediction signal: ${best.name}. They have ${best.wins} wins from ${best.matches} completed matches and a ${best.netRuns >= 0 ? '+' : ''}${best.netRuns} run differential. Ask about a specific team or player for a narrower prediction.';
  }

  static _TeamRecord? _bestTeam(_AiContext c) {
    final records = _teamRecords(c);
    return records.isEmpty ? null : records.first;
  }

  static List<_TeamRecord> _teamRecords(_AiContext c) {
    final byName = <String, _TeamRecord>{};
    _TeamRecord record(String name) =>
        byName.putIfAbsent(name, () => _TeamRecord(name: name));

    for (final m in c.matches.where((m) => m.status == MatchStatus.completed)) {
      final a = record(m.teamA);
      final b = record(m.teamB);
      a.matches++;
      b.matches++;
      final ar = _scoreRuns(m.scoreA);
      final br = _scoreRuns(m.scoreB);
      a.netRuns += ar - br;
      b.netRuns += br - ar;
      if (m.winner == m.teamA || ar > br) {
        a.wins++;
      } else if (m.winner == m.teamB || br > ar) {
        b.wins++;
      }
    }
    final records = byName.values.toList();
    records.sort((a, b) {
      final winCompare = b.wins.compareTo(a.wins);
      if (winCompare != 0) return winCompare;
      return b.netRuns.compareTo(a.netRuns);
    });
    return records;
  }

  static int _scoreRuns(String score) {
    final runs = score.split('/').first.trim();
    return int.tryParse(runs) ?? 0;
  }

  static String _teamVerdict(_TeamRecord r) {
    if (r.matches == 0)
      return 'There is not enough completed-match evidence yet.';
    if (r.wins == r.matches && r.matches >= 2)
      return 'Their form is excellent and consistent.';
    if (r.netRuns > 30) return 'They are winning the run-difference battle.';
    if (r.netRuns < -30)
      return 'They need better starts or tighter death overs.';
    return 'Their form is competitive but still close enough to swing.';
  }
}

class _AiContext {
  final String userName;
  final List<AdminMatch> matches;
  final List<AdminTeam> teams;
  final List<TeamInfo> catalog;
  final List<TeamMembership> memberships;
  final ScoringSession? activeSession;

  const _AiContext({
    required this.userName,
    required this.matches,
    required this.teams,
    required this.catalog,
    required this.memberships,
    required this.activeSession,
  });

  Iterable<String> get allTeamNames sync* {
    for (final team in teams) {
      yield team.name;
    }
    for (final team in catalog) {
      yield team.name;
    }
    for (final match in matches) {
      yield match.teamA;
      yield match.teamB;
    }
  }
}

class _TeamRecord {
  final String name;
  int matches = 0;
  int wins = 0;
  int netRuns = 0;

  _TeamRecord({required this.name});
}
