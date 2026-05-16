import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'directions.dart' show DirectionStep;

// ══════════════════════════════════════════════════════════
//  AIRPORT INDOOR DIRECTIONS SCREEN
// ══════════════════════════════════════════════════════════
class AirportDirectionsScreen extends StatefulWidget {
  final String terminalName;
  final String airportName;
  final String lockerId;
  final List<DirectionStep> steps;

  const AirportDirectionsScreen({
    super.key,
    required this.terminalName,
    required this.airportName,
    required this.lockerId,
    required this.steps,
  });

  @override
  State<AirportDirectionsScreen> createState() =>
      _AirportDirectionsScreenState();
}

class _AirportDirectionsScreenState extends State<AirportDirectionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _stepsCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _pathCtrl;
  late Animation<double> _pathAnim;

  int _activeStep = 0;
  bool _navStarted = false;

  @override
  void initState() {
    super.initState();

    _heroCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
          ..forward();

    _stepsCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
          ..forward();

    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
          ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _pathCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
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
    setState(() {
      _navStarted = true;
      _activeStep = 0;
    });
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
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF2E3449),
      body: Stack(children: [
        // ── BACKGROUND GLOW ─────────────────────────────
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF4FC3F7).withValues(alpha: 0.07),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFF5A623).withValues(alpha: 0.06),
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
                        width: 42,
                        height: 42,
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
                    Text('Airport Navigation',
                        style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEEF0F6))),
                    const Spacer(),
                    Container(
                      width: 42,
                      height: 42,
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
                position: Tween<Offset>(
                        begin: const Offset(0, 0.3), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: _heroCtrl, curve: Curves.easeOutCubic)),
                child: FadeTransition(
                  opacity: _heroCtrl,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF4FC3F7),
                                Color(0xFF0288D1)
                              ]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.4),
                                    blurRadius: 16)
                              ],
                            ),
                            child: const Icon(Icons.flight_rounded,
                                color: Color(0xFF2E3449), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.terminalName,
                                      style: GoogleFonts.syne(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFEEF0F6))),
                                  const SizedBox(height: 3),
                                  Text(widget.airportName,
                                      style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: const Color(0xFF6A7090))),
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
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 20)
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(children: [
                        AnimatedBuilder(
                          animation: _pathAnim,
                          builder: (_, __) => CustomPaint(
                            size: Size.infinite,
                            painter: _AirportFloorPlanPainter(
                                pathProgress: _pathAnim.value),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 12,
                          child: _MapLegend(),
                        ),
                        Positioned(
                          top: 38,
                          right: 48,
                          child: AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, child) => Transform.scale(
                                scale: _pulseAnim.value, child: child),
                            child: _LockerPin(),
                          ),
                        ),
                        const Positioned(
                          top: 155,
                          left: 30,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FC3F7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: const Color(0xFF4FC3F7).withValues(alpha: 0.3)),
                    ),
                    child: Text('${widget.steps.length} steps',
                        style: GoogleFonts.syne(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4FC3F7))),
                  ),
                ]),
              ),
            ),

            // ── DIRECTION STEPS LIST ─────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final step = widget.steps[i];
                  final done = _navStarted && i < _activeStep;
                  final current = _navStarted &&
                      i == _activeStep &&
                      i < widget.steps.length;
                  final isLast = i == widget.steps.length - 1;
                  return _AirportStepTile(
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

            SliverToBoxAdapter(child: SizedBox(height: bottom + 120)),
          ],
        ),

        // ── START NAVIGATION BUTTON ──────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2E3449).withValues(alpha: 0.0),
                  const Color(0xFF2E3449).withValues(alpha: 0.95),
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
                            colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF4FC3F7).withValues(alpha: 0.45),
                              blurRadius: 22,
                              offset: const Offset(0, 6)),
                          BoxShadow(
                              color: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
                              blurRadius: 40,
                              offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
          color: const Color(0xFF7B8FFF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFF7B8FFF).withValues(alpha: 0.3)),
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

// ── AIRPORT STEP TILE ────────────────────────────────────
class _AirportStepTile extends StatelessWidget {
  final DirectionStep step;
  final int index;
  final bool isDone, isCurrent, isLast;
  final AnimationController animCtrl;
  final double delay;

