import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/services/anthropic_service.dart';
import 'package:au_connect/services/application_state.dart';
import 'package:au_connect/l10n/app_localizations.dart';
import 'chatbot_dashboard_screen.dart';
import 'personal_information_screen.dart';
import 'document_upload_screen.dart';
import 'select_program_screen.dart';
import 'payments_screen.dart';
import 'submit_application_screen.dart';
import 'application_progress_screen.dart';
import 'payment_history_screen.dart';
import 'profile_settings_screen.dart';
import 'applicant_announcements_screen.dart';
import 'applicant_interviews_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBg      = Color(0xFFF8F7F5);
const _kDark    = Color(0xFF1C1917);
const _kMuted   = Color(0xFF78716C);
const _kBorder  = Color(0xFFE8E3DF);
const _kRedSoft = Color(0xFFFEE2E2);
const _kRedMid  = Color(0xFFE8C0C8);
const _kAmberBg = Color(0xFFFEF3C7);
const _kAmberBd = Color(0xFFFFCC80);
const _kAmberFg = Color(0xFFD97706);
const _kAmberDk = Color(0xFF92400E);
const _kBlueBg  = Color(0xFFEAF0FF);
const _kBlueBd  = Color(0xFFC0CCFF);
const _kBlueFg  = Color(0xFF3B5BDB);
const _kPurpBg  = Color(0xFFEDE9FE);
const _kPurpBd  = Color(0xFFCCBBEE);
const _kPurpFg  = Color(0xFF7C3AED);
const _kGreenBg = Color(0xFFD1FAE5);
const _kGreenBd = Color(0xFFAADDBB);
const _kGreenFg = Color(0xFF059669);
const _kGreenDk = Color(0xFF065F46);
const _kGrayBg  = Color(0xFFF3F4F6);
const _kGrayFg  = Color(0xFF6B7280);

// ─── Root widget ──────────────────────────────────────────────────────────────

class InternationalDashboardScreen extends StatefulWidget {
  const InternationalDashboardScreen({super.key});

  @override
  State<InternationalDashboardScreen> createState() =>
      _InternationalDashboardState();
}

