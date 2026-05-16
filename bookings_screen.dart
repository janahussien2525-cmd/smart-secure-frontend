import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'auth_service.dart';
import 'l10n/strings.dart';

const String _base = kIsWeb
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

const _kBg      = Color(0xFF2E3449);
const _kSurface = Color(0xFF434A64);
const _kCard    = Color(0xFF394057);
const _kAccent  = Color(0xFFF5A623);
const _kGreen   = Color(0xFF00C9A7);
const _kRed     = Color(0xFFE05A7A);
const _kPurple  = Color(0xFF7B8FFF);
const _kText    = Color(0xFFEEF0F6);
const _kMuted   = Color(0xFF6A7090);
const _kBorder  = Color(0x18FFFFFF);

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  bool   _loading = true;
  String? _error;
  List   _allRentals = [];
  List   _delegatedRentals = [];

  // Tab keys used for filtering (keep English)
  final List<String> _tabs = ['All', 'Active', 'Completed', 'Cancelled', 'Shared'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _fetchRentals();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<String> _getToken() => AuthService.getToken();

  Future<void> _fetchRentals() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await _getToken();
      final results = await Future.wait([
        http.get(Uri.parse('$_base/rentals'),          headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('$_base/rentals/delegated'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10)),
      ]);

      final res  = results[0];
      final resD = results[1];

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final delegBody = resD.statusCode == 200 ? jsonDecode(resD.body) : <String, dynamic>{};
        setState(() {
          _allRentals       = body['rentals'] as List;
          _delegatedRentals = (delegBody['rentals'] as List?) ?? [];
          _loading          = false;
        });
      } else {
        setState(() { _loading = false; _error = context.s.failedToLoadBookings; });
      }
    } catch (_) {
      setState(() { _loading = false; _error = context.s.cannotConnect; });
    }
  }

  Future<void> _cancelRental(Map<String, dynamic> rental) async {
    final s = context.s;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.cancelBooking, style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: _kText)),
        content: Text(s.cancelConfirm(rental['locker_code'] ?? '', rental['location_name'] ?? ''),
          style: GoogleFonts.dmSans(color: _kMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text(s.no, style: GoogleFonts.syne(color: _kMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text(s.yesCancel, style: GoogleFonts.syne(color: _kRed, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final token = await _getToken();
      final res = await http.put(
        Uri.parse('$_base/rentals/${rental['rental_id']}/cancel'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (!mounted) return;
      if (res.statusCode == 200) {
        _fetchRentals();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.bookingCancelled, style: GoogleFonts.syne(color: Colors.white)),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body['message'] ?? s.failedToCancel, style: GoogleFonts.syne(color: Colors.white)),
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
    }
  }

  Future<void> _endRental(Map<String, dynamic> rental) async {
    final s = context.s;
    try {
      final token = await _getToken();
      final res = await http.put(
        Uri.parse('$_base/rentals/${rental['rental_id']}/end'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (!mounted) return;
      if (res.statusCode == 200) {
        _fetchRentals();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.rentalEnded, style: GoogleFonts.syne(color: Colors.white)),
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
    }
  }

  Future<void> _extendRental(Map<String, dynamic> rental) async {
    int selectedHours = 1;
    final confirmed = await showDialog<int>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: _kCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(context.s.extendRental, style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: _kText)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(rental['location_name'] ?? '', style: GoogleFonts.dmSans(color: _kMuted, fontSize: 13)),
            const SizedBox(height: 16),
            Text(context.s.howManyHours, style: GoogleFonts.dmSans(color: _kMuted, fontSize: 13)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                onPressed: () { if (selectedHours > 1) setDlg(() => selectedHours--); },
                icon: const Icon(Icons.remove_circle_outline, color: _kAccent),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF4F5774), borderRadius: BorderRadius.circular(12)),
                child: Text('$selectedHours h', style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
              ),
              IconButton(
                onPressed: () { if (selectedHours < 24) setDlg(() => selectedHours++); },
                icon: const Icon(Icons.add_circle_outline, color: _kAccent),
              ),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(context.s.cancel, style: GoogleFonts.syne(color: _kMuted))),
            TextButton(onPressed: () => Navigator.pop(ctx, selectedHours),
              child: Text(context.s.extend, style: GoogleFonts.syne(color: _kAccent, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
    if (confirmed == null || !mounted) return;
    try {
      final token = await _getToken();
      final res = await http.put(
        Uri.parse('$_base/rentals/${rental['rental_id']}/extend'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'extra_hours': confirmed}),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (!mounted) return;
      if (res.statusCode == 200) {
        _fetchRentals();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.s.extendedBy(confirmed), style: GoogleFonts.syne(color: Colors.white)),
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
    }
  }

  List _filtered(String tab) {
    if (tab == 'All')    return _allRentals;
    if (tab == 'Shared') return _delegatedRentals;
    return _allRentals.where((r) => (r['status'] as String) == tab.toLowerCase()).toList();
  }

  String _tabLabel(String key, AppStrings s) {
    switch (key) {
      case 'Active':    return s.tabActive;
      case 'Completed': return s.tabCompleted;
      case 'Cancelled': return s.tabCancelled;
      case 'Shared':    return s.tabShared;
      default:          return s.tabAll;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s      = context.s;
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [

        // ── HEADER ────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
          decoration: const BoxDecoration(color: _kCard, borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFF4F5774), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: _kText, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Text(s.bookingHistory, style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
              const Spacer(),
              GestureDetector(
                onTap: _fetchRentals,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFF4F5774), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.refresh_rounded, color: _kMuted, size: 18),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(color: _kAccent, borderRadius: BorderRadius.circular(99)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              labelStyle:         GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w500),
              labelColor:         _kBg,
              unselectedLabelColor: _kMuted,
              tabs: _tabs.map((t) {
                final label = _tabLabel(t, s);
                final count = t == 'All'
                    ? _allRentals.length
                    : t == 'Shared'
                        ? _delegatedRentals.length
                        : _allRentals.where((r) => r['status'] == t.toLowerCase()).length;
                return Tab(text: count > 0 ? '$label ($count)' : label);
              }).toList(),
            ),
            const SizedBox(height: 4),
          ]),
        ),

        // ── CONTENT ───────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2))
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _fetchRentals)
                  : TabBarView(
                      controller: _tabCtrl,
                      children: _tabs.map((tab) {
                        final list = _filtered(tab);
                        if (list.isEmpty) return _EmptyState(tab: tab);
                        return RefreshIndicator(
                          color: _kAccent,
                          backgroundColor: _kCard,
                          onRefresh: _fetchRentals,
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final r      = list[i] as Map<String, dynamic>;
                              final status = r['status'] as String? ?? '';
                              final isDelegated = r['is_delegated'] == true;
                              return _RentalCard(
                                rental: r,
                                onCancel: (status == 'active' && !isDelegated)
                                    ? () => _cancelRental(r)
                                    : null,
                                onExtend: (['active', 'overdue'].contains(status) && !isDelegated)
                                    ? () => _extendRental(r)
                                    : null,
                                onEnd: (status == 'overdue' && !isDelegated)
                                    ? () => _endRental(r)
                                    : null,
                                onTap: () => Navigator.pushNamed(context, '/receipt', arguments: r),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
        ),
      ]),
    );
  }
}

// ── RENTAL CARD ───────────────────────────────────────────
class _RentalCard extends StatelessWidget {
  final Map<String, dynamic> rental;
  final VoidCallback? onCancel;
  final VoidCallback? onExtend;
  final VoidCallback? onEnd;
  final VoidCallback? onTap;
  const _RentalCard({required this.rental, this.onCancel, this.onExtend, this.onEnd, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = rental['status'] as String? ?? 'unknown';
    final Color statusColor = {
      'active':    _kGreen,
      'completed': _kMuted,
      'cancelled': _kRed,
      'overdue':   _kRed,
    }[status] ?? _kMuted;

    final amount = double.tryParse(rental['total_amount']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status == 'active' ? _kGreen.withValues(alpha: 0.3) : _kBorder),
      ),
      child: Column(children: [

        // Top row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [

            // Icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(
                _sizeInitial(rental['locker_size'] as String? ?? '?'),
                style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800, color: statusColor),
              )),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rental['location_name'] ?? 'Unknown',
                style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: _kText),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(rental['address'] ?? '', style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Text('${context.s.codePrefix} ${rental['locker_code'] ?? '—'}',
                  style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted.withValues(alpha: 0.7))),
                const SizedBox(width: 8),
                Text('· ${rental['locker_size'] ?? ''}',
                  style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted.withValues(alpha: 0.7))),
              ]),
            ])),

            // Amount + status
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('EGP ${amount.toStringAsFixed(2)}',
                style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w800, color: _kText)),
              const SizedBox(height: 4),
              _StatusBadge(status: status, color: statusColor),
            ]),
          ]),
        ),

        // Divider
        Container(height: 1, color: _kBorder),

        // Bottom: dates + cancel button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _DateRow(icon: Icons.play_circle_outline_rounded, color: _kGreen, label: context.s.start, value: _formatDt(rental['start_time'])),
              const SizedBox(height: 4),
              _DateRow(icon: Icons.stop_circle_outlined, color: _kRed, label: context.s.end, value: _formatDt(rental['end_time'])),
            ])),
            if (onExtend != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onExtend,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _kPurple.withValues(alpha: 0.3)),
                  ),
                  child: Text(context.s.extend, style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: _kPurple)),
                ),
              ),
            ],
            if (onEnd != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEnd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
                  ),
                  child: Text(context.s.end, style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen)),
                ),
              ),
            ],
            if (onCancel != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                  ),
                  child: Text(context.s.cancel, style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: _kRed)),
                ),
              ),
            ],
          ]),
        ),
      ]),
    ),
    );
  }

  String _sizeInitial(String s) {
    if (s.toLowerCase().contains('small'))  return 'S';
    if (s.toLowerCase().contains('medium')) return 'M';
    if (s.toLowerCase().contains('large'))  return 'L';
    if (s.toLowerCase().contains('extra'))  return 'XL';
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
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

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color  color;
  const _StatusBadge({required this.status, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      context.s.rentalStatus(status),
      style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

class _DateRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label, value;
  const _DateRow({required this.icon, required this.color, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 13),
    const SizedBox(width: 5),
    Text('$label: ', style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
    Text(value, style: GoogleFonts.dmSans(fontSize: 11, color: _kText, fontWeight: FontWeight.w600)),
  ]);
}

// ── EMPTY STATE ───────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String tab;
  const _EmptyState({required this.tab});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.receipt_long_outlined, color: _kMuted, size: 52),
    const SizedBox(height: 16),
    Text(context.s.noBookings(tab == 'All' ? '' : tab),
      style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: _kText)),
    const SizedBox(height: 8),
    Text(context.s.historyWillAppear,
      style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
  ]));
}

// ── ERROR STATE ───────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.wifi_off_rounded, color: _kMuted, size: 48),
    const SizedBox(height: 16),
    Text(message, style: GoogleFonts.dmSans(fontSize: 14, color: _kMuted)),
    const SizedBox(height: 20),
    GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kAccent, Color(0xFFE8920A)]),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(context.s.retry, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: _kBg)),
      ),
    ),
  ]));
}
