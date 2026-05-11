import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../models/scoring_models.dart';
import '../../route_paths.dart';
import '../../services/supabase_service.dart';
import '../../services/pdf_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/match_summary_widgets.dart';

class LiveScoringScreen extends StatefulWidget {
  final ScoringSession session;
  const LiveScoringScreen({super.key, required this.session});

  @override
  State<LiveScoringScreen> createState() => _LiveScoringScreenState();
}

class _LiveScoringScreenState extends State<LiveScoringScreen> {
  late ScoringSession _s;

  @override
  void initState() {
    super.initState();
    _s = widget.session.copy();
  }

  InningsState get _inn => _s.currentInnings!;

  Future<void> _finishMatchAndReturnHome() async {
    if (!mounted) return;
    final store = AppStore.of(context);
    store.saveScoringSession(_s);
    store.clearActiveLiveSession();
    await store.refreshMatches();
    if (!mounted) return;
    // Clear stacked routes (e.g. New match, Live scoring) and land on player home.
    // popUntil(isFirst) wrongly stops at RoleSelect under Home when that was never replaced.
    Navigator.of(context).pushNamedAndRemoveUntil(
      RoutePaths.home,
      (route) => false,
    );
  }

  void _pauseAndGoHome() {
    if (!mounted) return;
    final store = AppStore.of(context);
    store.setActiveLiveSession(_s);
    store.saveScoringSession(_s);
    Navigator.of(context).pushNamedAndRemoveUntil(
      RoutePaths.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_s.isCompleted) {
      return _MatchResultScreen(session: _s, onDone: _finishMatchAndReturnHome);
    }
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.g1,
        foregroundColor: C.white,
        automaticallyImplyLeading: false,
        leading: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: C.dark, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text('Live Scoring', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Pause and go home',
            onPressed: _pauseAndGoHome,
            icon: const Icon(Icons.home_rounded),
          ),
        ],
      ),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _scoreHeader(), const SizedBox(height: 16),
          _battersCard(), const SizedBox(height: 14),
          _bowlerCard(), const SizedBox(height: 14),
          _thisOver(), const SizedBox(height: 14),
          _scoringPad(),
        ]),
      )),
    );
  }

  Widget _scoreHeader() {
    final total = _inn.totalRuns;
    final wkts = _inn.totalWickets;
    final overs = _inn.oversText;
    final rr = _inn.runRate.toStringAsFixed(1);
    final target = _inn.targetRuns;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: C.g1, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$total/$wkts', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: C.white)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Overs $overs', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white70)),
            Text('RR $rr', style: const TextStyle(fontSize: 13, color: Colors.white60)),
          ]),
        ]),
        if (target > 0) ...[
          const SizedBox(height: 8),
          Text('Target $target | Need ${target - total} runs from ${(_inn.targetOvers * 6) - _inn.legalBalls} balls | Req ${_inn.requiredRate.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 13, color: Colors.white70)),
        ],
        const SizedBox(height: 6),
        Text('${_inn.battingTeam} vs ${_inn.bowlingTeam}', style: const TextStyle(fontSize: 13, color: Colors.white60)),
      ]),
    );
  }

  Widget _battersCard() {
    final s = _inn.currentStriker;
    final ns = _inn.currentNonStriker;
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BATSMEN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: C.grey)),
      const SizedBox(height: 12),
      if (s != null) _batterRow(s, true),
      if (ns != null) const SizedBox(height: 10),
      if (ns != null) _batterRow(ns, false),
    ]));
  }

  Widget _batterRow(PlayerInMatch p, bool isStriker) {
    return Row(children: [
      Icon(isStriker ? Icons.sports_cricket : Icons.person_outline, size: 18, color: C.g2),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.dark)),
        Text('${p.runs} (${p.ballsFaced})  ${p.fours}x4 ${p.sixes}x6', style: const TextStyle(fontSize: 12, color: C.grey)),
      ])),
      Text(p.strikeRate.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.dark)),
    ]);
  }

  Widget _bowlerCard() {
    final b = _inn.currentBowler;
    if (b == null) return const SizedBox.shrink();
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BOWLER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: C.grey)),
      const SizedBox(height: 12),
      Row(children: [
        const Icon(Icons.sports_baseball, size: 18, color: C.g2),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.dark)),
          Text('${b.oversText}  ${b.runsConceded}/${b.wicketsTaken}  Econ ${b.economy.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, color: C.grey)),
        ])),
      ]),
    ]));
  }

  Widget _thisOver() {
    final recent = _inn.balls.length > 6 ? _inn.balls.sublist(_inn.balls.length - 6) : _inn.balls;
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('THIS OVER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: C.grey)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: recent.map((b) => _ballChip(b)).toList()),
    ]));
  }

  Widget _ballChip(Ball b) {
    String txt = '${b.runsOffBat + b.extraRuns}';
    Color bg = C.gLight;
    Color fg = C.dark;
    if (b.isWicket) { txt = 'W'; bg = Colors.red; fg = C.white; }
    else if (b.extraType == 'wide') { txt = 'Wd${b.extraRuns > 0 ? '+'+b.extraRuns.toString() : ''}'; bg = Colors.orange.shade100; fg = Colors.orange.shade800; }
    else if (b.extraType == 'no_ball') { txt = 'NB${b.runsOffBat > 0 ? '+'+b.runsOffBat.toString() : ''}'; bg = Colors.orange.shade100; fg = Colors.orange.shade800; }
    else if (b.runsOffBat == 4) { bg = Colors.blue.shade50; fg = Colors.blue; }
    else if (b.runsOffBat == 6) { bg = Colors.purple.shade50; fg = Colors.purple; }
    return Chip(label: Text(txt, style: TextStyle(fontWeight: FontWeight.w800, color: fg, fontSize: 13)), backgroundColor: bg, padding: const EdgeInsets.symmetric(horizontal: 8), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap);
  }

  Widget _scoringPad() {
    final rows = [
      ['0','1','2','3'],
      ['4','5','6','Wd'],
      ['Nb','Bye','Lb','Wicket'],
      ['Undo','Swap','Done'],
    ];
    return _card(
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SCORING PAD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: C.grey)),
        const SizedBox(height: 12),
        ...rows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: row.map((label) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: label == row.last ? 0 : 8),
                child: _scoreBtn(label),
              ),
            )).toList(),
          ),
        )),
      ]),
    );
  }


  Widget _scoreBtn(String label) {
    VoidCallback? onTap;
    Color bg = C.white;
    Color fg = C.dark;
    if (label == '4') { bg = Colors.blue.shade50; fg = Colors.blue.shade700; }
    if (label == '6') { bg = Colors.purple.shade50; fg = Colors.purple.shade700; }
    if (label == 'Wicket') { bg = Colors.red.shade50; fg = Colors.red; }
    if (label == 'Wd' || label == 'Nb' || label == 'Bye' || label == 'Lb') { bg = Colors.orange.shade50; fg = Colors.orange.shade700; }
    if (label == 'Undo') { bg = Colors.grey.shade100; }
    switch (label) {
      case '0': case '1': case '2': case '3': case '4': case '5': case '6':
        onTap = () => _recordBall(runs: int.parse(label));
        break;
      case 'Wd': onTap = () => _showExtraDialog('wide'); break;
      case 'Nb': onTap = () => _showExtraDialog('no_ball'); break;
      case 'Bye': onTap = () => _showExtraDialog('bye'); break;
      case 'Lb': onTap = () => _showExtraDialog('leg_bye'); break;
      case 'Wicket': onTap = _showWicketDialog; break;
      case 'Undo': onTap = _undo; break;
      case 'Swap': onTap = _swapStrikers; break;
      case 'Done':
        onTap = _s.isCompleted ? _finishMatchAndReturnHome : null;
        break;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(onTap: _s.isCompleted ? null : onTap, borderRadius: BorderRadius.circular(12),
        child: Container(alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg))),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(16)), child: child);
  }

  void _recordBall({int runs = 0, int extraRuns = 0, String? extraType, bool wicket = false, String? wicketType, String? wicketPlayer}) {
    if (_s.isCompleted) return;
    final overNo = _inn.oversCompleted;
    final ballNo = _inn.ballsInCurrentOver + 1;
    final ballId = _inn.balls.length + 1;
    
    final striker = _inn.currentStriker;
    final nonStriker = _inn.currentNonStriker;
    final bowler = _inn.currentBowler;

    final ball = Ball(
      id: ballId, 
      overNo: overNo, 
      ballNo: ballNo, 
      runsOffBat: runs, 
      extraRuns: extraRuns, 
      extraType: extraType, 
      isWicket: wicket, 
      wicketType: wicketType, 
      wicketPlayerName: wicketPlayer,
      strikerName: striker?.name,
      nonStrikerName: nonStriker?.name,
      bowlerName: bowler?.name,
    );

    setState(() {
      _inn.balls.add(ball);
      if (striker != null) {
        striker.runs += runs;
        striker.ballsFaced += ball.isLegal ? 1 : 0;
        if (runs == 4) striker.fours++;
        if (runs == 6) striker.sixes++;
        if (ball.isLegal && (runs % 2 == 1)) _swapStrikers();
      }
      if (bowler != null) {
        bowler.runsConceded += runs + extraRuns;
        if (ball.isLegal) {
          bowler.ballsBowled++;
          if (bowler.ballsBowled >= 6) { bowler.oversBowled++; bowler.ballsBowled = 0; }
        }
        if (wicket) bowler.wicketsTaken++;
      }
      if (wicket && striker != null) { striker.isOut = true; striker.dismissal = wicketType ?? 'out'; }
      _checkInningsEnd();
      _checkOverChange();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppStore.of(context).saveScoringSession(_s);
      SupabaseService.createBall(ball, _s.setup.id, _s.currentInningsNo).catchError((_) {});
      SupabaseService
          .updateInningsSummary(_inn, _s.setup.id)
          .catchError((_) {});
    });
  }

  void _undo() {
    if (_inn.balls.isEmpty) return;
    setState(() {
      final ball = _inn.balls.removeLast();
      final striker = _inn.currentStriker;
      final bowler = _inn.currentBowler;
      if (striker != null) {
        striker.runs -= ball.runsOffBat;
        striker.ballsFaced -= ball.isLegal ? 1 : 0;
        if (ball.runsOffBat == 4) striker.fours--;
        if (ball.runsOffBat == 6) striker.sixes--;
      }
      if (bowler != null) {
        bowler.runsConceded -= (ball.runsOffBat + ball.extraRuns);
        if (ball.isLegal) {
          bowler.ballsBowled--;
          if (bowler.ballsBowled < 0) { bowler.oversBowled--; bowler.ballsBowled = 5; }
        }
        if (ball.isWicket) bowler.wicketsTaken--;
      }
      if (ball.isWicket) {
        final dismissed = _inn.batsmen.where((p) => p.isOut && p.name == ball.wicketPlayerName).toList();
        for (final p in dismissed) { p.isOut = false; p.dismissal = null; }
      }
    });
  }

  void _swapStrikers() {
    final s = _inn.currentStriker;
    final ns = _inn.currentNonStriker;
    if (s == null || ns == null) return;
    setState(() {
      final si = _inn.batsmen.indexOf(s);
      final nsi = _inn.batsmen.indexOf(ns);
      if (si >= 0 && nsi >= 0) {
        final tmp = _inn.batsmen[si];
        _inn.batsmen[si] = _inn.batsmen[nsi];
        _inn.batsmen[nsi] = tmp;
      }
    });
  }

  void _checkInningsEnd() {
    // All out or overs complete
    if (_inn.totalWickets >= _inn.batsmen.length - 1 || _inn.oversCompleted >= _inn.targetOvers) {
      _endInnings();
      return;
    }
    // Chase successful — 2nd innings team passed target
    if (_s.currentInningsNo == 2 && _inn.targetRuns > 0 && _inn.totalRuns >= _inn.targetRuns) {
      _endInnings();
    }
  }

  void _checkOverChange() {
    if (_inn.ballsInCurrentOver == 0 && _inn.balls.isNotEmpty && !_s.isCompleted) {
      final bowler = _inn.currentBowler;
      if (bowler != null) { bowler.isBowling = false; }
      _swapStrikers();
      Future.delayed(Duration.zero, () => _pickBowler(_inn.oversCompleted));
    }
  }

  void _endInnings() {
    if (_s.currentInningsNo == 1) {
      SupabaseService
          .updateInningsSummary(_inn, _s.setup.id, isCompleted: true)
          .catchError((_) {});
      final target = _inn.totalRuns + 1;
      final batTeam = _s.setup.bowlingFirst;
      final bowlTeam = _s.setup.battingFirst;
      final batSquad = batTeam == _s.setup.teamA ? _s.setup.teamAPlayers : _s.setup.teamBPlayers;
      final bowlSquad = bowlTeam == _s.setup.teamA ? _s.setup.teamAPlayers : _s.setup.teamBPlayers;
      // Use explicit mutable lists — const [] (the default) is unmodifiable and
      // would throw when _recordBall tries to call balls.add() in innings 2.
      final batsmen = batSquad.map((n) => PlayerInMatch(name: n)).toList();
      final bowlers = bowlSquad.map((n) => PlayerInMatch(name: n)).toList();
      final inn2 = InningsState(
        inningsNo: 2,
        battingTeam: batTeam,
        bowlingTeam: bowlTeam,
        batsmen: batsmen,
        bowlers: bowlers,
        balls: [],          // explicit mutable list — IMPORTANT
        targetRuns: target,
        targetOvers: _s.setup.overs,
      );
      _s.innings2 = inn2;
      _s.currentInningsNo = 2;
      SupabaseService.createInnings(inn2, _s.setup.id).catchError((_) {});
      Future.delayed(Duration.zero, () => _pickOpenersDialog());
    } else {
      SupabaseService
          .updateInningsSummary(_inn, _s.setup.id, isCompleted: true)
          .catchError((_) {});
      _s.isCompleted = true;
      final r1 = _s.innings1?.totalRuns ?? 0;
      final r2 = _s.innings2?.totalRuns ?? 0;
      if (r1 > r2) _s.result = '${_s.setup.battingFirst} won by ${r1 - r2} runs';
      else if (r2 > r1) _s.result = '${_s.setup.bowlingFirst} won by ${(_inn.batsmen.length - 1) - (_s.innings2?.totalWickets ?? 0)} wickets';
      else _s.result = 'Match Tied';
      // Persist full scorecard to DB immediately.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppStore.of(context).saveScoringSession(_s);
      });
    }
  }

  void _showExtraDialog(String type) {
    int runs = 0;
    bool withRuns = false;
    if (type == 'bye' || type == 'leg_bye') withRuns = true;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (c, setD) => AlertDialog(
      title: Text(type == 'wide' ? 'Wide' : type == 'no_ball' ? 'No Ball' : type == 'bye' ? 'Bye' : 'Leg Bye'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if (withRuns) TextField(keyboardType: TextInputType.number, onChanged: (v) => setD(() => runs = int.tryParse(v) ?? 0), decoration: const InputDecoration(labelText: 'Runs off bat / Byes')),
        if (!withRuns) Wrap(spacing: 10, children: [0,1,2,3,4].map((r) => ChoiceChip(label: Text('$r'), selected: runs == r, onSelected: (_) => setD(() => runs = r))).toList()),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () {
          if (type == 'wide') _recordBall(extraRuns: 1 + runs, extraType: type);
          else if (type == 'no_ball') _recordBall(runs: runs, extraRuns: 1, extraType: type);
          else _recordBall(extraRuns: runs, extraType: type);
          Navigator.pop(ctx);
        }, child: const Text('OK'))],
    )));
  }

  void _showWicketDialog() {
    String type = 'bowled';
    String? player;
    final available = _inn.batsmen.where((p) => !p.isOut && !p.isBatting).map((p) => p.name).toList();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (c, setD) => AlertDialog(
      title: const Text('Wicket'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Wrap(spacing: 8, children: ['bowled','caught','run_out','stumped','lbw'].map((t) => ChoiceChip(label: Text(t), selected: type == t, onSelected: (_) => setD(() => type = t))).toList()),
        if (available.isNotEmpty) const SizedBox(height: 12),
        if (available.isNotEmpty) Text('New batsman (optional)', style: TextStyle(fontSize: 12, color: C.grey)),
        if (available.isNotEmpty) const SizedBox(height: 6),
        if (available.isNotEmpty) DropdownButtonFormField<String>(isExpanded: true, value: player, hint: const Text('Select new batsman'), items: available.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(), onChanged: (v) => setD(() => player = v)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () {
          final inningsBefore = _s.currentInningsNo;
          final striker = _inn.currentStriker;
          _recordBall(wicket: true, wicketType: type, wicketPlayer: striker?.name);
          Navigator.pop(ctx);
          if (player != null && _s.currentInningsNo == inningsBefore && !_s.isCompleted) {
            setState(() {
              final p = _inn.batsmen.firstWhere((x) => x.name == player);
              p.isBatting = true;
            });
          }
        }, child: const Text('OK'))],
    )));
  }

  void _pickBowler(int overNo) {
    final items = _inn.bowlers.map((p) => p.name).toList();
    String? selected;
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(builder: (c, setD) => AlertDialog(
      title: Text('New Bowler (Over ${overNo + 1})'),
      content: Column(mainAxisSize: MainAxisSize.min, children: items.map((n) => RadioListTile<String>(title: Text(n), value: n, groupValue: selected, onChanged: (v) => setD(() => selected = v))).toList()),
      actions: [TextButton(onPressed: selected != null ? () { setState(() { for (final p in _inn.bowlers) p.isBowling = false; _inn.bowlers.firstWhere((x) => x.name == selected).isBowling = true; }); Navigator.pop(ctx); } : null, child: const Text('OK'))],
    )));
  }

  void _pickOpenersDialog() {
    final batters = _inn.batsmen.map((p) => p.name).toList();
    final bowlerNames = _inn.bowlers.map((p) => p.name).toList();
    String? s, ns, b;
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(builder: (c, setD) {
      final canStart = s != null && ns != null && b != null && s != ns;
      return AlertDialog(
        title: const Text('Select Openers & Bowler'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Striker', style: TextStyle(fontSize: 12, color: C.grey)), const SizedBox(height: 4),
          DropdownButtonFormField<String>(isExpanded: true, value: s, hint: const Text('Select'), items: batters.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(), onChanged: (v) => setD(() => s = v)),
          const SizedBox(height: 10),
          Text('Non-Striker', style: TextStyle(fontSize: 12, color: C.grey)), const SizedBox(height: 4),
          DropdownButtonFormField<String>(isExpanded: true, value: ns, hint: const Text('Select'), items: batters.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(), onChanged: (v) => setD(() => ns = v)),
          const SizedBox(height: 10),
          Text('Opening Bowler', style: TextStyle(fontSize: 12, color: C.grey)), const SizedBox(height: 4),
          DropdownButtonFormField<String>(isExpanded: true, value: b, hint: const Text('Select'), items: bowlerNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(), onChanged: (v) => setD(() => b = v)),
          if (s != null && ns != null && s == ns)
            const Padding(padding: EdgeInsets.only(top: 8), child: Text('Striker and Non-Striker must be different', style: TextStyle(color: Colors.red, fontSize: 12))),
        ])),
        actions: [
          TextButton(
            onPressed: canStart ? () {
              setState(() {
                for (final p in _inn.batsmen) p.isBatting = (p.name == s || p.name == ns);
                for (final p in _inn.bowlers) p.isBowling = (p.name == b);
              });
              Navigator.pop(ctx);
            } : null,
            child: const Text('Start'),
          ),
        ],
      );
    }));
  }
}

