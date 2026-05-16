import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: unused_import
import 'app_state.dart';
import 'auth_service.dart';
import 'l10n/strings.dart';

const String _base = kIsWeb
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  bool _loading  = true;
  double _balance = 0;
  List  _transactions = [];
  String _prefillAmount = '';

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchWallet();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<String> _getToken() => AuthService.getToken();

  Future<void> _fetchWallet() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      final balRes = await http.get(Uri.parse('$_base/wallet'),
          headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
      final notifRes = await http.get(Uri.parse('$_base/notifications'),
          headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
      if (balRes.statusCode == 200) {
        final balJson = jsonDecode(balRes.body);
        setState(() => _balance = double.tryParse(balJson['balance']?.toString() ?? '0') ?? 0);
      }
      if (notifRes.statusCode == 200) {
        final notifJson = jsonDecode(notifRes.body);
        setState(() => _transactions = (notifJson['notifications'] as List?) ?? []);
      }
      setState(() => _loading = false);
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF2E3449),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF5A623), strokeWidth: 2))
          : Column(children: [

              // ── HEADER + BALANCE CARD ──────────────────
              Container(
                padding: EdgeInsets.fromLTRB(20, top + 16, 20, 28),
                decoration: const BoxDecoration(
                  color: Color(0xFF394057),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(children: [

                  // Nav row
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: const Color(0xFF4F5774), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFEEF0F6), size: 16),
                      ),
                    ),
                    const Spacer(),
                    Text(s.wallet, style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6))),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ]),

                  const SizedBox(height: 28),

                  // Balance display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A2E48), Color(0xFF0E1820)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF5A623).withValues(alpha: 0.2)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.wallet, color: Color(0xFFF5A623), size: 20),
                        const SizedBox(width: 8),
                        Text(s.availableBalance, style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6A7090))),
                      ]),
                      const SizedBox(height: 10),
                      Text('EGP ${_balance.toStringAsFixed(2)}',
                        style: GoogleFonts.syne(fontSize: 36, fontWeight: FontWeight.w800, color: const Color(0xFFEEF0F6))),
                      const SizedBox(height: 6),
                      Text(s.smartSecureWallet, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF3A4060))),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  // Quick top-up amounts
                  Row(children: [
                    _QuickAmount(amount: 10, onTap: () => _showTopUpSheet(prefill: '10')),
                    const SizedBox(width: 8),
                    _QuickAmount(amount: 25, onTap: () => _showTopUpSheet(prefill: '25')),
                    const SizedBox(width: 8),
                    _QuickAmount(amount: 50, onTap: () => _showTopUpSheet(prefill: '50')),
                    const SizedBox(width: 8),
                    _QuickAmount(amount: 100, onTap: () => _showTopUpSheet(prefill: '100')),
                  ]),
                ]),
              ),

              // ── TABS ──────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                decoration: BoxDecoration(
                  color: const Color(0xFF434A64),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    color: const Color(0xFFF5A623),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle:    GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w500),
                  labelColor:         const Color(0xFF2E3449),
                  unselectedLabelColor: const Color(0xFF6A7090),
                  tabs: [Tab(text: s.historyTab), Tab(text: s.topUp)],
                ),
              ),

              // ── TAB CONTENT ──────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [

                    // History tab
                    _transactions.isEmpty
                        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.receipt_long_outlined, color: Color(0xFF6A7090), size: 48),
                            const SizedBox(height: 12),
                            Text(s.noTransactions, style: GoogleFonts.syne(color: const Color(0xFF6A7090), fontSize: 14)),
                          ]))
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
                            itemCount: _transactions.length,
                            itemBuilder: (_, i) => _TransactionTile(tx: _transactions[i] as Map<String, dynamic>),
                          ),

                    // Top Up tab
                    SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
                      child: _TopUpForm(
                        prefill: _prefillAmount,
                        onSuccess: (amount) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.walletToppedUpAmount(amount),
                                style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.w600)),
                              backgroundColor: const Color(0xFF00C9A7),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          _tabCtrl.animateTo(0);
                          _fetchWallet();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ]),
    );
  }

  void _showTopUpSheet({String prefill = ''}) {
    setState(() => _prefillAmount = prefill);
    _tabCtrl.animateTo(1);
  }
}

