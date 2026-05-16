import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── DATA MODEL ────────────────────────────────────────────
class DirectionStep {
  final IconData icon;
  final String label;
  const DirectionStep({required this.icon, required this.label});
}

// ── MALL FLOOR PLAN DATA ──────────────────────────────────
// Each mall can supply its own floor plan config.
// For now we paint a generic mall SVG-style layout via CustomPainter.

// ══════════════════════════════════════════════════════════
//  INDOOR DIRECTIONS SCREEN
// ══════════════════════════════════════════════════════════
class IndoorDirectionsScreen extends StatefulWidget {
  final String locationName;
  final String mallName;
  final String lockerId;
  final List<DirectionStep> steps;

  const IndoorDirectionsScreen({
    super.key,
    required this.locationName,
    required this.mallName,
    required this.lockerId,
    required this.steps,
  });

  @override
  State<IndoorDirectionsScreen> createState() => _IndoorDirectionsScreenState();
}

class _IndoorDirectionsScreenState extends State<IndoorDirectionsScreen>
    with TickerProviderStateMixin {
  // ── Animations ────────────────────────────────────────
  late AnimationController _heroCtrl;
  late AnimationController _stepsCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late AnimationController _pathCtrl;
  late Animation<double>   _pathAnim;

  int _activeStep = 0;
  bool _navStarted = false;

  @override
  void initState() {
    super.initState();

    _heroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();

    _stepsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _pathCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _pathAnim = CurvedAnimation(parent: _pathCtrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _stepsCtrl.dispose();
    _pulseCtrl.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  void _startNavigation() {
    setState(() { _navStarted = true; _activeStep = 0; });
    _advanceStep();
  }

  void _advanceStep() async {
    for (int i = 0; i < widget.steps.length; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() => _activeStep = i + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final top    = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF2E3449),
      body: Stack(children: [

        // ── BACKGROUND GLOW ─────────────────────────────
        Positioned(
          top: -80, right: -80,
          child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFF5A623).withOpacity(0.07),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 120, left: -60,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF7B8FFF).withOpacity(0.06),
                Colors.transparent,
              ]),
            ),
          ),
        ),

        // ── MAIN CONTENT ────────────────────────────────
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── TOP BAR ─────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _heroCtrl,
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, top + 12, 16, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF434A64),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x1FFFFFFF)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFFEEF0F6), size: 16),
                      ),
                    ),
                    const Spacer(),
                    Text('Indoor Navigation',
                        style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEEF0F6))),
                    const Spacer(),
                    // Share / expand placeholder
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF434A64),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                      ),
                      child: const Icon(Icons.share_rounded,
                          color: Color(0xFF6A7090), size: 18),
                    ),
                  ]),
                ),
              ),
            ),

            // ── LOCATION HEADER ──────────────────────────
            SliverToBoxAdapter(
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                    .animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic)),
                child: FadeTransition(
                  opacity: _heroCtrl,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFFF5A623).withOpacity(0.4),
                                blurRadius: 16)
                          ],
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: Color(0xFF2E3449), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.locationName,
                              style: GoogleFonts.syne(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFEEF0F6))),
                          const SizedBox(height: 3),
                          Text(widget.mallName,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: const Color(0xFF6A7090))),
                          const SizedBox(height: 6),
                          _LockerIdChip(id: widget.lockerId),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            // ── FLOOR MAP ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: FadeTransition(
                  opacity: _heroCtrl,
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E1420),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x18FFFFFF)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.35), blurRadius: 20)
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(children: [
                        // Floor plan painter
                        AnimatedBuilder(
                          animation: _pathAnim,
                          builder: (_, __) => CustomPaint(
                            size: Size.infinite,
                            painter: _MallFloorPlanPainter(pathProgress: _pathAnim.value),
                          ),
                        ),
                        // Legend overlay
                        Positioned(
                          bottom: 10, left: 12,
                          child: _MapLegend(),
                        ),
                        // Pulsing locker pin
                        Positioned(
                          top: 46, right: 52,
                          child: AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, child) => Transform.scale(
                                scale: _pulseAnim.value, child: child),
                            child: _LockerPin(),
                          ),
                        ),
                        // User dot
                        const Positioned(
                          top: 100, left: 62,
                          child: _UserDot(),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),

            // ── STEPS HEADER ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Row(children: [
                  Text('Directions',
                      style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFEEF0F6))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: const Color(0xFFF5A623).withOpacity(0.3)),
                    ),
                    child: Text('${widget.steps.length} steps',
                        style: GoogleFonts.syne(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF5A623))),
                  ),
                ]),
              ),
            ),

            // ── DIRECTION STEPS LIST ─────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final step     = widget.steps[i];
                  final done     = _navStarted && i < _activeStep;
                  final current  = _navStarted && i == _activeStep && i < widget.steps.length;
                  final isLast   = i == widget.steps.length - 1;
                  return _DirectionStepTile(
                    step: step,
                    index: i,
                    isDone: done,
                    isCurrent: current,
                    isLast: isLast,
                    animCtrl: _stepsCtrl,
                    delay: i * 0.12,
                  );
                },
                childCount: widget.steps.length,
              ),
            ),

            // ── BOTTOM PADDING ───────────────────────────
            SliverToBoxAdapter(child: SizedBox(height: bottom + 120)),
          ],
        ),

        // ── START NAVIGATION BUTTON ──────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2E3449).withOpacity(0.0),
                  const Color(0xFF2E3449).withOpacity(0.95),
                  const Color(0xFF2E3449),
                ],
              ),
            ),
            child: _navStarted && _activeStep >= widget.steps.length
                ? _ArrivedBanner()
                : GestureDetector(
                    onTap: _startNavigation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFF5A623).withOpacity(0.45),
                              blurRadius: 22,
                              offset: const Offset(0, 6)),
                          BoxShadow(
                              color: const Color(0xFFF5A623).withOpacity(0.2),
                              blurRadius: 40,
                              offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.navigation_rounded,
                            color: Color(0xFF2E3449), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _navStarted ? 'Navigating…' : 'Start Navigation',
                          style: GoogleFonts.syne(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2E3449)),
                        ),
                      ]),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  SUB-WIDGETS
