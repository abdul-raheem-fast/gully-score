import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ballCtrl;
  late AnimationController _textCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _dotsCtrl;

  late Animation<double> _ballScale;
  late Animation<double> _ballFade;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _glow;
  late Animation<double> _dotsFade;

  @override
  void initState() {
    super.initState();

    // Ball bounces in
    _ballCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _ballScale = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ballCtrl, curve: Curves.elasticOut));
    _ballFade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ballCtrl, curve: const Interval(0.0, 0.4)));

    // Text slides up after ball
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _textFade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide = Tween(begin: 24.0, end: 0.0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    // Dots fade in
    _dotsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _dotsFade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _dotsCtrl, curve: Curves.easeOut));

    // Glow pulses forever
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _glow = Tween(begin: 0.45, end: 0.9).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Sequence: ball → text → dots → navigate
    _ballCtrl.forward().then((_) =>
        _textCtrl.forward().then((_) => _dotsCtrl.forward()));

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  void dispose() {
    _ballCtrl.dispose();
    _textCtrl.dispose();
    _glowCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF163F1B),
              Color(0xFF1E6124),
              Color(0xFF29772E),
              Color(0xFF337A38),
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── Cricket ball with glow ──
              AnimatedBuilder(
                animation: Listenable.merge([_ballCtrl, _glowCtrl]),
                builder: (_, __) => FadeTransition(
                  opacity: _ballFade,
                  child: ScaleTransition(
                    scale: _ballScale,
                    child: Stack(alignment: Alignment.center, children: [
                      // Glow ring
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: C.orange.withOpacity(_glow.value * 0.5),
                              blurRadius: 55,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      // Ball
                      Container(
                        width: 108,
                        height: 108,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: C.orange,
                        ),
                        child: CustomPaint(painter: _BallPainter()),
                      ),
                    ]),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── GULLYSCORE text ──
              AnimatedBuilder(
                animation: _textCtrl,
                builder: (_, child) => FadeTransition(
                  opacity: _textFade,
                  child: Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: child,
                  ),
                ),
                child: Column(children: [
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                        text: 'GULLY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      TextSpan(
                        text: 'SCORE',
                        style: TextStyle(
                          color: C.orange,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'C R I C K E T   A N A L Y T I C S',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 3.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ]),
              ),

              const Spacer(flex: 2),

              // ── Page dots ──
              FadeTransition(
                opacity: _dotsFade,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Dot(active: true),
                    const SizedBox(width: 8),
                    _Dot(active: false),
                    const SizedBox(width: 8),
                    _Dot(active: false),
                  ],
                ),
              ),

              const SizedBox(height: 52),
            ],
          ),
        ),
      ),
    );
  }
}

// Orange active dot, small grey inactive dots
class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: active ? 22 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: active ? C.orange : Colors.white30,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

// Cricket ball seam lines
class _BallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final cx = s.width / 2, cy = s.height / 2;
    final r = s.width * 0.34;

    // Left seam arc
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx - r * 0.5, cy),
          width: r * 1.05,
          height: r * 1.8),
      -1.05, 2.10, false, p,
    );
    // Right seam arc
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx + r * 0.5, cy),
          width: r * 1.05,
          height: r * 1.8),
      2.09, 2.10, false, p,
    );

    // Stitch dots
    final dp = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final y = cy - r * 0.5 + i * r * 0.26;
      canvas.drawCircle(Offset(cx - r * 0.07, y), 1.7, dp);
      canvas.drawCircle(Offset(cx + r * 0.07, y), 1.7, dp);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
