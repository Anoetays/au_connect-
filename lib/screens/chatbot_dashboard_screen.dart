import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/anthropic_service.dart';
import 'package:au_connect/services/gemini_service.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-featured AI chatbot screen powered by Google Gemini.
/// Accepts a [systemPrompt] so it can be reused across applicant types, students, etc.
class ChatbotDashboardScreen extends StatefulWidget {
  final String systemPrompt;
  final String title;

  const ChatbotDashboardScreen({
    super.key,
    this.systemPrompt = AUSystemPrompts.applicant,
    this.title = 'Admissions Assistant',
  });

  @override
  State<ChatbotDashboardScreen> createState() =>
      _ChatbotDashboardScreenState();
}

class _ChatbotDashboardScreenState extends State<ChatbotDashboardScreen> {
  String _selectedLanguage = 'English';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Chat messages displayed in the UI: {role: 'user'|'bot', text: '...'}
  final List<Map<String, String>> _messages = [];

  bool _isTyping = false;
  late final AIChatService _aiService;

  static const _languages = [
    ('🇬🇧', 'English'),
    ('🇫🇷', 'Français'),
    ('🇵🇹', 'Português'),
    ('🇹🇿', 'Kiswahili'),
  ];

  static const _quickActions = [
    ('✅', 'Track Application',    'Check your status',   'How do I track my application?'),
    ('📄', 'Required Documents',   'See the full list',   'What documents do I need to apply?'),
    ('🎓', 'Available Programmes', 'Browse faculties',    'What programmes does Africa University offer?'),
    ('💳', 'Application Fee',      'Payment options',     'How much is the application fee and how do I pay?'),
  ];

  static const _suggestions = [
    'What are the entry requirements for undergraduate programmes?',
    'When does the next intake start?',
    'Can I apply as an international student?',
    'How long does the admissions process take?',
  ];

  // ── color tokens ────────────────────────────────────────────────────────────
  static const _kCrimson  = AppTheme.primaryCrimson;
  static const _kCrimsonD = AppTheme.primaryDark;
  static const _kParch    = AppTheme.background;
  static const _kSurf     = Colors.white;
  static const _kInk      = AppTheme.textPrimary;
  static const _kSub      = AppTheme.textSecondary;
  static const _kMuted    = AppTheme.textMuted;
  static const _kBorder   = AppTheme.border;
  static const _kRedBg    = AppTheme.primaryLight;

  @override
  void initState() {
    super.initState();
    _aiService = AIChatService(systemPrompt: widget.systemPrompt);
    _messages.add({
      'role': 'bot',
      'text':
          'Hello! I\'m your Africa University admissions assistant. How can I help you today?\n\nI can assist with application requirements, documents, programmes, fees, and more.',
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? override}) async {
    final text = (override ?? _messageController.text).trim();
    if (text.isEmpty || _isTyping) return;

    if (override == null) _messageController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });
    _scrollToBottom();