class _InternationalDashboardState extends State<InternationalDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  late final AnimationController _ctrl;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _application;
  List<Map<String, dynamic>> _documents = [];
  bool _loading = true;
  String? _error;

  final _appState = ApplicationState.instance;

  StreamSubscription<List<Map<String, dynamic>>>? _appStreamSub;

  String _s(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    final text = v.toString();
    return text.isEmpty ? fallback : text;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _loadData();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _appStreamSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        SupabaseService.getProfile(),
        SupabaseService.getMyApplication(),
      ]);
      final app = results[1];
      List<Map<String, dynamic>> docs = [];
      if (app != null) {
        final appId = _s(app['id']);
        if (appId.isNotEmpty) {
          docs = await SupabaseService.getDocuments(appId);
        }
      }
      if (!mounted) return;
      final profile = results[0];
      _appState.syncFromData(profile: profile, application: app, documents: docs);
      setState(() {
        _profile = profile;
        _application = app;
        _documents = docs;
        _loading = false;
      });
      // Start streaming for real-time updates
      _appStreamSub = SupabaseService.streamMyApplications().listen((apps) {
        if (!mounted) return;
        final app = apps.isNotEmpty ? apps.first : null;
        setState(() => _application = app);
      });
      _ctrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load data. Pull down to retry.';
        _loading = false;
      });
    }
  }

  // ── computed ─────────────────────────────────────────────────────────────────
  String get _displayName {
    final username = _s(_profile?['username']);
    if (username.isNotEmpty) return username;
    final name = _s(_profile?['full_name']);
    if (name.isNotEmpty) return name.split(' ').first;
    return SupabaseService.currentUser?.email?.split('@').first ?? 'Student';
  }

  String get _country =>
      _s(_profile?['country_of_origin'], 'Not Specified');

  String get _status =>
      _s(_application?['status']);

  bool get _passportVerified => _documents.any((d) =>
      _s(d['document_type']).toLowerCase().contains('passport') &&
      d['verified'] == true);

  int get _docsUploaded {
    final uploaded = _documents
        .map((d) => _s(d['document_type']).toLowerCase())
        .toSet();
    const keys = [
      'passport', 'transcript', 'ielts', 'medical', 'bank', 'birth', 'insurance'
    ];
    return keys.where((k) => uploaded.any((t) => t.contains(k))).length;
  }

  bool get _isAdmitted =>
      _status.toLowerCase() == 'approved' ||
      _status.toLowerCase() == 'accepted' ||
      _status.toLowerCase() == 'admitted';

  /// Opens the full international application flow.
  /// Does NOT route to any local/onboarding dashboard.
  void _startApplicationFlow(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalInformationScreen(
          nextRoute: (_) => SelectProgramScreen(
            nextRoute: (_) => DocumentUploadScreen(
              nextRoute: (_) => PaymentsScreen(
                nextRoute: (_) => const SubmitApplicationScreen(),
              ),
            ),
          ),
        ),
      ),
    ).then((_) => _loadData());
  }

  // ── build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final initials =
        _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'I';

    final tabs = [
      _HomeTab(
        profile: _profile,
        application: _application,
        documents: _documents,
        loading: _loading,
        error: _error,
        onRefresh: _loadData,
        onStartApplication: _startApplicationFlow,
        displayName: _displayName,
        country: _country,
        status: _status,
        passportVerified: _passportVerified,
        docsUploaded: _docsUploaded,
        ctrl: _ctrl,
      ),
      _ApplicationTab(
        profile: _profile,
        application: _application,
        documents: _documents,
        loading: _loading,
        onRefresh: _loadData,
        onStartApplication: _startApplicationFlow,
        status: _status,
      ),
      _VisaPaymentsTab(
        application: _application,
        isAdmitted: _isAdmitted,
        onStartApplication: _startApplicationFlow,
      ),
      const _TransportTab(),
      const _FinancialTab(),
    ];

    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: _buildFab(context),
      body: Column(
        children: [
          _buildTopNav(context, initials),
          Expanded(child: tabs[_tab]),
        ],
      ),
    );
  }

  // ── TOP NAV ──────────────────────────────────────────────────────────────────
  Widget _buildTopNav(BuildContext context, String initials) {
    final l10n = AppLocalizations.of(context)!;
    final navItems = [
      (Icons.grid_view_rounded,         l10n.dashboard),
      (Icons.layers_outlined,           l10n.applicationProgress),
      (Icons.send_outlined,             '${l10n.visa} & Travel'),
      (Icons.credit_card_outlined,      l10n.payments),
      (Icons.directions_bus_outlined,   '${l10n.transport} & ${l10n.accommodation}'),
      (Icons.campaign_outlined,         l10n.announcements),
      (Icons.event_outlined,          'Interviews'),
    ];

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
        boxShadow: [
          BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Logo
          RichText(
            text: TextSpan(
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 20,
                letterSpacing: -0.5,
                color: AppTheme.primary,
              ),
              children: [
                const TextSpan(text: 'AU'),
                TextSpan(
                  text: 'Connect',
                  style: TextStyle(color: _kDark),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Nav links (scrollable)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: navItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isActive = _tab == i;
                  return _NavLink(
                    icon: item.$1,
                    label: item.$2,
                    active: isActive,
                    onTap: () {
                      // Application Progress (1) → shared screen
                      if (i == 1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ApplicationProgressScreen(),
                          ),
                        );
                        return;
                      }
                      // Payments (3) → payment history screen
                      if (i == 3) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentHistoryScreen(),
                          ),
                        );
                        return;
                      }
                      // Announcements (5) → announcements screen
                      if (i == 5) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ApplicantAnnouncementsScreen(),
                          ),
                        );
                        return;
                      }
                      // Interviews (6) → interviews screen
                      if (i == 6) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ApplicantInterviewsScreen(),
                          ),
                        );
                        return;
                      }
                      setState(() => _tab = i);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _LangButton(),
          const SizedBox(width: 10),
          // Avatar with popup menu
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProfileSettingsScreen()),
                );
              } else if (value == 'logout') {
                final nav = Navigator.of(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Log Out?',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700, fontSize: 17)),
                    content: Text('Are you sure you want to log out?',
                        style: GoogleFonts.dmSans(fontSize: 14)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(AppLocalizations.of(ctx)!.cancel)),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white),
                          child: Text(AppLocalizations.of(ctx)!.logout)),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  await SupabaseService.signOut();
                  if (!mounted) return;
                  nav.pushNamedAndRemoveUntil('/', (_) => false);
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(children: [
                  const Icon(Icons.settings_outlined,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 10),
                  Text(AppLocalizations.of(ctx)!.settings,
                      style: GoogleFonts.dmSans(fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  const Icon(Icons.logout,
                      size: 16, color: AppTheme.primaryCrimson),
                  const SizedBox(width: 10),
                  Text(AppLocalizations.of(ctx)!.logout,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppTheme.primaryCrimson)),
                ]),
              ),
            ],
            tooltip: '',
            padding: EdgeInsets.zero,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ──────────────────────────────────────────────────────────────────────
  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatbotDashboardScreen(
            systemPrompt: AUSystemPrompts.international,
            title: 'International Student Assistant',
          ),
        ),
      ),
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: const StadiumBorder(),
      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
      label: Text('Ask AI',
          style: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Nav Link widget ──────────────────────────────────────────────────────────

class _NavLink extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavLink({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: widget.active
                ? _kRedSoft
                : (_hover ? _kBg : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.active ? AppTheme.primary : _kMuted,
              ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: widget.active ? AppTheme.primary : _kMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab 0: Home ──────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? application;
  final List<Map<String, dynamic>> documents;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final void Function(BuildContext) onStartApplication;
  final String displayName;
  final String country;
  final String status;
  final bool passportVerified;
  final int docsUploaded;
  final AnimationController ctrl;

  const _HomeTab({
    required this.profile,
    required this.application,
    required this.documents,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onStartApplication,
    required this.displayName,
    required this.country,
    required this.status,
    required this.passportVerified,
    required this.docsUploaded,
    required this.ctrl,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Animation<double> _stagger(int i) => CurvedAnimation(
        parent: widget.ctrl,
        curve: Interval(
          (i * 0.08).clamp(0.0, 1.0),
          ((i * 0.08) + 0.55).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );

  bool get _hasFullName {
    final n = widget.profile?['full_name'] as String?;
    return n != null && n.isNotEmpty;
  }

  bool get _hasProgramme => (widget.application?['program'] as String?) != null;
  bool get _hasDocuments => widget.docsUploaded > 0;
  bool get _isSubmitted =>
      widget.application != null &&
      widget.status.isNotEmpty &&
      widget.status != 'draft';

  int get _progressPct {
    int done = 0;
    if (_hasFullName) done++;
    if (_hasDocuments) done++;
    if (_hasProgramme) done++;
    if (_isSubmitted) done += 2;
    return (done / 5 * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppTheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.error != null) _buildErrorBanner(),
                    FadeTransition(
                      opacity: _stagger(0),
                      child: SlideTransition(
                        position: Tween(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero)
                            .animate(_stagger(0)),
                        child: _buildPageHeader(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _stagger(1),
                      child: SlideTransition(
                        position: Tween(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero)
                            .animate(_stagger(1)),
                        child: _buildHeroBanner(context),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                        opacity: _stagger(2), child: _buildStatsRow()),
                    const SizedBox(height: 32),
                    FadeTransition(
                        opacity: _stagger(3),
                        child: _buildTwoCol(context)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kRedSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kRedMid),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 14, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.error!,
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppTheme.primary)),
            ),
          ],
        ),
      );

  Widget _buildPageHeader() {
    final statusLabel = widget.status.isEmpty
        ? 'Application Pending'
        : widget.status[0].toUpperCase() + widget.status.substring(1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 28,
                    color: _kDark,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  children: [
                    const TextSpan(text: 'Welcome, '),
                    TextSpan(
                      text: widget.displayName,
                      style: const TextStyle(color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text('International Student Portal — Africa University',
                  style: GoogleFonts.dmSans(fontSize: 13.5, color: _kMuted)),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _kAmberBg,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAmberFg,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kAmberDk,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7F1D1D),
            AppTheme.primary,
            Color(0xFFDC2626),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative circle top-right
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: 60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 36, 40, 36),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✈  YOUR JOURNEY STARTS HERE',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 30,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: -0.3,
                            ),
                            children: const [
                              TextSpan(text: 'Begin Your '),
                              TextSpan(
                                text: 'International',
                                style:
                                    TextStyle(fontStyle: FontStyle.italic),
                              ),
                              TextSpan(text: '\nJourney at Africa University'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Complete your visa, documents, and application\nrequirements to secure your place on campus.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13.5,
                            color: Colors.white.withValues(alpha: 0.72),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () {
                            if (widget.application != null) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const ApplicationProgressScreen()));
                            } else {
                              _showCountryPicker(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 11),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.application != null
                                      ? 'Check ${AppLocalizations.of(context)!.applicationProgress}'
                                      : AppLocalizations.of(context)!.getStarted,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 14, color: AppTheme.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  // Right: progress ring
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _progressPct / 100,
                              strokeWidth: 6,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$_progressPct%',
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)!.complete,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    color: Colors.white
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.applicationProgress,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    const countries = [
      'Nigeria', 'Kenya', 'Ghana', 'South Africa', 'Tanzania',
      'Ethiopia', 'Uganda', 'Rwanda', 'Zambia', 'Zimbabwe',
      'Malawi', 'Mozambique', 'Botswana', 'Namibia', 'Cameroon',
      'Senegal', "Côte d'Ivoire", 'Democratic Republic of Congo',
      'Angola', 'Other',
    ];
    String? selected;
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (_, setModal) {
            final query = searchCtrl.text.toLowerCase();
            final filtered = query.isEmpty
                ? countries
                : countries
                    .where((c) => c.toLowerCase().contains(query))
                    .toList();

            return Container(
              height: MediaQuery.of(sheetCtx).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFFFAF7F2),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFDDD5C8),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Your Country',
                            style: GoogleFonts.dmSerifDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1208))),
                        const SizedBox(height: 4),
                        Text('Choose the country you are applying from.',
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: const Color(0xFF8A7E74))),
                        const SizedBox(height: 16),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFDDD5C8),
                                width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(Icons.search_rounded,
                                  size: 16,
                                  color: Color(0xFF8A7E74)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: searchCtrl,
                                  onChanged: (_) => setModal(() {}),
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13.5,
                                      color: const Color(0xFF1A1208)),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    hintText: 'Search country…',
                                    hintStyle: GoogleFonts.dmSans(
                                        fontSize: 13.5,
                                        color: const Color(0xFFC4BAB0)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final isSel = selected == c;
                        return GestureDetector(
                          onTap: () => setModal(() => selected = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFFF9EDEF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF9B1B30)
                                    : const Color(0xFFDDD5C8),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(c,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isSel
                                            ? const Color(0xFF9B1B30)
                                            : const Color(0xFF1A1208))),
                                const Spacer(),
                                if (isSel)
                                  const Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: Color(0xFF9B1B30)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24, 12, 24,
                      MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                    ),
                    child: GestureDetector(
                      onTap: selected == null
                          ? null
                          : () {
                              Navigator.pop(sheetCtx);
                              widget.onStartApplication(context);
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: selected != null
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFC0263E),
                                    Color(0xFF9B1B30)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(colors: [
                                  Color(0xFFD6CFC6),
                                  Color(0xFFC4BBAF)
                                ]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: selected != null
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF9B1B30)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text('Continue',
                            style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            iconBg: _kRedSoft,
            iconBorder: _kRedMid,
            iconColor: AppTheme.primary,
            icon: Icons.description_outlined,
            value: '${widget.docsUploaded}/7',
            label: 'Documents Submitted',
            badge: 'Action Needed',
            badgeBg: _kRedSoft,
            badgeFg: const Color(0xFF991B1B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            iconBg: _kAmberBg,
            iconBorder: _kAmberBd,
            iconColor: _kAmberFg,
            icon: Icons.badge_outlined,
            value: widget.passportVerified ? 'Verified' : 'Pending',
            label: 'Passport Status',
            badge: widget.passportVerified ? 'Verified' : 'Awaiting',
            badgeBg: widget.passportVerified ? _kGreenBg : _kAmberBg,
            badgeFg: widget.passportVerified ? _kGreenDk : _kAmberDk,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            iconBg: _kPurpBg,
            iconBorder: _kPurpBd,
            iconColor: _kPurpFg,
            icon: Icons.shield_outlined,
            value: widget.status.toLowerCase() == 'approved'
                ? 'Approved'
                : 'N/A',
            label: 'Visa Status',
            badge: 'Not Started',
            badgeBg: _kGrayBg,
            badgeFg: _kGrayFg,
          ),
        ),
      ],
    );
  }

  Widget _buildTwoCol(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final wide = constraints.maxWidth > 700;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildProfileCard()),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  _buildTimelineCard(),
                  const SizedBox(height: 20),
                  _buildQuickActionsCard(context),
                ],
              ),
            ),
          ],
        );
      }
      return Column(
        children: [
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildTimelineCard(),
          const SizedBox(height: 20),
          _buildQuickActionsCard(context),
        ],
      );
    });
  }

  Widget _buildProfileCard() {
    final hasApplication = widget.application != null;
    final hasInsurance = widget.documents.any((d) =>
        (d['document_type'] as String? ?? '')
            .toLowerCase()
            .contains('insurance'));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _kRedSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      size: 14, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Application Profile',
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kDark),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => widget.onStartApplication,
                  child: Text(
                    'Edit Profile',
                    style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          // Checklist items
          _checkItem(
            iconBg: _kGrayBg,
            iconColor: _kGrayFg,
            icon: Icons.flag_outlined,
            label: 'Country of Origin',
            sub: widget.country,
            badge: widget.country == 'Not Specified' ? 'Unset' : null,
            badgeBg: _kGrayBg,
            badgeFg: _kGrayFg,
          ),
          _checkItem(
            iconBg: _kAmberBg,
            iconColor: _kAmberFg,
            icon: Icons.badge_outlined,
            label: 'Passport',
            sub: widget.passportVerified
                ? 'Verified'
                : 'Document upload required',
            badge: widget.passportVerified ? null : 'Pending',
            badgeBg: _kAmberBg,
            badgeFg: _kAmberDk,
          ),
          _checkItem(
            iconBg: _kRedSoft,
            iconColor: AppTheme.primary,
            icon: Icons.monitor_heart_outlined,
            label: 'Medical Insurance',
            sub: hasInsurance ? 'Submitted' : 'Not Submitted',
            badge: hasInsurance ? null : 'Required',
            badgeBg: _kRedSoft,
            badgeFg: const Color(0xFF991B1B),
          ),
          _checkItem(
            iconBg: _kAmberBg,
            iconColor: _kAmberFg,
            icon: Icons.school_outlined,
            label: 'Academic Application',
            sub: hasApplication
                ? (widget.application!['program'] as String? ??
                    'In Progress')
                : 'Not Started',
            badge: hasApplication ? null : 'Pending',
            badgeBg: _kAmberBg,
            badgeFg: _kAmberDk,
          ),
          _checkItem(
            iconBg: _kGreenBg,
            iconColor: _kGreenFg,
            icon: Icons.directions_bus_outlined,
            label: 'Transport & Accommodation',
            sub: 'Not Arranged',
            badge: 'Pending',
            badgeBg: _kAmberBg,
            badgeFg: _kAmberDk,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _checkItem({
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String label,
    required String sub,
    String? badge,
    Color badgeBg = _kGrayBg,
    Color badgeFg = _kGrayFg,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF5F0EE))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kDark)),
                Text(sub,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: _kMuted)),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                badge,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeFg,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    final steps = [
      (1, 'Complete Personal Profile',
          'Fill in country, contact & personal details', _hasFullName),
      (2, 'Upload Documents',
          'Passport, insurance & academic certificates', _hasDocuments),
      (3, 'Select Programme',
          'Choose faculty & degree programme', _hasProgramme),
      (4, 'Pay Application Fee',
          '\$25 via EcoCash, Flutterwave or card', _isSubmitted),
      (5, 'Submit & Await Offer Letter',
          'Review → Submit → Receive offer by email', _isSubmitted),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _kPurpBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.timeline_rounded,
                      size: 14, color: _kPurpFg),
                ),
                const SizedBox(width: 10),
                Text(
                  'Application Steps',
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kDark),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              children: steps.asMap().entries.map((entry) {
                final i = entry.key;
                final step = entry.value;
                final isLast = i == steps.length - 1;
                final isDone = step.$4;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? _kGreenBg : _kGrayBg,
                          ),
                          alignment: Alignment.center,
                          child: isDone
                              ? const Icon(Icons.check_rounded,
                                  size: 11, color: _kGreenFg)
                              : Text(
                                  '${step.$1}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _kGrayFg,
                                  ),
                                ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 28,
                            color: _kBorder,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: isLast ? 0 : 16, top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.$2,
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _kDark)),
                            Text(step.$3,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: _kMuted)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    final actions = [
      (Icons.upload_file_outlined, _kRedSoft, AppTheme.primary,
          'Upload Documents', '7 required',
          () => widget.onStartApplication(context)),
      (Icons.shield_outlined, _kPurpBg, _kPurpFg,
          'Apply for Visa', 'Start process',
          () => widget.onStartApplication(context)),
      (Icons.credit_card_outlined, _kAmberBg, _kAmberFg,
          'Pay App Fee', '\$25 USD',
          () => widget.onStartApplication(context)),
      (Icons.home_outlined, _kGreenBg, _kGreenFg,
          'Book Accommodation', 'On-campus options',
          () => widget.onStartApplication(context)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _kRedSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      size: 14, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kDark),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
            ),
            itemCount: actions.length,
            itemBuilder: (ctx, i) {
              final a = actions[i];
              return _QaItem(
                icon: a.$1,
                iconBg: a.$2,
                iconColor: a.$3,
                title: a.$4,
                sub: a.$5,
                onTap: a.$6,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Application Process ───────────────────────────────────────────────

class _ApplicationTab extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? application;
  final List<Map<String, dynamic>> documents;
  final bool loading;
  final Future<void> Function() onRefresh;
  final void Function(BuildContext) onStartApplication;
  final String status;

  const _ApplicationTab({
    required this.profile,
    required this.application,
    required this.documents,
    required this.loading,
    required this.onRefresh,
    required this.onStartApplication,
    required this.status,
  });

  bool get _hasFullName {
    final n = profile?['full_name'] as String?;
    return n != null && n.isNotEmpty;
  }

  bool get _hasProgramme => (application?['program'] as String?) != null;
  bool get _hasDocuments => documents.isNotEmpty;
  bool get _isSubmitted =>
      application != null &&
      status.isNotEmpty &&
      status != 'draft';

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.applicationProgress,
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 28,
                      color: _kDark,
                      letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text(
                'Complete each step to submit your international application.',
                style: GoogleFonts.dmSans(
                    fontSize: 13.5, color: _kMuted, height: 1.5),
              ),
              const SizedBox(height: 28),

              if (application != null) ...[
                _buildStatusBanner(),
                const SizedBox(height: 24),
              ],

              _sectionLabel('YOUR STEPS'),
              _stepCard(context, stepNum: 1,
                  title: 'Personal Information',
                  subtitle: 'Fill in your name, date of birth, and contact details.',
                  icon: Icons.person_outline_rounded,
                  isComplete: _hasFullName,
                  onTap: () => onStartApplication(context)),
              _stepCard(context, stepNum: 2,
                  title: 'Select Programme',
                  subtitle: 'Choose your degree, faculty, and intake year.',
                  icon: Icons.school_outlined,
                  isComplete: _hasProgramme,
                  onTap: () => onStartApplication(context)),
              _stepCard(context, stepNum: 3,
                  title: 'Upload Documents',
                  subtitle: 'Submit passport, transcripts, medical certificate, and more.',
                  icon: Icons.upload_file_outlined,
                  isComplete: _hasDocuments,
                  onTap: () => onStartApplication(context)),
              _stepCard(context, stepNum: 4,
                  title: 'Pay Application Fee',
                  subtitle: 'Complete the USD application fee payment to proceed.',
                  icon: Icons.credit_card_outlined,
                  isComplete: _isSubmitted,
                  onTap: () => onStartApplication(context)),
              _stepCard(context, stepNum: 5,
                  title: 'Submit & Await Decision',
                  subtitle: 'Your application is reviewed by the AU admissions team.',
                  icon: Icons.check_circle_outline_rounded,
                  isComplete: _isSubmitted,
                  isLast: true,
                  onTap: _isSubmitted ? null : () => onStartApplication(context)),

              if (application == null) ...[
                const SizedBox(height: 28),
                _sectionLabel('GET STARTED'),
                _startBanner(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color bg, border, fg;
    IconData icon;
    String label;
    switch (status.toLowerCase()) {
      case 'approved':
      case 'accepted':
      case 'admitted':
        bg = _kGreenBg; border = _kGreenBd; fg = _kGreenFg;
        icon = Icons.check_circle_rounded; label = 'Application Approved';
        break;
      case 'rejected':
      case 'denied':
        bg = _kRedSoft; border = _kRedMid; fg = AppTheme.primary;
        icon = Icons.cancel_rounded; label = 'Application Declined';
        break;
      case 'under_review':
      case 'review':
        bg = _kBlueBg; border = _kBlueBd; fg = _kBlueFg;
        icon = Icons.hourglass_top_rounded; label = 'Under Review';
        break;
      default:
        bg = _kAmberBg; border = _kAmberBd; fg = _kAmberFg;
        icon = Icons.pending_outlined; label = 'Application Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
                Text(
                  'Your application is being processed by the Africa University admissions team.',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: fg.withValues(alpha: 0.8),
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard(
    BuildContext context, {
    required int stepNum,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isComplete,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isComplete ? _kGreenBg : _kRedSoft,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isComplete ? _kGreenBd : _kRedMid, width: 1.5),
              ),
              child: isComplete
                  ? const Icon(Icons.check_rounded, size: 14, color: _kGreenFg)
                  : Center(
                      child: Text('$stepNum',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary))),
            ),
            if (!isLast)
              Container(width: 1.5, height: 32, color: _kBorder),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isComplete ? _kGreenBg : _kRedSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isComplete ? _kGreenBd : _kRedMid),
                    ),
                    child: Icon(icon,
                        size: 16,
                        color: isComplete ? _kGreenFg : AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kDark)),
                        Text(subtitle,
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: _kMuted,
                                height: 1.4)),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppTheme.primary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _startBanner(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B0F25), AppTheme.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ready to Apply?',
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              'Begin your international application to Africa University today.',
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => onStartApplication(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Start Application',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                color: _kMuted)),
      );
}

