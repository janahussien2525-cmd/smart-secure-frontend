import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'language_service.dart';
import 'l10n/strings.dart';

class ExploreMenu extends StatelessWidget {
  final Map<String, dynamic>? user;
  final Function(String route) onNavigate;
  final VoidCallback onLogout;
  final int unreadCount;

  const ExploreMenu({
    super.key,
    required this.user,
    required this.onNavigate,
    required this.onLogout,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final name    = user?['full_name'] as String? ?? 'User';
    final email   = user?['email']    as String? ?? '';
    final balance = user?['wallet_balance']?.toString() ?? '0.00';
    final top     = MediaQuery.of(context).padding.top;
    final bottom  = MediaQuery.of(context).padding.bottom;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF394057),
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
        child: Column(children: [

          // ── HEADER ──────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, top + 20, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF434A64),
              borderRadius: BorderRadius.only(topRight: Radius.circular(28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: const Color(0xFF4F5774), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.close_rounded, color: Color(0xFF6A7090), size: 18),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // User avatar + info → tappable to profile
              GestureDetector(
                onTap: () => onNavigate('/profile'),
                child: Row(children: [
                  Container(
                    width: 56, height: 56,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF2E3449)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6))),
                    const SizedBox(height: 2),
                    Text(email, style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF6A7090)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5A623).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFFF5A623).withValues(alpha: 0.3)),
                      ),
                      child: Text(s.viewProfile, style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFF5A623))),
                    ),
                  ])),
                ]),
              ),
            ]),
          ),

          // ── SCROLLABLE CONTENT ───────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 20, 16, bottom + 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Wallet balance card
                GestureDetector(
                  onTap: () => onNavigate('/wallet'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A2E48), Color(0xFF0E1A2E)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF5A623).withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: const Color(0xFFF5A623).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.wallet, color: Color(0xFFF5A623), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.walletBalance, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6A7090))),
                        Text('EGP $balance', style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFFEEF0F6))),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE8920A)]),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(s.topUp, style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF2E3449))),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 14),

                // Subscription plan badge
                GestureDetector(
                  onTap: () => onNavigate('/plans'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF434A64),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF7B8FFF).withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(color: const Color(0xFF7B8FFF).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF7B8FFF), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.freePlan, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6))),
                        Text(s.tapToUpgrade, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6A7090))),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B8FFF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0xFF7B8FFF).withValues(alpha: 0.3)),
                        ),
                        child: Text(s.upgrade, style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF7B8FFF))),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 24),

                // Section label
                Text(s.menu, style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF6A7090), letterSpacing: 1.5)),
                const SizedBox(height: 10),

                // Menu items
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF434A64),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x18FFFFFF)),
                  ),
                  child: Column(children: [
                    if ((user?['role'] as String? ?? 'customer') == 'admin') ...[
                      _MenuItem(icon: Icons.admin_panel_settings_rounded, label: s.adminPanel, color: const Color(0xFFE05A7A), onTap: () => onNavigate('/admin')),
                      _Divider(),
                    ],
                    _MenuItem(icon: Icons.history_rounded,        label: s.bookingHistory,  color: const Color(0xFF00C9A7), onTap: () => onNavigate('/bookings')),
                    _Divider(),
                    _MenuItem(icon: Icons.credit_card_rounded, label: s.paymentMethods, color: const Color(0xFF00C9A7), onTap: () => onNavigate('/payment-methods')),
                    _Divider(),
                    _MenuItem(icon: Icons.notifications_outlined,  label: s.notifications,    color: const Color(0xFF7B8FFF), onTap: () => onNavigate('/notifications'),
                      badge: unreadCount > 0 ? '$unreadCount' : null),
                    _Divider(),
                    _MenuItem(icon: Icons.language_rounded,        label: s.language,         color: const Color(0xFFF5A623), onTap: () => _showLanguagePicker(context)),
                    _Divider(),
                    _MenuItem(icon: Icons.help_outline_rounded,    label: s.helpCenter,      color: const Color(0xFF9AA0B0), onTap: () => onNavigate('/help')),
                  ]),
                ),

                const SizedBox(height: 20),

                // Logout
                GestureDetector(
                  onTap: () => _confirmLogout(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE05A7A).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE05A7A).withValues(alpha: 0.25)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.logout_rounded, color: Color(0xFFE05A7A), size: 18),
                      const SizedBox(width: 8),
                      Text(s.logOut, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFE05A7A))),
                    ]),
                  ),
                ),

                const SizedBox(height: 12),

                // App version
                Center(child: Text(s.version, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF3A4060)))),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF434A64),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LanguagePickerSheet(),
    );
  }

  void _confirmLogout(BuildContext context) {
    final s = context.s;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF434A64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.logOut, style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6))),
        content: Text(s.logOutConfirm, style: GoogleFonts.dmSans(color: const Color(0xFF6A7090))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: Text(s.cancel, style: GoogleFonts.syne(color: const Color(0xFF6A7090)))),
          TextButton(onPressed: () { Navigator.pop(context); onLogout(); },
            child: Text(s.logOut, style: GoogleFonts.syne(color: const Color(0xFFE05A7A), fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final String?  badge;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.color, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFEEF0F6)))),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFE05A7A), borderRadius: BorderRadius.circular(99)),
            child: Text(badge!, style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
          )
        else
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF6A7090), size: 18),
      ]),
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: const Color(0x18FFFFFF));
}

class _LanguagePickerSheet extends StatefulWidget {
  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  String _selected = LanguageService.current;

  static const _langs = [
    {'code': 'en', 'flag': '🇺🇸'},
    {'code': 'ar', 'flag': '🇪🇬'},
    {'code': 'fr', 'flag': '🇫🇷'},
  ];

  Future<void> _pick(String code) async {
    setState(() => _selected = code);
    await LanguageService.setLanguage(code);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(s.selectLanguage, style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFEEF0F6))),
        const SizedBox(height: 16),
        ..._langs.map((l) {
          final label = l['code'] == 'en' ? s.langEnglish : l['code'] == 'ar' ? s.langArabic : s.langFrench;
          return GestureDetector(
            onTap: () => _pick(l['code']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _selected == l['code'] ? const Color(0xFFF5A623).withValues(alpha: 0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selected == l['code'] ? const Color(0xFFF5A623).withValues(alpha: 0.3) : const Color(0x18FFFFFF)),
              ),
              child: Row(children: [
                Text(l['flag']!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFEEF0F6)))),
                if (_selected == l['code']) const Icon(Icons.check_circle_rounded, color: Color(0xFFF5A623), size: 18),
              ]),
            ),
          );
        }),
        const SizedBox(height: 8),
      ]),
    );
  }
}