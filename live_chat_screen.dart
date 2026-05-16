import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/strings.dart';

const _kBg      = Color(0xFF2E3449);
const _kSurface = Color(0xFF434A64);
const _kCard    = Color(0xFF394057);
const _kAccent  = Color(0xFFF5A623);
const _kGreen   = Color(0xFF00C9A7);
const _kText    = Color(0xFFEEF0F6);
const _kMuted   = Color(0xFF6A7090);
const _kBorder  = Color(0x18FFFFFF);

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});
  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final _ctrl       = TextEditingController();
  final _scroll     = ScrollController();
  final _messages   = <_Message>[];
  bool  _botTyping  = false;
  bool  _showQuick  = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.s;
      setState(() {
        _messages.add(_Message(text: s.chatWelcome, isUser: false));
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _ctrl.clear();
    setState(() {
      _messages.add(_Message(text: trimmed, isUser: true));
      _showQuick  = false;
      _botTyping  = true;
    });
    _scrollToBottom();

    final delay = 800 + (trimmed.length * 15).clamp(0, 1200);
    Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      final reply = _getBotReply(trimmed, context.s);
      setState(() {
        _botTyping = false;
        _messages.add(_Message(text: reply, isUser: false));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getBotReply(String message, AppStrings s) {
    final m = message.toLowerCase();
    if (m.contains('hello') || m.contains('hi') || m.contains('hey') ||
        m.contains('مرحب') || m.contains('bonjour') || m.contains('salut')) {
      return s.chatReplyGreeting;
    }
    if (m.contains('book') || m.contains('reserv') || m.contains('how to') ||
        m.contains('احجز') || m.contains('حجز') || m.contains('réserv') || m.contains('كيف')) {
      return s.chatReplyBook;
    }
    if (m.contains('cancel') || m.contains('إلغاء') || m.contains('annul')) {
      return s.chatReplyCancel;
    }
    if (m.contains('price') || m.contains('cost') || m.contains('rate') ||
        m.contains('how much') || m.contains('pay') || m.contains('سعر') ||
        m.contains('prix') || m.contains('tarif')) {
      return s.chatReplyPrice;
    }
    if (m.contains('wallet') || m.contains('top up') || m.contains('topup') ||
        m.contains('recharge') || m.contains('fund') || m.contains('محفظ') ||
        m.contains('portefeuille') || m.contains('شحن')) {
      return s.chatReplyWallet;
    }
    if (m.contains('overdue') || m.contains('late') || m.contains('expire') ||
        m.contains('تأخ') || m.contains('retard')) {
      return s.chatReplyOverdue;
    }
    if (m.contains('size') || m.contains('small') || m.contains('medium') ||
        m.contains('large') || m.contains('xl') || m.contains('حجم') ||
        m.contains('taille') || m.contains('أحجام')) {
      return s.chatReplySizes;
    }
    if (m.contains('secure') || m.contains('safe') || m.contains('encrypt') ||
        m.contains('security') || m.contains('آمن') || m.contains('sécur')) {
      return s.chatReplySecurity;
    }
    if (m.contains('plan') || m.contains('multiple') || m.contains('unlimited') ||
        m.contains('pro') || m.contains('business') || m.contains('خطة') ||
        m.contains('illimit')) {
      return s.chatReplyPlans;
    }
    if (m.contains('thank') || m.contains('شكر') || m.contains('merci') ||
        m.contains('شكراً')) {
      return s.chatReplyThanks;
    }
    return s.chatReplyDefault;
  }

  @override
  Widget build(BuildContext context) {
    final s      = context.s;
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [

        // ── HEADER ─────────────────────────────────────────────────
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
                decoration: BoxDecoration(
                  color: const Color(0xFF4F5774),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: _kText, size: 16),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kAccent, Color(0xFFE8920A)]),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.support_agent_rounded, color: _kBg, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.chatTitle,
                    style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: _kText)),
                Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(s.chatConnected,
                      style: GoogleFonts.dmSans(fontSize: 11, color: _kGreen)),
                ]),
              ]),
            ),
          ]),
        ),

        // ── MESSAGES ───────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: _messages.length + (_botTyping ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == _messages.length && _botTyping) {
                return _TypingBubble(label: s.chatBotTyping);
              }
              return _MessageBubble(message: _messages[i]);
            },
          ),
        ),

        // ── QUICK REPLIES ──────────────────────────────────────────
        if (_showQuick)
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [s.chatQuick1, s.chatQuick2, s.chatQuick3, s.chatQuick4]
                  .map((q) => _QuickChip(label: q, onTap: () => _send(q)))
                  .toList(),
            ),
          ),

        if (_showQuick) const SizedBox(height: 8),

        // ── INPUT ──────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 12),
          decoration: const BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _kBorder),
                ),
                child: TextField(
                  controller: _ctrl,
                  style: GoogleFonts.dmSans(color: _kText, fontSize: 14),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    hintText: s.chatInputHint,
                    hintStyle: GoogleFonts.dmSans(color: _kMuted, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _send(_ctrl.text),
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kAccent, Color(0xFFE8920A)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.send_rounded, color: _kBg, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── MESSAGE BUBBLE ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kAccent, Color(0xFFE8920A)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.support_agent_rounded, color: _kBg, size: 16),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? _kAccent : _kSurface,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4  : 18),
                ),
                border: isUser ? null : Border.all(color: _kBorder),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: isUser ? _kBg : _kText,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// ── TYPING BUBBLE ─────────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  final String label;
  const _TypingBubble({required this.label});
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double>    _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Container(
        width: 28, height: 28,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kAccent, Color(0xFFE8920A)]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.support_agent_rounded, color: _kBg, size: 16),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: _kBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _Dot(delay: 0,   fade: _fade),
          const SizedBox(width: 4),
          _Dot(delay: 0.3, fade: _fade),
          const SizedBox(width: 4),
          _Dot(delay: 0.6, fade: _fade),
          const SizedBox(width: 8),
          Text(widget.label,
              style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
        ]),
      ),
    ]),
  );
}

class _Dot extends StatelessWidget {
  final double delay;
  final Animation<double> fade;
  const _Dot({required this.delay, required this.fade});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: fade,
    builder: (_, __) {
      final v = ((fade.value + delay) % 1.0);
      final opacity = (v < 0.5 ? v * 2 : (1 - v) * 2).clamp(0.3, 1.0);
      return Opacity(
        opacity: opacity,
        child: Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(color: _kAccent, shape: BoxShape.circle),
        ),
      );
    },
  );
}

// ── QUICK REPLY CHIP ──────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final String       label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _kAccent.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: GoogleFonts.syne(
              fontSize: 12, fontWeight: FontWeight.w600, color: _kAccent)),
    ),
  );
}

// ── MODEL ─────────────────────────────────────────────────────────────────────

class _Message {
  final String text;
  final bool   isUser;
  const _Message({required this.text, required this.isUser});
}
