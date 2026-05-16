import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/strings.dart';
import 'unlock_service.dart';

const _kCard    = Color(0xFF394057);
const _kSurface = Color(0xFF434A64);
const _kPurple  = Color(0xFF7B8FFF);
const _kText    = Color(0xFFEEF0F6);
const _kMuted   = Color(0xFF6A7090);

/// Shows a bottom sheet asking the user to choose between OTP and QR unlock.
Future<void> showUnlockMethodSheet(
  BuildContext context,
  Map<String, dynamic> rental,
) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _UnlockMethodSheet(rental: rental),
  );
}

class _UnlockMethodSheet extends StatelessWidget {
  final Map<String, dynamic> rental;
  const _UnlockMethodSheet({required this.rental});

  @override
  Widget build(BuildContext context) {
    final s      = context.s;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottom + 24),
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Drag handle
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: _kMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(height: 20),

        // Title
        Text(
          s.chooseUnlockMethod,
          style: GoogleFonts.syne(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        const SizedBox(height: 20),

        // OTP option
        _MethodCard(
          icon: Icons.sms_rounded,
          color: const Color(0xFF00C9A7),
          title: s.enterOtp,
          desc: s.otpDesc,
          onTap: () {
            Navigator.pop(context);
            final rentalId = rental['rental_id'];
            showUnlockFlow(context, rentalId);
          },
        ),

        const SizedBox(height: 12),

        // QR option
        _MethodCard(
          icon: Icons.qr_code_scanner_rounded,
          color: _kPurple,
          title: s.scanQr,
          desc: s.qrDesc,
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/qr-scanner', arguments: rental);
          },
        ),
      ]),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   desc;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
            style: GoogleFonts.syne(
              fontSize: 15, fontWeight: FontWeight.w700, color: _kText)),
          const SizedBox(height: 3),
          Text(desc,
            style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: _kMuted, size: 20),
      ]),
    ),
  );
}
