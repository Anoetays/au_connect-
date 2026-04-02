import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/supabase_service.dart';

// ── colour tokens ─────────────────────────────────────────────────────────────
const _kRed     = AppTheme.primaryCrimson;
const _kDark    = AppTheme.textPrimary;
const _kSub     = AppTheme.textSecondary;
const _kMuted   = AppTheme.textMuted;
const _kBorder  = AppTheme.border;
const _kBg      = AppTheme.background;
const _kGreenBg = Color(0xFFD1FAE5);
const _kGreenFg = Color(0xFF059669);
const _kBlueBg  = Color(0xFFEAF0FF);
const _kBlueFg  = Color(0xFF3B5BDB);

// ── visa step model ───────────────────────────────────────────────────────────
class _VisaStep {
  final int number;
  final String title;
  final String description;
  final IconData icon;
  bool done;
  _VisaStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    this.done = false,
  });
}

// ── main widget ───────────────────────────────────────────────────────────────
class VisaApplicationScreen extends StatefulWidget {
  const VisaApplicationScreen({super.key});
  @override
  State<VisaApplicationScreen> createState() => _VisaApplicationScreenState();
}

class _VisaApplicationScreenState extends State<VisaApplicationScreen> {
  Map<String, dynamic>? _application;
  bool _loading = true;

