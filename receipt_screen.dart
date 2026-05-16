import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';
// ignore: unused_import
import 'unlock_service.dart';
import 'unlock_method_sheet.dart';
import 'l10n/strings.dart';

const String _rBase = kIsWeb
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

const _kBg      = Color(0xFF2E3449);
const _kCard    = Color(0xFF394057);
const _kSurface = Color(0xFF434A64);
const _kAccent  = Color(0xFFF5A623);
const _kGreen   = Color(0xFF00C9A7);
const _kRed     = Color(0xFFE05A7A);
const _kPurple  = Color(0xFF7B8FFF);
const _kText    = Color(0xFFEEF0F6);
const _kMuted   = Color(0xFF6A7090);
const _kBorder  = Color(0x18FFFFFF);

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});
  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late Map<String, dynamic> _rental;
  bool _initialized = false;
  bool _delegating  = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _rental      = Map<String, dynamic>.from(
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>);
      _initialized = true;
    }
  }

  Future<void> _showShareDialog() async {
    final s = context.s;
    final ctrl = TextEditingController();
    final existingPhone = _rental['delegate_phone'] as String?;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: _kCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.shareLockerAccess,
              style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: _kText)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (existingPhone != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: _kGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.currentlySharedWith(existingPhone),
                      style: GoogleFonts.dmSans(fontSize: 12, color: _kText))),
                ]),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _delegateAccess(null);
                },
                icon: const Icon(Icons.cancel_rounded, color: _kRed, size: 16),
                label: Text(s.revokeAccess, style: GoogleFonts.syne(color: _kRed, fontWeight: FontWeight.w700)),
              ),
              const Divider(color: _kBorder),
              Text(s.shareWithDifferent, style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
              const SizedBox(height: 8),
            ] else ...[
              Text(s.enterFriendPhone,
                  style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.syne(color: _kText),
              decoration: InputDecoration(
                hintText: s.phoneHint,
                hintStyle: GoogleFonts.dmSans(color: _kMuted),
                prefixIcon: const Icon(Icons.phone_rounded, color: _kMuted, size: 18),
                filled: true,
                fillColor: _kSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kAccent),
                ),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel, style: GoogleFonts.syne(color: _kMuted)),
            ),
            TextButton(
              onPressed: () async {
                final phone = ctrl.text.trim();
                if (phone.isEmpty) return;
                Navigator.pop(ctx);
                await _delegateAccess(phone);
              },
              child: Text(s.share, style: GoogleFonts.syne(color: _kAccent, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _delegateAccess(String? phone) async {
    setState(() => _delegating = true);
    try {
      final token = await AuthService.getToken();
      final res = await http.put(
        Uri.parse('$_rBase/rentals/${_rental['rental_id']}/delegate'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'delegate_phone': phone}),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() => _rental = {..._rental, 'delegate_phone': phone});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body['message'] ?? 'Done.', style: GoogleFonts.syne(color: Colors.white)),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body['message'] ?? 'Failed.', style: GoogleFonts.syne(color: Colors.white)),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.s.connectionError, style: GoogleFonts.syne(color: Colors.white)),
        backgroundColor: _kRed, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      }
    } finally {
      if (mounted) setState(() => _delegating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();

    final s = context.s;
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    final status = _rental['status'] as String? ?? 'unknown';
    final Color statusColor = {
      'active':    _kGreen,
      'completed': _kMuted,
      'cancelled': _kRed,
      'overdue':   _kRed,
    }[status] ?? _kMuted;

    final amount       = double.tryParse(_rental['total_amount']?.toString() ?? '0') ?? 0;
    final canDelegate  = status == 'active' || status == 'overdue';
    final isDelegated  = _rental['is_delegated'] == true;
    final delegatePhone = _rental['delegate_phone'] as String?;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [

        // Header
        Container(
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
          decoration: const BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFF4F5774), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: _kText, size: 16),
              ),
            ),
            const SizedBox(width: 14),
            Text(s.receiptTitle, style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
          ]),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 24, 20, bottom + 24),
            child: Column(children: [

              // Amount circle
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('EGP ${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: statusColor)),
                  Text(status[0].toUpperCase() + status.substring(1),
                    style: GoogleFonts.dmSans(fontSize: 11, color: statusColor)),
                ]),
              ),
              const SizedBox(height: 24),

              // Access code box (only for active/overdue)
              if (canDelegate) ...[
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _rental['locker_code'] ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(s.accessCodeCopied, style: GoogleFonts.syne(color: Colors.white)),
                      backgroundColor: _kGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kAccent.withValues(alpha: 0.4)),
                    ),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.key_rounded, color: _kAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(s.accessCode, style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w700, color: _kAccent, letterSpacing: 1.5)),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy_rounded, color: _kAccent, size: 13),
                      ]),
                      const SizedBox(height: 8),
                      Text(_rental['locker_code'] ?? '—',
                        style: GoogleFonts.syne(fontSize: 36, fontWeight: FontWeight.w800, color: _kAccent, letterSpacing: 6)),
                      Text(s.tapToCopy, style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Unlock Locker button
                GestureDetector(
                  onTap: () => showUnlockMethodSheet(context, _rental),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kGreen, Color(0xFF00A88F)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.lock_open_rounded, color: _kBg, size: 16),
                      const SizedBox(width: 8),
                      Text(s.unlockLockerBtn, style: GoogleFonts.syne(
                          fontSize: 14, fontWeight: FontWeight.w800, color: _kBg)),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),

                // Share Access button (not shown for delegated rentals)
                if (!isDelegated) ...[
                  GestureDetector(
                    onTap: _delegating ? null : _showShareDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _delegating
                            ? _kPurple.withValues(alpha: 0.05)
                            : _kPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kPurple.withValues(alpha: 0.35)),
                      ),
                      child: _delegating
                          ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _kPurple, strokeWidth: 2)))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.person_add_rounded, color: _kPurple, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                delegatePhone != null
                                    ? s.sharedWithEdit(delegatePhone)
                                    : s.shareAccessWithFriend,
                                style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: _kPurple),
                              ),
                            ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Delegated badge (shown when viewing a rental shared with you)
                if (isDelegated) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _kPurple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kPurple.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.people_rounded, color: _kPurple, size: 16),
                      const SizedBox(width: 8),
                      Text(s.sharedWithYou,
                          style: GoogleFonts.dmSans(fontSize: 12, color: _kPurple)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              // Details card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(children: [
                  _ReceiptRow(label: s.locLocation,    value: _rental['location_name'] ?? '—'),
                  _Divider(),
                  _ReceiptRow(label: s.locAddress,     value: _rental['address'] ?? _rental['location_address'] ?? '—'),
                  _Divider(),
                  _ReceiptRow(label: s.lockerCodeLabel, value: _rental['locker_code'] ?? '—', bold: true),
                  _Divider(),
                  _ReceiptRow(label: s.sizeLabel,      value: _rental['locker_size'] ?? '—'),
                  _Divider(),
                  _ReceiptRow(label: s.start,          value: _formatDt(_rental['start_time'])),
                  _Divider(),
                  _ReceiptRow(label: s.end,            value: _formatDt(_rental['end_time'])),
                  _Divider(),
                  _ReceiptRow(label: s.statusLabel,    value: status[0].toUpperCase() + status.substring(1), valueColor: statusColor),
                  _Divider(),
                  _ReceiptRow(label: s.totalPaid,      value: 'EGP ${amount.toStringAsFixed(2)}', bold: true, valueColor: _kAccent),
                ]),
              ),

              const SizedBox(height: 16),

              // Booking ID
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(s.bookingId, style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
                  Text('#${_rental['rental_id'] ?? '—'}',
                    style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: _kText)),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  String _formatDt(dynamic raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return '—';
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year}  $h:$m';
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label, value;
  final bool   bold;
  final Color? valueColor;
  const _ReceiptRow({required this.label, required this.value, this.bold = false, this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted))),
      Expanded(child: Text(
        value,
        style: GoogleFonts.syne(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: valueColor ?? _kText,
        ),
        textAlign: TextAlign.end,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      )),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(height: 1, color: _kBorder);
}
