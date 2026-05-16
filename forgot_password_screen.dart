import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'l10n/strings.dart';

const String _base = kIsWeb
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool _loading  = false;
  bool _hidePass = true;
  String? _error;
  bool _success  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.post(
        Uri.parse('$_base/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':        _emailCtrl.text.trim(),
          'phone':        _phoneCtrl.text.trim(),
          'new_password': _passCtrl.text,
        }),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() { _success = true; _loading = false; });
      } else {
        setState(() { _error = body['message'] ?? 'Reset failed.'; _loading = false; });
      }
    } catch (_) {
      setState(() { _error = 'Cannot connect to server.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF2E3449),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, top + 16, 24, bottom + 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFF4F5774), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFEEF0F6), size: 16),
            ),
          ),
          const SizedBox(height: 32),

          // Icon
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFF5A623), size: 28),
          ),
          const SizedBox(height: 20),

          Text(s.resetPassword, style: GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFFEEF0F6))),
          const SizedBox(height: 8),
          Text(s.resetPasswordSubtitle,
            style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF6A7090))),
          const SizedBox(height: 32),

          if (_success) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF00C9A7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00C9A7).withValues(alpha: 0.3)),
              ),
              child: Column(children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF00C9A7), size: 40),
                const SizedBox(height: 12),
                Text(s.passwordReset, style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6))),
                const SizedBox(height: 6),
                Text(s.passwordResetMsg,
                  style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6A7090)), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(s.backToLogin, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF2E3449))),
                  ),
                ),
              ]),
            ),
          ] else ...[
            Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                _FieldLabel(s.emailLabel),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.dmSans(color: const Color(0xFFEEF0F6), fontSize: 15),
                  decoration: _inputDeco(hint: 'your@email.com',
                    prefix: const Icon(Icons.email_outlined, color: Color(0xFF6A7090), size: 20)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.emailRequired;
                    if (!v.contains('@')) return s.enterValidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _FieldLabel(s.phone),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.dmSans(color: const Color(0xFFEEF0F6), fontSize: 15),
                  decoration: _inputDeco(hint: '+1 555 000 0000',
                    prefix: const Icon(Icons.phone_outlined, color: Color(0xFF6A7090), size: 20)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.phoneRequired;
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _FieldLabel(s.newPassword),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _hidePass,
                  style: GoogleFonts.dmSans(color: const Color(0xFFEEF0F6), fontSize: 15),
                  decoration: _inputDeco(
                    hint: 'Min. 6 characters',
                    prefix: const Icon(Icons.lock_outline_rounded, color: Color(0xFF6A7090), size: 20),
                    suffix: GestureDetector(
                      onTap: () => setState(() => _hidePass = !_hidePass),
                      child: Icon(_hidePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: const Color(0xFF6A7090), size: 20),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.passwordRequired;
                    if (v.length < 6) return s.minSixChars;
                    return null;
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE05A7A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE05A7A).withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFE05A7A), size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFFE05A7A)))),
                    ]),
                  ),
                ],

                const SizedBox(height: 28),

                GestureDetector(
                  onTap: _loading ? null : _submit,
                  child: Container(
                    height: 54,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFFF5A623).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Color(0xFF2E3449), strokeWidth: 2.5))
                          : Text(s.resetPassword, style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF2E3449))),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  InputDecoration _inputDeco({required String hint, Widget? prefix, Widget? suffix}) => InputDecoration(
    hintText: hint,
    prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: prefix) : null,
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix) : null,
    suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF9AA0B0)));
}