// ─── Tab 2: Visa & Payments ────────────────────────────────────────────────────

class _VisaPaymentsTab extends StatelessWidget {
  final Map<String, dynamic>? application;
  final bool isAdmitted;
  final void Function(BuildContext) onStartApplication;

  const _VisaPaymentsTab({
    required this.application,
    required this.isAdmitted,
    required this.onStartApplication,
  });

  bool get _hasApplied => application != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasApplied) return _notApplied(context);
    if (!isAdmitted) return _awaitingAdmission();
    return _admittedContent(context);
  }

  Widget _notApplied(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: _kRedSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kRedMid),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    size: 32, color: AppTheme.primary),
              ),
              const SizedBox(height: 20),
              Text('Application Required',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22, color: _kDark, letterSpacing: -0.3)),
              const SizedBox(height: 10),
              Text(
                'You have not yet applied to Africa University. Travel & Visa services become available after you submit your application and receive an admission decision.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: _kMuted, height: 1.6),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Starts the international application flow — NOT /onboarding_dashboard
                  onPressed: () => onStartApplication(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Start Your Application',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _awaitingAdmission() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: _kAmberBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kAmberBd),
                ),
                child: const Icon(Icons.lock_clock_outlined,
                    size: 32, color: Color(0xFFE65100)),
              ),
              const SizedBox(height: 20),
              Text('Awaiting Admission',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22, color: _kDark, letterSpacing: -0.3)),
              const SizedBox(height: 10),
              Text(
                'Travel & Visa services are only available once you have been admitted. Your application is currently under review — check the Application tab for your current status.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: _kMuted, height: 1.6),
              ),
            ],
          ),
        ),
      );

  Widget _admittedContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B0F25), AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You are admitted!',
                            style: GoogleFonts.dmSerifDisplay(
                                fontSize: 16, color: Colors.white)),
                        Text(
                            'You can now begin your visa and payment preparations.',
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _sl('STUDENT VISA'),
            _infoCard(
              icon: Icons.article_outlined,
              title: 'Zimbabwe Student Visa (Class D)',
              subtitle:
                  'Required for most non-SADC nationals. Apply at your nearest Zimbabwe embassy before travelling.',
            ),
            const SizedBox(height: 12),
            ...[
              ('Valid Passport',
                  'Valid for at least 6 months beyond your study period'),
              ('Admission / Offer Letter',
                  'Official acceptance letter from Africa University'),
              ('Completed Visa Application Form',
                  'Obtainable from your nearest Zimbabwe embassy'),
              ('Recent Passport-Sized Photos',
                  '2 colour photos against a white background'),
              ('Proof of Financial Means',
                  'Bank statement or sponsor letter (min. USD 300/month)'),
              ('Medical Certificate',
                  'Health certificate from a recognised institution'),
              ('Proof of Medical Insurance',
                  'Valid international health insurance coverage'),
            ].map((e) => _docItem(e.$1, e.$2)),
            const SizedBox(height: 24),
            _sl('FEES & PAYMENTS'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder, width: 1.5),
              ),
              child: Column(
                children: [
                  _feeRow('Application Fee', 'USD 50', isFirst: true),
                  _feeRow('Tuition (per semester)', 'USD 1,200 – 1,800'),
                  _feeRow('Medical Levy', 'USD 30 / semester'),
                  _feeRow('Library & IT Levy', 'USD 20 / semester'),
                  _feeRow('Accommodation (on-campus)',
                      'USD 400 – 600 / semester'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentsScreen(
                    nextRoute: (_) => const SubmitApplicationScreen(),
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B0F25), AppTheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text('Make a Payment',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sl(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                color: _kMuted)),
      );

  Widget _infoCard(
          {required IconData icon,
          required String title,
          required String subtitle}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder, width: 1.5)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: _kRedSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kRedMid)),
              child: Icon(icon, size: 16, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kDark)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: _kMuted, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _docItem(String label, String detail) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder, width: 1.5)),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 16, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kDark)),
                  Text(detail,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: _kMuted, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _feeRow(String label, String amount, {bool isFirst = false}) =>
      Column(
        children: [
          if (!isFirst) const Divider(height: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(fontSize: 13, color: _kDark)),
                Text(amount,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary)),
              ],
            ),
          ),
        ],
      );
}