  const _AirportStepTile({
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
    final intervalEnd = (delay + 0.3).clamp(0.1, 1.0);
    final anim = CurvedAnimation(
      parent: animCtrl,
      curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutCubic),
    );

    Color accentColor = isDone
        ? const Color(0xFF00C9A7)
        : isCurrent
            ? const Color(0xFF4FC3F7)
            : const Color(0xFF2A3050);

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
          .animate(anim),
      child: FadeTransition(
        opacity: anim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF00C9A7).withValues(alpha: 0.15)
                      : isCurrent
                          ? const Color(0xFF4FC3F7).withValues(alpha: 0.15)
                          : const Color(0xFF434A64),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor,
                    width: isCurrent ? 2 : 1.5,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                              color: const Color(0xFF4FC3F7).withValues(alpha: 0.35),
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
                            ? const Color(0xFF00C9A7).withValues(alpha: 0.6)
                            : const Color(0xFF2A3050),
                        const Color(0xFF2A3050).withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 10, bottom: isLast ? 0 : 36),
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
                            color: const Color(0xFF4FC3F7).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text('Current',
                              style: GoogleFonts.syne(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF4FC3F7))),
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
                color: const Color(0xFF00C9A7).withValues(alpha: 0.45),
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
              color: const Color(0xFF2E3449).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x18FFFFFF)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              _LegendItem(
                  color: Color(0xFFF5A623),
                  icon: Icons.location_on_rounded,
                  label: 'Locker'),
              SizedBox(width: 10),
              _LegendItem(
                  color: Color(0xFF7B8FFF),
                  icon: Icons.circle,
                  label: 'You',
                  small: true),
              SizedBox(width: 10),
              _LegendItem(
                  color: Color(0xFFE05A7A),
                  icon: Icons.remove,
                  label: 'Path'),
            ]),
          ),
        ),
      );
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final bool small;
  const _LegendItem(
      {required this.color,
      required this.icon,
      required this.label,
      this.small = false});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: small ? 8 : 12),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 9, color: const Color(0xFFEEF0F6))),
      ]);
}

// ── LOCKER PIN ────────────────────────────────────────────
class _LockerPin extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.5),
                  blurRadius: 14)
            ],
          ),
          child: const Icon(Icons.lock_rounded,
              color: Color(0xFF2E3449), size: 18),
        ),
        Container(width: 3, height: 8, color: const Color(0xFFF5A623)),
        Container(
          width: 8,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFF5A623).withValues(alpha: 0.3),
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
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF7B8FFF),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF7B8FFF).withValues(alpha: 0.5),
                blurRadius: 8)
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════
//  AIRPORT FLOOR PLAN PAINTER
//  Layout (left→right, top→bottom):
//    Top row : [GATE A] [GATE B] [DUTY FREE] [SMART SECURE LOCKERS]
//    Mid row : main concourse corridor
//    Bot row : [ARRIVALS HALL] [PASSPORT CTRL] [CUSTOMS] [EXIT/PICKUP]
// ══════════════════════════════════════════════════════════
class _AirportFloorPlanPainter extends CustomPainter {
  final double pathProgress;
  const _AirportFloorPlanPainter({required this.pathProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF0A1020));

    final gridPaint = Paint()
      ..color = const Color(0xFF4F5774)
      ..strokeWidth = 0.5;
    for (double gx = 0; gx < w; gx += 20) {
      canvas.drawLine(Offset(gx, 0), Offset(gx, h), gridPaint);
    }
    for (double gy = 0; gy < h; gy += 20) {
      canvas.drawLine(Offset(0, gy), Offset(w, gy), gridPaint);
    }

    // ── TOP ROW ROOMS ───────────────────────────────────
    _drawRoom(canvas, Rect.fromLTWH(w * 0.03, h * 0.04, w * 0.18, h * 0.38),
        label: 'GATE A', labelSize: 8);
    _drawRoom(canvas, Rect.fromLTWH(w * 0.24, h * 0.04, w * 0.18, h * 0.38),
        label: 'GATE B', labelSize: 8);
    _drawRoom(canvas, Rect.fromLTWH(w * 0.45, h * 0.04, w * 0.16, h * 0.38),
        label: 'DUTY FREE', labelSize: 7.5);
    _drawRoom(canvas, Rect.fromLTWH(w * 0.64, h * 0.04, w * 0.32, h * 0.38),
        label: 'SMART SECURE\nLOCKERS', labelSize: 7, accent: true);

