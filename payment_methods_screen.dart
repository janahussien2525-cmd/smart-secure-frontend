import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';
import 'l10n/strings.dart';
import 'add_card_screen.dart'; // ← FIXED: direct import

const String _base = kIsWeb
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

const _kBg      = Color(0xFF2E3449);
const _kSurface = Color(0xFF434A64);
const _kCard    = Color(0xFF394057);
const _kAccent  = Color(0xFFF5A623);
const _kGreen   = Color(0xFF00C9A7);
const _kRed     = Color(0xFFE05A7A);
const _kText    = Color(0xFFEEF0F6);
const _kMuted   = Color(0xFF6A7090);
const _kBorder  = Color(0x18FFFFFF);

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  Future<String> _getToken() => AuthService.getToken();

  Future<void> _fetchCards() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$_base/payment-methods'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _cards = List<Map<String, dynamic>>.from(
              body['payment_methods'] ?? []);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _removeCard(int cardId) async {
    final s = context.s;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.confirmRemoveCard,
            style: GoogleFonts.syne(
                fontWeight: FontWeight.w700, color: _kText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(s.cancel, style: GoogleFonts.syne(color: _kMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.removeCard,
                style: GoogleFonts.syne(
                    color: _kRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final token = await _getToken();
      final res = await http.delete(
        Uri.parse('$_base/payment-methods/$cardId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.s.cardRemovedSuccessfully,
              style: GoogleFonts.syne(color: Colors.white)),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
        _fetchCards();
      }
    } catch (_) {}
  }

  Future<void> _setDefault(int cardId) async {
    try {
      final token = await _getToken();
      await http.put(
        Uri.parse('$_base/payment-methods/$cardId/default'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      _fetchCards();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s      = context.s;
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        // ── Header ────────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
          decoration: const BoxDecoration(
            color: _kCard,
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F5774),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _kText, size: 16),
              ),
            ),
            const SizedBox(width: 14),
            Text(s.paymentMethods,
                style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kText)),
          ]),
        ),

        // ── Body ──────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: _kAccent, strokeWidth: 2))
              : RefreshIndicator(
                  color: _kAccent,
                  backgroundColor: _kCard,
                  onRefresh: _fetchCards,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        EdgeInsets.fromLTRB(20, 24, 20, bottom + 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Empty state
                        if (_cards.isEmpty) ...[
                          Center(
                            child: Column(children: [
                              const SizedBox(height: 40),
                              Container(
                                width: 80, height: 80,
                                decoration: const BoxDecoration(
                                    color: _kSurface,
                                    shape: BoxShape.circle),
                                child: const Icon(
                                    Icons.credit_card_off_rounded,
                                    color: _kMuted,
                                    size: 38),
                              ),
                              const SizedBox(height: 20),
                              Text(s.noSavedCards,
                                  style: GoogleFonts.syne(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _kText)),
                              const SizedBox(height: 8),
                              Text(s.noSavedCardsDesc,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13, color: _kMuted),
                                  textAlign: TextAlign.center),
                            ]),
                          ),
                        ] else ...[
                          Text(s.savedCards,
                              style: GoogleFonts.syne(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _kMuted,
                                  letterSpacing: 1.5)),
                          const SizedBox(height: 14),
                          ..._cards.map((card) => _CardTile(
                                card: card,
                                onRemove: () =>
                                    _removeCard(card['id'] as int),
                                onSetDefault:
                                    card['is_default'] == true
                                        ? null
                                        : () => _setDefault(
                                            card['id'] as int),
                              )),
                        ],

                        const SizedBox(height: 24),

                        // ── Add new card (FIXED: Navigator.push) ─────────
                        GestureDetector(
                          onTap: () async {
                            final added = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddCardScreen(),
                              ),
                            );
                            if (added == true && mounted) _fetchCards();
                          },
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: _kSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      _kAccent.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_card_rounded,
                                    color: _kAccent, size: 20),
                                const SizedBox(width: 10),
                                Text(s.addNewCard,
                                    style: GoogleFonts.syne(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _kAccent)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Info note ─────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _kSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _kBorder),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: _kMuted, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.penaltyAutoChargeNote,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12, color: _kMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

// ── Card Tile ─────────────────────────────────────────────────────────────────

class _CardTile extends StatelessWidget {
  final Map<String, dynamic> card;
  final VoidCallback onRemove;
  final VoidCallback? onSetDefault;
  const _CardTile(
      {required this.card,
      required this.onRemove,
      this.onSetDefault});

  @override
  Widget build(BuildContext context) {
    final s         = context.s;
    final brand     = card['card_brand'] as String? ?? 'Card';
    final last4     = card['card_last4'] as String? ?? '••••';
    final month     =
        card['expiry_month']?.toString().padLeft(2, '0') ?? '••';
    final year =
        card['expiry_year']?.toString().substring(2) ?? '••';
    final isDefault = card['is_default'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDefault ? _kAccent.withValues(alpha: 0.4) : _kBorder,
          width: isDefault ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // Card icon
        Container(
          width: 50, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F5774), Color(0xFF0C1020)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder),
          ),
          child: Center(
            child: Text(
              brand
                  .substring(0, brand.length.clamp(0, 4))
                  .toUpperCase(),
              style: GoogleFonts.syne(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: _kText),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Card info
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Text(s.cardLabel(brand, last4),
                  style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kText)),
              if (isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: _kAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(s.defaultCard,
                      style: GoogleFonts.syne(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _kAccent)),
                ),
              ],
            ]),
            const SizedBox(height: 3),
            Text('$month/$year',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: _kMuted)),
          ]),
        ),

        // Actions
        if (onSetDefault != null)
          GestureDetector(
            onTap: onSetDefault,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                    color: _kAccent.withValues(alpha: 0.3)),
              ),
              child: Text(s.setAsDefault,
                  style: GoogleFonts.syne(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kAccent)),
            ),
          ),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(99),
              border:
                  Border.all(color: _kRed.withValues(alpha: 0.3)),
            ),
            child: Text(s.removeCard,
                style: GoogleFonts.syne(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kRed)),
          ),
        ),
      ]),
    );
  }
}