import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/admin_models.dart';
import '../models/scoring_models.dart';

class PdfService {
  static Future<void> generateAndPrintScorecard(AdminMatch match, List<InningsState> innings, PlayerInMatch motm) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(match),
            pw.SizedBox(height: 20),
            if (motm.name != 'N/A') _buildMotm(motm),
            pw.SizedBox(height: 20),
            for (var inn in innings) ...[
              _buildInningsSection(inn),
              pw.SizedBox(height: 20),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Scorecard_${match.teamA}_vs_${match.teamB}.pdf',
    );
  }

  static pw.Widget _buildHeader(AdminMatch m) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('GULLY SCORE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
        pw.SizedBox(height: 8),
        pw.Text('${m.teamA} vs ${m.teamB}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(m.result ?? '', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
        pw.SizedBox(height: 4),
        pw.Text('${m.venue}  •  ${m.date.day}/${m.date.month}/${m.date.year}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.Divider(thickness: 2, color: PdfColors.green900),
      ],
    );
  }

  static pw.Widget _buildMotm(PlayerInMatch p) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        border: pw.Border.all(color: PdfColors.amber, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          pw.Text('MAN OF THE MATCH: ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
          pw.Text(p.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Spacer(),
          pw.Text(_statsSummary(p), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        ],
      ),
    );
  }

  static String _statsSummary(PlayerInMatch p) {
    List<String> stats = [];
    if (p.runs > 0) stats.add('${p.runs}(${p.ballsFaced})');
    if (p.wicketsTaken > 0) stats.add('${p.wicketsTaken}/${p.runsConceded}');
    return stats.join('  •  ');
  }

  static pw.Widget _buildInningsSection(InningsState inn) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: PdfColors.grey200,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${inn.battingTeam} Innings', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('${inn.totalRuns}/${inn.totalWickets} (${inn.oversText} ov)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        _buildBattingTable(inn.batsmen),
        pw.SizedBox(height: 15),
        _buildBowlingTable(inn.bowlers),
      ],
    );
  }

  static pw.Widget _buildBattingTable(List<PlayerInMatch> batsmen) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _th('BATTER'), _th('R'), _th('B'), _th('4s'), _th('6s'), _th('SR'),
          ],
        ),
        for (var p in batsmen.where((p) => p.ballsFaced > 0 || p.isOut))
          pw.TableRow(
            children: [
              _td(p.name, align: pw.Alignment.centerLeft),
              _td('${p.runs}', bold: true),
              _td('${p.ballsFaced}'),
              _td('${p.fours}'),
              _td('${p.sixes}'),
              _td(p.strikeRate.toStringAsFixed(1)),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildBowlingTable(List<PlayerInMatch> bowlers) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _th('BOWLER'), _th('O'), _th('M'), _th('R'), _th('W'), _th('ECON'),
          ],
        ),
        for (var p in bowlers.where((p) => p.ballsBowled > 0 || p.oversBowled > 0))
          pw.TableRow(
            children: [
              _td(p.name, align: pw.Alignment.centerLeft),
              _td(p.oversText),
              _td('${p.maidens}'),
              _td('${p.runsConceded}'),
              _td('${p.wicketsTaken}', bold: true),
              _td(p.economy.toStringAsFixed(1)),
            ],
          ),
      ],
    );
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _td(String text, {bool bold = false, pw.Alignment align = pw.Alignment.center}) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }
}