    final reply = await _aiService.sendMessage(text);

    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'bot', 'text': reply});
      _isTyping = false;
    });
    _scrollToBottom();
  }

  Future<void> _switchLanguage(String lang) async {
    if (_selectedLanguage == lang) return;
    setState(() => _selectedLanguage = lang);
    await _aiService.sendMessage('Please respond in $lang from now on.');
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kParch,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 22),
                      _buildLanguageTabs(),
                      const SizedBox(height: 22),
                      _buildMessages(),
                      if (_isTyping) ...[
                        const SizedBox(height: 14),
                        _buildTypingBubble(),
                      ],
                      // Quick actions + suggestions only before first user message
                      if (_messages.length == 1) ...[
                        const SizedBox(height: 18),
                        _buildSectionLabel('Quick Actions'),
                        _buildQuickGrid(),
                        const SizedBox(height: 20),
                        _buildSectionLabel('People Also Ask'),
                        _buildSuggestionChips(),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: _kSurf,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Row(
                  children: [
                    const Icon(Icons.chevron_left_rounded,
                        size: 20, color: _kCrimson),
                    Text('Back',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kCrimson)),
                  ],
                ),
              ),
              const Spacer(),
              Text('AI Assistant',
                  style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kInk)),
              const Spacer(),
              const Text('🔔', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [_kCrimson, _kCrimsonD],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x4DB71C1C),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text('🎓', style: TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 12),
        Text('Admissions Assistant',
            style: GoogleFonts.dmSans(
                fontSize: 20, fontWeight: FontWeight.w700, color: _kInk)),
        const SizedBox(height: 4),
        Text(
          'Powered by Gemini AI — ask me anything\nabout Africa University.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
              fontSize: 12, color: _kSub, height: 1.5),
        ),
      ],
    );
  }

  // ── Language tabs ─────────────────────────────────────────────────────────

  Widget _buildLanguageTabs() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _languages.map((lang) {
        final isActive = _selectedLanguage == lang.$2;
        return GestureDetector(
          onTap: () => _switchLanguage(lang.$2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: isActive ? _kCrimson : _kSurf,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? _kCrimson : _kBorder,
                width: 1.5,
              ),
            ),
            child: Text(
              '${lang.$1} ${lang.$2}',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : _kSub,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Widget _buildMessages() {
    return Column(
      children: _messages.map((msg) {
        final isBot = msg['role'] == 'bot';
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: isBot ? _buildBotBubble(msg['text']!) : _buildUserBubble(msg['text']!),
        );
      }).toList(),
    );
  }

  Widget _buildBotBubble(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _kRedBg,
          ),
          child: const Center(child: Text('🎓', style: TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
            decoration: BoxDecoration(
              color: _kSurf,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _kBorder),
            ),
            child: Text(text,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: _kInk, height: 1.55)),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildUserBubble(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 48),
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
            decoration: const BoxDecoration(
              color: _kCrimson,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(text,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: Colors.white, height: 1.55)),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _kCrimson,
          ),
          child: Center(
            child: Text('A',
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ── Typing indicator ──────────────────────────────────────────────────────

  Widget _buildTypingBubble() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _kRedBg,
          ),
          child: const Center(child: Text('🎓', style: TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            color: _kSurf,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: _kBorder),
          ),
          child: const _AnimatedDots(),
        ),
      ],
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: _kSub),
      ),
    );
  }

  // ── Quick action grid ─────────────────────────────────────────────────────

  Widget _buildQuickGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: _quickActions.map((q) {
        return _QuickCard(
          emoji: q.$1,
          label: q.$2,
          sub: q.$3,
          onTap: () => _sendMessage(override: q.$4),
        );
      }).toList(),
    );
  }

  // ── Suggestion chips ──────────────────────────────────────────────────────

  Widget _buildSuggestionChips() {
    return Column(
      children: _suggestions.map((s) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _sendMessage(override: s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _kSurf,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(s,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kInk)),
                  ),
                  Text('›',
                      style: TextStyle(
                          fontSize: 16, color: _kMuted,
                          fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _kParch,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _kSurf,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder, width: 1.5),
                  ),
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                    style: GoogleFonts.dmSans(fontSize: 13, color: _kInk),
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about Africa University…',
                      hintStyle:
                          GoogleFonts.dmSans(fontSize: 13, color: _kMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isTyping ? null : _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _isTyping
                        ? _kCrimson.withValues(alpha: 0.5)
                        : _kCrimson,
                    shape: BoxShape.circle,
                    boxShadow: _isTyping
                        ? []
                        : const [
                            BoxShadow(
                              color: Color(0x59B71C1C),
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                          ],
                  ),
                  child: const Center(
                    child: Text('›',
                        style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            height: 1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick action card ─────────────────────────────────────────────────────────

class _QuickCard extends StatefulWidget {
  final String emoji;
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _QuickCard(
      {required this.emoji,
      required this.label,
      required this.sub,
      required this.onTap});

  @override
  State<_QuickCard> createState() => _QuickCardState();
}

class _QuickCardState extends State<_QuickCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? AppTheme.primaryLight
                  : AppTheme.border,
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppTheme.primaryCrimson.withValues(alpha: 0.09),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(widget.emoji,
                      style: const TextStyle(fontSize: 17)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.label,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(widget.sub,
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Animated typing dots ──────────────────────────────────────────────────────

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final phase = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (0.3 + 0.7 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2))
                .clamp(0.3, 1.0);
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 4.0 : 0),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.textMuted.withValues(alpha: opacity),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