// ─── Tab 3: Transport & Accommodation ────────────────────────────────────────

class _TransportTab extends StatelessWidget {
  const _TransportTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transport & Accommodation',
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 28, color: _kDark, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text(
              'Everything you need to know about getting to campus and where to stay.',
              style: GoogleFonts.dmSans(fontSize: 13.5, color: _kMuted, height: 1.5),
            ),
            const SizedBox(height: 28),
            _sl('GETTING TO CAMPUS'),
            _card(icon: Icons.flight_rounded, title: 'Airport Arrival',
                body: 'Harare International Airport (HRE) is the nearest major airport, approximately 15 km from campus. Pre-arranged shuttle services are available — contact the International Students Office at least 48 hours before arrival.'),
            const SizedBox(height: 10),
            _card(icon: Icons.directions_bus_outlined, title: 'Campus Shuttle',
                body: 'Africa University operates a daily shuttle service between the main gate and Mutare CBD. Timetable available from the Student Services Office.'),
            const SizedBox(height: 10),
            _card(icon: Icons.local_taxi_rounded, title: 'Taxis & Kombis',
                body: 'Local taxis and minibuses (kombis) connect Mutare to surrounding areas. Use authorised taxi stands.'),
            const SizedBox(height: 24),
            _sl('ON-CAMPUS ACCOMMODATION'),
            _card(icon: Icons.home_rounded, title: 'Student Residences',
                body: 'Africa University offers on-campus residences for international students. Rooms are furnished with single beds, study desks, and shared bathroom facilities per corridor.'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kRedSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kRedMid, width: 1.5),
              ),
              child: Column(
                children: [
                  'Single and double occupancy rooms available',
                  'Communal kitchens on each floor',
                  'Campus security 24/7',
                  'Wi-Fi coverage in all residences',
                  'Laundry facilities available',
                ]
                    .map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 14, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text(item,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12, color: _kDark)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            _sl('OFF-CAMPUS OPTIONS'),
            _card(
                icon: Icons.apartment_rounded,
                title: 'Private Accommodation',
                body: "Affordable private accommodation is available in Mutare's Dangamvura and Chikanga suburbs, with shared minibus access to campus. Rates from USD 80–150/month."),
            const SizedBox(height: 24),
            _sl('CONTACT'),
            _contactCard(
              icon: Icons.support_agent_rounded,
              iconBg: _kBlueBg,
              iconBorder: _kBlueBd,
              iconColor: _kBlueFg,
              title: 'International Students Office',
              detail: 'Email: international@africau.edu\nPhone: +263 20 60606',
            ),
          ],
        ),
      ),
    );
  }

  Widget _sl(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 9.5, fontWeight: FontWeight.w500,
                letterSpacing: 2, color: _kMuted)),
      );

  Widget _card({required IconData icon, required String title, required String body}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder, width: 1.5)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: _kRedSoft,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _kRedMid)),
              child: Icon(icon, size: 17, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600, color: _kDark)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: _kMuted, height: 1.55)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _contactCard({
    required IconData icon,
    required Color iconBg,
    required Color iconBorder,
    required Color iconColor,
    required String title,
    required String detail,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder, width: 1.5)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: iconBorder)),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600, color: _kDark)),
                  const SizedBox(height: 4),
                  Text(detail,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: _kMuted, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─── Tab 4: Financial Assistance ──────────────────────────────────────────────

class _FinancialTab extends StatelessWidget {
  const _FinancialTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Assistance',
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 28, color: _kDark, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text(
              'Scholarships, bursaries, and payment plans for international students.',
              style: GoogleFonts.dmSans(fontSize: 13.5, color: _kMuted, height: 1.5),
            ),
            const SizedBox(height: 28),
            _sl('SCHOLARSHIPS'),
            _fundCard(
              icon: Icons.emoji_events_outlined,
              iconColor: _kAmberFg, iconBg: _kAmberBg, iconBorder: _kAmberBd,
              title: 'Africa University Merit Scholarship',
              subtitle: 'Up to 50% tuition waiver for high-achieving international students.',
              tag: 'Academic Merit', tagColor: _kAmberFg, tagBg: _kAmberBg, tagBorder: _kAmberBd,
            ),
            const SizedBox(height: 10),
            _fundCard(
              icon: Icons.public_rounded,
              iconColor: _kBlueFg, iconBg: _kBlueBg, iconBorder: _kBlueBd,
              title: 'UMC Church Sponsorship',
              subtitle: 'Partial or full sponsorship for students from United Methodist Church member countries.',
              tag: 'Church-Based', tagColor: _kBlueFg, tagBg: _kBlueBg, tagBorder: _kBlueBd,
            ),
            const SizedBox(height: 10),
            _fundCard(
              icon: Icons.diversity_3_rounded,
              iconColor: _kPurpFg, iconBg: _kPurpBg, iconBorder: _kPurpBd,
              title: 'SADC Student Fund',
              subtitle: 'Regional bursary fund for SADC-member country nationals.',
              tag: 'Regional Aid', tagColor: _kPurpFg, tagBg: _kPurpBg, tagBorder: _kPurpBd,
            ),
            const SizedBox(height: 24),
            _sl('PAYMENT PLANS'),
            _infoCard(
              icon: Icons.calendar_month_outlined,
              title: 'Semester Payment Plan',
              body: 'Pay tuition in two equal instalments per academic year. First instalment due at the start of each semester, second due mid-semester.',
            ),
            const SizedBox(height: 10),
            _infoCard(
              icon: Icons.account_balance_rounded,
              title: 'Bank Wire Transfer',
              body: 'Payments can be made via international wire transfer in USD. Bank details are provided upon admission. Include your student ID as the payment reference.',
            ),
            const SizedBox(height: 24),
            _sl('HOW TO APPLY'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder, width: 1.5)),
              child: Column(
                children: [
                  _howStep('1', 'Submit your academic application first.'),
                  const Divider(height: 20),
                  _howStep('2', 'Request a financial assistance form from the International Students Office.'),
                  const Divider(height: 20),
                  _howStep('3', 'Attach supporting documents: transcripts, financial statements, reference letters.'),
                  const Divider(height: 20),
                  _howStep('4', 'Await notification within 3–4 weeks of the application deadline.'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sl('CONTACT'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder, width: 1.5)),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                        color: _kGreenBg,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: _kGreenBd)),
                    child: const Icon(Icons.support_agent_rounded,
                        size: 17, color: _kGreenFg),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Financial Aid Office',
                            style: GoogleFonts.dmSans(
                                fontSize: 13, fontWeight: FontWeight.w600, color: _kDark)),
                        Text('Email: finaid@africau.edu\nPhone: +263 20 60607',
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: _kMuted, height: 1.6)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sl(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 9.5, fontWeight: FontWeight.w500,
                letterSpacing: 2, color: _kMuted)),
      );

  Widget _fundCard({
    required IconData icon,
    required Color iconColor, required Color iconBg, required Color iconBorder,
    required String title, required String subtitle,
    required String tag,
    required Color tagColor, required Color tagBg, required Color tagBorder,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder, width: 1.5)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: iconBorder)),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(title,
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kDark))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: tagBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: tagBorder)),
                        child: Text(tag,
                            style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: tagColor,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: _kMuted, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _infoCard({required IconData icon, required String title, required String body}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder, width: 1.5)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: _kRedSoft,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _kRedMid)),
              child: Icon(icon, size: 17, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600, color: _kDark)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: _kMuted, height: 1.55)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _howStep(String num, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
                color: _kRedSoft,
                shape: BoxShape.circle,
                border: Border.all(color: _kRedMid)),
            alignment: Alignment.center,
            child: Text(num,
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: _kDark, height: 1.5))),
        ],
      );
}

