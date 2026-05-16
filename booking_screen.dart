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

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  Map<String, dynamic>? _location;
  List _lockers        = [];
  bool _loadingLockers = true;
  String? _lockersError;

  // Multi-select: up to _maxLockers depending on plan
  final List<Map<String, dynamic>> _selectedLockers = [];
  String _userPlan = 'free';

  int get _maxLockers => _userPlan == 'standard' ? 2 : 1;

  DateTime _startDate = DateTime.now().add(const Duration(hours: 1));
  DateTime _endDate   = DateTime.now().add(const Duration(hours: 2));

  bool _booking = false;
  String? _bookingError;

  String _paymentType = 'wallet';
  int? _selectedCardId;
  List<Map<String, dynamic>> _savedCards  = [];
  double _walletBalance = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_location == null) {
      _location = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _fetchLockers();
      _fetchSavedCards();
      _fetchWalletBalance();
      _fetchUserPlan();
    }
  }

  Future<String> _getToken() => AuthService.getToken();

  Future<void> _fetchUserPlan() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$_base/subscription'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        setState(() => _userPlan = body['plan'] ?? 'free');
      }
    } catch (_) {}
  }

  Future<void> _fetchSavedCards() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$_base/payment-methods'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && mounted) {
        final body  = jsonDecode(res.body);
        final cards = List<Map<String, dynamic>>.from(body['payment_methods'] ?? []);
        final def   = cards.where((c) => c['is_default'] == true).toList();
        setState(() {
          _savedCards = cards;
          if (def.isNotEmpty) _selectedCardId = def.first['id'] as int?;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$_base/wallet'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        setState(() => _walletBalance =
            double.tryParse(body['balance']?.toString() ?? '0') ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _fetchLockers() async {
    setState(() { _loadingLockers = true; _lockersError = null; });
    try {
      final id  = _location!['location_id'];
      final res = await http.get(
        Uri.parse('$_base/locations/$id/lockers'),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _lockers        = body['lockers'] as List;
          _loadingLockers = false;
        });
      } else {
        setState(() { _loadingLockers = false; _lockersError = 'Failed to load lockers'; });
      }
    } catch (_) {
      setState(() { _loadingLockers = false; _lockersError = 'Cannot connect to server'; });
    }
  }

  double get _totalHours => _endDate.difference(_startDate).inMinutes / 60.0;

  double get _totalCost {
    if (_selectedLockers.isEmpty) return 0;
    final hours = _totalHours.ceil();
    return _selectedLockers.fold(0.0, (sum, lk) {
      final rate = double.tryParse(lk['price_per_hour']?.toString() ?? '0') ?? 0;
      return sum + rate * hours;
    });
  }

  bool get _isValidTime =>
      _endDate.isAfter(_startDate.add(const Duration(minutes: 30)));

  bool get _canConfirm =>
      _selectedLockers.isNotEmpty && _isValidTime;

  void _toggleLocker(Map<String, dynamic> locker) {
    setState(() {
      final id       = locker['locker_id'];
      final isSelected = _selectedLockers.any((l) => l['locker_id'] == id);
      if (isSelected) {
        _selectedLockers.removeWhere((l) => l['locker_id'] == id);
      } else if (_selectedLockers.length < _maxLockers) {
        _selectedLockers.add(locker);
      }
    });
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: _datepickerTheme,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDate),
      builder: _datepickerTheme,
    );
    if (time == null || !mounted) return;
    setState(() {
      _startDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (!_endDate.isAfter(_startDate.add(const Duration(minutes: 30)))) {
        _endDate = _startDate.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate.add(const Duration(minutes: 30)),
      lastDate: _startDate.add(const Duration(days: 30)),
      builder: _datepickerTheme,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endDate),
      builder: _datepickerTheme,
    );
    if (time == null || !mounted) return;
    setState(() =>
        _endDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Widget _datepickerTheme(BuildContext context, Widget? child) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: const ColorScheme.dark(
        primary: _kAccent, onPrimary: _kBg, surface: _kSurface, onSurface: _kText,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: _kCard),
    ),
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
      child: child!,
    ),
  );

  Future<void> _confirmBooking() async {
    if (_selectedLockers.isEmpty) {
      setState(() => _bookingError = 'Please select a locker.');
      return;
    }
    if (!_isValidTime) {
      setState(() => _bookingError = 'End time must be at least 30 minutes after start.');
      return;
    }
    setState(() { _booking = true; _bookingError = null; });
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse('$_base/rentals'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'locker_ids':  _selectedLockers.map((l) => l['locker_id']).toList(),
          'start_time':  _startDate.toIso8601String(),
          'end_time':    _endDate.toIso8601String(),
          'payment_type': _paymentType,
          if (_paymentType == 'card' && _selectedCardId != null)
            'payment_method_id': _selectedCardId,
        }),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (!mounted) return;

      if (res.statusCode == 201) {
        setState(() => _booking = false);
        _showSuccess(body);
      } else {
        setState(() { _booking = false; _bookingError = body['message'] ?? 'Booking failed.'; });
      }
    } catch (_) {
      if (mounted) setState(() { _booking = false; _bookingError = 'Cannot connect to server.'; });
    }
  }

  void _showSuccess(Map<String, dynamic> body) {
    final lockerCodes = _selectedLockers.map((l) => l['locker_code'] as String? ?? '').join(' & ');
    final totalPaid   = double.tryParse(
      (body['rentals'] as List?)
          ?.fold<double>(0, (s, r) => s + (double.tryParse(r['total_amount']?.toString() ?? '0') ?? 0))
          .toString() ??
      body['rental']?['total_amount']?.toString() ?? '0',
    )?.toStringAsFixed(2) ?? _totalCost.toStringAsFixed(2);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: _kGreen, size: 40),
          ),
          const SizedBox(height: 20),
          Text(context.s.bookingConfirmed,
              style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
          const SizedBox(height: 8),
          Text(
            'Locker${_selectedLockers.length > 1 ? 's' : ''} $lockerCodes\nat ${_location!['name']}',
            style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kSurface, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder),
            ),
            child: Column(children: [
              _SuccessRow(label: 'Start', value: _formatDt(_startDate)),
              const SizedBox(height: 8),
              _SuccessRow(label: 'End',   value: _formatDt(_endDate)),
              const SizedBox(height: 8),
              _SuccessRow(label: 'Total', value: 'EGP $totalPaid', valueColor: _kAccent),
            ]),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () { Navigator.pop(context); Navigator.pop(context); },
            child: Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kAccent, Color(0xFFE8920A)]),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(child: Text('Back to Home',
                  style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: _kBg))),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s      = context.s;
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final loc    = _location;
    final isStandard = _userPlan == 'standard';

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [

        // ── HEADER ────────────────────────────────────────
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
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.bookALocker,
                  style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
              if (loc != null)
                Text(loc['name'] ?? '',
                    style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),

        // ── CONTENT ───────────────────────────────────────
        Expanded(
          child: _loadingLockers
              ? const Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2))
              : _lockersError != null
                  ? _ErrorState(message: _lockersError!, onRetry: _fetchLockers)
                  : _lockers.isEmpty
                      ? _EmptyState(locationName: loc?['name'] ?? '')
                      : ListView(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 140),
                          children: [

                            if (loc != null) _LocationStrip(location: loc),
                            const SizedBox(height: 20),

                            // Locker selection header
                            Row(children: [
                              Expanded(child: Text(s.selectALocker,
                                  style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: _kText))),
                              // Standard plan hint badge
                              if (isStandard)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _kPurple.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(color: _kPurple.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'Select up to 2  (${_selectedLockers.length}/2)',
                                    style: GoogleFonts.dmSans(fontSize: 11, color: _kPurple, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ]),
                            const SizedBox(height: 12),

                            ..._lockers.map((lk) {
                              final locker   = lk as Map<String, dynamic>;
                              final avail    = locker['status'] == 'available';
                              final id       = locker['locker_id'];
                              final selected = _selectedLockers.any((l) => l['locker_id'] == id);
                              final canSelect = avail && (selected || _selectedLockers.length < _maxLockers);
                              return _LockerCard(
                                locker:   locker,
                                selected: selected,
                                onTap:    canSelect ? () => _toggleLocker(locker) : null,
                              );
                            }),

                            const SizedBox(height: 24),

                            Text(s.selectTime,
                                style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: _kText)),
                            const SizedBox(height: 12),

                            Row(children: [
                              Expanded(child: _TimeCard(
                                label: s.start, icon: Icons.play_circle_outline_rounded,
                                color: _kGreen, dateTime: _startDate, onTap: _pickStart,
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _TimeCard(
                                label: s.end, icon: Icons.stop_circle_outlined,
                                color: _kRed, dateTime: _endDate, onTap: _pickEnd,
                              )),
                            ]),

                            if (!_isValidTime && _selectedLockers.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('End time must be at least 30 min after start.',
                                  style: GoogleFonts.dmSans(fontSize: 12, color: _kRed)),
                            ],

                            if (_userPlan == 'free' && _totalHours > 4) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _kAccent.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _kAccent.withValues(alpha: 0.35)),
                                ),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Icon(Icons.lock_clock_rounded, color: _kAccent, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(s.freePlanLimitTitle,
                                        style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: _kAccent)),
                                    const SizedBox(height: 4),
                                    Text(s.freePlanLimitMsg,
                                        style: GoogleFonts.dmSans(fontSize: 12, color: _kText)),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(context, '/plans'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [_kAccent, Color(0xFFE8920A)]),
                                          borderRadius: BorderRadius.circular(99),
                                        ),
                                        child: Text(s.upgradePlan,
                                            style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: _kBg)),
                                      ),
                                    ),
                                  ])),
                                ]),
                              ),
                            ],

                            const SizedBox(height: 16),

                            if (_selectedLockers.isNotEmpty)
                              _CostSummary(
                                lockers:   _selectedLockers,
                                startDate: _startDate,
                                endDate:   _endDate,
                                totalCost: _totalCost,
                                hours:     _totalHours.ceil(),
                              ),

                            if (_selectedLockers.isNotEmpty) ...[
                              const SizedBox(height: 20),

                              Text(s.paymentMethod,
                                  style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w700,
                                      color: _kMuted, letterSpacing: 1.5)),
                              const SizedBox(height: 12),

                              // Wallet option
                              GestureDetector(
                                onTap: () => setState(() => _paymentType = 'wallet'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: _paymentType == 'wallet' ? _kGreen.withValues(alpha: 0.08) : _kSurface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _paymentType == 'wallet' ? _kGreen.withValues(alpha: 0.4) : _kBorder,
                                      width: _paymentType == 'wallet' ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.wallet, color: _kGreen, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(s.payFromWallet, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
                                      Text('EGP ${_walletBalance.toStringAsFixed(2)}',
                                          style: GoogleFonts.dmSans(fontSize: 11,
                                              color: _walletBalance >= _totalCost ? _kGreen : _kRed)),
                                    ])),
                                    if (_paymentType == 'wallet')
                                      const Icon(Icons.check_circle_rounded, color: _kGreen, size: 20),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 8),

                              ..._savedCards.map((card) {
                                final cardId   = card['id'] as int;
                                final brand    = card['card_brand'] as String? ?? 'Card';
                                final last4    = card['card_last4'] as String? ?? '••••';
                                final selected = _paymentType == 'card' && _selectedCardId == cardId;
                                return GestureDetector(
                                  onTap: () => setState(() { _paymentType = 'card'; _selectedCardId = cardId; }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                    decoration: BoxDecoration(
                                      color: selected ? _kAccent.withValues(alpha: 0.08) : _kSurface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: selected ? _kAccent.withValues(alpha: 0.4) : _kBorder,
                                        width: selected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(children: [
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(color: _kAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                        child: const Icon(Icons.credit_card_rounded, color: _kAccent, size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(s.cardLabel(brand, last4),
                                          style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: _kText))),
                                      if (selected)
                                        const Icon(Icons.check_circle_rounded, color: _kAccent, size: 20),
                                    ]),
                                  ),
                                );
                              }),

                              if (_paymentType == 'wallet' && _walletBalance < _totalCost && _totalCost > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _kRed.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.warning_amber_rounded, color: _kRed, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(s.insufficientWalletBalance,
                                        style: GoogleFonts.dmSans(fontSize: 12, color: _kRed))),
                                  ]),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ],

                            if (_bookingError != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _kRed.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.error_outline_rounded, color: _kRed, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_bookingError!,
                                      style: GoogleFonts.dmSans(fontSize: 13, color: _kRed))),
                                ]),
                              ),
                            ],
                          ],
                        ),
        ),
      ]),

      // ── CONFIRM BUTTON ──────────────────────────────────
      bottomNavigationBar: _lockers.isEmpty || _loadingLockers
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 16),
              decoration: const BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_selectedLockers.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(
                      _selectedLockers.length > 1
                          ? '${_selectedLockers.length} lockers'
                          : 'Total',
                      style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted),
                    ),
                    Text('EGP ${_totalCost.toStringAsFixed(2)}',
                        style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: _kAccent)),
                  ]),
                ),
                GestureDetector(
                  onTap: _booking ? null : _confirmBooking,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity, height: 54,
                    decoration: BoxDecoration(
                      gradient: _canConfirm
                          ? const LinearGradient(colors: [_kAccent, Color(0xFFE8920A)])
                          : null,
                      color: _canConfirm ? null : const Color(0xFF4F5774),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(child: _booking
                        ? const CircularProgressIndicator(color: _kBg, strokeWidth: 2)
                        : Text(s.confirmBooking,
                            style: GoogleFonts.syne(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: _canConfirm ? _kBg : _kMuted,
                            ))),
                  ),
                ),
              ]),
            ),
    );
  }

  String _formatDt(DateTime dt) {
    final d  = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m  = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'AM' : 'PM';
    return '$d/$mo/${dt.year}  $h:$m $ap';
  }
}

