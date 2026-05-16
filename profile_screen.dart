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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _user;

  @override
  void initState() { super.initState(); _fetchProfile(); }

  Future<void> _fetchProfile() async {
    try {
      final token = await AuthService.getToken();
      final res   = await http.get(Uri.parse('$_base/auth/profile'),
          headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() { _user = json['user']; _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) { setState(() => _loading = false); }
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(user: _user!, onSaved: (updated) {
        setState(() => _user = {..._user!, ...updated});
      }),
    );
  }

  void _openPasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF2E3449),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF5A623), strokeWidth: 2))
          : CustomScrollView(slivers: [

              // ── APP BAR ────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF394057),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: Column(children: [
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
                      Text(s.profile, style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6))),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ]),

                    const SizedBox(height: 28),

                    // Avatar
                    Container(
                      width: 84, height: 84,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (_user?['full_name'] as String? ?? 'U').isNotEmpty
                              ? (_user!['full_name'] as String)[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.syne(fontSize: 34, fontWeight: FontWeight.w800, color: const Color(0xFF2E3449)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(_user?['full_name'] ?? '', style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFFEEF0F6))),
                    const SizedBox(height: 4),
                    Text(_user?['email'] ?? '', style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6A7090))),

                    const SizedBox(height: 16),

                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5A623).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFFF5A623).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        (_user?['role'] as String? ?? 'customer').toUpperCase(),
                        style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFF5A623)),
                      ),
                    ),
                  ]),
                ),
              ),

              // ── INFO CARDS ──────────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(children: [

                  _InfoCard(items: [
                    _InfoRow(icon: Icons.person_outline_rounded,  label: s.fullName,         value: _user?['full_name'] ?? '—'),
                    _InfoRow(icon: Icons.email_outlined,           label: s.emailLabel,       value: _user?['email']     ?? '—'),
                    _InfoRow(icon: Icons.phone_outlined,           label: s.phoneLabel,       value: _user?['phone']     ?? '—'),
                  ]),

                  const SizedBox(height: 12),

                  _InfoCard(items: [
                    _InfoRow(icon: Icons.wallet,          label: s.walletBalanceLabel, value: 'EGP ${(double.tryParse(_user?['wallet_balance']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}'),
                    _InfoRow(icon: Icons.calendar_today_outlined, label: s.memberSince, value: _formatDate(_user?['created_at'])),
                  ]),

                  const SizedBox(height: 24),

                  // Action buttons
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    label: s.editNamePhone,
                    color: const Color(0xFFF5A623),
                    onTap: _openEditSheet,
                  ),
                  const SizedBox(height: 10),
                  _ActionBtn(
                    icon: Icons.lock_outline_rounded,
                    label: s.changePassword,
                    color: const Color(0xFF7B8FFF),
                    onTap: _openPasswordSheet,
                  ),

                  const SizedBox(height: 40),
                ]),
              )),
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

// ── INFO CARD ─────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<Widget> items;
  const _InfoCard({required this.items});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: const Color(0xFF434A64), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x18FFFFFF))),
    child: Column(children: items),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF6A7090), size: 18),
      const SizedBox(width: 12),
      Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF6A7090))),
      const Spacer(),
      Text(value, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFEEF0F6))),
    ]),
  );
}

// ── ACTION BUTTON ─────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        const Spacer(),
        Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 18),
      ]),
    ),
  );
}