// ─── _LangButton ──────────────────────────────────────────────────────────────

class _LangButton extends StatefulWidget {
  @override
  State<_LangButton> createState() => _LangButtonState();
}

class _LangButtonState extends State<_LangButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/language_change'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hover ? AppTheme.primary : _kBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_outlined,
                  size: 13,
                  color: _hover ? AppTheme.primary : _kMuted),
              const SizedBox(width: 6),
              Text(
                'English',
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: _hover ? AppTheme.primary : _kMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _PendingPill ─────────────────────────────────────────────────────────────

class _PendingPill extends StatefulWidget {
  @override
  State<_PendingPill> createState() => _PendingPillState();
}

class _PendingPillState extends State<_PendingPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD080),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD080)
                        .withValues(alpha: 0.5 + 0.3 * _ctrl.value),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'PENDING',
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _StatCard ────────────────────────────────────────────────────────────────

class _StatCard extends StatefulWidget {
  final Color iconBg, iconBorder, iconColor;
  final IconData icon;
  final String value, label;
  final String? badge;
  final Color badgeBg, badgeFg;

  const _StatCard({
    required this.iconBg,
    required this.iconBorder,
    required this.iconColor,
    required this.icon,
    required this.value,
    required this.label,
    this.badge,
    this.badgeBg = _kGrayBg,
    this.badgeFg = _kGrayFg,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _hover
            ? Matrix4.translationValues(0, -3, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover
                ? AppTheme.primary.withValues(alpha: 0.25)
                : _kBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary
                  .withValues(alpha: _hover ? 0.08 : 0.03),
              blurRadius: _hover ? 20 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: widget.iconBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.iconBorder),
              ),
              child: Icon(widget.icon, size: 20, color: widget.iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.value,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 24,
                      color: _kDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.label,
                    style: GoogleFonts.dmSans(
                        fontSize: 12.5, color: _kMuted),
                  ),
                ],
              ),
            ),
            if (widget.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.badgeBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  widget.badge!,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.badgeFg,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── _QaItem ──────────────────────────────────────────────────────────────────

class _QaItem extends StatefulWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, sub;
  final VoidCallback onTap;

  const _QaItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  State<_QaItem> createState() => _QaItemState();
}

class _QaItemState extends State<_QaItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hover ? _kBg : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(widget.icon, size: 16, color: widget.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.title,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kDark)),
                    Text(widget.sub,
                        style: GoogleFonts.dmSans(
                            fontSize: 11.5, color: _kMuted)),
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
