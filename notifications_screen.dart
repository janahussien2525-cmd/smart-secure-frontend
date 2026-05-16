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
const _kRed     = Color(0xFFE05A7A);
const _kText    = Color(0xFFEEF0F6);
const _kMuted   = Color(0xFF6A7090);
const _kBorder  = Color(0x18FFFFFF);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool  _loading = true;
  String? _error;
  List  _notifications = [];

  @override
  void initState() { super.initState(); _fetchNotifications(); }

  Future<String> _getToken() => AuthService.getToken();

  Future<void> _fetchNotifications() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$_base/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept-Language': Localizations.localeOf(context).languageCode,
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() { _notifications = body['notifications'] as List; _loading = false; });
      } else {
        setState(() { _loading = false; _error = context.s.failedToLoadNotif; });
      }
    } catch (_) {
      setState(() { _loading = false; _error = context.s.cannotConnect; });
    }
  }

  Future<void> _markRead(int notifId, int index) async {
    try {
      final token = await _getToken();
      await http.put(
        Uri.parse('$_base/notifications/$notifId/read'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      setState(() {
        (_notifications[index] as Map<String, dynamic>)['is_read'] = true;
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      final token = await _getToken();
      await http.put(
        Uri.parse('$_base/notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      setState(() {
        for (final n in _notifications) {
          (n as Map<String, dynamic>)['is_read'] = true;
        }
      });
    } catch (_) {}
  }

  int get _unreadCount => _notifications.where((n) => (n as Map)['is_read'] == false).length;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [

        // ── HEADER ────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
          decoration: const BoxDecoration(color: _kCard, borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
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
              Text(s.notificationsTitle, style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
              if (_unreadCount > 0)
                Text(s.unreadCount(_unreadCount), style: GoogleFonts.dmSans(fontSize: 12, color: _kAccent)),
            ])),
            if (_unreadCount > 0)
              GestureDetector(
                onTap: _markAllRead,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _kPurple.withValues(alpha: 0.3)),
                  ),
                  child: Text(s.markAllRead, style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w700, color: _kPurple)),
                ),
              ),
          ]),
        ),

        // ── CONTENT ───────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2))
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _fetchNotifications)
                  : _notifications.isEmpty
                      ? _EmptyState()
                      : RefreshIndicator(
                          color: _kAccent,
                          backgroundColor: _kCard,
                          onRefresh: _fetchNotifications,
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
                            itemCount: _notifications.length,
                            itemBuilder: (_, i) {
                              final n    = _notifications[i] as Map<String, dynamic>;
                              final read = n['is_read'] as bool? ?? false;
                              return _NotifCard(
                                notification: n,
                                onTap: read ? null : () => _markRead(n['notification_id'] as int, i),
                              );
                            },
                          ),
                        ),
        ),
      ]),
    );
  }
}

// ── NOTIF CARD ────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;
  const _NotifCard({required this.notification, this.onTap});

  String _translateMessage(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'en') return notification['message'] as String? ?? '';

    final s = context.s;
    final type = notification['type'] as String? ?? '';
    final raw = notification['message'] as String? ?? '';

    // Extract EGP amount: "EGP 150.00" or "EGP150"
    final amountMatch = RegExp(r'EGP\s*([\d,]+\.?\d*)').firstMatch(raw);
    final amount = amountMatch?.group(1) ?? '';

    // Extract locker code: capital letters/digits like "A3", "B12"
    final lockerMatch = RegExp(r'\blocker\s+([A-Z0-9]{1,6})\b', caseSensitive: false).firstMatch(raw);
    final locker = lockerMatch?.group(1) ?? '';

    // Extract location name (between "at " and end/period)
    final locationMatch = RegExp(r'\bat\s+(.+?)(?:\.|$)').firstMatch(raw);
    final location = locationMatch?.group(1)?.trim() ?? '';

    // Extract hours
    final hoursMatch = RegExp(r'(\d+)h').firstMatch(raw);
    final hours = hoursMatch?.group(1) ?? '';

    switch (type) {
      case 'booking':
        if (raw.toLowerCase().contains('cancel')) return s.notifBookingCancelled(locker);
        return s.notifBookingConfirmed(locker, location);
      case 'wallet':
        if (raw.toLowerCase().contains('penalty') || raw.toLowerCase().contains('penalt')) {
          return s.notifPenaltyCharged(amount);
        }
        return s.notifWalletTopup(amount);
      case 'overdue':
        return s.notifOverdue(location);
      case 'extend':
      case 'extended':
        return s.notifRentalExtended(hours);
      default:
        return s.notifGeneral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type    = notification['type'] as String? ?? 'general';
    final isRead  = notification['is_read'] as bool? ?? false;
    // ignore: unused_local_variable
    final message = notification['message'] as String? ?? '';
    final displayMessage = _translateMessage(context);

    final (Color color, IconData icon) = switch (type) {
      'booking' => (_kGreen,  Icons.lock_rounded),
      'wallet'  => (_kAccent, Icons.wallet),
      'overdue' => (_kRed,    Icons.warning_rounded),
      _         => (_kPurple, Icons.notifications_rounded),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? _kSurface : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRead ? _kBorder : color.withValues(alpha: 0.25),
            width: isRead ? 1 : 1.5,
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Icon
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isRead ? 0.06 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color.withValues(alpha: isRead ? 0.5 : 1), size: 20),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(displayMessage,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: isRead ? _kMuted : _kText,
                fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Text(_formatTime(notification['sent_at'], context.s),
              style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted.withValues(alpha: 0.7))),
          ])),

          if (!isRead) ...[
            const SizedBox(width: 8),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ]),
      ),
    );
  }

  String _formatTime(dynamic raw, AppStrings s) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return '—';
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return s.justNow;
    if (diff.inMinutes < 60) return s.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24)   return s.hoursAgo(diff.inHours);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── EMPTY STATE ───────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(
      width: 80, height: 80,
      decoration: const BoxDecoration(color: _kSurface, shape: BoxShape.circle),
      child: const Icon(Icons.notifications_off_outlined, color: _kMuted, size: 36),
    ),
    const SizedBox(height: 20),
    Text(s.noNotifications, style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: _kText)),
    const SizedBox(height: 8),
    Text(s.notifEmptyDesc,
      style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted), textAlign: TextAlign.center),
  ]));
  }
}

// ── ERROR STATE ───────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.wifi_off_rounded, color: _kMuted, size: 48),
    const SizedBox(height: 16),
    Text(message, style: GoogleFonts.dmSans(fontSize: 14, color: _kMuted)),
    const SizedBox(height: 20),
    GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kAccent, Color(0xFFE8920A)]),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(context.s.retry, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: _kBg)),
      ),
    ),
  ]));
}
