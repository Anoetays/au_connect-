import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/services/anthropic_service.dart';
import 'chatbot_dashboard_screen.dart';
import 'document_upload_screen.dart';
import 'select_program_screen.dart';
import 'submit_application_screen.dart';

// ─── color tokens ─────────────────────────────────────────────────────────────
const _kCrimson      = AppTheme.primaryDark;
const _kCrimsonLight = AppTheme.primaryCrimson;
const _kCrimsonPale  = AppTheme.primaryLight;
const _kInk          = AppTheme.textPrimary;
const _kInkMid       = AppTheme.textSecondary;
const _kParchment    = AppTheme.background;
const _kParchDeep    = Color(0xFFF0EBE1);
const _kBorder       = AppTheme.border;
const _kMuted        = AppTheme.textMuted;
const _kGreenBg      = Color(0xFFD1FAE5);
const _kGreenFg      = Color(0xFF10B981);

class ApplicationStatusScreen extends StatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  State<ApplicationStatusScreen> createState() =>
      _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _application;
  List<Map<String, dynamic>> _documents = [];
  bool _loading = true;
  String? _error;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  String _lang = 'English';
  bool _langOpen = false;
  static const _langs = ['English', 'French', 'Shona', 'Ndebele'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final app = await SupabaseService.getMyApplication();
      List<Map<String, dynamic>> docs = [];
      if (app != null) {
        docs = await SupabaseService.getDocuments(app['id'] as String);
      }
      if (!mounted) return;
      setState(() {
        _application = app;
        _documents   = docs;
        _loading     = false;
      });
      _ctrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load application data.'; _loading = false; });
    }
  }

  bool get _hasProgram   => (_application?['program'] as String?) != null;
  bool get _hasDocuments => _documents.isNotEmpty;
  bool get _hasSubmitted => !(['draft', null].contains(_application?['status']));

  int get _currentStepIndex {
    if (!_hasProgram)   return 2;
    if (!_hasDocuments) return 3;
    if (!_hasSubmitted) return 4;
    return 5;
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { if (_langOpen) setState(() => _langOpen = false); },
      child: Scaffold(
        backgroundColor: _kParchment,
        body: Column(
          children: [
            _buildTopNav(context),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kCrimson))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: _kCrimson,
                      child: FadeTransition(
                        opacity: _fade,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildBody(context),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TOP NAV ────────────────────────────────────────────────────────────────
  Widget _buildTopNav(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: Color(0xF5FAF7F2),
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          // Brand
          Text(
            'AU Connect',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _kCrimson,
              letterSpacing: 0.06 * 20,
            ),
          ),
          const Spacer(),
          // Nav links — scrollable on narrow screens
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Language button
                  _LangPicker(
                    selected: _lang,
                    open: _langOpen,
                    langs: _langs,
                    onToggle: () =>
                        setState(() => _langOpen = !_langOpen),
                    onSelect: (l) =>
                        setState(() { _lang = l; _langOpen = false; }),
                  ),
                  const SizedBox(width: 6),

                  _NavLink(
                    label: 'Dashboard',
                    icon: Icons.grid_view_rounded,
                    active: false,
                    onTap: () =>
                        Navigator.pushNamed(context, '/onboarding_dashboard'),
                  ),
                  _NavDivider(),
                  _NavLink(
                    label: 'Application Progress',
                    icon: Icons.show_chart_rounded,
                    active: true,
                  ),
                  _NavDivider(),
                  _NavLink(
                    label: 'Payments',
                    icon: Icons.credit_card_outlined,
                    active: false,
                    onTap: () =>
                        Navigator.pushNamed(context, '/payments'),
                  ),
                  _NavDivider(),
                  _NavLink(
                    label: 'Financial Assistance',
                    icon: Icons.list_rounded,
                    active: false,
                    onTap: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Financial Assistance – coming soon')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BODY ───────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_error != null) ...[
              _buildErrorBanner(),
              const SizedBox(height: 24),
            ],
            _application == null
                ? _buildEmptyCard(context)
                : _buildProgressCard(context),
          ],
        ),
      ),
    );
  }

  // ── ERROR BANNER ───────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 540),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded,
            color: Colors.orange.shade700, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(_error!,
              style: TextStyle(
                  color: Colors.orange.shade800, fontSize: 13)),
        ),
        TextButton(onPressed: _loadData, child: const Text('Retry')),
      ]),
    );
  }

  // ── EMPTY STATE CARD ──────────────────────────────────────────────────────
  Widget _buildEmptyCard(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 540),
      padding: const EdgeInsets.fromLTRB(48, 60, 48, 52),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1A1208),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x0A1A1208),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kCrimsonPale,
              border: Border.all(
                  color: _kCrimson.withValues(alpha: 0.15), width: 1.5),
            ),
            child: const Icon(Icons.calendar_today_outlined,
                size: 30, color: _kCrimson),
          ),
          const SizedBox(height: 28),

          Text(
            'No Application Found',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: _kInk,
              letterSpacing: 0.01 * 26,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 320,
            child: Text(
              "You haven't started an application yet. Go back to the dashboard to begin.",
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                color: _kMuted,
                height: 1.65,
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Gradient rule
          Container(
            width: 48,
            height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kCrimson, Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 36),

          // Start button
          _CrimsonButton(
            label: 'Start Application',
            onTap: () =>
                Navigator.pushNamed(context, '/onboarding_dashboard'),
          ),
          const SizedBox(height: 16),

          // Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Need help? ',
                style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatbotDashboardScreen(
                      systemPrompt: AUSystemPrompts.applicant,
                      title: 'Admissions Assistant',
                    ),
                  ),
                ),
                child: Text(
                  'Contact support',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kCrimson,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PROGRESS CARD ─────────────────────────────────────────────────────────
  Widget _buildProgressCard(BuildContext context) {
    final stepIndex = _currentStepIndex;
    final steps = [
      _AppStep(label: 'Personal Information', done: true),
      _AppStep(label: 'Academic History',      done: true),
      _AppStep(label: 'Programme Selection',   done: _hasProgram,   isCurrent: stepIndex == 2),
      _AppStep(label: 'Document Upload',       done: _hasDocuments, isCurrent: stepIndex == 3),
      _AppStep(label: 'Review & Submit',       done: _hasSubmitted, isCurrent: stepIndex == 4),
    ];

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.fromLTRB(36, 36, 36, 36),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1A1208),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Row(
            children: [
              _PulseDot(),
              const SizedBox(width: 10),
              Text(
                'IN PROGRESS',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _kGreenFg,
                  letterSpacing: 0.12 * 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Application Progress',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track your application steps below.',
            style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted),
          ),

          // Gradient rule
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kBorder, Colors.transparent],
                ),
              ),
            ),
          ),

          // Steps
          ...steps.asMap().entries.map((e) {
            return _StepRow(
              index: e.key,
              step: e.value,
              isLast: e.key == steps.length - 1,
            );
          }),

          const SizedBox(height: 28),

          // Continue button
          _CrimsonButton(
            label: 'Continue Application →',
            onTap: () => _handleContinue(context, stepIndex),
          ),

          // AI link
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ChatbotDashboardScreen(
                  systemPrompt: AUSystemPrompts.applicant,
                  title: 'Admissions Assistant',
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.smart_toy_outlined,
                    size: 13, color: _kMuted),
                const SizedBox(width: 6),
                Text(
                  'Have questions? Ask our AI assistant',
                  style: GoogleFonts.dmSans(
                      fontSize: 12.5, color: _kMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleContinue(BuildContext context, int stepIndex) {
    switch (stepIndex) {
      case 2:
        Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SelectProgramScreen()))
            .then((_) => _loadData());
        break;
      case 3:
        Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DocumentUploadScreen()))
            .then((_) => _loadData());
        break;
      case 4:
        Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const SubmitApplicationScreen()))
            .then((_) => _loadData());
        break;
      default:
        Navigator.pushNamed(context, '/onboarding_dashboard');
    }
  }
}

