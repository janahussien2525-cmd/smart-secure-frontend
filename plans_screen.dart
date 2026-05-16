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
const _kPurple  = Color(0xFF7B8FFF);
const _kText    = Color(0xFFEEF0F6);
const _kMuted   = Color(0xFF6A7090);
const _kBorder  = Color(0x18FFFFFF);
const _kRed     = Color(0xFFE05A7A);

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});
  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  bool    _loading = true;
  String  _currentPlan  = 'free';
  String? _expiresAt;
  String? _billingCycle;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<String> _getToken() => AuthService.getToken();

  Future<void> _loadSubscription() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$_base/subscription'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _currentPlan  = body['plan']          ?? 'free';
          _expiresAt    = body['expires_at'];
          _billingCycle = body['billing_cycle'];
          _loading      = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _subscribe(String plan, String billingCycle) async {
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse('$_base/subscription'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'plan': plan, 'billing_cycle': billingCycle}),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _currentPlan  = body['plan'];
          _expiresAt    = body['expires_at'];
          _billingCycle = body['billing_cycle'];
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.s.subscribedSuccess, style: GoogleFonts.syne(color: Colors.white)),
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
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _showSubscribeDialog(String plan) {
    String selectedCycle = 'day';
    final s = context.s;
    final isStandard = plan == 'standard';
    final planName   = isStandard ? s.planNameStandard : s.planNamePremium;
    final dayPrice   = isStandard ? 'EGP 50'  : 'EGP 100';
    final monthPrice = isStandard ? 'EGP 300' : 'EGP 600';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: _kCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.billingCycle,
              style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: _kText)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(planName, style: GoogleFonts.dmSans(color: _kMuted, fontSize: 13)),
            const SizedBox(height: 16),
            Row(children: [
              _CycleOption(
                label: s.billingDay,   price: dayPrice,
                selected: selectedCycle == 'day',
                onTap: () => setDlg(() => selectedCycle = 'day'),
              ),
              const SizedBox(width: 10),
              _CycleOption(
                label: s.billingMonth, price: monthPrice,
                selected: selectedCycle == 'month',
                onTap: () => setDlg(() => selectedCycle = 'month'),
              ),
            ]),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel, style: GoogleFonts.syne(color: _kMuted)),
            ),
            TextButton(
              onPressed: () { Navigator.pop(ctx); _subscribe(plan, selectedCycle); },
              child: Text(s.subscribeBtn,
                  style: GoogleFonts.syne(color: _kAccent, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatExpiry(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _planDisplayName(AppStrings s) {
    switch (_currentPlan) {
      case 'standard': return s.planNameStandard;
      case 'premium':  return s.planNamePremium;
      default:         return s.planNameFree;
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
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
          decoration: const BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: const Color(0xFF4F5774),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: _kText, size: 16),
              ),
            ),
            const SizedBox(width: 14),
            Text(s.plansAndPricing,
                style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
          ]),
        ),

        // ── CONTENT ───────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2))
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, bottom + 24),
                  child: Column(children: [

                    // Current plan banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F5774), Color(0xFF0C1020)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.workspace_premium_rounded, color: _kAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(s.currentPlan,
                              style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
                        ]),
                        const SizedBox(height: 8),
                        Text(_planDisplayName(s),
                            style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w800, color: _kText)),
                        const SizedBox(height: 4),
                        if (_expiresAt != null) ...[
                          if (_billingCycle != null)
                            Text(
                              _billingCycle == 'day' ? s.billingDay : s.billingMonth,
                              style: GoogleFonts.dmSans(fontSize: 11, color: _kAccent),
                            ),
                          const SizedBox(height: 2),
                          Text('${s.planExpires}: ${_formatExpiry(_expiresAt)}',
                              style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
                        ] else
                          Text(s.payPerUse,
                              style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
                      ]),
                    ),

                    const SizedBox(height: 28),
                    Text(s.availablePlans,
                        style: GoogleFonts.syne(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: _kMuted, letterSpacing: 1.5)),
                    const SizedBox(height: 14),

                    // ── FREE ──
                    _PlanCard(
                      name:        s.planNameFree,
                      priceLine:   'EGP 0',
                      color:       _kGreen,
                      isCurrent:   _currentPlan == 'free',
                      features: [
                        _Feature(s.featureLessThan4h,          true),
                        _Feature(s.feature1LockerPerLocation,  true),
                        _Feature(s.featureMax3Locations,       true),
                        _Feature(s.featurePayPerUse,           true),
                        _Feature(s.featureTimeExtension,       false),
                      ],
                      buttonLabel: s.planCurrentBtn,
                      onTap:       null,
                    ),

                    const SizedBox(height: 14),

                    // ── STANDARD ──
                    _PlanCard(
                      name:        s.planNameStandard,
                      priceLine:   '50 EGP / Day  ·  300 EGP / Month',
                      color:       _kPurple,
                      isCurrent:   _currentPlan == 'standard',
                      badge:       s.popular,
                      features: [
                        _Feature(s.featureMoreThan4h,            true),
                        _Feature(s.featureDailyMonthlyAccess,    true),
                        _Feature(s.feature2LockersPerLocation,   true),
                        _Feature(s.featureTimeExtension,         true),
                        _Feature(s.featureBookingHistory,        true),
                      ],
                      buttonLabel: _currentPlan == 'standard' ? s.planCurrentBtn : s.subscribeBtn,
                      onTap: _currentPlan == 'standard'
                          ? null
                          : () => _showSubscribeDialog('standard'),
                    ),

                    const SizedBox(height: 14),

                    // ── PREMIUM ──
                    _PlanCard(
                      name:        s.planNamePremium,
                      priceLine:   '100 EGP / Day  ·  600 EGP / Month',
                      color:       _kAccent,
                      isCurrent:   _currentPlan == 'premium',
                      badge:       s.bestValue,
                      features: [
                        _Feature(s.featureUnlimitedHours,   true),
                        _Feature(s.featureUnlimitedLockers, true),
                        _Feature(s.featureSmartCamera,      true),
                        _Feature(s.featureLiveMonitoring,   true),
                        _Feature(s.featureMotionDetection,  true),
                      ],
                      buttonLabel: _currentPlan == 'premium' ? s.planCurrentBtn : s.subscribeBtn,
                      onTap: _currentPlan == 'premium'
                          ? null
                          : () => _showSubscribeDialog('premium'),
                    ),
                  ]),
                ),
        ),
      ]),
    );
  }
}

