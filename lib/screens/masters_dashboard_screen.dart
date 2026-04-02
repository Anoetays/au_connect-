import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/services/anthropic_service.dart';
import 'package:au_connect/services/application_state.dart';
import 'chatbot_dashboard_screen.dart';
import 'application_progress_screen.dart';
import 'payment_history_screen.dart';
import 'profile_settings_screen.dart';
import 'personal_information_screen.dart';
import 'document_upload_screen.dart';
import 'masters_postgrad_docs_screen.dart';
import 'select_program_screen.dart';
import 'payments_screen.dart';
import 'submit_application_screen.dart';

// ─── color tokens ──────────────────────────────────────────────────────────────
const _kRed      = AppTheme.primaryCrimson;
const _kRedDeep  = AppTheme.primaryDark;
const _kRedSoft  = AppTheme.primaryLight;
const _kRedMid   = Color(0xFFE8C0C8);
const _kDark     = AppTheme.textPrimary;
const _kMuted    = AppTheme.textMuted;
const _kBorder   = Color(0x21B91C1C);
const _kBg       = AppTheme.background;

class MastersDashboardScreen extends StatefulWidget {
  const MastersDashboardScreen({super.key});

  @override
  State<MastersDashboardScreen> createState() => _MastersDashboardScreenState();
}

