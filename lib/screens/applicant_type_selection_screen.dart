import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/l10n/app_localizations.dart';

class ApplicantTypeSelectionScreen extends StatefulWidget {
  const ApplicantTypeSelectionScreen({super.key});

  @override
  State<ApplicantTypeSelectionScreen> createState() =>
      _ApplicantTypeSelectionScreenState();
}

class _ApplicantTypeSelectionScreenState
    extends State<ApplicantTypeSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  List<_Pathway> _buildPathways(AppLocalizations l10n) => [
    _Pathway(
      icon: Icons.home_rounded,
      iconClass: _IconClass.local,
      title: l10n.localApplicant,
      tag: l10n.zimbabweanCitizen,
      tagClass: _TagClass.green,
      description: l10n.localApplicantDesc,
      route: '/onboarding_dashboard',
      badge: l10n.mostCommon,
    ),
    _Pathway(
      icon: Icons.language_rounded,
      iconClass: _IconClass.intl,
      title: l10n.international,
      tag: l10n.usdFeesApply,
      tagClass: _TagClass.blue,
      description: l10n.internationalDesc,
      route: '/international_dashboard',
      badge: null,
    ),
    _Pathway(
      icon: Icons.school_rounded,
      iconClass: _IconClass.masters,
      title: l10n.mastersPostgraduate,
      tag: l10n.researchTrack,
      tagClass: _TagClass.purple,
      description: l10n.mastersDesc,
      route: '/masters_dashboard',
      badge: null,
    ),
    _Pathway(
      icon: Icons.replay_rounded,
      iconClass: _IconClass.returning,
      title: l10n.returningStudent,
      tag: l10n.reAdmission,
      tagClass: _TagClass.green,
      description: l10n.returningDesc,
      route: '/returning_dashboard',
      badge: null,
    ),
  ];

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
          (0.05 + i * 0.08).clamp(0.0, 0.9),
          (0.05 + i * 0.08 + 0.45).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pathways = _buildPathways(l10n);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Bottom glow blob
          Positioned(
            bottom: -150, right: -100,
            child: IgnorePointer(
              child: Container(
                width: 400, height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          // Top accent bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primaryDark, AppTheme.primary, Color(0xFFE85070), AppTheme.primary,
                ]),
              ),
            ),
          ),
          // Main scroll content
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHero(context)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 2),
                          child: Text(
                            l10n.selectPathway,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 3.2,
                              color: AppTheme.textMuted,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        );
                      }
                      final idx = i - 1;
                      return _AnimCard(
                        anim: _stagger(idx),
                        child: _PathwayCard(
                          pathway: pathways[idx],
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pushNamed(context, pathways[idx].route);
                          },
                        ),
                      );
                    },
                    childCount: pathways.length + 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand row
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Africa University',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.4,
                          fontFamily: GoogleFonts.dmSans().fontFamily,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Eyebrow
                  Text(
                    l10n.applicationPortal,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3.5,
                      color: Colors.white.withValues(alpha: 0.55),
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                      children: const [
                        TextSpan(text: 'Welcome to\n'),
                        TextSpan(
                          text: 'AU Connect',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Subtitle
                  Text(
                    l10n.chooseApplicantType,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.65,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Pill row
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: const [
                      _HeroPill(label: '5 pathways', icon: Icons.list_rounded),
                      _HeroPill(label: 'Online Application', icon: Icons.desktop_mac_rounded),
                      _HeroPill(label: 'Fast Track', icon: Icons.bolt_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

}

// ── Hero pill chip ────────────────────────────────────────────────────────────

class _HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _HeroPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated entrance wrapper ─────────────────────────────────────────────────

class _AnimCard extends StatelessWidget {
  final Animation<double> anim;
  final Widget child;
  const _AnimCard({required this.anim, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - anim.value)),
          child: child,
        ),
      ),
    );
  }
}

// ── Pathway card ──────────────────────────────────────────────────────────────

class _PathwayCard extends StatefulWidget {
  final _Pathway pathway;
  final VoidCallback onTap;
  const _PathwayCard({required this.pathway, required this.onTap});

  @override
  State<_PathwayCard> createState() => _PathwayCardState();
}

class _PathwayCardState extends State<_PathwayCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.pathway;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hovered
                    ? AppTheme.primary.withValues(alpha: 0.28)
                    : AppTheme.primary.withValues(alpha: 0.13),
                width: 1.5,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        blurRadius: 36,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.06),
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
                  // Card content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                p.iconClass.bgStart,
                                p.iconClass.bgEnd,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: p.iconClass.border),
                          ),
                          child: Icon(p.icon,
                              size: 22, color: p.iconClass.iconColor),
                        ),
                        const SizedBox(width: 14),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 7,
                                children: [
                                  Text(
                                    p.title,
                                    style: GoogleFonts.dmSerifDisplay(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: _hovered
                                          ? AppTheme.primaryDark
                                          : AppTheme.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: p.tagClass.bg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: p.tagClass.border),
                                    ),
                                    child: Text(
                                      p.tag,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.5,
                                        color: p.tagClass.text,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                p.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                  color: AppTheme.textMuted,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Arrow button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          transform: Matrix4.translationValues(
                              _hovered ? 3 : 0, 0, 0),
                          width: 36, height: 36,
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
                  // "Most common" badge
                  if (p.badge != null)
                    Positioned(
                      top: 0, right: 18,
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
                          p.badge!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
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
      ),
    );
  }
}