// ── LOCATION STRIP ────────────────────────────────────────
class _LocationStrip extends StatelessWidget {
  final Map<String, dynamic> location;
  const _LocationStrip({required this.location});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kSurface, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _kBorder),
    ),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: _kAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.location_on_rounded, color: _kAccent, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(location['name'] ?? '',
            style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: _kText)),
        const SizedBox(height: 2),
        Text(location['address'] ?? '',
            style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${location['available_lockers'] ?? 0}',
            style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800, color: _kGreen)),
        Text('available', style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted)),
      ]),
    ]),
  );
}

// ── LOCKER CARD ───────────────────────────────────────────
class _LockerCard extends StatelessWidget {
  final Map<String, dynamic> locker;
  final bool selected;
  final VoidCallback? onTap;
  const _LockerCard({required this.locker, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final avail = locker['status'] == 'available';
    final dimmed = !avail && !selected; // greyed out when unavailable and not selected
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _kAccent.withValues(alpha: 0.07) : _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _kAccent : (dimmed ? _kMuted.withValues(alpha: 0.2) : _kBorder),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [

          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: avail
                  ? (selected ? _kAccent.withValues(alpha: 0.15) : _kGreen.withValues(alpha: 0.08))
                  : _kMuted.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(
              _sizeInitial(locker['type_name'] as String? ?? '?'),
              style: GoogleFonts.syne(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: avail ? (selected ? _kAccent : _kGreen) : _kMuted,
              ),
            )),
          ),
          const SizedBox(width: 14),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(locker['type_name'] ?? '',
                  style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: _kText)),
              const SizedBox(width: 8),
              _StatusBadge(status: locker['status'] as String? ?? 'unknown'),
            ]),
            const SizedBox(height: 4),
            Text(locker['dimensions'] ?? '',
                style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
          ])),

          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              'EGP ${double.tryParse(locker['price_per_hour']?.toString() ?? '0')?.toStringAsFixed(2) ?? '—'}',
              style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w800,
                  color: avail ? _kAccent : _kMuted),
            ),
            Text('/hr', style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted)),
            if (selected) ...[
              const SizedBox(height: 4),
              const Icon(Icons.check_circle_rounded, color: _kAccent, size: 18),
            ],
          ]),
        ]),
      ),
    );
  }

  String _sizeInitial(String typeName) {
    if (typeName.toLowerCase().contains('small'))  return 'S';
    if (typeName.toLowerCase().contains('medium')) return 'M';
    if (typeName.toLowerCase().contains('large'))  return 'L';
    if (typeName.toLowerCase().contains('extra'))  return 'XL';
    return typeName.isNotEmpty ? typeName[0].toUpperCase() : '?';
  }
}