// ── BILLING CYCLE OPTION ──────────────────────────────────
class _CycleOption extends StatelessWidget {
  final String label, price;
  final bool   selected;
  final VoidCallback onTap;
  const _CycleOption({
    required this.label, required this.price,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _kAccent.withValues(alpha: 0.15) : const Color(0xFF4F5774),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _kAccent : Colors.transparent),
        ),
        child: Column(children: [
          Text(label,
              style: GoogleFonts.syne(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: selected ? _kAccent : _kMuted)),
          const SizedBox(height: 4),
          Text(price,
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: selected ? _kText : _kMuted)),
        ]),
      ),
    ),
  );
}

// ── PLAN CARD ─────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final String  name, priceLine, buttonLabel;
  final Color   color;
  final bool    isCurrent;
  final String? badge;
  final List<_Feature> features;
  final VoidCallback?  onTap;

  const _PlanCard({
    required this.name, required this.priceLine, required this.color,
    required this.isCurrent, required this.features,
    required this.buttonLabel, this.badge, this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: isCurrent ? color.withValues(alpha: 0.4) : _kBorder,
          width: isCurrent ? 1.5 : 1),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Row(children: [
        Expanded(child: Row(children: [
          Text(name,
              style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w800, color: _kText)),
          if (isCurrent) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(context.s.planActive,
                  style: GoogleFonts.syne(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
            ),
          ],
          if (badge != null && !isCurrent) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
              child: Text(badge!,
                  style: GoogleFonts.syne(fontSize: 9, fontWeight: FontWeight.w700, color: _kBg)),
            ),
          ],
        ])),
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.workspace_premium_rounded, color: color, size: 22),
        ),
      ]),

      const SizedBox(height: 10),
      Text(priceLine, style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
      const SizedBox(height: 14),
      Container(height: 1, color: _kBorder),
      const SizedBox(height: 14),

      ...features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(
            f.included ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: f.included ? color : _kMuted.withValues(alpha: 0.4),
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(f.label,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: f.included ? _kText : _kMuted.withValues(alpha: 0.5))),
        ]),
      )),

      const SizedBox(height: 16),

      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity, height: 46,
          decoration: BoxDecoration(
            gradient: (!isCurrent && onTap != null)
                ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
                : null,
            color: isCurrent ? color.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(999),
            border: isCurrent ? Border.all(color: color.withValues(alpha: 0.3)) : null,
          ),
          child: Center(
            child: Text(buttonLabel,
                style: GoogleFonts.syne(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: isCurrent ? color : _kBg)),
          ),
        ),
      ),
    ]),
  );
}

class _Feature {
  final String label;
  final bool   included;
  const _Feature(this.label, this.included);
}