// ─────────────────────────────────────────────────────────────
//  MATCH RESULT SCREEN
// ─────────────────────────────────────────────────────────────
class _MatchResultScreen extends StatelessWidget {
  final ScoringSession session;
  final Future<void> Function() onDone;
  const _MatchResultScreen({required this.session, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final inn1 = session.innings1;
    final inn2 = session.innings2;
    final result = session.result ?? 'Match Complete';
    final innings = [if (inn1 != null) inn1, if (inn2 != null) inn2];
    final motm = MatchSummaryWidgets.calculateManOfTheMatch(innings);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5C20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Match Result', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () => _downloadPdf(context),
            tooltip: 'Download Scorecard PDF',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF1A5C20),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  Text(
                    result,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _teamScore(session.setup.teamA,
                          '${inn1?.totalRuns ?? 0}/${inn1?.totalWickets ?? 0}',
                          '${inn1?.oversText ?? "0.0"} ov', true),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text('vs', style: TextStyle(color: Colors.white54, fontSize: 14)),
                      ),
                      _teamScore(session.setup.teamB,
                          '${inn2?.totalRuns ?? 0}/${inn2?.totalWickets ?? 0}',
                          '${inn2?.oversText ?? "0.0"} ov', false),
                    ],
                  ),
                ],
              ),
            ),
            const TabBar(
              labelColor: C.g1,
              unselectedLabelColor: C.grey,
              indicatorColor: C.g1,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              tabs: [
                Tab(text: 'SUMMARY'),
                Tab(text: 'SCORECARD'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSummaryTab(motm, innings),
                  _buildScorecardTab(innings),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: ElevatedButton.icon(
                onPressed: () => onDone(),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.g2,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(PlayerInMatch motm, List<InningsState> innings) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (motm.name != 'N/A') MatchSummaryWidgets.manOfTheMatch(motm),
        ...innings.map((inn) => _summaryInningsCard(inn)),
      ],
    );
  }

  Widget _summaryInningsCard(InningsState inn) {
    final topBat = (List<PlayerInMatch>.from(inn.batsmen)..sort((a, b) => b.runs.compareTo(a.runs))).take(2).toList();
    final topBowl = (List<PlayerInMatch>.from(inn.bowlers)..sort((a, b) => b.wicketsTaken.compareTo(a.wicketsTaken))).take(1).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(inn.battingTeam, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: C.dark)),
              Text('${inn.totalRuns}/${inn.totalWickets} (${inn.oversText})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: C.dark)),
            ],
          ),
          const Divider(height: 24),
          ...topBat.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(p.name, style: const TextStyle(fontSize: 13, color: C.dark))),
                Text('${p.runs}(${p.ballsFaced})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
              ],
            ),
          )),
          if (topBowl.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text(topBowl[0].name, style: const TextStyle(fontSize: 13, color: C.grey))),
                Text('${topBowl[0].wicketsTaken}/${topBowl[0].runsConceded}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.grey)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScorecardTab(List<InningsState> innings) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        for (var inn in innings) ..._detailedInningsSection(inn),
      ],
    );
  }

  List<Widget> _detailedInningsSection(InningsState inn) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Text('${inn.inningsNo == 1 ? "1st" : "2nd"} Innings — ${inn.battingTeam}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.dark)),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            _tableHeader(['BATTER', 'R', 'B', '4s', '6s', 'SR']),
            ...inn.batsmen.where((p) => p.ballsFaced > 0 || p.isOut).map((p) => _batterRow(p)),
            const Divider(height: 1),
            _tableHeader(['BOWLER', 'O', 'R', 'W', 'Econ']),
            ...inn.bowlers.where((p) => p.ballsBowled > 0 || p.oversBowled > 0).map((p) => _bowlerRow(p)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ];
  }

  Widget _tableHeader(List<String> cols) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(child: Text(cols[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: C.grey))),
          for (var i = 1; i < cols.length; i++)
            SizedBox(width: 40, child: Text(cols[i], textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: C.grey))),
        ],
      ),
    );
  }

  Widget _batterRow(PlayerInMatch p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
                if (p.isOut) Text(p.dismissal ?? 'out', style: const TextStyle(fontSize: 10, color: C.grey)),
              ],
            ),
          ),
          _cell('${p.runs}', bold: true),
          _cell('${p.ballsFaced}'),
          _cell('${p.fours}'),
          _cell('${p.sixes}'),
          _cell(p.strikeRate.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _bowlerRow(PlayerInMatch p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(child: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dark))),
          _cell(p.oversText),
          _cell('${p.runsConceded}'),
          _cell('${p.wicketsTaken}', bold: true),
          _cell(p.economy.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _cell(String txt, {bool bold = false}) {
    return SizedBox(
      width: 40,
      child: Text(
        txt,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: C.dark),
      ),
    );
  }

  Widget _teamScore(String team, String score, String overs, bool isLeft) {
    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(_abbr(team), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(score, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        Text(overs, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  String _abbr(String team) {
    final w = team.split(' ').where((e) => e.isNotEmpty).take(2).map((e) => e[0].toUpperCase()).join();
    return w.length >= 2 ? w : team.trim().toUpperCase().substring(0, team.length.clamp(0, 2));
  }

  void _downloadPdf(BuildContext context) async {
    final inn1 = session.innings1;
    final inn2 = session.innings2;
    final innings = [if (inn1 != null) inn1, if (inn2 != null) inn2];
    final motm = MatchSummaryWidgets.calculateManOfTheMatch(innings);
    
    final match = AdminMatch(
      id: session.setup.id,
      teamA: session.setup.teamA,
      teamB: session.setup.teamB,
      scoreA: '${inn1?.totalRuns ?? 0}/${inn1?.totalWickets ?? 0}',
      scoreB: '${inn2?.totalRuns ?? 0}/${inn2?.totalWickets ?? 0}',
      venue: session.setup.venue,
      date: session.setup.date,
      status: MatchStatus.completed,
      result: session.result,
      overs: session.setup.overs,
    );

    try {
      await PdfService.generateAndPrintScorecard(match, innings, motm);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