// ── Icon colour variants ──────────────────────────────────────────────────────

enum _IconClass { local, intl, masters, returning, transfer }

extension _IconClassStyle on _IconClass {
  Color get bgStart => switch (this) {
        _IconClass.local => AppTheme.primaryLight,
        _IconClass.intl => const Color(0xFFEAF0FF),
        _IconClass.masters => const Color(0xFFEFE8F5),
        _IconClass.returning => const Color(0xFFE8F5EE),
        _IconClass.transfer => const Color(0xFFFFF3E0),
      };

  Color get bgEnd => switch (this) {
        _IconClass.local => AppTheme.border,
        _IconClass.intl => const Color(0xFFD0DCFF),
        _IconClass.masters => const Color(0xFFDDD0EE),
        _IconClass.returning => const Color(0xFFC8EDD8),
        _IconClass.transfer => const Color(0xFFFFE0B0),
      };

  Color get border => switch (this) {
        _IconClass.local => AppTheme.border,
        _IconClass.intl => const Color(0xFFC0CCFF),
        _IconClass.masters => const Color(0xFFCCBBEE),
        _IconClass.returning => const Color(0xFFAADDBB),
        _IconClass.transfer => const Color(0xFFFFCC80),
      };

  Color get iconColor => switch (this) {
        _IconClass.local => AppTheme.primary,
        _IconClass.intl => const Color(0xFF3A5FCC),
        _IconClass.masters => const Color(0xFF7040BB),
        _IconClass.returning => const Color(0xFF1E8A4A),
        _IconClass.transfer => const Color(0xFFC07010),
      };
}

// ── Tag colour variants ───────────────────────────────────────────────────────

enum _TagClass { green, blue, purple, orange, red }

extension _TagClassStyle on _TagClass {
  Color get bg => switch (this) {
        _TagClass.green => const Color(0xFFE8F5EE),
        _TagClass.blue => const Color(0xFFEAF0FF),
        _TagClass.purple => const Color(0xFFEFE8F5),
        _TagClass.orange => const Color(0xFFFFF3E0),
        _TagClass.red => AppTheme.primaryLight,
      };

  Color get border => switch (this) {
        _TagClass.green => const Color(0xFFAADDBB),
        _TagClass.blue => const Color(0xFFC0CCFF),
        _TagClass.purple => const Color(0xFFCCBBEE),
        _TagClass.orange => const Color(0xFFFFCC80),
        _TagClass.red => AppTheme.border,
      };

  Color get text => switch (this) {
        _TagClass.green => const Color(0xFF1E8A4A),
        _TagClass.blue => const Color(0xFF3A5FCC),
        _TagClass.purple => const Color(0xFF7040BB),
        _TagClass.orange => const Color(0xFFC07010),
        _TagClass.red => AppTheme.primary,
      };
}

// ── Data class ────────────────────────────────────────────────────────────────

class _Pathway {
  final IconData icon;
  final _IconClass iconClass;
  final String title;
  final String tag;
  final _TagClass tagClass;
  final String description;
  final String route;
  final String? badge;

  const _Pathway({
    required this.icon,
    required this.iconClass,
    required this.title,
    required this.tag,
    required this.tagClass,
    required this.description,
    required this.route,
    required this.badge,
  });
}
