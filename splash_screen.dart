import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_service.dart';
import 'l10n/strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _particleCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _glowAnim;

  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    // Generate floating particles
    for (int i = 0; i < 18; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 2 + _rng.nextDouble() * 3,
        speed: 0.003 + _rng.nextDouble() * 0.005,
        opacity: 0.1 + _rng.nextDouble() * 0.25,
        phase: _rng.nextDouble() * 2 * pi,
      ));
    }

    // Logo: scale + fade
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    // Text reveal
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
      CurvedAnimation(parent: _textCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );

    // Glow pulse
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _particleCtrl, curve: Curves.easeInOut),
    );

    // Sequence
    _logoCtrl.forward().then((_) {
      _textCtrl.forward();
    });

    // Navigate after 2.8s — go to home if already logged in
    Future.delayed(const Duration(milliseconds: 2800), () async {
      if (!mounted) return;
      final loggedIn = await AuthService.isLoggedIn();
      if (mounted) {
        Navigator.pushReplacementNamed(context, loggedIn ? '/home' : '/login');
      }
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF2E3449),
      body: AnimatedBuilder(
        animation: Listenable.merge([_logoCtrl, _textCtrl, _particleCtrl]),
        builder: (context, _) {
          return Stack(
            children: [

              // ── RADIAL GLOW BACKGROUND ──────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _BackgroundPainter(
                    glowOpacity: _glowAnim.value,
                    particles: _particles,
                    animValue: _particleCtrl.value,
                  ),
                ),
              ),

              // ── GRID LINES (subtle) ──────────────────────────
              Positioned.fill(
                child: CustomPaint(painter: _GridPainter()),
              ),

              // ── CENTER CONTENT ───────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Logo mark
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow ring
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF5A623).withOpacity(0.25 * _glowAnim.value),
                                    blurRadius: 60,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            // Icon container
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF5A623), Color(0xFFE8920A)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF5A623).withOpacity(0.45),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                color: Color(0xFF2E3449),
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Brand name
                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Smart',
                                style: GoogleFonts.syne(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFEEF0F6),
                                  letterSpacing: -1.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Secure',
                                style: GoogleFonts.syne(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFF5A623),
                                  letterSpacing: -1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tagline
                    FadeTransition(
                      opacity: _taglineFade,
                      child: SlideTransition(
                        position: _taglineSlide,
                        child: Text(
                          s.tagline,
                          style: GoogleFonts.syne(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6A7090),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── LOADING BAR (bottom) ─────────────────────────
              Positioned(
                bottom: 60,
                left: size.width * 0.35,
                right: size.width * 0.35,
                child: FadeTransition(
                  opacity: _taglineFade,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedBuilder(
                      animation: _particleCtrl,
                      builder: (_, __) => const LinearProgressIndicator(
                        value: null,
                        backgroundColor: Color(0xFF434A64),
                        valueColor: AlwaysStoppedAnimation(Color(0xFFF5A623)),
                        minHeight: 2,
                      ),
                    ),
                  ),
                ),
              ),

            ],
          );
        },
      ),
    );
  }
}

// ── PARTICLE DATA ─────────────────────────────────────────
class _Particle {
  double x, y, size, speed, opacity, phase;
  _Particle({required this.x, required this.y, required this.size, required this.speed, required this.opacity, required this.phase});
}

// ── BACKGROUND PAINTER ────────────────────────────────────
class _BackgroundPainter extends CustomPainter {
  final double glowOpacity;
  final List<_Particle> particles;
  final double animValue;

  _BackgroundPainter({required this.glowOpacity, required this.particles, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Radial gradient glow
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 0.85,
        colors: [
          const Color(0xFFF5A623).withOpacity(0.07 * glowOpacity),
          const Color(0xFF2E3449).withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Particles
    for (final p in particles) {
      final dy = sin(animValue * 2 * pi + p.phase) * 0.03;
      final px = p.x * size.width;
      final py = (p.y + dy) * size.height;
      canvas.drawCircle(
        Offset(px, py),
        p.size,
        Paint()..color = const Color(0xFFF5A623).withOpacity(p.opacity * glowOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => true;
}

// ── GRID PAINTER ──────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.025)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