// ── QUICK AMOUNT BUTTON ───────────────────────────────────
class _QuickAmount extends StatelessWidget {
  final int amount;
  final VoidCallback onTap;
  const _QuickAmount({required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5A623).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF5A623).withValues(alpha: 0.25)),
        ),
        child: Center(child: Text('+EGP $amount',
          style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFF5A623)))),
      ),
    ),
  );
}

// ── TRANSACTION TILE ──────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final message = tx['message'] as String? ?? '';
    final isTopUp    = message.contains('topped up');
    final isRefund   = message.contains('refunded') || message.contains('cancelled');
    final isBooking  = message.contains('Booking confirmed');

    final Color color;
    final IconData icon;
    if (isTopUp) {
      color = const Color(0xFF00C9A7);
      icon  = Icons.add_circle_outline_rounded;
    } else if (isRefund) {
      color = const Color(0xFF7B8FFF);
      icon  = Icons.undo_rounded;
    } else if (isBooking) {
      color = const Color(0xFFF5A623);
      icon  = Icons.lock_outline_rounded;
    } else {
      color = const Color(0xFF6A7090);
      icon  = Icons.notifications_outlined;
    }

    // Extract first dollar amount from message for display
    final amountMatch = RegExp(r'EGP\s*([\d.]+)').firstMatch(message);
    final amountStr = amountMatch != null ? 'EGP ${amountMatch.group(1)}' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF434A64),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message,
            style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFEEF0F6)),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(_formatDate(tx['sent_at']), style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6A7090))),
        ])),
        // ignore: unnecessary_null_comparison
        if (amountStr != null && amountStr.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            isTopUp || isRefund ? '+$amountStr' : amountStr,
            style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ]),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── TOP UP FORM ───────────────────────────────────────────
class _TopUpForm extends StatefulWidget {
  final Function(double amount) onSuccess;
  final String prefill;
  const _TopUpForm({required this.onSuccess, this.prefill = ''});
  @override
  State<_TopUpForm> createState() => _TopUpFormState();
}

class _TopUpFormState extends State<_TopUpForm> {
  final _amountCtrl = TextEditingController();
  final _cardCtrl   = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl    = TextEditingController();
  bool  _saving     = false;
  String? _error;
  int   _selectedPreset = -1;

  final List<int> _presets = [10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    if (widget.prefill.isNotEmpty) {
      _amountCtrl.text = widget.prefill;
      final idx = _presets.indexOf(int.tryParse(widget.prefill) ?? -1);
      _selectedPreset = idx;
    }
  }

  @override
  void didUpdateWidget(_TopUpForm old) {
    super.didUpdateWidget(old);
    if (widget.prefill != old.prefill && widget.prefill.isNotEmpty) {
      _amountCtrl.text = widget.prefill;
      final idx = _presets.indexOf(int.tryParse(widget.prefill) ?? -1);
      setState(() => _selectedPreset = idx);
    }
  }