class _MastersDashboardScreenState extends State<MastersDashboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _application;
  List<Map<String, dynamic>> _documents = [];
  bool _loading = true;
  String? _error;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  final _appState = ApplicationState.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      final results = await Future.wait([
        SupabaseService.getProfile(),
        SupabaseService.getMyApplication(),
      ]);
      final profile = results[0];
      final app     = results[1];
      List<Map<String, dynamic>> docs = [];
      if (app != null) {
        docs = await SupabaseService.getDocuments(app['id'] as String);
      }
      if (!mounted) return;
      _appState.syncFromData(profile: profile, application: app, documents: docs);
      setState(() {
        _profile     = profile;
        _application = app;
        _documents   = docs;
        _loading     = false;
      });
      _ctrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load data.'; _loading = false; });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _firstName {
    final full = (_profile?['full_name'] as String?) ?? '';
    return full.isNotEmpty ? full.split(' ').first : 'Student';
  }

  String get _appStatus =>
      (_application?['status'] as String?)?.capitalize() ?? 'Pending';

  String get _programme =>
      (_application?['program'] as String?) ?? 'Masters';

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _navigate(Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadData());
  }

  Future<void> _confirmBack() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Go Back?',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text(
          'Are you sure you want to go back? Your progress will be saved.',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/applicant_type_selection');
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Out?',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await SupabaseService.signOut();
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBg,
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFab(context),
      body: Column(
        children: [
          // 3-px accent bar
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kRedDeep, _kRed, Color(0xFFE85070), _kRed],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _kRed))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: _kRed,
                    child: FadeTransition(
                      opacity: _fade,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildContent(context),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 100,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: _kDark, size: 22),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Menu',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 17, color: _kRed),
            onPressed: _confirmBack,
            tooltip: 'Back',
          ),
        ],
      ),
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'AU ',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _kDark,
                letterSpacing: -0.3,
              ),
            ),
            TextSpan(
              text: 'Connect',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _kRed,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kBorder),
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context) {
    final initials = _firstName.isNotEmpty ? _firstName[0].toUpperCase() : 'M';
    final email = SupabaseService.currentUser?.email ?? '';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(color: _kRed),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(initials,
                          style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_firstName,
                            style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(email,
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.75)),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Masters / Postgraduate',
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    active: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.track_changes_outlined,
                    label: 'Application Progress',
                    onTap: () =>
                        _navigate(const ApplicationProgressScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.flight_outlined,
                    label: 'Travel & Visa',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Travel & Visa — coming soon')),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.payment_outlined,
                    label: 'Payments',
                    onTap: () => _navigate(const PaymentHistoryScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.directions_bus_outlined,
                    label: 'Transport',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Transport — coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => _navigate(const ProfileSettingsScreen()),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Logout',
              danger: true,
              onTap: () {
                Navigator.pop(context);
                _confirmLogout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatbotDashboardScreen(
            systemPrompt: AUSystemPrompts.applicant,
            title: 'Admissions Assistant',
          ),
        ),
      ),
      backgroundColor: _kRed,
      elevation: 6,
      icon: const Icon(Icons.chat_bubble_outline_rounded,
          color: Colors.white, size: 18),
      label: const Text('Ask AI',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13)),
    );
  }

  // ── CONTENT ────────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) _buildErrorBanner(),
              _buildPageHeader(),
              const SizedBox(height: 20),
              _buildProgressBar(),
              const SizedBox(height: 20),
              _buildHeroBanner(context),
              const SizedBox(height: 20),
              _buildSectionLabel('Overview'),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildSectionLabel('Key Deadlines'),
              _buildDeadlinesCard(),
              const SizedBox(height: 20),
              _buildSectionLabel('Research Requirements'),
              _buildRequirementsCard(),
              const SizedBox(height: 20),
              _buildSectionLabel('Quick Actions'),
              _buildQuickActionsCard(context),
              const SizedBox(height: 20),
              _buildTipsCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ── PROGRESS BAR ──────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    final pct = (_appState.progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Application Progress',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kDark)),
              Text('$pct% Complete',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kRed)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _appState.progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 8,
                backgroundColor: const Color(0xFFF1E8E8),
                valueColor: const AlwaysStoppedAnimation<Color>(_kRed),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ERROR BANNER ───────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
        ),
        TextButton(onPressed: _loadData, child: const Text('Retry')),
      ]),
    );
  }

  // ── PAGE HEADER ────────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _kRed,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59C41E3A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_outlined, size: 10, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                'POSTGRADUATE PORTAL',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Welcome, ',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _kDark,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: _firstName,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _kRed,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Masters / Postgraduate Application',
          style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w300, color: _kMuted),
        ),
      ],
    );
  }

  // ── HERO BANNER ────────────────────────────────────────────────────────────

  Widget _buildHeroBanner(BuildContext context) {
    final pct = (_appState.progress * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kRedDeep, _kRed, Color(0xFFA01428)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40C41E3A),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x14FFFFFF), Colors.transparent],
                ),
              ),
            ),
          ),
          // Progress ring
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(60, 60),
                    painter: _RingPainter(progress: _appState.progress),
                  ),
                  Text(
                    '$pct%',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PendingDot(),
                    const SizedBox(width: 6),
                    Text(
                      'PENDING',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Begin Your ',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                    ),
                    TextSpan(
                      text: 'Postgraduate Journey',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your application and submit all required documents\nto secure your place at Africa University.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  if (_application != null) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const ApplicationProgressScreen()));
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonalInformationScreen(
                          nextRoute: (_) => DocumentUploadScreen(
                            nextRoute: (_) => MastersPostgradDocsScreen(
                              nextRoute: (_) => SelectProgramScreen(
                                nextRoute: (_) => PaymentsScreen(
                                  nextRoute: (_) =>
                                      const SubmitApplicationScreen(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ).then((_) => _loadData());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _application != null
                            ? 'Check Application Progress'
                            : 'Get Started',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kRed,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded,
                          size: 16, color: _kRed),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SECTION LABEL ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 2.0,
          color: _kMuted,
        ),
      ),
    );
  }

  // ── STATS GRID ────────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    final stats = [
      _StatData(
        label: 'Documents Submitted',
        value: '${_documents.length}/6',
        iconData: Icons.insert_drive_file_outlined,
        iconBg: const Color(0xFFEAF0FF),
        iconBorder: const Color(0xFFC0CCFF),
        iconColor: const Color(0xFF3A5FCC),
      ),
      _StatData(
        label: 'Application Status',
        value: _appStatus,
        iconData: Icons.smartphone_outlined,
        iconBg: _kRedSoft,
        iconBorder: _kRedMid,
        iconColor: _kRed,
      ),
      _StatData(
        label: 'Programme',
        value: _programme,
        iconData: Icons.school_outlined,
        iconBg: const Color(0xFFEFE8F5),
        iconBorder: const Color(0xFFCCBBEE),
        iconColor: const Color(0xFF7040BB),
      ),
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        if (isNarrow) {
          return Column(
            children: stats
                .map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StatCard(data: s),
                    ))
                .toList(),
          );
        }
        return Row(
          children: stats
              .asMap()
              .entries
              .map((e) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: e.key < stats.length - 1 ? 10 : 0),
                      child: _StatCard(data: e.value),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  // ── DEADLINES CARD ────────────────────────────────────────────────────────

  Widget _buildDeadlinesCard() {
    final deadlines = [
      ('Research Proposal', 'Jun 30, 2025', false),
      ('Document Submission', 'Jul 15, 2025', false),
      ('Application Fee', 'Jul 31, 2025', true),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: deadlines.map((d) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: d.$3 ? Colors.green : _kRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(d.$1,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kDark)),
                ),
                Text(d.$2,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: _kMuted)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: d.$3
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    d.$3 ? 'Done' : 'Upcoming',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: d.$3
                          ? const Color(0xFF166534)
                          : AppTheme.statusPending,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── REQUIREMENTS CARD ─────────────────────────────────────────────────────

  Widget _buildRequirementsCard() {
    final reqs = [
      (Icons.description_outlined, 'Research Proposal'),
      (Icons.school_outlined, 'Honours / Bachelor\'s Degree Certificate'),
      (Icons.badge_outlined, 'Certified Academic Transcripts'),
      (Icons.person_outline_rounded, 'Two Referees\' Letters'),
      (Icons.credit_card_outlined, 'National ID or Passport'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: reqs.map((r) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kRedSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(r.$1, size: 16, color: _kRed),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(r.$2,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: _kDark)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── QUICK ACTIONS ─────────────────────────────────────────────────────────

  Widget _buildQuickActionsCard(BuildContext context) {
    final actions = [
      (Icons.person_outline_rounded, 'Personal Info', () {
        if (!_appState.canNavigateTo(0, context)) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PersonalInformationScreen(
              nextRoute: (_) => DocumentUploadScreen(
                nextRoute: (_) => MastersPostgradDocsScreen(
                  nextRoute: (_) => SelectProgramScreen(
                    nextRoute: (_) => PaymentsScreen(
                      nextRoute: (_) => const SubmitApplicationScreen(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ).then((_) => _loadData());
      }),
      (Icons.upload_file_outlined, 'Upload Docs', () {
        if (!_appState.canNavigateTo(1, context)) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentUploadScreen(
              nextRoute: (_) => MastersPostgradDocsScreen(
                nextRoute: (_) => SelectProgramScreen(
                  nextRoute: (_) => PaymentsScreen(
                    nextRoute: (_) => const SubmitApplicationScreen(),
                  ),
                ),
              ),
            ),
          ),
        ).then((_) => _loadData());
      }),
      (Icons.payment_outlined, 'Pay Fee', () {
        if (!_appState.canNavigateTo(3, context)) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
        ).then((_) => _loadData());
      }),
      (Icons.track_changes_outlined, 'My Progress', () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ApplicationProgressScreen()),
        );
      }),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: actions.map((a) {
          return GestureDetector(
            onTap: a.$3,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kRed, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(a.$1, size: 16, color: _kRed),
                  const SizedBox(width: 8),
                  Text(a.$2,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kRed)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── TIPS CARD ─────────────────────────────────────────────────────────────

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDE7F6), Color(0xFFF3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8B4FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lightbulb_outline_rounded,
                color: Color(0xFF7C3AED), size: 18),
            const SizedBox(width: 8),
            Text('Postgraduate Tip',
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7C3AED))),
          ]),
          const SizedBox(height: 6),
          Text(
            'Ensure your research proposal is approved by a supervisor before submitting. Late proposals may delay your application review.',
            style: GoogleFonts.dmSans(
                fontSize: 12.5, color: const Color(0xFF7C3AED), height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Ring painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 6) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    paint.color = Colors.white.withValues(alpha: 0.2);
    canvas.drawCircle(Offset(cx, cy), radius, paint);

    paint.color = Colors.white;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Pending dot ──────────────────────────────────────────────────────────────

class _PendingDot extends StatefulWidget {
  @override
  State<_PendingDot> createState() => _PendingDotState();
}

class _PendingDotState extends State<_PendingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.4 + 0.6 * _c.value),
          ),
        ),
      );
}

// ─── Stat data ────────────────────────────────────────────────────────────────

class _StatData {
  final String label, value;
  final IconData iconData;
  final Color iconBg, iconBorder, iconColor;
  const _StatData({
    required this.label,
    required this.value,
    required this.iconData,
    required this.iconBg,
    required this.iconBorder,
    required this.iconColor,
  });
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x21B91C1C)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.iconBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: data.iconBorder),
            ),
            child: Icon(data.iconData, size: 18, color: data.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label,
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppTheme.textMuted)),
                const SizedBox(height: 2),
                Text(data.value,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Drawer item ──────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool danger;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppTheme.primaryCrimson
        : active
            ? AppTheme.primaryCrimson
            : AppTheme.textSecondary;
    return ListTile(
      leading: Icon(icon, size: 20, color: color),
      title: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: color)),
      tileColor: active ? AppTheme.primaryLight : null,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }
}

// ─── String extension ─────────────────────────────────────────────────────────

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
