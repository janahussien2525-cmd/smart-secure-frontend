import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'directions.dart' show DirectionStep;

// ══════════════════════════════════════════════════════════
//  RAILWAY STATION INDOOR DIRECTIONS SCREEN
// ══════════════════════════════════════════════════════════
class RailwayDirectionsScreen extends StatefulWidget {
  final String stationName;
  final String cityName;
  final String lockerId;
  final List<DirectionStep> steps;

  const RailwayDirectionsScreen({
    super.key,
    required this.stationName,
    required this.cityName,
    required this.lockerId,
    required this.steps,
  });

  @override
  State<RailwayDirectionsScreen> createState() =>
      _RailwayDirectionsScreenState();
}

class _RailwayDirectionsScreenState extends State<RailwayDirectionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _stepsCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late AnimationController _pathCtrl;
  late Animation<double>   _pathAnim;

  int  _activeStep = 0;
  bool _navStarted = false;

  @override
  void initState() {
    super.initState();

    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();

    _stepsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _pathCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
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
                const Color(0xFF00C9A7).withValues(alpha: 0.07),
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
                const Color(0xFFF5A623).withValues(alpha: 0.05),
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
                    Text('Railway Navigation',
                        style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEEF0F6))),
                    const Spacer(),
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
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF00C9A7),
                                Color(0xFF00897B),
                              ]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF00C9A7).withValues(alpha: 0.4),
                                    blurRadius: 16)
                              ],
                            ),
                            child: const Icon(Icons.train_rounded,
                                color: Color(0xFF2E3449), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.stationName,
                                      style: GoogleFonts.syne(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFEEF0F6))),
                                  const SizedBox(height: 3),
                                  Text(widget.cityName,
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
                            painter: _RailwayFloorPlanPainter(
                                pathProgress: _pathAnim.value),
                          ),
                        ),
                        Positioned(
                          bottom: 10, left: 12,
                          child: _MapLegend(),
                        ),
                        // Pulsing locker pin — near lockers zone
                        Positioned(
                          top: 30, right: 44,
                          child: AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, child) => Transform.scale(
                                scale: _pulseAnim.value, child: child),
                            child: _LockerPin(),
                          ),
                        ),
                        // User dot — near main entrance
                        const Positioned(
                          top: 160, left: 28,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C9A7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: const Color(0xFF00C9A7).withValues(alpha: 0.3)),
                    ),
                    child: Text('${widget.steps.length} steps',
                        style: GoogleFonts.syne(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00C9A7))),
                  ),
                ]),
              ),
            ),

            // ── DIRECTION STEPS LIST ─────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final step    = widget.steps[i];
                  final done    = _navStarted && i < _activeStep;
                  final current = _navStarted &&
                      i == _activeStep &&
                      i < widget.steps.length;
                  final isLast  = i == widget.steps.length - 1;
                  return _RailwayStepTile(
                    step:      step,
                    index:     i,
                    isDone:    done,
                    isCurrent: current,
                    isLast:    isLast,
                    animCtrl:  _stepsCtrl,
                    delay:     i * 0.12,
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
          bottom: 0, left: 0, right: 0,
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
                            colors: [Color(0xFF00C9A7), Color(0xFF00897B)]),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF00C9A7).withValues(alpha: 0.45),
                              blurRadius: 22,
                              offset: const Offset(0, 6)),
                          BoxShadow(
                              color: const Color(0xFF00C9A7).withValues(alpha: 0.2),
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
          color: const Color(0xFF00C9A7).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: const Color(0xFF00C9A7).withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_rounded, color: Color(0xFF00C9A7), size: 12),
          const SizedBox(width: 5),
          Text('Locker ID: $id',
              style: GoogleFonts.syne(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF00C9A7),
                  letterSpacing: 0.5)),
        ]),
      );
}

