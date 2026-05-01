import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/scoring_models.dart';
import '../../route_paths.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class NewMatchScreen extends StatefulWidget {
  const NewMatchScreen({super.key});
  @override State<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  final _teamA = TextEditingController();
  final _teamB = TextEditingController();
  final _venue = TextEditingController();
  final _overs = TextEditingController(text: '20');
  String _format = 'T20';
  DateTime _date = DateTime.now();
  final List<TextEditingController> _squadA = [TextEditingController()];
  final List<TextEditingController> _squadB = [TextEditingController()];
  String _tossWinner = '', _electedTo = 'bat';
  String _striker = '', _nonStriker = '', _bowler = '';
  final _formats = ['T20','10-Over','ODI','Test'];

  void _next() => _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  void _prev() => _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

  bool get _ok {
    switch (_page) {
      case 0: return _teamA.text.trim().isNotEmpty && _teamB.text.trim().isNotEmpty && _venue.text.trim().isNotEmpty && _overs.text.trim().isNotEmpty;
      case 1: return _squadA.every((c) => c.text.trim().isNotEmpty) && _squadA.length >= 2;
      case 2: return _squadB.every((c) => c.text.trim().isNotEmpty) && _squadB.length >= 2;
      case 3: return _tossWinner.isNotEmpty && _striker.isNotEmpty && _nonStriker.isNotEmpty && _bowler.isNotEmpty && _striker != _nonStriker;
      default: return false;
    }
  }

  void _start() {
    final setup = MatchSetup(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      teamA: _teamA.text.trim(), teamB: _teamB.text.trim(), venue: _venue.text.trim(),
      overs: int.tryParse(_overs.text.trim()) ?? 20, format: _format, date: _date,
      tossWinner: _tossWinner, electedTo: _electedTo,
      teamAPlayers: _squadA.map((c) => c.text.trim()).toList(),
      teamBPlayers: _squadB.map((c) => c.text.trim()).toList(),
    );
    final batTeam = setup.battingFirst;
    final bowlTeam = setup.bowlingFirst;
    final batSquad = batTeam == setup.teamA ? setup.teamAPlayers : setup.teamBPlayers;
    final bowlSquad = bowlTeam == setup.teamA ? setup.teamAPlayers : setup.teamBPlayers;
    final batsmen = batSquad.map((n) => PlayerInMatch(name: n)).toList();
    final bowlers = bowlSquad.map((n) => PlayerInMatch(name: n)).toList();
    for (final p in batsmen) { if (p.name == _striker || p.name == _nonStriker) p.isBatting = true; }
    for (final p in bowlers) { if (p.name == _bowler) p.isBowling = true; }
    final innings = InningsState(inningsNo: 1, battingTeam: batTeam, bowlingTeam: bowlTeam, batsmen: batsmen, bowlers: bowlers, targetOvers: setup.overs);
    final session = ScoringSession(setup: setup, innings1: innings, currentInningsNo: 1);
    SupabaseService.createMatch(setup).catchError((_) {});
    SupabaseService.createInnings(innings, setup.id).catchError((_) {});
    Navigator.pushNamed(context, RoutePaths.liveScoring, arguments: session);
  }

  @override void dispose() {
    _pageCtrl.dispose(); _teamA.dispose(); _teamB.dispose(); _venue.dispose(); _overs.dispose();
    for (final c in _squadA) c.dispose(); for (final c in _squadB) c.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.white, elevation: 0, surfaceTintColor: C.white,
        title: const Text('New Match', style: TextStyle(color: C.dark, fontWeight: FontWeight.w800, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: C.dark), onPressed: () => Navigator.pop(context)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(3), child: LinearProgressIndicator(value: (_page + 1) / 4, backgroundColor: C.gLight, valueColor: const AlwaysStoppedAnimation<Color>(C.g2), minHeight: 3)),
      ),
      body: PageView(controller: _pageCtrl, physics: const NeverScrollableScrollPhysics(), onPageChanged: (i) => setState(() => _page = i),
        children: [step1(), stepSquad(_teamA.text, _squadA), stepSquad(_teamB.text, _squadB), step4()],
      ),
    );
  }

  Widget step1() => SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _title('Match Details'), const SizedBox(height: 16),
    _field('Team A', _teamA, icon: Icons.sports_cricket), const SizedBox(height: 14),
    _field('Team B', _teamB, icon: Icons.sports_cricket), const SizedBox(height: 14),
    _field('Venue', _venue, icon: Icons.location_on), const SizedBox(height: 14),
    Row(children: [
      Expanded(flex: 2, child: _field('Overs', _overs, icon: Icons.timer, keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly])),
      const SizedBox(width: 14),
      Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Format', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.grey)), const SizedBox(height: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: C.gLight, borderRadius: BorderRadius.circular(14)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _format, isExpanded: true, icon: const Icon(Icons.arrow_drop_down, color: C.g2), style: const TextStyle(color: C.dark, fontSize: 14, fontWeight: FontWeight.w600),
            items: _formats.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(color: C.dark)))).toList(),
            onChanged: (v) => setState(() => _format = v!),
          )),
        ),
      ])),
    ]),
    const SizedBox(height: 14),
    _datePicker(),
    const SizedBox(height: 28), _navButtons(),
  ]));

  Widget _datePicker() => InkWell(onTap: () async {
    final p = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2024), lastDate: DateTime(2030),
      builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: C.g2)), child: child!));
    if (p != null) setState(() => _date = p);
  }, borderRadius: BorderRadius.circular(14),
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), decoration: BoxDecoration(color: C.gLight, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [const Icon(Icons.calendar_today, color: C.g2, size: 20), const SizedBox(width: 12),
        Text('${_date.day.toString().padLeft(2,'0')} ${_monthName(_date.month)} ${_date.year}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.dark)),
        const Spacer(), const Icon(Icons.arrow_forward_ios, color: C.grey, size: 14)])),
    ),
  );

  Widget stepSquad(String team, List<TextEditingController> squad) => StatefulBuilder(builder: (ctx, setSt) {
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title('${team.isEmpty ? "Team" : team} Squad'), const SizedBox(height: 4),
      const Text('Add at least 2 players', style: TextStyle(fontSize: 12, color: C.grey)), const SizedBox(height: 16),
      ...List.generate(squad.length, (i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
        Expanded(child: _field('Player ${i+1}', squad[i], icon: Icons.person_outline)),
        if (squad.length > 1) IconButton(onPressed: () { squad[i].dispose(); setSt(() => squad.removeAt(i)); }, icon: const Icon(Icons.remove_circle_outline, color: Colors.red)),
      ]))),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: () => setSt(() => squad.add(TextEditingController())), icon: const Icon(Icons.add, color: C.g2), label: const Text('Add Player', style: TextStyle(color: C.g2, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: C.g2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
      ),
      const SizedBox(height: 28), _navButtons(),
    ]));
  });

  Widget step4() {
    final tA = _teamA.text.trim(), tB = _teamB.text.trim();
    final teams = [if (tA.isNotEmpty) tA, if (tB.isNotEmpty) tB];
    final batFirst = (_tossWinner == tA && _electedTo == 'bat') || (_tossWinner == tB && _electedTo == 'field') ? tA : tB;
    final bowlFirst = batFirst == tA ? tB : tA;
    final batSquad = batFirst == tA ? _squadA.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList() : _squadB.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList();
    final bowlSquad = bowlFirst == tA ? _squadA.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList() : _squadB.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList();
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title('Toss & Openers'), const SizedBox(height: 16),
      const Text('Toss Winner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.grey)), const SizedBox(height: 6),
      Wrap(spacing: 10, children: teams.map((t) => ChoiceChip(
        label: Text(t, style: TextStyle(color: _tossWinner == t ? C.white : C.dark, fontWeight: FontWeight.w700)),
        selected: _tossWinner == t, selectedColor: C.g2, backgroundColor: C.gLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (_) => setState(() => _tossWinner = t),
      )).toList()),
      const SizedBox(height: 14),
      const Text('Elected To', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.grey)), const SizedBox(height: 6),
      Wrap(spacing: 10, children: ['bat','field'].map((e) => ChoiceChip(
        label: Text(e == 'bat' ? 'Bat First' : 'Field First', style: TextStyle(color: _electedTo == e ? C.white : C.dark, fontWeight: FontWeight.w700)),
        selected: _electedTo == e, selectedColor: C.g2, backgroundColor: C.gLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (_) => setState(() => _electedTo = e),
      )).toList()),
      const SizedBox(height: 20),
      if (batSquad.isNotEmpty) ...[Text('Batting First: $batFirst', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.dark)), const SizedBox(height: 10),
        _dd('Striker', batSquad, _striker, (v) => setState(() => _striker = v ?? '')),
        const SizedBox(height: 10),
        _dd('Non-Striker', batSquad, _nonStriker, (v) => setState(() => _nonStriker = v ?? '')),
      ],
      const SizedBox(height: 20),
      if (bowlSquad.isNotEmpty) ...[Text('Bowling First: $bowlFirst', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.dark)), const SizedBox(height: 10),
        _dd('Opening Bowler', bowlSquad, _bowler, (v) => setState(() => _bowler = v ?? '')),
      ],
      const SizedBox(height: 28), _navButtons(start: true),
    ]));
  }

  Widget _dd(String label, List<String> items, String value, ValueChanged<String?> onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.grey)), const SizedBox(height: 6),
    Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: C.gLight, borderRadius: BorderRadius.circular(14)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: value.isEmpty ? null : value, hint: Text('Select $label', style: const TextStyle(color: C.hint, fontSize: 14)), icon: const Icon(Icons.arrow_drop_down, color: C.g2), style: const TextStyle(color: C.dark, fontSize: 14, fontWeight: FontWeight.w600),
        items: items.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: C.dark)))).toList(),
        onChanged: onChanged,
      )),
    ),
  ]);

  Widget _navButtons({bool start = false}) => Row(children: [
    if (_page > 0) Expanded(child: OutlinedButton(onPressed: _prev, style: OutlinedButton.styleFrom(side: const BorderSide(color: C.g2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Back', style: TextStyle(color: C.g2, fontWeight: FontWeight.w700)))),
    if (_page > 0) const SizedBox(width: 12),
    Expanded(child: ElevatedButton(
      onPressed: _ok ? (start ? _start : _next) : null,
      style: ElevatedButton.styleFrom(backgroundColor: C.g2, disabledBackgroundColor: C.gLight, foregroundColor: C.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
      child: Text(start ? 'Start Match' : 'Next', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
    )),
  ]);

  Widget _title(String text) => Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: C.dark));

  Widget _field(String label, TextEditingController ctrl, {IconData? icon, TextInputType? keyboard, List<TextInputFormatter>? formatters}) => TextField(
    controller: ctrl, keyboardType: keyboard, inputFormatters: formatters,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.dark),
    decoration: InputDecoration(labelText: label, prefixIcon: icon != null ? Icon(icon, color: C.g2, size: 20) : null, filled: true, fillColor: C.gLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18)),
  );

  String _monthName(int m) => const ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m];
}