  late final List<_VisaStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = [
      _VisaStep(
        number: 1,
        title: 'Receive and download your Offer Letter',
        description: 'Your offer letter from Africa University is required for all visa applications.',
        icon: Icons.description_outlined,
        done: true, // auto-ticked on arrival
      ),
      _VisaStep(
        number: 2,
        title: 'Apply for a Zimbabwe Student Visa',
        description: 'Visit your nearest Zimbabwean embassy or consulate and submit your visa application with your offer letter and supporting documents.',
        icon: Icons.account_balance_outlined,
      ),
      _VisaStep(
        number: 3,
        title: 'Obtain a Study Permit',
        description: "Apply for a Study Permit from Zimbabwe's Department of Immigration. Required for stays longer than 3 months.",
        icon: Icons.badge_outlined,
      ),
      _VisaStep(
        number: 4,
        title: 'Submit Proof of Medical Insurance',
        description: 'All international students must provide valid medical insurance coverage for the duration of their studies.',
        icon: Icons.health_and_safety_outlined,
      ),
      _VisaStep(
        number: 5,
        title: 'Arrange Accommodation and Flights',
        description: 'Book your travel and confirm your accommodation. The university can assist with on-campus housing applications.',
        icon: Icons.flight_outlined,
      ),
      _VisaStep(
        number: 6,
        title: 'Complete Online Enrollment',
        description: 'Log into the Africa University student portal and complete your online enrollment to finalise your registration.',
        icon: Icons.school_outlined,
      ),
    ];
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final app = await SupabaseService.getMyApplication();
      final uid = SupabaseService.currentUserId;
      if (uid != null) {
        try {
          final progress = await Supabase.instance.client
              .from('visa_progress')
              .select()
              .eq('user_id', uid)
              .maybeSingle();
          if (progress != null) {
            final completed = List<int>.from(
                (progress['completed_steps'] as List? ?? []));
            for (final step in _steps) {
              if (step.number == 1 || completed.contains(step.number)) {
                step.done = true;
              }
            }
          }
        } catch (_) {}
      }
      if (mounted) setState(() { _application = app; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleStep(int stepNumber) async {
    if (stepNumber == 1) return; // step 1 always ticked
    final step = _steps.firstWhere((s) => s.number == stepNumber);
    setState(() => step.done = !step.done);
    try {
      final uid = SupabaseService.currentUserId;
      if (uid != null) {
        final completedNums =
            _steps.where((s) => s.done).map((s) => s.number).toList();
        await Supabase.instance.client.from('visa_progress').upsert({
          'user_id': uid,
          'completed_steps': completedNums,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      }
    } catch (_) {}
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  int get _completedCount => _steps.where((s) => s.done).length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: _kRed)));
    }

    final name = _application?['applicant_name'] as String? ?? 'Student';
    final programme = _application?['programme'] as String? ?? '—';
    final appId = _application?['applicant_id'] as String? ?? '—';

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        _buildTopBar(),
        Expanded(child: SingleChildScrollView(
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 80),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _buildIntroCard(name, programme),
                const SizedBox(height: 20),
                _buildProgressBar(),
                const SizedBox(height: 20),
                _buildSectionLabel('VISA & STUDY PERMIT STEPS'),
                _buildStepsList(),
                const SizedBox(height: 20),
                _buildResourcesCard(),
                const SizedBox(height: 20),
                _buildOfferLetterCard(name, programme, appId),
              ]),
            ),
          )),
        )),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder))),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Row(children: [
                const Icon(Icons.chevron_left_rounded, size: 20, color: _kRed),
                Text('Back', style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _kRed)),
              ]),
            ),
            const Spacer(),
            Text('Visa & Study Permit Guide', style: GoogleFonts.dmSans(
              fontSize: 15, fontWeight: FontWeight.w700, color: _kDark)),
            const Spacer(),
            const SizedBox(width: 60),
          ]),
        ),
      ),
    );
  }

  Widget _buildIntroCard(String name, String programme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B5BDB)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.flight_takeoff_rounded,
                color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Text('Welcome, $name!', style: GoogleFonts.dmSans(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
        const SizedBox(height: 12),
        Text(
          'Congratulations on your acceptance into $programme! '
          'To study in Zimbabwe, international students require a student visa '
          'and study permit. This guide will walk you through the process.',
          style: GoogleFonts.dmSans(
            fontSize: 13, color: Colors.white.withValues(alpha: 0.9), height: 1.55)),
      ]),
    );
  }

  Widget _buildProgressBar() {
    final pct = (_completedCount / _steps.length * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Visa Process Progress', style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w600, color: _kDark)),
          Text('$_completedCount/${_steps.length} steps · $pct%',
            style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w700, color: _kBlueFg)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _completedCount / _steps.length),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => LinearProgressIndicator(
              value: val, minHeight: 7,
              backgroundColor: const Color(0xFFE8EDFF),
              valueColor: const AlwaysStoppedAnimation<Color>(_kBlueFg)),
          ),
        ),
      ]),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label, style: GoogleFonts.dmSans(
        fontSize: 10, fontWeight: FontWeight.w700,
        letterSpacing: 1.5, color: _kSub)),
    );
  }

  Widget _buildStepsList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder)),
      child: Column(
        children: _steps.asMap().entries.map((e) =>
          _buildStep(e.value, e.key == _steps.length - 1)).toList()),
    );
  }

  Widget _buildStep(_VisaStep step, bool isLast) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        GestureDetector(
          onTap: () => _toggleStep(step.number),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.done ? _kGreenFg : const Color(0xFFF3F4F6),
              border: Border.all(
                color: step.done ? _kGreenFg : _kBorder, width: 2)),
            child: Center(child: step.done
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : Icon(step.icon, size: 14, color: _kMuted)),
          ),
        ),
        if (!isLast)
          Container(
            width: 2, height: 44,
            color: step.done
                ? _kGreenFg.withValues(alpha: 0.3)
                : _kBorder,
            margin: const EdgeInsets.symmetric(vertical: 4)),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Padding(
        padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(step.title, style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: step.done ? _kGreenFg : _kDark))),
            if (step.done)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kGreenBg, borderRadius: BorderRadius.circular(20)),
                child: Text('Done', style: GoogleFonts.dmSans(
                  fontSize: 10, fontWeight: FontWeight.w600, color: _kGreenFg))),
          ]),
          const SizedBox(height: 4),
          Text(step.description, style: GoogleFonts.dmSans(
            fontSize: 11, color: _kSub, height: 1.5)),
          if (!step.done && step.number > 1)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GestureDetector(
                onTap: () => _toggleStep(step.number),
                child: Text('Mark as complete', style: GoogleFonts.dmSans(
                  fontSize: 11, color: _kBlueFg,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500)),
              ),
            ),
        ]),
      )),
    ]);
  }

  Widget _buildResourcesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Resources & Contacts', style: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w700, color: _kDark)),
        const SizedBox(height: 14),
        _resourceItem(
          icon: Icons.language_rounded,
          label: 'Zimbabwe Department of Immigration',
          subtitle: 'www.immigration.gov.zw',
          onTap: () => _launchUrl('https://www.immigration.gov.zw'),
        ),
        const SizedBox(height: 10),
        _resourceItem(
          icon: Icons.email_outlined,
          label: 'AU International Office',
          subtitle: 'international@africau.edu',
          onTap: () => _launchUrl('mailto:international@africau.edu'),
        ),
        const SizedBox(height: 10),
        _resourceItem(
          icon: Icons.phone_outlined,
          label: 'AU Admissions Helpline',
          subtitle: '+263 20 2160422',
          onTap: () => _launchUrl('tel:+26320160422'),
        ),
      ]),
    );
  }

  Widget _resourceItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kBlueBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC0CCFF).withValues(alpha: 0.5))),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _kBlueBg, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC0CCFF))),
            child: Icon(icon, size: 16, color: _kBlueFg)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w600, color: _kDark)),
            Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: _kBlueFg)),
          ])),
          const Icon(Icons.open_in_new_rounded, size: 14, color: _kMuted),
        ]),
      ),
    );
  }

  Widget _buildOfferLetterCard(String name, String programme, String appId) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kGreenBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGreenFg.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.description_outlined, color: _kGreenFg, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your Offer Letter is Ready', style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w700, color: _kGreenFg)),
          Text('$programme · Ref: $appId', style: GoogleFonts.dmSans(
            fontSize: 11, color: _kGreenFg.withValues(alpha: 0.8))),
        ])),
        GestureDetector(
          onTap: () => _showOfferLetterDialog(name, programme, appId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: _kGreenFg, borderRadius: BorderRadius.circular(9)),
            child: Text('View / Download', style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  void _showOfferLetterDialog(String name, String programme, String appId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7F1D1D), _kRed]),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AFRICA UNIVERSITY', style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w800, color: _kRed,
                  letterSpacing: 1)),
                Text('Office of Admissions', style: GoogleFonts.dmSans(
                  fontSize: 11, color: _kMuted)),
              ]),
            ]),
            const SizedBox(height: 16),
            Container(height: 2, decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_kRed, Color(0xFFE8C0C8)]))),
            const SizedBox(height: 16),
            _offerRow('Student', name),
            _offerRow('Reference', appId),
            _offerRow('Programme', programme),
            _offerRow('Academic Year', '2025 / 2026'),
            _offerRow('Mode of Study', 'Full-time'),
            const SizedBox(height: 16),
            Text(
              'This letter confirms your admission and should be presented to the Zimbabwe Department of Immigration when applying for your study permit.',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: _kMuted, height: 1.5),
              textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close')),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9))),
                icon: const Icon(Icons.download_rounded, size: 14),
                label: const Text('Download PDF'),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Offer letter downloaded')));
                }),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _offerRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: GoogleFonts.dmSans(
          fontSize: 12, color: _kMuted))),
        Expanded(child: Text(value, style: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w600, color: _kDark))),
      ]),
    );
  }
}
