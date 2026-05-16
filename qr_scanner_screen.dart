import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'l10n/strings.dart';

const _kPurple = Color(0xFF7B8FFF);
const _kOrange = Color(0xFFF5A623);

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});
  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with TickerProviderStateMixin {

  Map<String, dynamic>? _rental;
  String _lockerCode = '';

  late AnimationController _nfcCtrl;
  late Animation<double>   _nfcFade;
  late Animation<Offset>   _nfcSlide;
  bool _nfcVisible = false;

  // Generated QR state
  String _qrData    = '';
  int    _countdown = 2;
  Timer? _qrTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _nfcCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _nfcFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _nfcCtrl, curve: Curves.easeOut),
    );
    _nfcSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _nfcCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _nfcVisible = true);
        _nfcCtrl.forward();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_rental == null) {
      _rental = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;

      _lockerCode = _rental?['locker_code'] as String? ?? '';
      _qrData     = _generateQrPayload();

      _startQrCycle();
    }
  }

  /// Builds a base64-encoded JSON payload that changes every 2-second slot.
  /// The backend validates: locker matches + timestamp is within ±1 slot (±2 s).
  String _generateQrPayload() {
    if (_lockerCode.isEmpty) return '';
    final slot    = DateTime.now().millisecondsSinceEpoch ~/ 2000;
    final payload = jsonEncode({'locker': _lockerCode, 'ts': slot});
    return base64Url.encode(utf8.encode(payload));
  }

  void _startQrCycle() {
    if (_lockerCode.isEmpty) return;

    // Regenerate QR + rotate every 2 seconds
    _qrTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _qrData    = _generateQrPayload();
        _countdown = 2;
      });
    });

    // Countdown tick every second (visual only)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _countdown = _countdown > 1 ? _countdown - 1 : 2);
    });
  }

  @override
  void dispose() {
    _nfcCtrl.dispose();
    _qrTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s        = context.s;
    final bottom   = MediaQuery.of(context).padding.bottom;
    final location = _rental?['location_name'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1F35),
      body: Stack(children: [

        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1120), Color(0xFF1A1F35), Color(0xFF0D1120)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),

        Positioned.fill(
          child: SafeArea(
            child: Column(children: [

              // ── Top bar ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      s.scanToUnlock,
                      style: GoogleFonts.syne(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (location.isNotEmpty)
                      Text(
                        location,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                  ]),
                ]),
              ),

              const Spacer(),

              // ── QR Code card ──────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF252C45),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _kOrange.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.08),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [

                  // Label + countdown badge
                  Row(children: [
                    const Icon(Icons.qr_code_rounded, color: _kOrange, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _lockerCode.isNotEmpty
                            ? s.lookingForLocker(_lockerCode)
                            : s.pointCamera,
                        style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kOrange,
                        ),
                      ),
                    ),
                    // Countdown badge
                    if (_lockerCode.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _kOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _kOrange.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '${_countdown}s',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kOrange,
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 20),

                  if (_qrData.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox(
                        width: 180,
                        height: 180,
                        child: PrettyQrView.data(
                          data: _qrData,
                          decoration: const PrettyQrDecoration(
                            shape: PrettyQrSmoothSymbol(
                              color: Color(0xFF1A1F35),
                            ),
                            image: null,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          s.noActiveRental,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: Colors.white38,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  Text(
                    s.pointCamera,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),

              const Spacer(),

              // ── NFC tooltip ───────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 32),
                child: Column(children: [

                  if (_nfcVisible)
                    FadeTransition(
                      opacity: _nfcFade,
                      child: SlideTransition(
                        position: _nfcSlide,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _kPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _kPurple.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(children: [
                            const Icon(Icons.nfc_rounded, color: _kPurple, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.nfcTooltip,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: _kPurple,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),

                ]),
              ),

            ]),
          ),
        ),
      ]),
    );
  }
}