// ─── _AppStep ─────────────────────────────────────────────────────────────────
class _AppStep {
  final String label;
  final bool done, isCurrent;
  const _AppStep({
    required this.label,
    required this.done,
    this.isCurrent = false,
  });
}

// ─── _StepRow ─────────────────────────────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final int index;
  final _AppStep step;
  final bool isLast;

  const _StepRow({
    required this.index,
    required this.step,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: _kParchDeep)),
      ),
      child: Row(
        children: [
          // Circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.done ? _kGreenBg : _kParchDeep,
              border: step.isCurrent
                  ? Border.all(color: _kCrimson, width: 1.5)
                  : null,
            ),
            child: Center(
              child: step.done
                  ? const Icon(Icons.check_rounded,
                      size: 15, color: _kGreenFg)
                  : Text(
                      '${index + 1}',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: step.isCurrent ? _kCrimson : _kMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              step.label,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight:
                    step.done ? FontWeight.w500 : FontWeight.w400,
                color: step.done ? _kInk : _kMuted,
              ),
            ),
          ),
          if (step.isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _kCrimsonPale,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _kCrimson.withValues(alpha: 0.2)),
              ),
              child: Text(
                'CURRENT',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _kCrimson,
                  letterSpacing: 0.1 * 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── _PulseDot ────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 0.6)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _kGreenFg,
          boxShadow: [
            BoxShadow(color: Color(0x5910B981), blurRadius: 6),
          ],
        ),
      ),
    );
  }
}