// ── STATUS BADGE ──────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = status == 'available' ? _kGreen : _kMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: GoogleFonts.syne(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ── TIME CARD ─────────────────────────────────────────────
class _TimeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final DateTime dateTime;
  final VoidCallback onTap;
  const _TimeCard({required this.label, required this.icon, required this.color,
    required this.dateTime, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 8),
        Text(_date(dateTime), style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
        const SizedBox(height: 2),
        Text(_time(dateTime), style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(context.s.tapToChange, style: GoogleFonts.dmSans(fontSize: 10, color: color)),
        ),
      ]),
    ),
  );

  String _date(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  String _time(DateTime dt) {
    final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m  = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }
}

// ── COST SUMMARY ─────────────────────────────────────────
class _CostSummary extends StatelessWidget {
  final List<Map<String, dynamic>> lockers;
  final DateTime startDate, endDate;
  final double totalCost;
  final int hours;
  const _CostSummary({required this.lockers, required this.startDate,
    required this.endDate, required this.totalCost, required this.hours});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kSurface, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
    ),
    child: Column(children: [
      Row(children: [
        const Icon(Icons.receipt_long_rounded, color: _kAccent, size: 16),
        const SizedBox(width: 8),
        Text(context.s.priceSummary,
            style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
      ]),
      const SizedBox(height: 12),
      _Row(label: context.s.duration, value: '$hours hr${hours == 1 ? '' : 's'}'),
      // Line per locker
      ...lockers.map((lk) {
        final rate = double.tryParse(lk['price_per_hour']?.toString() ?? '0') ?? 0;
        final cost = rate * hours;
        return _Row(
          label: lk['type_name'] ?? context.s.lockerType,
          value: 'EGP ${cost.toStringAsFixed(2)} (${rate.toStringAsFixed(2)}/hr)',
        );
      }),
      Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 10), color: _kBorder),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(context.s.total,
            style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: _kText)),
        Text('EGP ${totalCost.toStringAsFixed(2)}',
            style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800, color: _kAccent)),
      ]),
    ]),
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
      Text(value,  style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w600, color: _kText)),
    ]),
  );
}

// ── SUCCESS ROW ───────────────────────────────────────────
class _SuccessRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _SuccessRow({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
        Text(value,  style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700,
            color: valueColor ?? _kText)),
      ]);
}

// ── EMPTY STATE ───────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String locationName;
  const _EmptyState({required this.locationName});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: const BoxDecoration(color: _kSurface, shape: BoxShape.circle),
        child: const Icon(Icons.lock_open_rounded, color: _kMuted, size: 36),
      ),
      const SizedBox(height: 20),
      Text(context.s.noLockersAvailable,
          style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
      const SizedBox(height: 8),
      Text(context.s.noLockersAt(locationName),
          style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: _kSurface, borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _kBorder),
          ),
          child: Text(context.s.goBack,
              style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: _kText)),
        ),
      ),
    ]),
  ));
}

// ── ERROR STATE ───────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, color: _kMuted, size: 48),
      const SizedBox(height: 16),
      Text(message,
          style: GoogleFonts.dmSans(fontSize: 14, color: _kMuted), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kAccent, Color(0xFFE8920A)]),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text('Retry',
              style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: _kBg)),
        ),
      ),
    ]),
  ));
}