// ══════════════════════════════════════════════════════════

class _LockerIdChip extends StatelessWidget {
  final String id;
  const _LockerIdChip({required this.id});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF7B8FFF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(99),
          border:
              Border.all(color: const Color(0xFF7B8FFF).withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_rounded, color: Color(0xFF7B8FFF), size: 12),
          const SizedBox(width: 5),
          Text('Locker ID: $id',
              style: GoogleFonts.syne(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7B8FFF),
                  letterSpacing: 0.5)),
        ]),
      );
}

// ── DIRECTION STEP TILE ───────────────────────────────────
class _DirectionStepTile extends StatelessWidget {
  final DirectionStep step;
  final int index;
  final bool isDone, isCurrent, isLast;
  final AnimationController animCtrl;
  final double delay;

  const _DirectionStepTile({
    required this.step,
    required this.index,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    required this.animCtrl,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final intervalStart = delay.clamp(0.0, 0.9);
    final intervalEnd   = (delay + 0.3).clamp(0.1, 1.0);
    final anim = CurvedAnimation(
      parent: animCtrl,
      curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutCubic),
    );

    Color accentColor = isDone
        ? const Color(0xFF00C9A7)
        : isCurrent
            ? const Color(0xFFF5A623)
            : const Color(0xFF2A3050);

    return SlideTransition(
      position:
          Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
              .animate(anim),
      child: FadeTransition(
        opacity: anim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Timeline column
            Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF00C9A7).withOpacity(0.15)
                      : isCurrent
                          ? const Color(0xFFF5A623).withOpacity(0.15)
                          : const Color(0xFF434A64),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor,
                    width: isCurrent ? 2 : 1.5,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                              color: const Color(0xFFF5A623).withOpacity(0.35),
                              blurRadius: 12)
                        ]
                      : [],
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Color(0xFF00C9A7), size: 18)
                    : Icon(step.icon, color: accentColor, size: 18),
              ),
              if (!isLast)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 2,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        isDone
                            ? const Color(0xFF00C9A7).withOpacity(0.6)
                            : const Color(0xFF2A3050),
                        const Color(0xFF2A3050).withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ]),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    top: 10, bottom: isLast ? 0 : 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Step ${index + 1}',
                          style: GoogleFonts.syne(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accentColor)),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5A623).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text('Current',
                              style: GoogleFonts.syne(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF5A623))),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(step.label,
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isDone
                                ? const Color(0xFF6A7090)
                                : const Color(0xFFEEF0F6))),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── ARRIVED BANNER ────────────────────────────────────────