    // ── MAIN CONCOURSE (horizontal corridor) ────────────
    final corridorPaint = Paint()
      ..color = const Color(0xFF1A2540)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(w * 0.00, h * 0.44, w * 1.0, h * 0.08),
        corridorPaint);

    // ── BOTTOM ROW ROOMS ────────────────────────────────
    _drawRoom(canvas, Rect.fromLTWH(w * 0.03, h * 0.54, w * 0.22, h * 0.36),
        label: 'ARRIVALS\nHALL', labelSize: 7.5);
    _drawRoom(canvas, Rect.fromLTWH(w * 0.28, h * 0.54, w * 0.18, h * 0.36),
        label: 'PASSPORT\nCONTROL', labelSize: 7);
    _drawRoom(canvas, Rect.fromLTWH(w * 0.49, h * 0.54, w * 0.18, h * 0.36),
        label: 'CUSTOMS', labelSize: 7.5);
    _drawRoom(canvas, Rect.fromLTWH(w * 0.70, h * 0.54, w * 0.27, h * 0.36),
        label: 'EXIT / PICKUP', labelSize: 7);

    // ── VERTICAL CONNECTOR (right side) ─────────────────
    canvas.drawRect(
        Rect.fromLTWH(w * 0.60, h * 0.04, w * 0.06, h * 0.88),
        corridorPaint);

    _drawAnimatedPath(canvas, size);
  }

  void _drawRoom(Canvas canvas, Rect rect,
      {required String label, double labelSize = 9, bool accent = false}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..color = accent
            ? const Color(0xFFF5A623).withValues(alpha: 0.07)
            : const Color(0xFF141E32),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..color = accent
            ? const Color(0xFFF5A623).withValues(alpha: 0.3)
            : const Color(0xFF2A3555)
        ..style = PaintingStyle.stroke
        ..strokeWidth = accent ? 1.5 : 1.0,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: labelSize,
          fontWeight: FontWeight.w700,
          color: accent
              ? const Color(0xFFF5A623).withValues(alpha: 0.7)
              : const Color(0xFF3A4565),
          height: 1.3,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 8);
    tp.paint(canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawAnimatedPath(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Path: user (arrivals hall) → up to concourse → right → up to lockers
    final pathPoints = [
      Offset(w * 0.08, h * 0.72),
      Offset(w * 0.08, h * 0.48),
      Offset(w * 0.63, h * 0.48),
      Offset(w * 0.63, h * 0.22),
      Offset(w * 0.80, h * 0.22),
    ];

    final dashPaint = Paint()
      ..color = const Color(0xFFE05A7A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const dashLen = 8.0;
    const gapLen = 6.0;
    const cycle = dashLen + gapLen;

    final offset = pathProgress * cycle;

    for (int seg = 0; seg < pathPoints.length - 1; seg++) {
      final a = pathPoints[seg];
      final b = pathPoints[seg + 1];
      final len = (b - a).distance;
      final dir = (b - a) / len;

      double t = 0;
      while (t < len) {
        final startT = t == 0 ? (cycle - offset % cycle) % cycle : t;
        final dashStart = startT;
        final dashEnd = math.min(dashStart + dashLen, len);
        if (dashStart >= len) break;
        canvas.drawLine(a + dir * dashStart, a + dir * dashEnd, dashPaint);
        t = dashEnd + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(_AirportFloorPlanPainter old) =>
      old.pathProgress != pathProgress;
}

// ══════════════════════════════════════════════════════════
//  DEFAULT AIRPORT STEPS
//  Navigation from Arrivals to the Smart Secure Locker
//  in Cairo International Airport Terminal 2.
// ══════════════════════════════════════════════════════════
List<DirectionStep> defaultAirportSteps() => const [
      DirectionStep(
          icon: Icons.flight_land_rounded,
          label: 'Enter through the arrivals hall of Terminal 2'),
      DirectionStep(
          icon: Icons.badge_rounded,
          label: 'Pass through passport control and customs'),
      DirectionStep(
          icon: Icons.luggage_rounded,
          label: 'Collect your baggage from the carousel'),
      DirectionStep(
          icon: Icons.straight_rounded,
          label: 'Walk straight along the main concourse corridor'),
      DirectionStep(
          icon: Icons.turn_right_rounded,
          label: 'Turn right at the Duty Free shop'),
      DirectionStep(
          icon: Icons.lock_rounded,
          label: 'Smart Secure Lockers are ahead on your right'),
    ];
