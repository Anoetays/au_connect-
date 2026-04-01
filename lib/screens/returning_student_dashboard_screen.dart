import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/services/anthropic_service.dart';
import 'chatbot_dashboard_screen.dart';
import 'application_status_screen.dart';
import 'document_upload_screen.dart';

// ─── colours ────────────────────────────────────────────────────────────────
const _kBg      = AppTheme.background;
const _kDark    = AppTheme.textPrimary;
const _kMuted   = AppTheme.textMuted;
const _kBorder  = Color(0x21B91C1C);
const _kRedSoft = AppTheme.primaryLight;
const _kRedMid  = Color(0xFFE8C0C8);
const _kAmberBg = Color(0xFFFFF3E0);
const _kAmberBd = Color(0xFFFFCC80);
const _kAmberFg = AppTheme.statusPending;
const _kPurpBg  = Color(0xFFEFE8F5);
const _kPurpBd  = Color(0xFFCCBBEE);
const _kPurpFg  = Color(0xFF7040BB);
const _kGreenBg = Color(0xFFE8F5EE);
const _kGreenBd = Color(0xFFAADDBB);
const _kGreenFg = Color(0xFF1E8A4A);

class ReturningStudentDashboardScreen extends StatelessWidget {
  const ReturningStudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const _ReturnBody();
}

class _ReturnBody extends StatefulWidget {
  const _ReturnBody();
  @override
  State<_ReturnBody> createState() => _ReturnBodyState();
}

