import 'auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'l10n/strings.dart';

const String baseUrl = kIsWeb 
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _identCtrl    = TextEditingController(); // email or phone
  final _passCtrl     = TextEditingController();
  bool _hidePass      = true;
  bool _loading       = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _identCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Returns true if input looks like a phone number
  
  bool _isPhone(String val) => RegExp(r'^[+\d\s\-()]{7,}$').hasMatch(val) && !val.contains('@');

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.signIn(
        identifier: _identCtrl.text.trim(),
        password:   _passCtrl.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.dmSans()),
            backgroundColor: const Color(0xFFE05A7A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: const Color(0xFF2E3449),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 48),

                    // ── LOGO ─────────────────────────────────────
                    Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.lock_rounded, color: Color(0xFF2E3449), size: 22),
                      ),
                      const SizedBox(width: 12),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(text: 'Smart',  style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFFEEF0F6))),
                          TextSpan(text: 'Secure', style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFFF5A623))),
                        ]),
                      ),
                    ]),

                    const SizedBox(height: 48),

                    Text(s.welcomeBack, style: GoogleFonts.syne(fontSize: 40, fontWeight: FontWeight.w800, color: const Color(0xFFEEF0F6), height: 1.05, letterSpacing: -1.5)),
                    const SizedBox(height: 12),
                    Text(s.signInSubtitle, style: GoogleFonts.dmSans(fontSize: 15, color: const Color(0xFF6A7090), fontWeight: FontWeight.w300)),

                    const SizedBox(height: 44),

                    // ── EMAIL OR PHONE ───────────────────────────
                    _FieldLabel(s.emailOrPhone),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _identCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.dmSans(color: const Color(0xFFEEF0F6), fontSize: 15),
                      decoration: _inputDeco(
                        hint: s.emailHint,
                        prefix: const Icon(Icons.person_outline_rounded, color: Color(0xFF6A7090), size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return s.fieldRequired;
                        final val = v.trim();
                        // must be either a valid email or a valid phone
                        final isEmail = val.contains('@') && val.contains('.');
                        final isPhone = RegExp(r'^[+\d\s\-()]{7,}$').hasMatch(val) && !val.contains('@');
                        if (!isEmail && !isPhone) return s.invalidEmailOrPhone;
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // ── PASSWORD ─────────────────────────────────
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _FieldLabel(s.password),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                        child: Text(s.forgotPassword, style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFFF5A623), fontWeight: FontWeight.w500)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _hidePass,
                      style: GoogleFonts.dmSans(color: const Color(0xFFEEF0F6), fontSize: 15),
                      decoration: _inputDeco(
                        hint: s.passwordHint,
                        prefix: const Icon(Icons.lock_outline_rounded, color: Color(0xFF6A7090), size: 20),
                        suffix: GestureDetector(
                          onTap: () => setState(() => _hidePass = !_hidePass),
                          child: Icon(_hidePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF6A7090), size: 20),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return s.passwordRequired;
                        if (v.length < 6) return s.minSixChars;
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // ── SIGN IN BUTTON ───────────────────────────
                    _GradientButton(label: s.signIn, loading: _loading, onTap: _login),

                    const SizedBox(height: 24),

                    // ── DIVIDER ──────────────────────────────────
                    Row(children: [
                      const Expanded(child: Divider(color: Color(0x12FFFFFF))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(s.orContinueWith, style: GoogleFonts.dmSans(color: const Color(0xFF6A7090), fontSize: 12)),
                      ),
                      const Expanded(child: Divider(color: Color(0x12FFFFFF))),
                    ]),

                    const SizedBox(height: 24),

                    // ── SOCIAL BUTTONS ───────────────────────────
                    const Row(children: [
                      Expanded(child: _SocialButton(label: 'Google', icon: Icons.g_mobiledata_rounded)),
                      SizedBox(width: 12),
                      Expanded(child: _SocialButton(label: 'Apple', icon: Icons.apple)),
                    ]),

                    const SizedBox(height: 48),

                    // ── SIGN UP LINK ─────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(text: s.noAccount, style: GoogleFonts.dmSans(color: const Color(0xFF6A7090), fontSize: 14)),
                            TextSpan(text: s.signUp, style: GoogleFonts.dmSans(color: const Color(0xFFF5A623), fontSize: 14, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({required String hint, Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.only(left: 4), child: prefix) : null,
      suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 4), child: suffix) : null,
    );
  }
}

// ── FIELD LABEL ───────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6), letterSpacing: 0.3));
  }
}

// ── GRADIENT BUTTON ───────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: const Color(0xFFF5A623).withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Color(0xFF2E3449), strokeWidth: 2.5))
              : Text(label, style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF2E3449))),
        ),
      ),
    );
  }
}

// ── SOCIAL BUTTON ─────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SocialButton({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$label ${s.socialComingSoon}',
            style: GoogleFonts.dmSans(color: Colors.white)),
          backgroundColor: const Color(0xFF6A7090),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF434A64),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: const Color(0xFFEEF0F6), size: 22),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: const Color(0xFFEEF0F6), fontSize: 14)),
        ]),
      ),
    );
  }
}