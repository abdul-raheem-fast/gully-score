import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  static const _pages = [
    _OBPage(
      line1: 'Score Every Ball,',
      line2: 'Track Every Star',
      desc:
          'Record ball-by-ball scores, track player stats, and analyze team performance for your gully cricket matches.',
      type: _IlluType.batAndBall,
    ),
    _OBPage(
      line1: 'Analyze Your',
      line2: 'Performance',
      desc:
          'Get detailed analytics on batting, bowling and fielding. Know your strengths and improve your game.',
      type: _IlluType.chart,
    ),
    _OBPage(
      line1: 'Compete &',
      line2: 'Lead the Pack',
      desc:
          'Compare yourself on the leaderboard, earn fair play points and become the star of gully cricket.',
      type: _IlluType.trophy,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _fadeCtrl.reset();
    _fadeCtrl.forward();
  }

  void _goNext() {
    final nextPage = (_page < _pages.length - 1) ? _page + 1 : _pages.length - 1;

    if (_page < _pages.length - 1) {
      setState(() {
        _page = nextPage;
      });
      _pageCtrl.animateToPage(nextPage,
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      Navigator.pushReplacementNamed(context, '/role-select');
    }
  }

  void _goPrevious() {
    if (_page > 0) {
      final prevPage = _page - 1;
      setState(() {
        _page = prevPage;
      });
      _pageCtrl.animateToPage(prevPage,
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/role-select'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: C.gLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Skip',
                        style: TextStyle(
                            color: C.g2,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ),

            // ── Pages ──
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (_, i) => FadeTransition(
                  opacity: i == _page ? _fade : const AlwaysStoppedAnimation(1),
                  child: _PageContent(page: _pages[i]),
                ),
              ),
            ),

            // ── Page indicator + prev button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Previous button (disabled on first page)
                  Opacity(
                    opacity: _page == 0 ? 0.3 : 1.0,
                    child: IconButton(
                      onPressed: _page == 0 ? null : _goPrevious,
                      icon: const Icon(Icons.arrow_back_ios_new),
                      splashRadius: 22,
                      color: C.g2,
                    ),
                  ),

                  const Spacer(),

                  // Dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? C.g2 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Spacer to balance the previous button
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Next / Get Started ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppButton(
                label: _page == _pages.length - 1 ? 'Get Started' : 'Next',
                onTap: _goNext,
              ),
            ),
            const SizedBox(height: 16),

            // ── Sign In link ──
            GestureDetector(
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/role-select'),
              child: RichText(
                text: const TextSpan(children: [
                  TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(color: C.grey, fontSize: 14),
                  ),
                  TextSpan(
                    text: 'Sign In',
                    style: TextStyle(
                        color: C.g2, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

enum _IlluType { batAndBall, chart, trophy }

class _OBPage {
  final String line1, line2, desc;
  final _IlluType type;
  const _OBPage(
      {required this.line1,
      required this.line2,
      required this.desc,
      required this.type});
}

class _PageContent extends StatelessWidget {
  final _OBPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      final maxHeight = constraints.maxHeight;
      // Keep the illustration sized relative to available space (not the full screen)
      final circleSz = maxWidth * 0.68;
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                // Big light-green circle with illustration
                Container(
                  width: circleSz,
                  height: circleSz,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE2F0E2), // light green matching Figma exactly
                  ),
                  child: Center(
                    child: SizedBox(
                      width: circleSz * 0.52,
                      height: circleSz * 0.52,
                      child:
                          CustomPaint(painter: _IlluPainter(type: page.type)),
                    ),
                  ),
                ),
                const SizedBox(height: 44),
                // Title: black line1, green line2
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(children: [
                    TextSpan(
                      text: '${page.line1}\n',
                      style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: C.dark,
                          height: 1.3),
                    ),
                    TextSpan(
                      text: page.line2,
                      style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: C.g2,
                          height: 1.3),
                    ),
                  ]),
                ),
                const SizedBox(height: 18),
                Text(
                  page.desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: C.grey, fontSize: 14.5, height: 1.65),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ── Illustrations drawn with CustomPainter ──────────────────
class _IlluPainter extends CustomPainter {
  final _IlluType type;
  const _IlluPainter({required this.type});

  @override
  void paint(Canvas canvas, Size s) {
    switch (type) {
      case _IlluType.batAndBall:
        _drawBatAndBall(canvas, s);
        break;
      case _IlluType.chart:
        _drawChart(canvas, s);
        break;
      case _IlluType.trophy:
        _drawTrophy(canvas, s);
        break;
    }
  }

  void _drawBatAndBall(Canvas canvas, Size s) {
    final cx = s.width / 2, cy = s.height / 2;

    // --- Stumps (3 vertical rectangles, right side) ---
    final stumpPaint = Paint()
      ..color = const Color(0xFFD2A679)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final x = cx + s.width * 0.10 + i * s.width * 0.09;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(x, cy + s.height * 0.08),
              width: s.width * 0.055,
              height: s.height * 0.55),
          const Radius.circular(3),
        ),
        stumpPaint,
      );
    }
    // Bails
    for (int i = 0; i < 2; i++) {
      final x = cx + s.width * 0.145 + i * s.width * 0.09;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(x, cy - s.height * 0.185),
              width: s.width * 0.11,
              height: s.height * 0.045),
          const Radius.circular(3),
        ),
        stumpPaint,
      );
    }

    // --- Bat (diagonal, left side) ---
    final batPath = Path();
    final bx = cx - s.width * 0.18, by = cy + s.height * 0.30;
    batPath.moveTo(bx, by);
    batPath.lineTo(bx - s.width * 0.07, by - s.height * 0.07);
    batPath.lineTo(bx - s.width * 0.24, by - s.height * 0.56);
    batPath.lineTo(bx - s.width * 0.11, by - s.height * 0.63);
    batPath.lineTo(bx + s.width * 0.06, by - s.height * 0.08);
    batPath.close();
    canvas.drawPath(
        batPath, Paint()..color = const Color(0xFFD2A679)..style = PaintingStyle.fill);

    // Bat handle
    canvas.drawLine(
      Offset(bx - s.width * 0.175, by - s.height * 0.60),
      Offset(bx + s.width * 0.03, by - s.height * 0.84),
      Paint()
        ..color = const Color(0xFF9E7B5A)
        ..strokeWidth = s.width * 0.055
        ..strokeCap = StrokeCap.round,
    );

    // --- Ball ---
    final ballCenter = Offset(cx + s.width * 0.06, cy - s.height * 0.10);
    canvas.drawCircle(
        ballCenter, s.width * 0.13, Paint()..color = const Color(0xFFE53935));
    // Seam
    final seamPaint = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(ballCenter.dx - s.width * 0.04, ballCenter.dy),
            width: s.width * 0.13,
            height: s.width * 0.22),
        -0.9, 1.8, false, seamPaint);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(ballCenter.dx + s.width * 0.04, ballCenter.dy),
            width: s.width * 0.13,
            height: s.width * 0.22),
        2.3, 1.8, false, seamPaint);
  }

  void _drawChart(Canvas canvas, Size s) {
    final bars = [0.40, 0.65, 1.0, 0.50, 0.78, 0.92];
    final colors = [
      C.g2.withOpacity(0.5),
      C.g2.withOpacity(0.6),
      C.g2,
      C.g2.withOpacity(0.5),
      C.g2.withOpacity(0.7),
      C.orange,
    ];
    final bw = s.width * 0.105;
    final gap = (s.width - bw * bars.length) / (bars.length + 1);
    final baseY = s.height * 0.88;
    final maxH = s.height * 0.72;

    for (int i = 0; i < bars.length; i++) {
      final x = gap + i * (bw + gap);
      final h = bars[i] * maxH;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, baseY - h, bw, h), const Radius.circular(6)),
        Paint()..color = colors[i],
      );
    }
    canvas.drawLine(Offset(0, baseY), Offset(s.width, baseY),
        Paint()..color = Colors.grey.shade300..strokeWidth = 1.5);
  }

  void _drawTrophy(Canvas canvas, Size s) {
    const gold = Color(0xFFFFB300);
    final cx = s.width / 2;

    // Cup body
    final cup = Path()
      ..moveTo(cx - s.width * 0.27, s.height * 0.12)
      ..lineTo(cx + s.width * 0.27, s.height * 0.12)
      ..quadraticBezierTo(cx + s.width * 0.29, s.height * 0.54,
          cx + s.width * 0.14, s.height * 0.65)
      ..lineTo(cx + s.width * 0.08, s.height * 0.71)
      ..lineTo(cx + s.width * 0.19, s.height * 0.71)
      ..lineTo(cx + s.width * 0.19, s.height * 0.80)
      ..lineTo(cx - s.width * 0.19, s.height * 0.80)
      ..lineTo(cx - s.width * 0.19, s.height * 0.71)
      ..lineTo(cx - s.width * 0.08, s.height * 0.71)
      ..quadraticBezierTo(cx - s.width * 0.29, s.height * 0.54,
          cx - s.width * 0.27, s.height * 0.12)
      ..close();
    canvas.drawPath(cup, Paint()..color = gold);

    // Handles
    final hp = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.075
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx - s.width * 0.295, s.height * 0.295),
            width: s.width * 0.22,
            height: s.height * 0.30),
        1.57, 3.14, false, hp);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx + s.width * 0.295, s.height * 0.295),
            width: s.width * 0.22,
            height: s.height * 0.30),
        -1.57, 3.14, false, hp);

    // Star inside cup
    _drawStar(canvas, Offset(cx, s.height * 0.37), s.width * 0.13,
        Colors.white.withOpacity(0.9));

    // Base plate
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, s.height * 0.845),
              width: s.width * 0.48,
              height: s.height * 0.065),
          const Radius.circular(5)),
      Paint()..color = gold,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    const n = 5;
    const inner = 0.42;
    for (int i = 0; i < n * 2; i++) {
      final angle = (i * 36 - 90) * 3.14159265 / 180;
      final rad = i.isEven ? r : r * inner;
      final x = center.dx + rad * _cos(angle);
      final y = center.dy + rad * _sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // Inline trig for no dart:math dependency
  double _cos(double a) {
    a = a % 6.2831853;
    return 1 - a*a/2 + a*a*a*a/24 - a*a*a*a*a*a/720;
  }
  double _sin(double a) {
    a = a % 6.2831853;
    return a - a*a*a/6 + a*a*a*a*a/120 - a*a*a*a*a*a*a/5040;
  }

  @override
  bool shouldRepaint(_) => false;
}
