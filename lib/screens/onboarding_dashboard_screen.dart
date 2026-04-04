import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:au_connect/l10n/app_localizations.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/services/anthropic_service.dart';
import 'package:au_connect/services/application_state.dart';
import 'package:au_connect/widgets/application_status_tracker.dart';
import 'chatbot_dashboard_screen.dart';
import 'create_profile_screen.dart';
import 'personal_information_screen.dart';
import 'document_upload_screen.dart';
import 'select_program_screen.dart';
import 'submit_application_screen.dart';
import 'application_progress_screen.dart';
import 'payment_history_screen.dart';
import 'profile_settings_screen.dart';
import 'applicant_announcements_screen.dart';
import 'applicant_interviews_screen.dart';

class OnboardingDashboardScreen extends StatelessWidget {
  const OnboardingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const _OnboardingBody();
}

class _OnboardingBody extends StatefulWidget {
  const _OnboardingBody();

  @override
  State<_OnboardingBody> createState() => _OnboardingBodyState();
}

class _OnboardingBodyState extends State<_OnboardingBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _application;
  Map<String, dynamic>? _offerLetter;
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;
  String? _error;

  final _appState = ApplicationState.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  StreamSubscription<List<Map<String, dynamic>>>? _annStreamSub;

  String _s(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    final text = v.toString();
    return text.isEmpty ? fallback : text;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _loadData();
    _setupAnnouncementsStreaming();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _annStreamSub?.cancel();
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
        SupabaseService.getAnnouncements('applicant'),
        SupabaseService.getMyOfferLetter(),
      ]);
      Map<String, dynamic>? app = results[1] as Map<String, dynamic>?;
      List<Map<String, dynamic>> docs = [];
      if (app != null) {
        final appId = _s(app['id']);
        if (appId.isNotEmpty) {
          docs = await SupabaseService.getDocuments(appId);
        }
      }
      if (!mounted) return;
      final profile = results[0] as Map<String, dynamic>?;
      _appState.syncFromData(
          profile: profile, application: app, documents: docs);
      setState(() {
        _profile = profile;
        _application = app;
        _announcements =
            (results[2] as List<Map<String, dynamic>>?) ?? [];
        _offerLetter = results[3] as Map<String, dynamic>?;
        _loading = false;
      });
      _ctrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.loadingError;
        _loading = false;
      });
    }
  }

  void _setupAnnouncementsStreaming() {
    _annStreamSub = SupabaseService.streamAnnouncements('applicant').listen(
      (announcements) {
        if (!mounted) return;
        setState(() {
          _announcements = announcements;
        });
      },
      onError: (error) {
        debugPrint('Announcements stream error: $error');
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _displayName {
    final username = _s(_profile?['username']);
    if (username.isNotEmpty) return username;
    final name = _s(_profile?['full_name']);
    if (name.isNotEmpty) return name.split(' ').first;
    return SupabaseService.currentUser?.email?.split('@').first ?? 'there';
  }


  Animation<double> _stagger(int i) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          (i * 0.08).clamp(0.0, 1.0),
          ((i * 0.08) + 0.55).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _navigate(Widget screen) {
    Navigator.pop(context); // close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadData());
  }

  Future<void> _confirmBack(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Go Back?',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, fontSize: 17)),
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
              backgroundColor: AppTheme.primaryCrimson,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pushReplacementNamed(
          context, '/applicant_type_selection');
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Out?',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, fontSize: 17)),
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
              backgroundColor: AppTheme.primaryCrimson,
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAF7F2), // parchment
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(context, l10n),
      floatingActionButton: _loading ? null : _buildFab(context),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFB71C1C), strokeWidth: 2.5)) // crimson
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFFB71C1C),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildDashboardHeader(l10n)),
                  SliverToBoxAdapter(child: _buildHeroBanner(l10n)),
                  SliverToBoxAdapter(child: _buildStatCards()),
                  if (_error != null)
                    SliverToBoxAdapter(child: _buildErrorBanner()),
                  if (_announcements.isNotEmpty)
                    SliverToBoxAdapter(child: _buildAnnouncement()),
                  if (_offerLetter != null)
                    SliverToBoxAdapter(child: _buildOfferLetterBanner()),
                  if (_application != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                        child: ApplicationStatusTracker(
                          applicationId: _s(_application!['id']),
                          currentStatus: _s(_application!['status'], 'Submitted'),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(child: _buildBottomGrid(l10n)),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AppLocalizations l10n) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 100,
      leading: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF1A1A1A), size: 22),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Menu',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 17, color: Color(0xFFB71C1C)),
            onPressed: () => _confirmBack(context),
            tooltip: 'Back',
          ),
        ],
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'AU',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 17,
              color: const Color(0xFFB71C1C), // crimson
            ),
          ),
          Text(
            'Connect',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A), // text-primary
            ),
          ),
          const SizedBox(width: 28),
          // Hide these nav items on extremely tight mobile screens if they overflow
          if (MediaQuery.of(context).size.width > 500) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dashboard_outlined, size: 14, color: Color(0xFFB71C1C)),
                  const SizedBox(width: 6),
                  Text('Dashboard', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFB71C1C))),
                ],
              ),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: () => _navigate(const ApplicationProgressScreen()),
              icon: const Icon(Icons.track_changes_outlined, size: 14, color: Color(0xFF6B7280)),
              label: Text('Application Progress', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280))),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: () => _navigate(const PaymentHistoryScreen()),
              icon: const Icon(Icons.payment_outlined, size: 14, color: Color(0xFF6B7280)),
              label: Text('Payments', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280))),
            ),
          ]
        ],
      ),
      centerTitle: false,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 14, color: Color(0xFF6B7280)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/language_change'),
              child: Text('English', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280))),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFB71C1C), // crimson
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'A',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 28),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB)), // border
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context) {
    final initials = _displayName.isNotEmpty
        ? _displayName[0].toUpperCase()
        : 'L';
    final email =
        SupabaseService.currentUser?.email ?? '';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryCrimson,
              ),
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
                        Text(_displayName,
                            style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(email,
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: Colors.white
                                    .withValues(alpha: 0.75)),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Local Student',
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

            // Nav items
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
                    onTap: () => _navigate(
                        const ApplicationProgressScreen()),
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
                    onTap: () =>
                        _navigate(const PaymentHistoryScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.directions_bus_outlined,
                    label: 'Transport',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Transport — coming soon')),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.campaign_outlined,
                    label: 'Announcements',
                    onTap: () => _navigate(const ApplicantAnnouncementsScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Interviews',
                    onTap: () => _navigate(const ApplicantInterviewsScreen()),
                  ),
                  const Divider(height: 1),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => _navigate(
                        const ProfileSettingsScreen()),
                  ),
                ],
              ),
            ),

            // Logout at bottom
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Logout',
              danger: true,
              onTap: () {
                Navigator.pop(context);
                _confirmLogout(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatbotDashboardScreen(
            systemPrompt: AUSystemPrompts.applicant,
            title: 'Admissions Assistant',
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFB71C1C), // crimson
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66B71C1C),
              blurRadius: 18,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Text('Ask AI',
                style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Dashboard Header Row ──────────────────────────────────────────────────

  // ── Dashboard Header Row ──────────────────────────────────────────────────

  Widget _buildDashboardHeader(AppLocalizations l10n) {
    final submitted = _appState.applicationSubmitted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome, ',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1A1A1A), // text-primary
                        ),
                      ),
                      TextSpan(
                        text: _displayName,
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB71C1C), // crimson
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Local Student Portal — Africa University',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF6B7280), // text-secondary
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: submitted ? const Color(0xFFD1FAE5) : const Color(0xFFFFF8E1), // pending-bg
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: submitted ? const Color(0xFF10B981).withValues(alpha: 0.25) : const Color(0xFFF59E0B).withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: submitted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  submitted ? 'Application Submitted' : 'Application Pending',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: submitted ? const Color(0xFF065F46) : const Color(0xFFF59E0B), // pending-fg
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Banner ───────────────────────────────────────────────────────────

  Widget _buildHeroBanner(AppLocalizations l10n) {
    final hasApplication = _application != null;
    final pct = hasApplication ? 100 : ((_appState.progress) * 100).round();
    final hasProfile = _s(_profile?['full_name']).isNotEmpty;

    return AnimatedBuilder(
      animation: _stagger(0),
      builder: (_, child) => Opacity(
        opacity: _stagger(0).value,
        child: Transform.translate(
            offset: Offset(0, 16 * (1 - _stagger(0).value)),
            child: child),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(28, 22, 28, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFB71C1C), // crimson
              Color(0xFF7F0000), // crimson-dark
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40, right: 140,
              width: 220, height: 220,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 36, 36, 36),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('✏️', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 6),
                            Text(
                              'YOUR JOURNEY STARTS HERE',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.65),
                                letterSpacing: 1.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Begin Your ',
                                style: GoogleFonts.dmSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                              TextSpan(
                                text: 'Academic\n',
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 26,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                              TextSpan(
                                text: 'Journey at Africa University',
                                style: GoogleFonts.dmSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Complete your documents and application\nrequirements to secure your place on campus.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 22),
                        GestureDetector(
                          onTap: hasApplication
                              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplicationProgressScreen()))
                              : () => Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => hasProfile
                                          ? PersonalInformationScreen(
                                              nextRoute: (_) => SelectProgramScreen(
                                                nextRoute: (_) => DocumentUploadScreen(
                                                  nextRoute: (_) => const SubmitApplicationScreen(),
                                                ),
                                              ),
                                            )
                                          : const CreateProfileScreen(),
                                    )).then((_) => _loadData()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hasApplication ? 'Check Application Progress' : 'Get Started',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: _appState.progress),
                          duration: const Duration(milliseconds: 1400),
                          curve: Curves.easeOutCubic,
                          builder: (_, val, __) => Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 5,
                                strokeCap: StrokeCap.round,
                                valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.2)),
                              ),
                              CircularProgressIndicator(
                                value: val,
                                strokeWidth: 5,
                                strokeCap: StrokeCap.round,
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                              ),
                              Center(
                                child: Text(
                                  '$pct%',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Complete',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                      ),
                      Text(
                        'Application\nProgress',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                          height: 1.4,
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

  // ── Stat Cards ────────────────────────────────────────────────────────────

  Widget _buildStatCards() {
    return AnimatedBuilder(
      animation: _stagger(1),
      builder: (_, child) => Opacity(
        opacity: _stagger(1).value,
        child: Transform.translate(
            offset: Offset(0, 16 * (1 - _stagger(1).value)),
            child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                iconText: '📄',
                iconBg: const Color(0xFFFFEBEE),
                iconColor: const Color(0xFFB71C1C),
                value: _appState.documentsUploaded ? '5/5' : '0/5',
                label: 'Documents Submitted',
                badgeText: _appState.documentsUploaded ? 'Done' : 'Action Needed',
                badgeBg: _appState.documentsUploaded ? const Color(0xFFD1FAE5) : const Color(0xFFFFEBEE),
                badgeColor: _appState.documentsUploaded ? const Color(0xFF065F46) : const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                iconText: '💳',
                iconBg: const Color(0xFFFFF8E1),
                iconColor: const Color(0xFFF59E0B),
                value: _appState.feePaid ? 'Paid' : 'Pending',
                label: 'Application Fee',
                badgeText: _appState.feePaid ? 'Paid' : 'Awaiting',
                badgeBg: _appState.feePaid ? const Color(0xFFD1FAE5) : const Color(0xFFFFF8E1),
                badgeColor: _appState.feePaid ? const Color(0xFF065F46) : const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                iconText: '🎓',
                iconBg: const Color(0xFFEDE7F6),
                iconColor: const Color(0xFF7C3AED),
                value: _appState.programmeSelected ? 'Selected' : 'N/A',
                label: 'Programme Selected',
                badgeText: _appState.programmeSelected ? 'Done' : 'Not Started',
                badgeBg: _appState.programmeSelected ? const Color(0xFFD1FAE5) : const Color(0xFFF3F4F6),
                badgeColor: _appState.programmeSelected ? const Color(0xFF065F46) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ── Error banner ──────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded,
            color: Colors.orange.shade700, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(_error!,
                style: TextStyle(
                    color: Colors.orange.shade800, fontSize: 13))),
        TextButton(onPressed: _loadData, child: const Text('Retry')),
      ]),
    );
  }

  // ── Announcement ──────────────────────────────────────────────────────────

  Widget _buildAnnouncement() {
    final latest = _announcements.first;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.campaign_rounded,
              color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('ANNOUNCEMENT',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      letterSpacing: 1.5)),
              const SizedBox(height: 2),
                Text(_s(latest['title'], 'Announcement'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ])),
        const Icon(Icons.chevron_right_rounded,
            color: AppTheme.textMuted, size: 18),
      ]),
    );
  }

  // ── Offer letter banner ───────────────────────────────────────────────────

  Widget _buildOfferLetterBanner() {
    final signedUrl = _s(_offerLetter?['signed_url']);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.statusApproved.withValues(alpha: 0.08),
          AppTheme.statusApproved.withValues(alpha: 0.03),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.statusApproved.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.statusApproved.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    AppTheme.statusApproved.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.picture_as_pdf_rounded,
              color: AppTheme.statusApproved, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Offer Letter Ready',
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(
                'Your offer of admission is available to download.',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppTheme.textMuted)),
          ]),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: signedUrl.isNotEmpty
              ? () async {
                  final uri = Uri.tryParse(signedUrl);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Could not open offer letter.')));
                  }
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.statusApproved,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Download',
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  // ── Bottom Grid ───────────────────────────────────────────────────────────

  Widget _buildBottomGrid(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _stagger(2),
      builder: (_, child) => Opacity(
        opacity: _stagger(2).value,
        child: Transform.translate(
            offset: Offset(0, 16 * (1 - _stagger(2).value)),
            child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 700) {
              return Column(
                children: [
                  _buildProfileCard(l10n),
                  const SizedBox(height: 20),
                  _buildStepsCard(l10n),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildProfileCard(l10n)),
                const SizedBox(width: 20),
                Expanded(child: _buildStepsCard(l10n)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Profile Card ──────────────────────────────────────────────────────────

  Widget _buildProfileCard(AppLocalizations l10n) {
    final hasProfile = _appState.personalInfoComplete;
    final docs = _appState.documentsUploaded;
    final prog = _appState.programmeSelected;
    final fee = _appState.feePaid;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, color: Color(0xFFB71C1C), size: 18),
                  const SizedBox(width: 8),
                  Text('Application Profile',
                      style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A))),
                ],
              ),
              GestureDetector(
                onTap: () => _navigate(const ProfileSettingsScreen()),
                child: Text('Edit Profile',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB71C1C))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProfileRow(
            icon: '🏠',
            label: 'Home Province',
            sub: hasProfile && _s(_profile?['county_state']).isNotEmpty
                ? _s(_profile?['county_state'])
                : 'Not Specified',
            badgeText: hasProfile ? 'Set' : 'Unset',
            badgeType: hasProfile ? 'none' : 'none',
          ),
          _ProfileRow(
            icon: '🪪',
            label: 'National ID',
            sub: docs ? 'Document uploaded' : 'Document upload required',
            badgeText: docs ? 'Done' : 'Pending',
            badgeType: docs ? 'done' : 'pending',
          ),
          _ProfileRow(
            icon: '📜',
            label: 'Academic Certificates',
            sub: docs ? 'Submitted' : 'Not Submitted',
            badgeText: docs ? 'Done' : 'Required',
            badgeType: docs ? 'done' : 'req',
          ),
          _ProfileRow(
            icon: '📋',
            label: 'Academic Application',
            sub: prog ? 'Started' : 'Not Started',
            badgeText: prog ? 'Progress' : 'Pending',
            badgeType: prog ? 'action' : 'pending',
          ),
          _ProfileRow(
            icon: '💰',
            label: 'Application Fee',
            sub: fee ? 'Paid' : 'Not Paid',
            badgeText: fee ? 'Paid' : 'Pending',
            badgeType: fee ? 'done' : 'pending',
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ── Steps Card ───────────────────────────────────────────────────────────

  Widget _buildStepsCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rtl_rounded, color: Color(0xFFB71C1C), size: 18),
              const SizedBox(width: 8),
              Text('Application Steps',
                  style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 20),
          _StepCard(
            numText: '1',
            title: 'Complete Personal Profile',
            sub: 'Fill in contact & personal details',
            isLast: false,
            done: _appState.personalInfoComplete,
            onTap: () => _navigateToStep(0),
          ),
          _StepCard(
            numText: '2',
            title: 'Upload Documents',
            sub: 'National ID & academic certificates',
            isLast: false,
            done: _appState.documentsUploaded,
            onTap: () => _navigateToStep(1),
          ),
          _StepCard(
            numText: '3',
            title: 'Select Programme',
            sub: 'Choose faculty & degree programme',
            isLast: false,
            done: _appState.programmeSelected,
            onTap: () => _navigateToStep(2),
          ),
          _StepCard(
            numText: '4',
            title: 'Pay Application Fee',
            sub: '\$25 via EcoCash, Flutterwave or card',
            isLast: false,
            done: _appState.feePaid,
            onTap: () => _navigateToStep(3),
          ),
          _StepCard(
            numText: '5',
            title: 'Submit & Await Offer Letter',
            sub: 'Review → Submit → Receive offer by email',
            isLast: true,
            done: _appState.applicationSubmitted,
            onTap: () => _navigateToStep(4),
          ),
        ],
      ),
    );
  }

  void _navigateToStep(int stepIndex) {
    if (!_appState.canNavigateTo(stepIndex, context)) return;
    switch (stepIndex) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PersonalInformationScreen(
              nextRoute: (_) => SelectProgramScreen(
                nextRoute: (_) => DocumentUploadScreen(
                  nextRoute: (_) => const SubmitApplicationScreen(),
                ),
              ),
            ),
          ),
        ).then((_) => _loadData());
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentUploadScreen(
              nextRoute: (_) => SelectProgramScreen(
                nextRoute: (_) => const SubmitApplicationScreen(),
              ),
            ),
          ),
        ).then((_) => _loadData());
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SelectProgramScreen(
              nextRoute: (_) => const SubmitApplicationScreen(),
            ),
          ),
        ).then((_) => _loadData());
        break;
      case 3:
        Navigator.pushNamed(context, '/payments')
            .then((_) => _loadData());
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const SubmitApplicationScreen()),
        ).then((_) => _loadData());
        break;
    }
  }

}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String iconText;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String badgeText;
  final Color badgeBg;
  final Color badgeColor;

  const _StatCard({
    required this.iconText,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(iconText, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A))),
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: const Color(0xFF6B7280))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(badgeText,
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor)),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Row ──────────────────────────────────────────────────────────────

