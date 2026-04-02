import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/application_state.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'personal_information_screen.dart';
import 'document_upload_screen.dart';
import 'select_program_screen.dart';
import 'payments_screen.dart';
import 'submit_application_screen.dart';

// ── color tokens ───────────────────────────────────────────────────────────────
const _kCrimson   = AppTheme.primaryCrimson;        // #B71C1C
const _kParch     = AppTheme.background;            // #FAF7F2
const _kSurf      = Colors.white;
const _kInk       = AppTheme.textPrimary;           // #1A1A1A
const _kMuted     = AppTheme.textMuted;             // #9CA3AF
const _kSub       = AppTheme.textSecondary;         // #6B7280
const _kBorder    = AppTheme.border;                // #E5E7EB
const _kRedBg     = AppTheme.primaryLight;          // #FFEBEE
const _kGreenBg   = Color(0xFFECFDF5);
const _kGreenFg   = Color(0xFF059669);
const _kAmberBg   = Color(0xFFFFF8E1);
const _kAmberFg   = Color(0xFFF59E0B);
const _kNeutralBg = Color(0xFFF3F4F6);
const _kNeutralFg = Color(0xFF6B7280);

class ApplicationProgressScreen extends StatefulWidget {
  const ApplicationProgressScreen({super.key});

  @override
  State<ApplicationProgressScreen> createState() =>
      _ApplicationProgressScreenState();
}

