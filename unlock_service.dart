import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';
import 'l10n/strings.dart';

const String _uBase = kIsWeb
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

const _kBg      = Color(0xFF2E3449);
const _kCard    = Color(0xFF394057);
const _kSurface = Color(0xFF434A64);
const _kAccent  = Color(0xFFF5A623);
const _kGreen   = Color(0xFF00C9A7);
const _kRed     = Color(0xFFE05A7A);
const _kText    = Color(0xFFEEF0F6);
const _kMuted   = Color(0xFF6A7090);
const _kBorder  = Color(0x18FFFFFF);

/// Shows the full OTP unlock flow.
/// [rentalId]  — rental to unlock
/// [context]   — build context for dialogs / snackbars
Future<void> showUnlockFlow(BuildContext context, dynamic rentalId) async {
  final s = AppStrings.of(context);
  // Step 1 — request OTP
  final token = await AuthService.getToken();
  String? devOtp;

  try {
    final res = await http.post(
      Uri.parse('$_uBase/rentals/$rentalId/request-otp'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));

    if (!context.mounted) return;
    final body = jsonDecode(res.body);

    if (res.statusCode != 200) {
      _snack(context, body['message'] ?? s.invalidOtp, error: true);
      return;
    }
    devOtp = body['otp'] as String?; // only present in dev
  } catch (_) {
    if (context.mounted) _snack(context, s.connectionError, error: true);
    return;
  }

  if (!context.mounted) return;

  // Step 2 — show OTP entry dialog
  final ctrl = TextEditingController(text: devOtp ?? '');
  bool unlocking = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setDlg) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _kGreen.withValues(alpha: 0.35), width: 2),
            ),
            child: const Icon(Icons.lock_open_rounded, color: _kGreen, size: 26),
          ),
          const SizedBox(height: 12),
          Text(s.unlockLocker, style: GoogleFonts.syne(
              fontWeight: FontWeight.w800, fontSize: 18, color: _kText)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          // Dev notice
          if (devOtp != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: _kAccent, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  s.devModeOtp,
                  style: GoogleFonts.dmSans(fontSize: 11, color: _kAccent),
                )),
              ]),
            ),
          const SizedBox(height: 16),
          Text(s.enterOtpInstruction,
              style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          // OTP input
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.syne(
              fontSize: 28, fontWeight: FontWeight.w800,
              color: _kText, letterSpacing: 8,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true, fillColor: _kSurface,
              hintText: s.otpHint,
              hintStyle: GoogleFonts.syne(fontSize: 28, color: _kMuted, letterSpacing: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kGreen, width: 2),
              ),
            ),
          ),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: unlocking ? null : () => Navigator.pop(ctx),
            child: Text(s.cancel, style: GoogleFonts.syne(color: _kMuted)),
          ),
          const SizedBox(width: 8),
          // Unlock button
          GestureDetector(
            onTap: unlocking
                ? null
                : () async {
                    final otp = ctrl.text.trim();
                    if (otp.length < 6) return;

                    // Security confirmation before unlocking
                    final confirmed = await showDialog<bool>(
                      context: ctx,
                      builder: (cctx) => AlertDialog(
                        backgroundColor: _kCard,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        content: Column(mainAxisSize: MainAxisSize.min, children: [
                          const SizedBox(height: 8),
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: _kAccent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: _kAccent.withValues(alpha: 0.4), width: 2),
                            ),
                            child: const Icon(Icons.shield_rounded, color: _kAccent, size: 26),
                          ),
                          const SizedBox(height: 16),
                          Text(s.confirmUnlock, style: GoogleFonts.syne(
                              fontSize: 17, fontWeight: FontWeight.w800, color: _kText)),
                          const SizedBox(height: 10),
                          Text(
                            s.confirmUnlockMsg,
                            style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted),
                            textAlign: TextAlign.center,
                          ),
                        ]),
                        actionsAlignment: MainAxisAlignment.center,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(cctx, false),
                            child: Text(s.cancel, style: GoogleFonts.syne(color: _kMuted)),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.pop(cctx, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(
                                color: _kAccent,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(s.yesUnlock, style: GoogleFonts.syne(
                                  fontWeight: FontWeight.w800, fontSize: 13, color: _kBg)),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;
                    setDlg(() => unlocking = true);

                    try {
                      final t = await AuthService.getToken();
                      final r = await http.post(
                        Uri.parse('$_uBase/rentals/$rentalId/unlock'),
                        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'},
                        body: jsonEncode({'otp': otp}),
                      ).timeout(const Duration(seconds: 10));
                      final b = jsonDecode(r.body);

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      if (r.statusCode == 200) {
                        _showUnlockSuccess(context, b['message'] ?? s.lockerOpened, s);
                      } else {
                        _snack(context, b['message'] ?? s.invalidOtp, error: true);
                      }
                    } catch (_) {
                      setDlg(() => unlocking = false);
                      _snack(ctx, s.connectionError, error: true);
                    }
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: unlocking ? null
                    : const LinearGradient(colors: [_kGreen, Color(0xFF00A88F)]),
                color: unlocking ? _kSurface : null,
                borderRadius: BorderRadius.circular(99),
              ),
              child: unlocking
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.lock_open_rounded, color: _kBg, size: 16),
                      const SizedBox(width: 6),
                      Text(s.unlock, style: GoogleFonts.syne(
                          fontWeight: FontWeight.w800, fontSize: 14, color: _kBg)),
                    ]),
            ),
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
}

/// Full-screen confirmation shown after successful unlock
void _showUnlockSuccess(BuildContext context, String message, AppStrings s) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _kGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: _kGreen.withValues(alpha: 0.4), width: 2),
          ),
          child: const Icon(Icons.check_rounded, color: _kGreen, size: 36),
        ),
        const SizedBox(height: 20),
        Text(s.lockerOpened, style: GoogleFonts.syne(
            fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 10),
        Text(message, style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(s.closeDoor,
            style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kGreen, Color(0xFF00A88F)]),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(s.gotIt, style: GoogleFonts.syne(
                fontWeight: FontWeight.w800, fontSize: 14, color: _kBg)),
          ),
        ),
      ]),
    ),
  );
}

void _snack(BuildContext context, String msg, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: GoogleFonts.syne(color: Colors.white)),
    backgroundColor: error ? _kRed : _kGreen,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));
}