class _ProfileRow extends StatelessWidget {
  final String icon;
  final String label;
  final String sub;
  final String badgeText;
  final String badgeType;
  final bool isLast;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.badgeText,
    required this.badgeType,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeFg;
    switch (badgeType) {
      case 'pending':
        badgeBg = const Color(0xFFFFF8E1);
        badgeFg = const Color(0xFFF59E0B);
        break;
      case 'req':
        badgeBg = const Color(0xFFFFEBEE);
        badgeFg = const Color(0xFFB71C1C);
        break;
      case 'action':
        badgeBg = const Color(0xFFFFEBEE);
        badgeFg = const Color(0xFFD32F2F);
        break;
      case 'done':
        badgeBg = const Color(0xFFD1FAE5);
        badgeFg = const Color(0xFF065F46);
        break;
      default: // none
        badgeBg = const Color(0xFFF3F4F6);
        badgeFg = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                Text(sub,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: const Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(badgeText,
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeFg)),
          ),
        ],
      ),
    );
  }
}

// ─── Step Card ────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final String numText;
  final String title;
  final String sub;
  final bool isLast;
  final bool done;
  final VoidCallback onTap;

  const _StepCard({
    required this.numText,
    required this.title,
    required this.sub,
    required this.isLast,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: done ? const Color(0xFFD1FAE5) : const Color(0xFFB71C1C).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: done
                    ? const Icon(Icons.check_rounded, color: Color(0xFF065F46), size: 16)
                    : Text(numText,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB71C1C))),
              ),
              if (!isLast)
                Container(
                  width: 1.5,
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: const Color(0xFFE5E7EB), // border
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A))),
                  const SizedBox(height: 3),
                  Text(sub,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: const Color(0xFF6B7280))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Drawer Item ──────────────────────────────────────────────────────────────

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
      title: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
      tileColor: active
          ? AppTheme.primaryLight
          : null,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }
}