class _ApplicationProgressScreenState extends State<ApplicationProgressScreen> {
  final _appState = ApplicationState.instance;
  Map<String, dynamic>? _application;
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _payments  = [];
  bool _loadingApp = true;
  StreamSubscription<List<Map<String, dynamic>>>? _appSub;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChanged);
    _appSub = SupabaseService.streamMyApplications().listen((rows) async {
      if (!mounted) return;
      final app = rows.isNotEmpty ? rows.first : null;

      List<Map<String, dynamic>> docs = [];
      List<Map<String, dynamic>> pays = [];
      if (app != null) {
        try {
          final results = await Future.wait([
            SupabaseService.getDocuments(app['id'] as String),
            SupabaseService.getPaymentHistory(),
          ]);
          docs = results[0];
          pays = results[1];
        } catch (_) {}
      }

      if (!mounted) return;
      // Sync ApplicationState so step badges reflect reality
      final profile = await SupabaseService.getProfile();
      if (mounted) {
        _appState.syncFromData(profile: profile, application: app, documents: docs);
        setState(() {
          _application = app;
          _documents   = docs;
          _payments    = pays;
          _loadingApp  = false;
        });
      }
    }, onError: (_) {
      if (mounted) setState(() => _loadingApp = false);
    });
  }

  @override
  void dispose() {
    _appSub?.cancel();
    _appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() => setState(() {});

  String get _liveStatus {
    final s = (_application?['status'] as String? ?? '').toLowerCase();
    return s;
  }

  bool get _isApproved => _liveStatus == 'approved';
  bool get _isDenied   => _liveStatus == 'rejected' || _liveStatus == 'denied';
  bool get _isReview   => _liveStatus == 'under review' || _liveStatus == 'under_review';
  bool get _isInternational =>
    (_application?['type'] as String? ?? '').toLowerCase().contains('international');

  void _startApplication() {
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
    );
  }

  // ── Derived state ─────────────────────────────────────────────────────────

  bool get _noneStarted =>
      !_appState.personalInfoComplete &&
      !_appState.documentsUploaded &&
      !_appState.programmeSelected &&
      !_appState.feePaid &&
      !_appState.applicationSubmitted;

  bool get _allDone => _appState.applicationSubmitted;

  double get _progress => _appState.progress;

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kParch,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          'Application Progress',
                          style: GoogleFonts.dmSans(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: _kInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track each step of your application below.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: _kSub,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Progress bar card
                        _buildProgressCard(),
                        const SizedBox(height: 20),

                        // Decision banners (from Supabase live status)
                        if (!_loadingApp && _isApproved) ...[
                          _buildApprovedBanner(),
                          const SizedBox(height: 12),
                          if (_isInternational) ...[
                            _buildVisaPrompt(),
                            const SizedBox(height: 12),
                          ],
                        ],
                        if (!_loadingApp && _isDenied) ...[
                          _buildDeniedBanner(),
                          const SizedBox(height: 20),
                        ],
                        if (!_loadingApp && _isReview) ...[
                          _buildReviewBanner(),
                          const SizedBox(height: 20),
                        ],

                        // All done banner (submitted, awaiting decision)
                        if (_allDone && !_isApproved && !_isDenied && !_isReview) ...[
                          _buildAllDoneBanner(),
                          const SizedBox(height: 20),
                        ],

                        // Empty state
                        if (_noneStarted) ...[
                          _buildEmptyState(),
                          const SizedBox(height: 24),
                        ],

                        // Steps section
                        _buildSectionLabel('Your Application Steps'),
                        _buildStepsCard(),
                        const SizedBox(height: 20),

                        // Payment section
                        _buildSectionLabel('Payment'),
                        _buildPaymentCard(),
                        const SizedBox(height: 20),

                        // Tip card
                        _buildTipCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: _kSurf,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Row(
                  children: [
                    const Icon(Icons.chevron_left_rounded,
                        size: 20, color: _kCrimson),
                    Text(
                      'Back',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kCrimson,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Application Progress',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 60),
            ],
          ),
        ),
      ),
    );
  }

  // ── Progress bar card ─────────────────────────────────────────────────────

  Widget _buildProgressCard() {
    final pct = _application != null ? 100 : (_progress * 100).round();
    final steps = [
      ('1', 'Profile',   _appState.personalInfoComplete),
      ('2', 'Programme', _appState.programmeSelected),
      ('3', 'Docs',      _appState.documentsUploaded),
      ('4', 'Fee',       _appState.feePaid),
      ('5', 'Submit',    _appState.applicationSubmitted),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: _kSurf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overall Progress',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _kInk)),
              Text('$pct% Complete',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _kCrimson)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 7,
                backgroundColor: _kBorder,
                valueColor: AlwaysStoppedAnimation<Color>(_kCrimson),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.map((s) {
              final done   = s.$3;
              final active = !done && _progress > 0;
              return Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? _kGreenFg
                          : (active ? _kCrimson : _kSurf),
                      border: Border.all(
                        color: done
                            ? _kGreenFg
                            : (active ? _kCrimson : _kBorder),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check, size: 10, color: Colors.white)
                          : Text(s.$1,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: active ? Colors.white : _kMuted,
                              )),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(s.$2,
                      style: GoogleFonts.dmSans(
                          fontSize: 10, fontWeight: FontWeight.w500, color: _kMuted)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
      decoration: BoxDecoration(
        color: _kSurf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _kRedBg,
            ),
            child: const Center(
              child: Text('📋', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No application has been made so far.',
            style: GoogleFonts.dmSans(
                fontSize: 15, fontWeight: FontWeight.w700, color: _kInk),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Start your application to begin tracking your progress here.',
            style: GoogleFonts.dmSans(fontSize: 12, color: _kSub, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _startApplication,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              decoration: BoxDecoration(
                color: _kCrimson,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Start Application',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(width: 7),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 15, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: _kSub,
        ),
      ),
    );
  }

  // ── Steps card ────────────────────────────────────────────────────────────

  Widget _buildStepsCard() {
    final steps = [
      _StepData(
        num: 1,
        title: 'Complete Personal Profile',
        sub: 'Fill in your name, contact details, and background.',
        done: _appState.personalInfoComplete,
      ),
      _StepData(
        num: 2,
        title: 'Select Programme',
        sub: () {
          final prog = _application?['programme'] as String?
                    ?? _application?['program']   as String?;
          return (prog != null && prog.isNotEmpty) ? prog : 'Choose faculty & degree programme.';
        }(),
        done: _appState.programmeSelected,
      ),
      _StepData(
        num: 3,
        title: 'Upload Documents',
        sub: _documents.isEmpty
            ? 'National ID & academic certificates.'
            : '${_documents.length} document${_documents.length == 1 ? "" : "s"} uploaded',
        done: _appState.documentsUploaded,
      ),
      _StepData(
        num: 4,
        title: 'Pay Application Fee',
        sub: _payments.isNotEmpty
            ? 'Fee paid · \$${(_payments.first['amount'] ?? 25).toString()}'
            : '\$25 via EcoCash, Flutterwave or card.',
        done: _appState.feePaid || _payments.isNotEmpty,
        isAwaitingFee: _payments.isEmpty && _appState.programmeSelected,
      ),
      _StepData(
        num: 5,
        title: 'Submit & Await Offer Letter',
        sub: _appState.applicationSubmitted
            ? 'Submitted — awaiting admissions decision.'
            : 'Review → Submit → Receive offer by email.',
        done: _appState.applicationSubmitted,
        isLast: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: steps.map((s) => _buildStep(s)).toList(),
      ),
    );
  }

  Widget _buildStep(_StepData s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: number + connector line
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.done
                    ? _kGreenBg
                    : const Color(0xFF1B1C1C).withValues(alpha: 0.08),
                // slight red tint for crimson step
              ),
              child: Center(
                child: s.done
                    ? const Icon(Icons.check, size: 13, color: _kGreenFg)
                    : Text(
                        '${s.num}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: s.done ? _kGreenFg : _kCrimson,
                        ),
                      ),
              ),
            ),
            if (!s.isLast)
              Container(
                width: 1.5,
                height: 40,
                color: _kBorder,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Right: content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: 3,
              bottom: s.isLast ? 0 : 16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kInk)),
                      const SizedBox(height: 2),
                      Text(s.sub,
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: _kSub, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildBadge(s),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(_StepData s) {
    final Color bg;
    final Color fg;
    final String label;

    if (s.done) {
      bg = _kGreenBg; fg = _kGreenFg; label = 'Done';
    } else if (s.isAwaitingFee) {
      bg = _kAmberBg; fg = _kAmberFg; label = 'Awaiting';
    } else {
      bg = _kNeutralBg; fg = _kNeutralFg; label = 'Not Started';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // ── Approved banner ───────────────────────────────────────────────────────

  Widget _buildApprovedBanner() {
    final programme = _application?['programme'] as String? ?? 'your programme';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kGreenBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGreenFg.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle_rounded, color: _kGreenFg, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Application Approved 🎉',
            style: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: Color(0xFF065F46)),
          )),
        ]),
        const SizedBox(height: 8),
        Text(
          'Congratulations! You have been accepted into $programme at Africa University.',
          style: GoogleFonts.dmSans(fontSize: 13, color: Color(0xFF065F46), height: 1.45),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showOfferLetter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: _kGreenFg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.description_outlined, size: 15, color: Colors.white),
              const SizedBox(width: 7),
              Text('View Offer Letter',
                style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
        ),
      ]),
    );
  }

  void _showOfferLetter() {
    final name = _application?['applicant_name'] as String? ?? 'Applicant';
    final programme = _application?['programme'] as String? ?? '—';
    final faculty = _application?['faculty'] as String? ?? '—';
    final appId = _application?['applicant_id'] as String? ?? '—';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          width: 560,
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Letterhead
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7F1D1D), _kCrimson]),
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 22)),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AFRICA UNIVERSITY',
                    style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _kCrimson,
                      letterSpacing: 1.2)),
                  Text('Office of Admissions · Mutare, Zimbabwe',
                    style: GoogleFonts.dmSans(fontSize: 11, color: _kSub)),
                ]),
              ]),
              const SizedBox(height: 24),
              Container(height: 2, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_kCrimson, Color(0xFFE8C0C8)]))),
              const SizedBox(height: 20),
              Text('OFFER OF ADMISSION',
                style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  letterSpacing: 2, color: _kCrimson)),
              const SizedBox(height: 12),
              Text('Dear $name,', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: _kInk)),
              const SizedBox(height: 10),
              Text(
                'We are pleased to offer you admission to Africa University for the 2025 academic year. '
                'This offer is subject to confirmation of your qualifications and compliance with all university requirements.',
                style: GoogleFonts.dmSans(fontSize: 13, color: _kInk, height: 1.6)),
              const SizedBox(height: 20),
              _offerRow('Student Name', name),
              _offerRow('Application ID', appId),
              _offerRow('Programme', programme),
              _offerRow('Faculty', faculty),
              _offerRow('Academic Year', '2025 / 2026'),
              _offerRow('Mode of Study', 'Full-time'),
              const SizedBox(height: 20),
              Text(
                'Please confirm your acceptance by visiting the student portal within 14 days of receiving this letter.',
                style: GoogleFonts.dmSans(fontSize: 13, color: _kSub, height: 1.5)),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Close', style: GoogleFonts.dmSans(color: _kSub))),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kCrimson, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: Text('Download', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Offer letter saved to downloads')));
                  }),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _offerRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 140, child: Text(label,
          style: GoogleFonts.dmSans(fontSize: 12, color: _kSub, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value,
          style: GoogleFonts.dmSans(fontSize: 13, color: _kInk, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _buildVisaPrompt() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0CCFF)),
      ),
      child: Row(children: [
        const Icon(Icons.flight_takeoff_rounded, color: Color(0xFF3B5BDB), size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(
          'As an international student, you need to apply for a Zimbabwe student visa and study permit.',
          style: GoogleFonts.dmSans(fontSize: 12, color: Color(0xFF3B5BDB), height: 1.4))),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/visa_application'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF3B5BDB),
              borderRadius: BorderRadius.circular(8)),
            child: Text('Visa Guide',
              style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  // ── Denied banner ─────────────────────────────────────────────────────────

  Widget _buildDeniedBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kRedBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCrimson.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.cancel_outlined, color: _kCrimson, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(
          'Your application was not successful at this time. Please check your notifications for the reason and next steps.',
          style: GoogleFonts.dmSans(fontSize: 13, color: _kCrimson, height: 1.45),
        )),
      ]),
    );
  }

  // ── Under Review banner ───────────────────────────────────────────────────

  Widget _buildReviewBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kAmberBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAmberFg.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.manage_search_rounded, color: _kAmberFg, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(
          'Your application is currently under review. You will be notified once a decision has been made.',
          style: GoogleFonts.dmSans(fontSize: 13, color: _kAmberFg, height: 1.45),
        )),
      ]),
    );
  }

  // ── All done banner ───────────────────────────────────────────────────────

  Widget _buildAllDoneBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kGreenBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGreenFg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: _kGreenFg, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your application has been submitted. We will notify you of our decision.',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF065F46),
                  height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment card ──────────────────────────────────────────────────────────

  Widget _buildPaymentCard() {
    if (_payments.isEmpty) {
      // No payment recorded — show pending prompt
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kSurf,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _kAmberBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.payment_outlined, size: 18, color: _kAmberFg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Pending',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600, color: _kInk)),
                  const SizedBox(height: 2),
                  Text('Application fee of \$25 has not been recorded.',
                      style: GoogleFonts.dmSans(fontSize: 12, color: _kSub)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Payment found — show receipt
    final pay = _payments.first;
    final amount  = pay['amount']    ?? pay['total']  ?? 25;
    final method  = pay['method']    ?? pay['payment_method'] ?? 'Card';
    final ref     = pay['reference'] ?? pay['transaction_id'] ?? pay['id'] ?? '—';
    final rawDate = pay['created_at'] ?? pay['paid_at'];
    String dateStr = '—';
    if (rawDate != null) {
      try {
        final dt = DateTime.parse(rawDate as String).toLocal();
        const mo = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
        dateStr = '${mo[dt.month - 1]} ${dt.day}, ${dt.year}';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kGreenBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGreenFg.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: _kGreenFg, size: 18),
              const SizedBox(width: 8),
              Text('Application Fee Paid ✓',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: Color(0xFF065F46))),
            ],
          ),
          const SizedBox(height: 12),
          _payRow('Amount',    '\$$amount'),
          _payRow('Method',    method.toString()),
          _payRow('Date',      dateStr),
          _payRow('Reference', ref.toString()),
        ],
      ),
    );
  }

  Widget _payRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: _kSub, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: _kInk, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Tip card ──────────────────────────────────────────────────────────────

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: _kCrimson.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCrimson.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kRedBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('💡', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Application Tip',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kCrimson)),
                const SizedBox(height: 3),
                Text(
                  'Complete each step in order. Have your academic certificates, national ID, and birth certificate ready before you begin.',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: _kSub, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step data model ───────────────────────────────────────────────────────────

class _StepData {
  final int num;
  final String title;
  final String sub;
  final bool done;
  final bool isLast;
  final bool isAwaitingFee;

  const _StepData({
    required this.num,
    required this.title,
    required this.sub,
    required this.done,
    this.isLast = false,
    this.isAwaitingFee = false,
  });
}