// ─── _CrimsonButton ───────────────────────────────────────────────────────────
class _CrimsonButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _CrimsonButton({required this.label, required this.onTap});

  @override
  State<_CrimsonButton> createState() => _CrimsonButtonState();
}

class _CrimsonButtonState extends State<_CrimsonButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 50,
          transform: _hover
              ? Matrix4.translationValues(0, -1, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kCrimsonLight, _kCrimson],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _kCrimson.withValues(alpha: _hover ? 0.42 : 0.32),
                blurRadius: _hover ? 22 : 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.06 * 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── _NavLink ─────────────────────────────────────────────────────────────────
class _NavLink extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  const _NavLink({
    required this.label,
    required this.icon,
    this.active = false,
    this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.active || _hover;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: on
                ? (widget.active ? Colors.transparent : _kParchDeep)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.icon,
                  size: 14,
                  color: on ? (widget.active ? _kCrimson : _kInk) : _kMuted),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: on ? (widget.active ? _kCrimson : _kInk) : _kMuted,
                  letterSpacing: 0.01 * 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _NavDivider ──────────────────────────────────────────────────────────────
class _NavDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: _kBorder,
    );
  }
}

// ─── _LangPicker ─────────────────────────────────────────────────────────────
class _LangPicker extends StatelessWidget {
  final String selected;
  final bool open;
  final List<String> langs;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  const _LangPicker({
    required this.selected,
    required this.open,
    required this.langs,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBorder, width: 1.5),
            ),
            child: Row(
              children: [
                Text(
                  selected,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _kInkMid,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.language_outlined,
                    size: 13, color: _kMuted),
              ],
            ),
          ),
        ),
        if (open)
          Positioned(
            top: 38,
            right: 0,
            child: Material(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              elevation: 8,
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  children: langs.map((l) {
                    final isSel = l == selected;
                    final idx = langs.indexOf(l);
                    return GestureDetector(
                      onTap: () => onSelect(l),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSel ? _kCrimsonPale : AppTheme.surface,
                          borderRadius: idx == 0
                              ? const BorderRadius.vertical(
                                  top: Radius.circular(10))
                              : idx == langs.length - 1
                                  ? const BorderRadius.vertical(
                                      bottom: Radius.circular(10))
                                  : null,
                        ),
                        child: Text(
                          l,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: isSel
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSel ? _kCrimson : _kInkMid,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