class _ArrivedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00C9A7), Color(0xFF00A88F)]),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF00C9A7).withOpacity(0.45),
                blurRadius: 22,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF2E3449), size: 20),
          const SizedBox(width: 10),
          Text('You have arrived!',
              style: GoogleFonts.syne(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E3449))),
        ]),
      );
}

// ── MAP LEGEND ────────────────────────────────────────────
class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E3449).withOpacity(0.65),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x18FFFFFF)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              _LegendItem(color: Color(0xFFF5A623), icon: Icons.location_on_rounded, label: 'Locker'),
              SizedBox(width: 10),
              _LegendItem(color: Color(0xFF7B8FFF), icon: Icons.circle, label: 'You', small: true),
              SizedBox(width: 10),
              _LegendItem(color: Color(0xFFE05A7A), icon: Icons.remove, label: 'Path'),
            ]),
          ),
        ),
      );
}

class _LegendItem extends StatelessWidget {
  final Color color; final IconData icon; final String label; final bool small;
  const _LegendItem({required this.color, required this.icon, required this.label, this.small = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: small ? 8 : 12),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.dmSans(fontSize: 9, color: const Color(0xFFEEF0F6))),
      ]);
}

// ── LOCKER PIN ────────────────────────────────────────────
class _LockerPin extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFF5A623).withOpacity(0.5),
                  blurRadius: 14)
            ],
          ),
          child: const Icon(Icons.lock_rounded, color: Color(0xFF2E3449), size: 18),
        ),
        Container(
          width: 3, height: 8,
          color: const Color(0xFFF5A623),
        ),
        Container(
          width: 8, height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFF5A623).withOpacity(0.3),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ]);
}

// ── USER DOT ──────────────────────────────────────────────
class _UserDot extends StatelessWidget {
  const _UserDot();
  @override
  Widget build(BuildContext context) => Container(
        width: 14, height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF7B8FFF),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF7B8FFF).withOpacity(0.5),
                blurRadius: 8)
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════
//  MALL FLOOR PLAN PAINTER
// ══════════════════════════════════════════════════════════
class _MallFloorPlanPainter extends CustomPainter {
  final double pathProgress;
  const _MallFloorPlanPainter({required this.pathProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Background ──────────────────────────────────────
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF0A1020));

    // ── GRID (subtle) ────────────────────────────────────
    final gridPaint = Paint()
      ..color = const Color(0xFF4F5774)
      ..strokeWidth = 0.5;
    for (double gx = 0; gx < w; gx += 20) {
      canvas.drawLine(Offset(gx, 0), Offset(gx, h), gridPaint);
    }
    for (double gy = 0; gy < h; gy += 20) {
      canvas.drawLine(Offset(0, gy), Offset(w, gy), gridPaint);
    }

