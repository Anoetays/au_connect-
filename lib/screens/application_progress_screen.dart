import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/application_state.dart';
import 'personal_information_screen.dart';
import 'document_upload_screen.dart';
import 'select_program_screen.dart';
import 'payments_screen.dart';
import 'submit_application_screen.dart';

class ApplicationProgressScreen extends StatefulWidget {
  const ApplicationProgressScreen({super.key});

  @override
  State<ApplicationProgressScreen> createState() =>
      _ApplicationProgressScreenState();
}

class _ApplicationProgressScreenState extends State<ApplicationProgressScreen> {
  final _appState = ApplicationState.instance;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() => setState(() {});

  void _startApplication() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalInformationScreen(
          nextRoute: (_) => DocumentUploadScreen(
            nextRoute: (_) => SelectProgramScreen(
              nextRoute: (_) => PaymentsScreen(
                nextRoute: (_) => const SubmitApplicationScreen(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool noneStarted = !_appState.personalInfoComplete &&
        !_appState.documentsUploaded &&
        !_appState.programmeSelected &&
        !_appState.feePaid &&
        !_appState.applicationSubmitted;

    final bool allDone = _appState.applicationSubmitted;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Application Progress',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 26,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track each step of your application below.',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Progress bar
                      _buildProgressBar(),
                      const SizedBox(height: 32),

                      if (allDone) ...[
                        _buildAllDoneBanner(),
                        const SizedBox(height: 24),
                      ],

                      if (noneStarted) ...[
                        _buildEmptyState(),
                      ] else ...[
                        _buildStepCard(
                          step: 1,
                          label: 'Select Programme',
                          description: 'Choose your faculty and degree programme.',
                          complete: _appState.programmeSelected,
                        ),
                        _buildStepCard(
                          step: 2,
                          label: 'Upload Documents',
                          description:
                              'Submit academic certificates, ID, and supporting files.',
                          complete: _appState.documentsUploaded,
                        ),
                        _buildStepCard(
                          step: 3,
                          label: 'Pay Application Fee',
                          description:
                              'Pay the \$25.00 non-refundable application fee.',
                          complete: _appState.feePaid,
                        ),
                        _buildStepCard(
                          step: 4,
                          label: 'Application Submitted',
                          description:
                              'Confirm and submit your completed application.',
                          complete: _appState.applicationSubmitted,
                        ),
                        _buildStepCard(
                          step: 5,
                          label: 'Awaiting Decision',
                          description:
                              'The admissions team is reviewing your application.',
                          complete: _appState.applicationSubmitted,
                          isLast: true,
                        ),
                      ],
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

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: AppTheme.primaryCrimson),
                  const SizedBox(width: 6),
                  Text(
                    'Back',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryCrimson,
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
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 60),
          ],
        ),
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    final pct = (_appState.progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overall Progress',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '$pct% Complete',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryCrimson,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _appState.progress,
            minHeight: 10,
            backgroundColor: const Color(0xFFF1E8E8),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryCrimson),
          ),
        ),
      ],
    );
  }

  // ── Step card ─────────────────────────────────────────────────────────────

  Widget _buildStepCard({
    required int step,
    required String label,
    required String description,
    required bool complete,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step connector
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: complete
                    ? AppTheme.primaryCrimson
                    : const Color(0xFFF1F5F9),
                border: Border.all(
                  color: complete
                      ? AppTheme.primaryCrimson
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Center(
                child: complete
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$step',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: complete
                    ? AppTheme.primaryCrimson.withValues(alpha: 0.25)
                    : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Step $step: $label',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: complete
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        complete ? 'Complete' : 'Pending',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: complete
                              ? const Color(0xFF166534)
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryLight,
            ),
            child: const Icon(Icons.assignment_outlined,
                size: 28, color: AppTheme.primaryCrimson),
          ),
          const SizedBox(height: 16),
          Text(
            'No application has been made so far.',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start your application to track your progress here.',
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            child: ElevatedButton(
              onPressed: _startApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCrimson,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Start Application',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── All done banner ───────────────────────────────────────────────────────

  Widget _buildAllDoneBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF16A34A), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '✅ Your application has been submitted. We will notify you of our decision.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF166534),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
