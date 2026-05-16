import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';
import 'l10n/strings.dart';

const String baseUrl = kIsWeb
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

// ── COLORS ────────────────────────────────────────────────
const _kBg      = Color(0xFF2E3449);
const _kSurface = Color(0xFF434A64);
const _kText    = Color(0xFFEEF0F6);
const _kMuted   = Color(0xFF6A7090);
const _kAccent  = Color(0xFFF5A623);
const _kRed     = Color(0xFFE05A7A);
const _kGreen   = Color(0xFF00C9A7);
const _kBorder  = Color(0x18FFFFFF);
const _kBlue    = Color(0xFF5B72FF);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey     = GlobalKey<FormState>();
  final _firstCtrl   = TextEditingController();
  final _lastCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _hidePass     = true;
  bool _hideConfirm  = true;
  bool _agreed       = false;
  bool _loading      = false;

  // National ID
  Uint8List? _idFrontBytes;
  Uint8List? _idBackBytes;
  final _picker = ImagePicker();

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
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isFront, required bool fromCamera}) async {
    try {
      final picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 1280,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        if (isFront) { _idFrontBytes = bytes; }
        else         { _idBackBytes  = bytes; }
      });
    } catch (_) {}
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      _showError(context.s.agreeTerms);
      return;
    }
    if (_idFrontBytes == null || _idBackBytes == null) {
      _showError('Please upload both sides of your national ID.');
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.signUp(
        fullName:       '${_firstCtrl.text.trim()} ${_lastCtrl.text.trim()}',
        email:          _emailCtrl.text.trim(),
        phone:          _phoneCtrl.text.trim(),
        password:       _passCtrl.text,
        nationalIdFront: base64Encode(_idFrontBytes!),
        nationalIdBack:  base64Encode(_idBackBytes!),
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans()),
      backgroundColor: _kRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kText, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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

                    const SizedBox(height: 8),

                    Text(s.joinSmartSecure, style: GoogleFonts.syne(fontSize: 38, fontWeight: FontWeight.w800, color: _kText, height: 1.08, letterSpacing: -1.5)),
                    const SizedBox(height: 10),
                    Text('First hour free. No subscription needed.', style: GoogleFonts.dmSans(fontSize: 14, color: _kMuted, fontWeight: FontWeight.w300)),

                    const SizedBox(height: 36),

                    // ── FIRST + LAST NAME ────────────────────────
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _FieldLabel(s.firstName),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _firstCtrl,
                          textCapitalization: TextCapitalization.words,
                          style: _inputTextStyle,
                          decoration: _inputDeco(hint: 'Ahmed'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
                        ),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _FieldLabel(s.lastName),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _lastCtrl,
                          textCapitalization: TextCapitalization.words,
                          style: _inputTextStyle,
                          decoration: _inputDeco(hint: 'Mohamed'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
                        ),
                      ])),
                    ]),

                    const SizedBox(height: 20),

                    // ── EMAIL ────────────────────────────────────
                    _FieldLabel(s.email),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: _inputTextStyle,
                      decoration: _inputDeco(
                        hint: 'you@example.com',
                        prefix: const Icon(Icons.mail_outline_rounded, color: _kMuted, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return s.fieldRequired;
                        if (!v.contains('@') || !v.contains('.')) return s.invalidEmailOrPhone;
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── PHONE NUMBER ─────────────────────────────
                    _FieldLabel(s.phone),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: _inputTextStyle,
                      decoration: _inputDeco(
                        hint: '+20 1XX XXX XXXX',
                        prefix: const Icon(Icons.phone_outlined, color: _kMuted, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return s.fieldRequired;
                        if (v.trim().length < 7) return s.invalidEmailOrPhone;
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── PASSWORD ─────────────────────────────────
                    _FieldLabel(s.password),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _hidePass,
                      style: _inputTextStyle,
                      decoration: _inputDeco(
                        hint: 'Min. 8 characters',
                        prefix: const Icon(Icons.lock_outline_rounded, color: _kMuted, size: 20),
                        suffix: GestureDetector(
                          onTap: () => setState(() => _hidePass = !_hidePass),
                          child: Icon(_hidePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _kMuted, size: 20),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return s.passwordRequired;
                        if (v.length < 8) return s.minSixChars;
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── CONFIRM PASSWORD ─────────────────────────
                    _FieldLabel(s.confirmPassword),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _hideConfirm,
                      style: _inputTextStyle,
                      decoration: _inputDeco(
                        hint: 'Re-enter your password',
                        prefix: const Icon(Icons.lock_outline_rounded, color: _kMuted, size: 20),
                        suffix: GestureDetector(
                          onTap: () => setState(() => _hideConfirm = !_hideConfirm),
                          child: Icon(_hideConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _kMuted, size: 20),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your password';
                        if (v != _passCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // ── NATIONAL ID UPLOAD ───────────────────────
                    Row(children: [
                      const Icon(Icons.badge_outlined, color: _kAccent, size: 18),
                      const SizedBox(width: 8),
                      Text('National ID Verification',
                          style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: _kText)),
                    ]),
                    const SizedBox(height: 4),
                    Text('Upload clear photos of your national ID',
                        style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
                    const SizedBox(height: 16),

                    _IdUploadCard(
                      label: 'ID Front Side',
                      imageBytes: _idFrontBytes,
                      onCamera: () => _pickImage(isFront: true, fromCamera: true),
                      onUpload: () => _pickImage(isFront: true, fromCamera: false),
                    ),
                    const SizedBox(height: 12),
                    _IdUploadCard(
                      label: 'ID Back Side',
                      imageBytes: _idBackBytes,
                      onCamera: () => _pickImage(isFront: false, fromCamera: true),
                      onUpload: () => _pickImage(isFront: false, fromCamera: false),
                    ),

                    const SizedBox(height: 28),

                    // ── TERMS CHECKBOX ───────────────────────────
                    GestureDetector(
                      onTap: () => setState(() => _agreed = !_agreed),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22, height: 22,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: _agreed ? _kAccent : Colors.transparent,
                              border: Border.all(color: _agreed ? _kAccent : _kBorder, width: 1.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: _agreed ? const Icon(Icons.check_rounded, color: _kBg, size: 14) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(children: [
                                TextSpan(text: s.agreeToTerms, style: GoogleFonts.dmSans(color: _kMuted, fontSize: 13)),
                                TextSpan(text: 'Terms of Service', style: GoogleFonts.dmSans(color: _kAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                                TextSpan(text: ' and ', style: GoogleFonts.dmSans(color: _kMuted, fontSize: 13)),
                                TextSpan(text: 'Privacy Policy', style: GoogleFonts.dmSans(color: _kAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── CREATE ACCOUNT BUTTON ────────────────────
                    GestureDetector(
                      onTap: _loading ? null : _register,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: _agreed ? const LinearGradient(colors: [_kAccent, Color(0xFFE8920A)]) : null,
                          color: _agreed ? null : _kSurface,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: _agreed ? [BoxShadow(color: _kAccent.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))] : [],
                        ),
                        child: Center(
                          child: _loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _kBg, strokeWidth: 2.5))
                              : Text(s.createAccount, style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: _agreed ? _kBg : _kMuted)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── SIGN IN LINK ─────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(text: s.alreadyHaveAccount, style: GoogleFonts.dmSans(color: _kMuted, fontSize: 14)),
                            TextSpan(text: s.signIn, style: GoogleFonts.dmSans(color: _kAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle get _inputTextStyle => GoogleFonts.dmSans(color: _kText, fontSize: 15);

  InputDecoration _inputDeco({required String hint, Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.only(left: 4), child: prefix) : null,
      suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 4), child: suffix) : null,
    );
  }
}

// ── NATIONAL ID UPLOAD CARD ───────────────────────────────
class _IdUploadCard extends StatelessWidget {
  final String     label;
  final Uint8List? imageBytes;
  final VoidCallback onCamera;
  final VoidCallback onUpload;

  const _IdUploadCard({
    required this.label,
    required this.imageBytes,
    required this.onCamera,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label,
              style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: _kText, letterSpacing: 0.3)),
          if (hasImage) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle_rounded, color: _kGreen, size: 16),
          ],
        ]),
        const SizedBox(height: 8),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasImage ? _kGreen.withValues(alpha: 0.45) : _kBorder,
              width: hasImage ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Stack(children: [
                  Positioned.fill(
                    child: Image.memory(imageBytes!, fit: BoxFit.cover),
                  ),
                  // Gradient overlay with buttons
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!kIsWeb) ...[
                            _IdButton(label: 'Retake', onTap: onCamera),
                            const SizedBox(width: 10),
                          ],
                          _IdButton(label: 'Re-upload', onTap: onUpload),
                        ],
                      ),
                    ),
                  ),
                ])
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: _kBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBorder),
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: _kMuted, size: 26),
                    ),
                    const SizedBox(height: 10),
                    Text('Take photo or upload',
                        style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!kIsWeb) ...[
                          _IdButton(label: 'Take Photo', onTap: onCamera),
                          const SizedBox(width: 10),
                        ],
                        _IdButton(label: 'Upload', onTap: onUpload),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── SMALL BUTTON ──────────────────────────────────────────
class _IdButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _IdButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        color: _kBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _kBlue.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
    ),
  );
}

// ── FIELD LABEL ───────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: _kText, letterSpacing: 0.3),
  );
}
