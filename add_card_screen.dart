import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
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
const _kText    = Color(0xFFEEF0F6);
const _kMuted   = Color(0xFF6A7090);
const _kBorder  = Color(0x18FFFFFF);

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});
  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl    = TextEditingController();
  final _holderCtrl = TextEditingController();

  bool     _loading    = false;
  bool     _setDefault = true;
  String?  _error;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _holderCtrl.dispose();
    super.dispose();
  }

  String _detectBrand(String number) {
    final n = number.replaceAll(' ', '');
    if (n.startsWith('4')) return 'Visa';
    if (n.startsWith('5') || n.startsWith('2')) return 'Mastercard';
    if (n.startsWith('3')) return 'Amex';
    return 'Card';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final token  = await AuthService.getToken();
      final number = _numberCtrl.text.replaceAll(' ', '');
      final expiry = _expiryCtrl.text.split('/');
      final month  =
          int.tryParse(expiry.isNotEmpty ? expiry[0] : '0') ?? 0;
      final year   = int.tryParse(
              expiry.length > 1 ? '20${expiry[1].trim()}' : '0') ??
          0;

      final res = await http.post(
        Uri.parse('$_base/payment-methods'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'card_last4':   number.substring(number.length - 4),
          'card_brand':   _detectBrand(number),
          'card_holder':  _holderCtrl.text.trim(),
          'expiry_month': month,
          'expiry_year':  year,
          'is_default':   _setDefault,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (res.statusCode == 201 || res.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        String message = 'Failed to save card.';
        try {
          final body = jsonDecode(res.body);
          message = body['message'] ?? body['error'] ?? message;
        } catch (_) {}
        setState(() { _error = message; _loading = false; });
      }
    } catch (e) {
      setState(
          () { _error = context.s.cannotConnect; _loading = false; });
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
            Text(s.addNewCard,
                style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kText)),
          ]),
        ),

        // ── Form ──────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding:
                EdgeInsets.fromLTRB(20, 24, 20, bottom + 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Card number
                  _FieldLabel(s.cardNumber),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _numberCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _CardNumberFormatter(),
                    ],
                    style: GoogleFonts.dmSans(
                        color: _kText,
                        fontSize: 15,
                        letterSpacing: 2),
                    decoration: _inputDeco(
                      hint: '0000 0000 0000 0000',
                      prefix: const Icon(
                          Icons.credit_card_rounded,
                          color: _kMuted,
                          size: 20),
                    ),
                    validator: (v) {
                      final n = v?.replaceAll(' ', '') ?? '';
                      if (n.length < 13) return s.enterCardNumber;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Expiry + CVV row
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(s.expiryDate),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _expiryCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9/]')),
                              _ExpiryFormatter(),
                            ],
                            style: GoogleFonts.dmSans(
                                color: _kText, fontSize: 15),
                            decoration:
                                _inputDeco(hint: 'MM/YY'),
                            validator: (v) {
                              if (v == null ||
                                  !v.contains('/') ||
                                  v.length < 5) {
                                return s.enterExpiry;
                              }
                              final parts = v.split('/');
                              final month = int.tryParse(parts[0]) ?? 0;
                              final year  = int.tryParse('20${parts[1].trim()}') ?? 0;
                              final now   = DateTime.now();
                              if (month < 1 || month > 12 ||
                                  year < now.year ||
                                  (year == now.year && month < now.month)) {
                                return s.cardExpired;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(s.cvv),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _cvvCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            style: GoogleFonts.dmSans(
                                color: _kText, fontSize: 15),
                            decoration:
                                _inputDeco(hint: '•••'),
                            validator: (v) {
                              if (v == null || v.length < 3) {
                                return s.enterCvv;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Card holder
                  _FieldLabel(s.cardHolder),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _holderCtrl,
                    textCapitalization:
                        TextCapitalization.characters,
                    style: GoogleFonts.dmSans(
                        color: _kText, fontSize: 15),
                    decoration: _inputDeco(
                      hint: 'NAME ON CARD',
                      prefix: const Icon(
                          Icons.person_outline_rounded,
                          color: _kMuted,
                          size: 20),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return s.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Set as default toggle
                  GestureDetector(
                    onTap: () => setState(
                        () => _setDefault = !_setDefault),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Row(children: [
                        const Icon(Icons.star_rounded,
                            color: _kAccent, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(s.setAsDefault,
                              style: GoogleFonts.syne(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kText)),
                        ),
                        AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          width: 44, height: 24,
                          decoration: BoxDecoration(
                            color: _setDefault
                                ? _kAccent
                                : const Color(0xFF4F5774),
                            borderRadius:
                                BorderRadius.circular(99),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(
                                milliseconds: 200),
                            alignment: _setDefault
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 18, height: 18,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 3),
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  // Error banner
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _kRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: _kRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: GoogleFonts.dmSans(
                                  fontSize: 13, color: _kRed)),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Submit button
                  GestureDetector(
                    onTap: _loading ? null : _submit,
                    child: Container(
                      height: 54,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [_kAccent, Color(0xFFE8920A)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                _kAccent.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: _kBg,
                                    strokeWidth: 2.5))
                            : Text(s.addCard,
                                style: GoogleFonts.syne(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _kBg)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded,
                          color: _kMuted, size: 14),
                      const SizedBox(width: 6),
                      Text(s.securedPayment,
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: _kMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  InputDecoration _inputDeco(
          {required String hint, Widget? prefix}) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: _kSurface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: _kAccent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: _kRed.withValues(alpha: 0.5))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kRed)),
        hintStyle:
            GoogleFonts.dmSans(color: _kMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        prefixIcon: prefix != null
            ? Padding(
                padding:
                    const EdgeInsets.only(left: 14, right: 10),
                child: prefix)
            : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.syne(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF9AA0B0)));
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue value) {
    final digits = value.text.replaceAll(' ', '');
    if (digits.length > 16) return old;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return value.copyWith(
      text: formatted,
      selection:
          TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue value) {
    final digits = value.text.replaceAll('/', '');
    if (digits.length > 4) return old;
    String formatted = digits;
    if (digits.length >= 3) {
      formatted =
          '${digits.substring(0, 2)}/${digits.substring(2)}';
    } else if (digits.length == 2 && old.text.length == 1) {
      formatted = '$digits/';
    }
    return value.copyWith(
      text: formatted,
      selection:
          TextSelection.collapsed(offset: formatted.length),
    );
  }
}