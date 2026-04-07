import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/l10n/app_localizations.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Animation<double> _stagger(int i) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          (i * 0.12).clamp(0.0, 0.9),
          ((i * 0.12) + 0.55).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Loading...', style: GoogleFonts.poppins(fontSize: 20)),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Background blobs
          _Blob(bottom: -180, left: -120, size: 520, opacity: 0.10),
          _Blob(top: -140, right: -100, size: 380, opacity: 0.07),

          // Top accent bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryDark,
                    AppTheme.primary,
                    Color(0xFFE85070),
                    AppTheme.primary,
                  ],
                ),
              ),
            ),
          ),

          // Top-right buttons: language + info
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 18),
                child: _AnimFade(
                  anim: _stagger(5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LangButton(onTap: () =>
                          Navigator.pushNamed(context, '/language_change')),
                      const SizedBox(width: 8),
                      const _InfoButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                  child: Column(
                    children: [
                      _AnimFade(
                          anim: _stagger(0), child: _buildHeader(context)),
                      const SizedBox(height: 28),
                      _AnimFade(
                        anim: _stagger(1),
                        child: _RoleCard(
                          icon: Icons.people_rounded,
                          title: l10n.studentRole,
                          description: l10n.studentDesc,
                          badge: l10n.mostCommon,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pushNamed(context, '/student_sign_in');
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimFade(
                        anim: _stagger(2),
                        child: _RoleCard(
                          icon: Icons.description_rounded,
                          title: l10n.applicantRole,
                          description: l10n.applicantDesc,
                          badge: null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pushNamed(context, '/applicant_sign_up');
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimFade(
                        anim: _stagger(3),
                        child: _RoleCard(
                          icon: Icons.admin_panel_settings_rounded,
                          title: l10n.adminRole,
                          description: l10n.adminDesc,
                          badge: null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pushNamed(context, '/admin_sign_in');
                          },
                        ),
                      ),
                      const SizedBox(height: 36),
                      _AnimFade(
                          anim: _stagger(4), child: _buildFooter()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Logo ring
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.border, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.15),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppTheme.primaryLight,
                spreadRadius: 6,
                blurRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.school_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Eyebrow
        const Text(
          'AFRICA UNIVERSITY',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 3.5,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 10),

        // Title
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: -0.6,
              height: 1.1,
            ),
            children: const [
              TextSpan(text: 'Welcome to '),
              TextSpan(
                text: 'AU Connect',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Subtitle
        const Text(
          'The central hub for your university journey.\nPlease select your role to continue.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: AppTheme.textMuted,
            height: 1.65,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '© 2024 AU Connect',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w300,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('·',
              style: TextStyle(color: AppTheme.border, fontSize: 11)),
        ),
        const Text(
          'All rights reserved',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

// ── Background blob ──────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double? top, bottom, left, right;
  final double size;
  final double opacity;

  const _Blob({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.primary.withValues(alpha: opacity),
                AppTheme.primary.withValues(alpha: opacity * 0.4),
                Colors.transparent,
              ],
              stops: const [0.0, 0.6, 0.85],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated fade + slide wrapper ────────────────────────────────────────────

class _AnimFade extends StatelessWidget {
  final Animation<double> anim;
  final Widget child;

  const _AnimFade({required this.anim, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - anim.value)),
          child: child,
        ),
      ),
    );
  }
}

// ── Info button ──────────────────────────────────────────────────────────────

class _InfoButton extends StatefulWidget {
  const _InfoButton();

  @override
  State<_InfoButton> createState() => _InfoButtonState();
}

class _InfoButtonState extends State<_InfoButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surface,
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: _hovered ? 0.4 : 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary
                  .withValues(alpha: _hovered ? 0.18 : 0.08),
              blurRadius: _hovered ? 16 : 8,
            ),
          ],
        ),
        child: const Icon(Icons.info_outline_rounded,
            size: 15, color: AppTheme.textMuted),
      ),
    );
  }
}

// ── Language button ───────────────────────────────────────────────────────────

class _LangButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LangButton({required this.onTap});

  @override
  State<_LangButton> createState() => _LangButtonState();
}

class _LangButtonState extends State<_LangButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: _hovered ? 0.4 : 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary
                    .withValues(alpha: _hovered ? 0.18 : 0.08),
                blurRadius: _hovered ? 16 : 8,
              ),
            ],
          ),
          child: const Icon(Icons.language_rounded,
              size: 15, color: AppTheme.textMuted),
        ),
      ),
    );
  }
}

// ── Role card ────────────────────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? badge;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered
                  ? AppTheme.primary.withValues(alpha: 0.30)
                  : AppTheme.primary.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.13),
                      blurRadius: 36,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Red wash overlay on hover
                if (_hovered)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.03),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),
                // Left stripe
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _hovered
                            ? [AppTheme.primary, AppTheme.primaryDark]
                            : [Colors.transparent, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Card content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
                  child: Row(
                    children: [
                      // Icon badge
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _hovered
                              ? AppTheme.primary.withValues(alpha: 0.10)
                              : AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.border,
                          ),
                        ),
                        child: Icon(widget.icon,
                            color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 16),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _hovered
                                    ? AppTheme.primaryDark
                                    : AppTheme.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.description,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w300,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Arrow button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hovered ? AppTheme.primary : Colors.transparent,
                          border: Border.all(
                            color: _hovered
                                ? AppTheme.primary
                                : AppTheme.primary.withValues(alpha: 0.18),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: _hovered ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge
                if (widget.badge != null)
                  Positioned(
                    top: 0,
                    right: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.badge!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
