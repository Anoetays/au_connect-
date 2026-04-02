import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:au_connect/main.dart';

class LanguageSelectionScreen extends StatefulWidget {
  /// When [isChange] is true (called from Settings), the screen pops instead
  /// of replacing the route, and the Continue button label says "Apply".
  final bool isChange;
  const LanguageSelectionScreen({super.key, this.isChange = false});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selected; // language code: en | fr | pt | sw

  static const _languages = [
    ('en', '🇬🇧', 'English'),
    ('fr', '🇫🇷', 'Français'),
    ('pt', '🇵🇹', 'Português'),
    ('sw', '🇹🇿', 'Kiswahili'),
  ];

  static const _crimsonDark = Color(0xFF7F1D1D);
  static const _crimson = Color(0xFFB91C1C);

  Future<void> _confirm() async {
    if (_selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', _selected!);

    if (!mounted) return;
    AuConnectApp.of(context)?.setLocale(Locale(_selected!));

    if (widget.isChange) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_crimsonDark, _crimson],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  children: [
                    // Back button when changing language
                    if (widget.isChange)
                      Align(
                        alignment: Alignment.topLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.chevron_left_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    if (widget.isChange) const SizedBox(height: 12),

                    // Logo
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.school_rounded,
                            color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // App name
                    Text(
                      'AU Connect',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Heading
                    Text(
                      'Choose Your Language',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 2×2 language grid
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _languages
                            .map((lang) => _LangCard(
                                  code: lang.$1,
                                  flag: lang.$2,
                                  label: lang.$3,
                                  selected: _selected == lang.$1,
                                  onTap: () =>
                                      setState(() => _selected = lang.$1),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Continue button
                    _ContinueButton(
                      label: widget.isChange ? 'Apply' : 'Continue',
                      enabled: _selected != null,
                      onTap: _confirm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Language card ─────────────────────────────────────────────────────────────

class _LangCard extends StatefulWidget {
  final String code;
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangCard({
    required this.code,
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_LangCard> createState() => _LangCardState();
}

class _LangCardState extends State<_LangCard> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selected
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.25),
              width: widget.selected ? 2.5 : 1.5,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 2,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.flag, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Continue button ───────────────────────────────────────────────────────────

class _ContinueButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _ContinueButton(
      {required this.label, required this.enabled, required this.onTap});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _hovered = false;

  static const _crimson = Color(0xFFB91C1C);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.enabled
                ? (_hovered
                    ? Colors.white.withValues(alpha: 0.92)
                    : Colors.white)
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: widget.enabled ? _crimson : Colors.white54,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