    // ── MALL WALLS ───────────────────────────────────────
    _drawRoom(canvas, Rect.fromLTWH(w * 0.05, h * 0.08, w * 0.28, h * 0.38),
        label: 'PULLMAN', labelSize: 7.5);
    _drawRoom(canvas, Rect.fromLTWH(w * 0.05, h * 0.55, w * 0.20, h * 0.35),
        label: 'ZARA', labelSize: 8);
    _drawRoom(canvas, Rect.fromLTWH(w * 0.30, h * 0.08, w * 0.22, h * 0.30),
        label: 'KIKO', labelSize: 7.5);
    _drawRoom(canvas, Rect.fromLTWH(w * 0.30, h * 0.44, w * 0.22, h * 0.46),
        label: 'VIRGIN', labelSize: 8);
    _drawRoom(canvas, Rect.fromLTWH(w * 0.58, h * 0.08, w * 0.37, h * 0.50),
        label: 'SMART SECURE\nLOCKERS', labelSize: 7, accent: true);
    _drawRoom(canvas, Rect.fromLTWH(w * 0.58, h * 0.64, w * 0.37, h * 0.26),
        label: 'CAFE', labelSize: 7.5);

    // ── CORRIDOR / PATH ───────────────────────────────────
    final corridorPaint = Paint()
      ..color = const Color(0xFF1A2540)
      ..style = PaintingStyle.fill;

    // Horizontal corridor
    canvas.drawRect(
        Rect.fromLTWH(w * 0.05, h * 0.47, w * 0.90, h * 0.06),
        corridorPaint);
    // Vertical corridor
    canvas.drawRect(
        Rect.fromLTWH(w * 0.54, h * 0.08, w * 0.06, h * 0.82),
        corridorPaint);

    // ── ANIMATED DASHED PATH ─────────────────────────────
    _drawAnimatedPath(canvas, size);
  }

  void _drawRoom(Canvas canvas, Rect rect,
      {required String label, double labelSize = 9, bool accent = false}) {
    // Fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..color = accent
            ? const Color(0xFFF5A623).withOpacity(0.07)
            : const Color(0xFF141E32),
    );
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..color = accent
            ? const Color(0xFFF5A623).withOpacity(0.3)
            : const Color(0xFF2A3555)
        ..style = PaintingStyle.stroke
        ..strokeWidth = accent ? 1.5 : 1.0,
    );
    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: labelSize,
          fontWeight: FontWeight.w700,
          color: accent
              ? const Color(0xFFF5A623).withOpacity(0.7)
              : const Color(0xFF3A4565),
          height: 1.3,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 8);
    tp.paint(
        canvas,
        rect.center -
            Offset(tp.width / 2, tp.height / 2));
  }

  void _drawAnimatedPath(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Path: user location → right corridor → locker
    final pathPoints = [
      Offset(w * 0.155, h * 0.72), // start (user)
      Offset(w * 0.57,  h * 0.72), // go right
      Offset(w * 0.57,  h * 0.32), // go up
      Offset(w * 0.72,  h * 0.32), // locker
    ];

    // Total path length
   
    double totalLen = 0;
    for (int i = 0; i < pathPoints.length - 1; i++) {
      totalLen += (pathPoints[i + 1] - pathPoints[i]).distance;
    }

    final dashPaint = Paint()
      ..color = const Color(0xFFE05A7A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const dashLen = 8.0;
    const gapLen  = 6.0;
    const cycle   = dashLen + gapLen;

    // ignore: unused_local_variable
    double drawn  = 0;
    double offset = pathProgress * cycle; // animate

    for (int seg = 0; seg < pathPoints.length - 1; seg++) {
      final a   = pathPoints[seg];
      final b   = pathPoints[seg + 1];
      final len = (b - a).distance;
      final dir = (b - a) / len;

      double t = 0;
      while (t < len) {
        // Skip ahead by animated offset at start
        final startT = t == 0 ? (cycle - offset % cycle) % cycle : t;
        double dashStart = startT;
        double dashEnd   = math.min(dashStart + dashLen, len);
        if (dashStart >= len) break;

        canvas.drawLine(a + dir * dashStart, a + dir * dashEnd, dashPaint);
        t = dashEnd + gapLen;
      }
      drawn += len;
    }
  }

  @override
  bool shouldRepaint(_MallFloorPlanPainter old) =>
      old.pathProgress != pathProgress;
}