  Future<void> _submit() async {
    final s = context.s;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = s.enterValidAmount);
      return;
    }
    if (_cardCtrl.text.trim().isEmpty) {
      setState(() => _error = s.enterCardNumber);
      return;
    }
    if (_expiryCtrl.text.trim().length < 5) {
      setState(() => _error = s.enterExpiry);
      return;
    }
    final expiryParts = _expiryCtrl.text.split('/');
    final expiryMonth = int.tryParse(expiryParts[0]) ?? 0;
    final expiryYear  = int.tryParse(expiryParts.length > 1 ? '20${expiryParts[1].trim()}' : '0') ?? 0;
    final now = DateTime.now();
    if (expiryMonth < 1 || expiryMonth > 12 ||
        expiryYear < now.year ||
        (expiryYear == now.year && expiryMonth < now.month)) {
      setState(() => _error = s.cardExpired);
      return;
    }
    if (_cvvCtrl.text.trim().isEmpty) {
      setState(() => _error = s.enterCvv);
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final token = await AuthService.getToken();
      final res = await http.post(
        Uri.parse('$_base/wallet/topup'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'amount': amount}),
      ).timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (res.statusCode == 200 && mounted) {
        setState(() => _saving = false);
        widget.onSuccess(amount);
        _amountCtrl.clear();
        _cardCtrl.clear();
        _expiryCtrl.clear();
        _cvvCtrl.clear();
      } else {
        setState(() { _saving = false; _error = json['message'] ?? context.s.topUpFailed; });
      }
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Cannot connect to server.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Text(s.selectAmount, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6))),
      const SizedBox(height: 12),

      // Preset amounts
      Row(children: List.generate(_presets.length, (i) {
        final sel = _selectedPreset == i;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() { _selectedPreset = i; _amountCtrl.text = _presets[i].toString(); });
            },
            child: Container(
              margin: EdgeInsets.only(right: i < _presets.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFFF5A623) : const Color(0xFF434A64),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? const Color(0xFFF5A623) : const Color(0x18FFFFFF)),
              ),
              child: Center(child: Text('EGP ${_presets[i]}',
                style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700,
                  color: sel ? const Color(0xFF2E3449) : const Color(0xFFEEF0F6)))),
            ),
          ),
        );
      })),

      const SizedBox(height: 16),

      // Custom amount
      _FormField(controller: _amountCtrl, label: s.customAmountLabel, icon: Icons.attach_money_rounded, keyboardType: TextInputType.number,
        onChanged: (_) => setState(() => _selectedPreset = -1)),

      const SizedBox(height: 24),

      Text(s.cardDetails, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6))),
      const SizedBox(height: 12),

      _FormField(controller: _cardCtrl, label: s.cardNumber, icon: Icons.credit_card_rounded, keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)]),
      const SizedBox(height: 12),

      Row(children: [
        Expanded(child: _FormField(
          controller: _expiryCtrl,
          label: s.expiryDate,
          icon: Icons.calendar_today_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [_ExpiryFormatter()],
        )),
        const SizedBox(width: 12),
        Expanded(child: _FormField(
          controller: _cvvCtrl,
          label: s.cvv,
          icon: Icons.lock_outline_rounded,
          obscure: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
        )),
      ]),

      if (_error != null) ...[
        const SizedBox(height: 10),
        Text(_error!, style: GoogleFonts.dmSans(color: const Color(0xFFE05A7A), fontSize: 13)),
      ],

      const SizedBox(height: 24),

      GestureDetector(
        onTap: _saving ? null : _submit,
        child: Container(
          width: double.infinity, height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [BoxShadow(color: const Color(0xFFF5A623).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Center(child: _saving
              ? const CircularProgressIndicator(color: Color(0xFF2E3449), strokeWidth: 2)
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_rounded, color: Color(0xFF2E3449), size: 20),
                  const SizedBox(width: 8),
                  Text(s.addFunds, style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF2E3449))),
                ])),
        ),
      ),

      const SizedBox(height: 12),

      Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_outline_rounded, color: Color(0xFF6A7090), size: 13),
        const SizedBox(width: 5),
        Text(s.securedPayment, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6A7090))),
      ])),
    ]);
  }
}

// ── FORM FIELD ────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    onChanged: onChanged,
    inputFormatters: inputFormatters,
    style: GoogleFonts.dmSans(color: const Color(0xFFEEF0F6), fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.dmSans(color: const Color(0xFF6A7090), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF6A7090), size: 18),
      filled: true,
      fillColor: const Color(0xFF4F5774),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x18FFFFFF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x18FFFFFF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFF5A623), width: 1.5)),
    ),
  );
}

// ── EXPIRY FORMATTER ──────────────────────────────────────
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    var text = next.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 4) text = text.substring(0, 4);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return next.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}