// ── EDIT PROFILE SHEET ────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(Map<String, dynamic>) onSaved;
  const _EditProfileSheet({required this.user, required this.onSaved});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _nameCtrl  = TextEditingController(text: widget.user['full_name'] ?? '');
  late final _phoneCtrl = TextEditingController(text: widget.user['phone']     ?? '');
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      final token = await AuthService.getToken();
      final res = await http.put(
        Uri.parse('$_base/auth/profile'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'full_name': _nameCtrl.text.trim(), 'phone': _phoneCtrl.text.trim()}),
      );
      final json = jsonDecode(res.body);
      if (res.statusCode == 200) {
        widget.onSaved({'full_name': _nameCtrl.text.trim(), 'phone': _phoneCtrl.text.trim()});
        if (mounted) Navigator.pop(context);
      } else {
        setState(() { _error = json['message'] ?? 'Failed to update.'; _saving = false; });
      }
    } catch (_) { setState(() { _error = 'Cannot connect to server.'; _saving = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF394057), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0x30FFFFFF), borderRadius: BorderRadius.circular(99))),
        const SizedBox(height: 20),
        Text(s.editProfile, style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6))),
        const SizedBox(height: 24),
        _Field(controller: _nameCtrl,  label: s.fullName, icon: Icons.person_outline_rounded),
        const SizedBox(height: 12),
        _Field(controller: _phoneCtrl, label: s.phoneLabel, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: GoogleFonts.dmSans(color: const Color(0xFFE05A7A), fontSize: 13)),
        ],
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _saving ? null : _save,
          child: Container(
            width: double.infinity, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(child: _saving
                ? const CircularProgressIndicator(color: Color(0xFF2E3449), strokeWidth: 2)
                : Text(s.saveChanges, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF2E3449)))),
          ),
        ),
      ]),
    );
  }
}

// ── CHANGE PASSWORD SHEET ─────────────────────────────────
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currCtrl = TextEditingController();
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _saving = false, _obscureCurr = true, _obscureNew = true, _obscureConf = true;
  String? _error;

  Future<void> _save() async {
    final s = context.s;
    if (_currCtrl.text.isEmpty)          { setState(() => _error = s.enterCurrentPass); return; }
    if (_newCtrl.text != _confCtrl.text) { setState(() => _error = s.passwordsDoNotMatch); return; }
    if (_newCtrl.text.length < 6)        { setState(() => _error = s.passwordMin6); return; }
    setState(() { _saving = true; _error = null; });
    try {
      final token = await AuthService.getToken();
      final res = await http.put(
        Uri.parse('$_base/auth/change-password'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'current_password': _currCtrl.text, 'new_password': _newCtrl.text}),
      );
      final json = jsonDecode(res.body);
      if (res.statusCode == 200) {
        if (mounted) Navigator.pop(context);
      } else {
        setState(() { _error = json['message'] ?? 'Failed.'; _saving = false; });
      }
    } catch (_) { setState(() { _error = 'Cannot connect to server.'; _saving = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bottom = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF394057), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0x30FFFFFF), borderRadius: BorderRadius.circular(99))),
        const SizedBox(height: 20),
        Text(s.changePassword, style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6))),
        const SizedBox(height: 24),
        _Field(controller: _currCtrl, label: s.currentPassword, icon: Icons.lock_outline_rounded, obscure: _obscureCurr,
          onToggle: () => setState(() => _obscureCurr = !_obscureCurr)),
        const SizedBox(height: 12),
        _Field(controller: _newCtrl,  label: s.newPassword,     icon: Icons.lock_rounded,         obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew)),
        const SizedBox(height: 12),
        _Field(controller: _confCtrl, label: s.confirmPassword,   icon: Icons.lock_rounded,         obscure: _obscureConf,
          onToggle: () => setState(() => _obscureConf = !_obscureConf)),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: GoogleFonts.dmSans(color: const Color(0xFFE05A7A), fontSize: 13)),
        ],
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _saving ? null : _save,
          child: Container(
            width: double.infinity, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7B8FFF), Color(0xFF5B6FDF)]),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(child: _saving
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text(s.updatePassword, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
          ),
        ),
      ]),
    );
  }
}

// ── SHARED FIELD WIDGET ───────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String   label;
  final IconData icon;
  final bool     obscure;
  final VoidCallback? onToggle;
  final TextInputType keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.onToggle,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller:   controller,
    obscureText:  obscure,
    keyboardType: keyboardType,
    style: GoogleFonts.dmSans(color: const Color(0xFFEEF0F6), fontSize: 14),
    decoration: InputDecoration(
      labelText:     label,
      labelStyle:    GoogleFonts.dmSans(color: const Color(0xFF6A7090), fontSize: 13),
      prefixIcon:    Icon(icon, color: const Color(0xFF6A7090), size: 18),
      suffixIcon:    onToggle != null
          ? GestureDetector(onTap: onToggle, child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF6A7090), size: 18))
          : null,
      filled:        true,
      fillColor:     const Color(0xFF4F5774),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x18FFFFFF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x18FFFFFF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFF5A623), width: 1.5)),
    ),
  );
}