// ── RAILWAY STEP TILE ─────────────────────────────────────
class _RailwayStepTile extends StatelessWidget {
  final DirectionStep       step;
  final int                 index;
  final bool                isDone, isCurrent, isLast;
  final AnimationController animCtrl;
  final double              delay;

  const _RailwayStepTile({
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

    final Color accentColor = isDone
        ? const Color(0xFF00C9A7)
        : isCurrent
            ? const Color(0xFF00C9A7)
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
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF00C9A7).withValues(alpha: 0.15)
                      : isCurrent
                          ? const Color(0xFF00C9A7).withValues(alpha: 0.15)
                          : const Color(0xFF434A64),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: isCurrent ? 2 : 1.5),
                  boxShadow: isCurrent
                      ? [BoxShadow(
                          color: const Color(0xFF00C9A7).withValues(alpha: 0.35),
                          blurRadius: 12)]
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
                  width: 2, height: 36,
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
                            color: const Color(0xFF00C9A7).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text('Current',
                              style: GoogleFonts.syne(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF00C9A7))),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(step.label,
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
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
              colors: [Color(0xFF00C9A7), Color(0xFF00897B)]),
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
  final Color   color;
  final IconData icon;
  final String  label;
  final bool    small;
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
          width: 36, height: 36,
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
          width: 8, height: 4,
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
        width: 14, height: 14,
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
//  RAILWAY STATION FLOOR PLAN PAINTER
//  Layout:
//    Top    : [PLATFORM 1] [PLATFORM 2] [PLATFORM 3]   (train tracks)
//    Middle : main concourse / waiting hall
//    Right  : [SMART SECURE LOCKERS]
//    Bottom : [TICKET OFFICE] [WAITING HALL] [SERVICES] [MAIN EXIT]
// ══════════════════════════════════════════════════════════
class _RailwayFloorPlanPainter extends CustomPainter {
  final double pathProgress;
  const _RailwayFloorPlanPainter({required this.pathProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF0A1020));

    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF4F5774)
      ..strokeWidth = 0.5;
    for (double gx = 0; gx < w; gx += 20) {
      canvas.drawLine(Offset(gx, 0), Offset(gx, h), gridPaint);
    }
    for (double gy = 0; gy < h; gy += 20) {
      canvas.drawLine(Offset(0, gy), Offset(w, gy), gridPaint);
    }

    // ── TRAIN TRACKS (top) ──────────────────────────────
    _drawTrack(canvas, Offset(0, h * 0.10), Offset(w * 0.62, h * 0.10));
    _drawTrack(canvas, Offset(0, h * 0.22), Offset(w * 0.62, h * 0.22));
    _drawTrack(canvas, Offset(0, h * 0.34), Offset(w * 0.62, h * 0.34));

    // Platform labels between tracks
    _drawPlatformLabel(canvas, Offset(w * 0.18, h * 0.05), 'PLATFORM 1');
    _drawPlatformLabel(canvas, Offset(w * 0.18, h * 0.17), 'PLATFORM 2');
    _drawPlatformLabel(canvas, Offset(w * 0.18, h * 0.28), 'PLATFORM 3');

    // ── MAIN CONCOURSE (horizontal band) ────────────────
    final corridorPaint = Paint()
      ..color = const Color(0xFF1A2540)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(0, h * 0.40, w * 0.64, h * 0.08), corridorPaint);

    // ── BOTTOM ROW ROOMS ────────────────────────────────
    _drawRoom(canvas,
        Rect.fromLTWH(w * 0.02, h * 0.50, w * 0.16, h * 0.38),
        label: 'TICKET\nOFFICE', labelSize: 7);
    _drawRoom(canvas,
        Rect.fromLTWH(w * 0.20, h * 0.50, w * 0.20, h * 0.38),
        label: 'WAITING\nHALL', labelSize: 7.5);
    _drawRoom(canvas,
        Rect.fromLTWH(w * 0.42, h * 0.50, w * 0.18, h * 0.38),
        label: 'SERVICES', labelSize: 7.5);

    // ── RIGHT COLUMN ────────────────────────────────────
    canvas.drawRect(
        Rect.fromLTWH(w * 0.64, 0, w * 0.06, h), corridorPaint);

    _drawRoom(canvas,
        Rect.fromLTWH(w * 0.72, h * 0.03, w * 0.26, h * 0.44),
        label: 'SMART SECURE\nLOCKERS', labelSize: 7, accent: true);
    _drawRoom(canvas,
        Rect.fromLTWH(w * 0.72, h * 0.50, w * 0.26, h * 0.38),
        label: 'MAIN EXIT', labelSize: 7.5);

    _drawAnimatedPath(canvas, size);
  }

  void _drawTrack(Canvas canvas, Offset a, Offset b) {
    // Rail lines
    final railPaint = Paint()
      ..color = const Color(0xFF2A3A5A)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const offset = Offset(0, 3);
    canvas.drawLine(a - offset, b - offset, railPaint);
    canvas.drawLine(a + offset, b + offset, railPaint);

    // Sleepers
    final sleeperPaint = Paint()
      ..color = const Color(0xFF1E2D47)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final len = (b - a).distance;
    final dir = (b - a) / len;
    for (double t = 12; t < len; t += 14) {
      final p = a + dir * t;
      canvas.drawLine(
          p + Offset(-dir.dy, dir.dx) * 5,
          p - Offset(-dir.dy, dir.dx) * 5,
          sleeperPaint);
    }
  }

  void _drawPlatformLabel(Canvas canvas, Offset center, String label) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3A4A6A),
            letterSpacing: 0.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
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

    // Path: user (near main exit bottom-right) → up right corridor → lockers
    final pathPoints = [
      Offset(w * 0.06, h * 0.69),  // user at entrance/waiting hall
      Offset(w * 0.06, h * 0.44),  // up to concourse
      Offset(w * 0.67, h * 0.44),  // walk right along concourse
      Offset(w * 0.67, h * 0.25),  // up right corridor
      Offset(w * 0.85, h * 0.25),  // arrive at lockers
    ];

    final dashPaint = Paint()
      ..color = const Color(0xFFE05A7A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const dashLen = 8.0;
    const gapLen  = 6.0;
    const cycle   = dashLen + gapLen;
    final offset  = pathProgress * cycle;

    for (int seg = 0; seg < pathPoints.length - 1; seg++) {
      final a   = pathPoints[seg];
      final b   = pathPoints[seg + 1];
      final len = (b - a).distance;
      final dir = (b - a) / len;

      double t = 0;
      while (t < len) {
        final startT   = t == 0 ? (cycle - offset % cycle) % cycle : t;
        final dashStart = startT;
        final dashEnd   = math.min(dashStart + dashLen, len);
        if (dashStart >= len) break;
        canvas.drawLine(a + dir * dashStart, a + dir * dashEnd, dashPaint);
        t = dashEnd + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(_RailwayFloorPlanPainter old) =>
      old.pathProgress != pathProgress;
}

// ══════════════════════════════════════════════════════════
//  DEFAULT RAILWAY STEPS
// ══════════════════════════════════════════════════════════
List<DirectionStep> defaultRailwaySteps() => const [
      DirectionStep(
          icon: Icons.login_rounded,
          label: 'Enter through the main station entrance'),
      DirectionStep(
          icon: Icons.confirmation_number_rounded,
          label: 'Pass the ticket office on your left'),
      DirectionStep(
          icon: Icons.people_rounded,
          label: 'Walk through the main waiting hall'),
      DirectionStep(
          icon: Icons.straight_rounded,
          label: 'Continue straight along the main concourse'),
      DirectionStep(
          icon: Icons.turn_right_rounded,
          label: 'Turn right at the services corridor'),
      DirectionStep(
          icon: Icons.lock_rounded,
          label: 'Smart Secure Lockers are on your right'),
    ];