class _ReturnBodyState extends State<_ReturnBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _application;
  List<Map<String, dynamic>> _academicRecords = [];
  Map<String, dynamic>? _feeRecord;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
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
        SupabaseService.getAcademicRecords(),
        SupabaseService.getFeeRecord(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile        = results[0] as Map<String, dynamic>?;
        _application    = results[1] as Map<String, dynamic>?;
        _academicRecords =
            (results[2] as List<Map<String, dynamic>>?) ?? [];
        _feeRecord      = results[3] as Map<String, dynamic>?;
        _loading = false;
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

  // ── computed ──────────────────────────────────────────────────────────────
  String get _displayName {
    final name = _profile?['full_name'] as String?;
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    return SupabaseService.currentUser?.email?.split('@').first ?? 'Student';
  }

  String get _status => _application?['status'] as String? ?? 'pending';

  double get _outstandingFees {
    if (_feeRecord == null) return 0;
    final due  = (_feeRecord!['amount_due']  as num?)?.toDouble() ?? 0;
    final paid = (_feeRecord!['amount_paid'] as num?)?.toDouble() ?? 0;
    return (due - paid).clamp(0, double.infinity);
  }

  bool get _hasAcademicHold => _outstandingFees > 0;

  String get _gpaDisplay {
    if (_academicRecords.isEmpty) return 'N/A';
    final gpas = _academicRecords
        .map((r) => (r['gpa'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    if (gpas.isEmpty) return 'N/A';
    return (gpas.reduce((a, b) => a + b) / gpas.length)
        .toStringAsFixed(2);
  }

  String get _balanceDisplay {
    final fees = _outstandingFees;
    if (fees == 0) return 'USD 0';
    return 'USD ${fees.toStringAsFixed(0)}';
  }

  Animation<double> _stagger(int i) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          (i * 0.08).clamp(0.0, 1.0),
          ((i * 0.08) + 0.55).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final initials = _displayName.isNotEmpty
        ? _displayName[0].toUpperCase()
        : 'A';

    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: _buildFab(context),
      body: Stack(
        children: [
          // 3px top accent bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Color(0xFF8B0F25),
                  AppTheme.primary,
                  Color(0xFFE85070),
                  AppTheme.primary,
                ]),
              ),
            ),
          ),
          Column(
            children: [
              _buildTopNav(context, initials),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppTheme.primary,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(child: _buildBody(context)),
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

  // ── TOP NAV ───────────────────────────────────────────────────────────────
  Widget _buildTopNav(BuildContext context, String initials) {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xECFFFFFF),
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // logo
          RichText(
            text: TextSpan(
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: _kDark,
                letterSpacing: -0.3,
              ),
              children: const [
                TextSpan(text: 'AU '),
                TextSpan(
                  text: 'Connect',
                  style: TextStyle(
                      color: AppTheme.primary, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // nav links
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _NavLink(
                    label: 'Dashboard',
                    active: true,
                    icon: const Icon(Icons.grid_view_rounded, size: 13),
                  ),
                  _NavLink(
                    label: 'Academic Records',
                    icon: const Icon(Icons.description_outlined, size: 13),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Academic Records – coming soon')),
                    ),
                  ),
                  _NavLink(
                    label: 'Application Progress',
                    icon: const Icon(Icons.show_chart_rounded, size: 13),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ApplicationStatusScreen()),
                    ),
                  ),
                  _NavLink(
                    label: 'Payments',
                    icon: const Icon(Icons.credit_card_outlined, size: 13),
                    onTap: () =>
                        Navigator.pushNamed(context, '/payments'),
                  ),
                  _NavLink(
                    label: 'Support',
                    icon: const Icon(Icons.info_outline_rounded, size: 13),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Support – coming soon')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _LangButton(),
          const SizedBox(width: 8),
          // avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF8B0F25)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BODY ──────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // error banner
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
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
                    child: Text(_error!,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppTheme.primary)),
                  ),
                ],
              ),
            ),

          // page header
          FadeTransition(
            opacity: _stagger(0),
            child: SlideTransition(
              position: Tween(
                      begin: const Offset(0, 0.3), end: Offset.zero)
                  .animate(_stagger(0)),
              child: _buildPageHeader(),
            ),
          ),
          const SizedBox(height: 20),

          // hero banner
          FadeTransition(
            opacity: _stagger(1),
            child: SlideTransition(
              position: Tween(
                      begin: const Offset(0, 0.3), end: Offset.zero)
                  .animate(_stagger(1)),
              child: _buildHeroBanner(context),
            ),
          ),
          const SizedBox(height: 20),

          // stats
          _buildSectionLabel('Overview'),
          FadeTransition(
            opacity: _stagger(2),
            child: _buildStatsGrid(),
          ),
          const SizedBox(height: 20),

          // academic history
          _buildSectionLabel('Academic History'),
          FadeTransition(
            opacity: _stagger(3),
            child: _buildAcademicHistoryCard(context),
          ),
          const SizedBox(height: 20),

          // checklist
          _buildSectionLabel('Re-admission Checklist'),
          FadeTransition(
            opacity: _stagger(4),
            child: _buildChecklistCard(context),
          ),
        ],
      ),
    );
  }

  // ── PAGE HEADER ───────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh_rounded,
                  size: 9, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                'RE-ADMISSION PORTAL',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _kDark,
              letterSpacing: -0.4,
              height: 1.1,
            ),
            children: [
              const TextSpan(text: 'Welcome back, '),
              TextSpan(
                text: _displayName,
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Re-admission Application Portal',
          style: GoogleFonts.dmSans(
              fontSize: 12,
              color: _kMuted,
              fontWeight: FontWeight.w300),
        ),
      ],
    );
  }

  // ── HERO BANNER ───────────────────────────────────────────────────────────
  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B0F25),
            AppTheme.primary,
            Color(0xFFA01428),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          // glow blobs
          Positioned(
            top: -60, right: -40,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: MediaQuery.of(context).size.width * 0.15,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // education icon top-right
          Positioned(
            top: 20, right: 20,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.school_outlined,
                  size: 18, color: Colors.white),
            ),
          ),
          // content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 70, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PendingPill(),
                const SizedBox(height: 14),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      height: 1.15,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Re-admission ',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      TextSpan(text: 'Status'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your application and clear outstanding obligations to resume your studies at Africa University.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w300,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ApplicationStatusScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Application Timeline',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded,
                            size: 14, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── STATS GRID ────────────────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            iconBg: _kPurpBg,
            iconBorder: _kPurpBd,
            iconColor: _kPurpFg,
            icon: Icons.star_outline_rounded,
            value: _gpaDisplay,
            label: 'GPA',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            iconBg: _kRedSoft,
            iconBorder: _kRedMid,
            iconColor: AppTheme.primary,
            icon: Icons.smartphone_outlined,
            value: _status.isEmpty
                ? 'Pending'
                : _status[0].toUpperCase() + _status.substring(1),
            label: 'Application Status',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            iconBg: _kGreenBg,
            iconBorder: _kGreenBd,
            iconColor: _kGreenFg,
            icon: Icons.credit_card_outlined,
            value: _balanceDisplay,
            label: 'Outstanding Balance',
          ),
        ),
      ],
    );
  }

  // ── ACADEMIC HISTORY CARD ─────────────────────────────────────────────────
  Widget _buildAcademicHistoryCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x08C41E3A), Colors.transparent],
              ),
              border:
                  Border(bottom: BorderSide(color: _kRedSoft)),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _kGreenBg,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: _kGreenBd),
                      ),
                      child: const Icon(Icons.school_outlined,
                          size: 16, color: _kGreenFg),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Previous Student Record',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kRedSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kRedMid),
                  ),
                  child: Text(
                    'Re-admission',
                    style: GoogleFonts.dmSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // content
          if (_academicRecords.isEmpty)
            _buildEmptyState(context)
          else
            ..._academicRecords.map((r) => _buildRecordRow(r)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _kRedSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kRedMid, width: 1.5),
            ),
            child: const Icon(Icons.description_outlined,
                size: 24, color: AppTheme.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'No Academic Records Found',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your previous academic records will appear here once verified by the Registrar\'s office.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: _kMuted,
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Contact Registrar – coming soon')),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Contact Registrar',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded,
                      size: 14, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRow(Map<String, dynamic> r) {
    final program = r['program'] as String? ?? 'Unknown Program';
    final year    = r['year']    as String? ?? '';
    final gpa     = (r['gpa']    as num?)?.toStringAsFixed(2) ?? 'N/A';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0DC41E3A))),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _kGreenBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kGreenBd),
            ),
            child: const Icon(Icons.school_outlined,
                size: 14, color: _kGreenFg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kDark,
                  ),
                ),
                if (year.isNotEmpty)
                  Text(year,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: _kMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: _kGreenBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGreenBd),
            ),
            child: Text(
              'GPA $gpa',
              style: GoogleFonts.dmSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: _kGreenFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CHECKLIST CARD ────────────────────────────────────────────────────────
  Widget _buildChecklistCard(BuildContext context) {
    final items = [
      _CheckItem(
        title: 'Submit Re-admission Application',
        desc: 'Complete the online re-admission form',
        done: _application != null,
        statusLabel: _application != null ? null : 'Pending',
        statusStyle: _CheckStatus.todo,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ApplicationStatusScreen()),
        ),
      ),
      _CheckItem(
        title: 'Clear Outstanding Fees',
        desc: 'Settle any unpaid balances from previous enrolment',
        done: !_hasAcademicHold,
        statusLabel: _hasAcademicHold ? 'Required' : null,
        statusStyle: _CheckStatus.warning,
        onTap: () => Navigator.pushNamed(context, '/payments'),
      ),
      _CheckItem(
        title: 'Upload Supporting Documents',
        desc: 'Transcripts, ID and reason for absence letter',
        done: false,
        statusLabel: 'Pending',
        statusStyle: _CheckStatus.todo,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DocumentUploadScreen()),
        ),
      ),
      _CheckItem(
        title: "Dean's Office Approval",
        desc: 'Await faculty review and approval decision',
        done: _status == 'approved',
        statusLabel: _status == 'approved' ? null : 'Awaiting',
        statusStyle: _CheckStatus.todo,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x08C41E3A), Colors.transparent],
              ),
              border:
                  Border(bottom: BorderSide(color: _kRedSoft)),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _kRedSoft,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: _kRedMid),
                  ),
                  child: const Icon(
                      Icons.checklist_rounded,
                      size: 16,
                      color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  'Re-admission Checklist',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
              ],
            ),
          ),
          // rows
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            final item   = e.value;
            return _CheckRow(item: item, isLast: isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 2,
          color: _kMuted,
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────
  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatbotDashboardScreen(
            systemPrompt: AUSystemPrompts.applicant,
            title: 'Re-admission Assistant',
          ),
        ),
      ),
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
      label: Text(
        'Ask AI',
        style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ─── data model ──────────────────────────────────────────────────────────────
enum _CheckStatus { todo, warning }

class _CheckItem {
  final String title, desc;
  final bool done;
  final String? statusLabel;
  final _CheckStatus statusStyle;
  final VoidCallback? onTap;

  const _CheckItem({
    required this.title,
    required this.desc,
    required this.done,
    this.statusLabel,
    this.statusStyle = _CheckStatus.todo,
    this.onTap,
  });
}

// ─── _NavLink ────────────────────────────────────────────────────────────────
class _NavLink extends StatefulWidget {
  final String label;
  final Widget icon;
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: on ? _kRedSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconTheme(
                data: IconThemeData(
                    color: on ? AppTheme.primary : _kMuted, size: 13),
                child: widget.icon,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: widget.active
                      ? FontWeight.w500
                      : FontWeight.w400,
                  color: on ? AppTheme.primary : _kMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _LangButton ─────────────────────────────────────────────────────────────
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
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hover ? AppTheme.primary : _kBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.language_outlined,
                size: 13,
                color: _hover ? AppTheme.primary : _kMuted),
            const SizedBox(width: 4),
            Text(
              'English',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: _hover ? AppTheme.primary : _kMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _PendingPill ────────────────────────────────────────────────────────────
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
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 5, height: 5,
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

// ─── _StatCard ───────────────────────────────────────────────────────────────
class _StatCard extends StatefulWidget {
  final Color iconBg, iconBorder, iconColor;
  final IconData icon;
  final String value, label;

  const _StatCard({
    required this.iconBg,
    required this.iconBorder,
    required this.iconColor,
    required this.icon,
    required this.value,
    required this.label,
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
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: _hover
            ? Matrix4.translationValues(0, -3, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover
                ? AppTheme.primary.withValues(alpha: 0.28)
                : _kBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary
                  .withValues(alpha: _hover ? 0.10 : 0.04),
              blurRadius: _hover ? 28 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              left: -16, top: -16, bottom: -16,
              width: _hover ? 4 : 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF8B0F25)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(16)),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: widget.iconBg,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: widget.iconBorder),
                  ),
                  child: Icon(widget.icon,
                      size: 16, color: widget.iconColor),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.value,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _kDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: _kMuted,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _CheckRow ───────────────────────────────────────────────────────────────
class _CheckRow extends StatefulWidget {
  final _CheckItem item;
  final bool isLast;

  const _CheckRow({required this.item, this.isLast = false});

  @override
  State<_CheckRow> createState() => _CheckRowState();
}

class _CheckRowState extends State<_CheckRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: _hover ? _kRedSoft : Colors.transparent,
            border: widget.isLast
                ? null
                : const Border(
                    bottom:
                        BorderSide(color: Color(0x0DC41E3A))),
            borderRadius: widget.isLast
                ? const BorderRadius.vertical(
                    bottom: Radius.circular(18))
                : null,
          ),
          child: Row(
            children: [
              // circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.done ? _kGreenFg : _kRedSoft,
                  border: Border.all(
                    color: item.done ? _kGreenFg : _kRedMid,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 11,
                  color: item.done ? Colors.white : _kRedMid,
                ),
              ),
              const SizedBox(width: 14),
              // body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _hover ? const Color(0xFF8B0F25) : _kDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.desc,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: _kMuted,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              // status badge
              if (item.statusLabel != null)
                _buildBadge(item.statusLabel!, item.statusStyle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, _CheckStatus style) {
    Color bg, border, fg;
    if (style == _CheckStatus.warning) {
      bg = _kAmberBg; border = _kAmberBd; fg = _kAmberFg;
    } else {
      bg = _kRedSoft; border = _kRedMid; fg = AppTheme.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
          color: fg,
        ),
      ),
    );
  }
}
