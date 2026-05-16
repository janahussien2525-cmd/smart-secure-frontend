import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/strings.dart';
import 'live_chat_screen.dart';

const _kBg      = Color(0xFF2E3449);
const _kSurface = Color(0xFF434A64);
const _kCard    = Color(0xFF394057);
const _kAccent  = Color(0xFFF5A623);
const _kGreen   = Color(0xFF00C9A7);
const _kPurple  = Color(0xFF7B8FFF);
const _kText    = Color(0xFFEEF0F6);
const _kMuted   = Color(0xFF6A7090);
const _kBorder  = Color(0x18FFFFFF);

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final faqs = [
      _FAQ(question: s.faqQ1, answer: s.faqA1),
      _FAQ(question: s.faqQ2, answer: s.faqA2),
      _FAQ(question: s.faqQ3, answer: s.faqA3),
      _FAQ(question: s.faqQ4, answer: s.faqA4),
      _FAQ(question: s.faqQ5, answer: s.faqA5),
      _FAQ(question: s.faqQ6, answer: s.faqA6),
      _FAQ(question: s.faqQ7, answer: s.faqA7),
      _FAQ(question: s.faqQ8, answer: s.faqA8),
    ];

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
            Text(s.helpCenterTitle, style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
          ]),
        ),

        // ── CONTENT ───────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 24, 20, bottom + 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Contact cards
              Row(children: [
                Expanded(child: _ContactCard(
                  icon:  Icons.email_outlined,
                  label: s.emailUs,
                  sub:   s.supportEmail,
                  color: _kPurple,
                  onTap: () {},
                )),
                const SizedBox(width: 12),
                Expanded(child: _ContactCard(
                  icon:  Icons.chat_bubble_outline_rounded,
                  label: s.liveChat,
                  sub:   s.avgResponse,
                  color: _kGreen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LiveChatScreen()),
                  ),
                )),
              ]),

              const SizedBox(height: 28),

              Text(s.frequentlyAskedQuestions,
                style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w700, color: _kMuted, letterSpacing: 1.5)),
              const SizedBox(height: 14),

              // FAQ accordion
              Container(
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  children: List.generate(faqs.length, (i) {
                    final isLast     = i == faqs.length - 1;
                    final isExpanded = _expandedIndex == i;
                    return _FAQTile(
                      faq:        faqs[i],
                      expanded:   isExpanded,
                      showDivider: !isLast,
                      onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 28),

              // App info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(children: [
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kAccent, Color(0xFFE8920A)]),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.lock_rounded, color: _kBg, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.appTitle, style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w800, color: _kText)),
                      Text(s.appVersion, style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  Container(height: 1, color: _kBorder),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _AppLink(label: s.privacyPolicy, onTap: () {})),
                    Container(width: 1, height: 16, color: _kBorder),
                    Expanded(child: _AppLink(label: s.termsOfService, onTap: () {})),
                    Container(width: 1, height: 16, color: _kBorder),
                    Expanded(child: _AppLink(label: s.licenses, onTap: () {})),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── CONTACT CARD ──────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String   label, sub;
  final Color    color;
  final VoidCallback onTap;
  const _ContactCard({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(label, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
        const SizedBox(height: 3),
        Text(sub, style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted), maxLines: 2),
      ]),
    ),
  );
}

// ── FAQ TILE ──────────────────────────────────────────────
class _FAQTile extends StatelessWidget {
  final _FAQ         faq;
  final bool         expanded, showDivider;
  final VoidCallback onTap;
  const _FAQTile({required this.faq, required this.expanded, required this.showDivider, required this.onTap});

  @override
  Widget build(BuildContext context) => Column(children: [
    GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Expanded(child: Text(faq.question,
            style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700,
              color: expanded ? _kAccent : _kText))),
          const SizedBox(width: 12),
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.keyboard_arrow_down_rounded,
              color: expanded ? _kAccent : _kMuted, size: 20),
          ),
        ]),
      ),
    ),
    AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Text(faq.answer, style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted, height: 1.6)),
      ),
      secondChild: const SizedBox.shrink(),
    ),
    if (showDivider) Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: _kBorder),
  ]);
}

class _FAQ {
  final String question, answer;
  const _FAQ({required this.question, required this.answer});
}

// ── APP LINK ──────────────────────────────────────────────
class _AppLink extends StatelessWidget {
  final String       label;
  final VoidCallback onTap;
  const _AppLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Center(child: Text(label,
      style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted,
        decoration: TextDecoration.underline, decorationColor: _kMuted))),
  );
}
