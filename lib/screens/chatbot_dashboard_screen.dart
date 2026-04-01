import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/anthropic_service.dart';
import 'package:au_connect/services/gemini_service.dart';

/// Full-featured AI chatbot screen powered by Google Gemini.
/// Accepts a [systemPrompt] so it can be reused across applicant types, students, etc.
class ChatbotDashboardScreen extends StatefulWidget {
  final String systemPrompt;
  final String title;

  const ChatbotDashboardScreen({
    super.key,
    this.systemPrompt = AUSystemPrompts.applicant,
    this.title = 'Campus Assistant',
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

  static const _languages = ['English', 'Français', 'Português', 'Kiswahili'];

  @override
  void initState() {
    super.initState();
    _aiService = AIChatService(systemPrompt: widget.systemPrompt);
    _messages.add({
      'role': 'bot',
      'text':
          'Hello! I\'m your Africa University assistant. How can I help you today?\n\nI can assist with application requirements, documents, programmes, fees, and more.',
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

  void _sendQuickMessage(String message) => _sendMessage(override: message);

  /// Switches the active language and silently instructs Gemini to respond in it.
  Future<void> _switchLanguage(String lang) async {
    if (_selectedLanguage == lang) return;
    setState(() => _selectedLanguage = lang);
    // Hidden instruction — not shown in the UI
    await _aiService.sendMessage('Please respond in $lang from now on.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leadingWidth: 200,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: const Icon(Symbols.smart_toy,
                    color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Africa University',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/admin_dashboard'),
            icon: const Icon(Symbols.notifications,
                color: AppTheme.textMuted),
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppTheme.border, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeader(isDark),
                      const SizedBox(height: 32),
                      _buildLanguageSelector(),
                      const SizedBox(height: 40),
                      _buildChatHistory(isDark),
                      if (_isTyping) ...[
                        const SizedBox(height: 16),
                        _buildTypingIndicator(isDark),
                      ],
                      // Quick-action cards shown only before first user message
                      if (_messages.length == 1) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(left: 48.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _buildActionCard(
                                    Symbols.check_circle,
                                    'Track Application',
                                    isDark,
                                    () => _sendQuickMessage(
                                        'How do I track my application status?'),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildActionCard(
                                    Symbols.description,
                                    'Required Documents',
                                    isDark,
                                    () => _sendQuickMessage(
                                        'What documents do I need?'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildActionCard(
                                    Symbols.school,
                                    'Available Programmes',
                                    isDark,
                                    () => _sendQuickMessage(
                                        'What programmes are available?'),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildActionCard(
                                    Symbols.payments,
                                    'Application Fee',
                                    isDark,
                                    () => _sendQuickMessage(
                                        'How do I pay the application fee?'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Symbols.smart_toy, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.textLight : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            'Powered by Gemini AI — ask me anything about Africa University.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : AppTheme.textMuted,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _languages.map((lang) {
        final isSelected = _selectedLanguage == lang;
        return InkWell(
          onTap: () => _switchLanguage(lang),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Symbols.translate,
                      color: Colors.white, size: 13),
                  const SizedBox(width: 5),
                ],
                Text(
                  lang,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChatHistory(bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return msg['role'] == 'bot'
            ? _buildBotMessage(msg['text']!, isDark)
            : _buildUserMessage(msg['text']!, isDark);
      },
    );
  }

  Widget _buildBotMessage(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
          ),
          child:
              const Icon(Symbols.smart_toy, color: AppTheme.primary, size: 17),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildUserMessage(String text, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 48),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 14, color: Colors.white, height: 1.6),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Symbols.person, color: Colors.white, size: 18, fill: 1),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            shape: BoxShape.circle,
            border:
                Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
          ),
          child: const Icon(Symbols.smart_toy,
              color: AppTheme.primary, size: 17),
        ),
        const SizedBox(width: 12),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(color: AppTheme.border),
          ),
          child: _AnimatedDots(),
        ),
      ],
    );
  }

  Widget _buildActionCard(
      IconData icon, String title, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.textPrimary
            : AppTheme.background,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.textPrimary
                : AppTheme.border,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.textPrimary
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.textSecondary
                          : AppTheme.border,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about Africa University...',
                      hintStyle: TextStyle(
                          color: AppTheme.textMuted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isTyping
                      ? AppTheme.primary.withValues(alpha: 0.5)
                      : AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isTyping ? Symbols.hourglass_top : Symbols.send,
                    color: Colors.white,
                    size: 18,
                    fill: 1,
                  ),
                  onPressed: _isTyping ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated three-dot typing indicator.
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final phase = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (0.3 + 0.7 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2)).clamp(0.3, 1.0);
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 4.0 : 0),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
