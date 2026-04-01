import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'personal_information_screen.dart';
import 'document_upload_screen.dart';
import 'select_program_screen.dart';
import 'payments_screen.dart';
import 'submit_application_screen.dart';
import 'application_status_screen.dart';

class VisaScreen extends StatelessWidget {
  final Map<String, dynamic>? application;
  const VisaScreen({super.key, this.application});

  String get _status => application?['status'] as String? ?? '';
  bool get _hasApplied => application != null;
  bool get _isAdmitted =>
      _status.toLowerCase() == 'approved' ||
      _status.toLowerCase() == 'accepted' ||
      _status.toLowerCase() == 'admitted';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Travel & Visa',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0x21B91C1C)),
        ),
      ),
      body: _isAdmitted
          ? _buildAdmittedContent(context)
          : _hasApplied
              ? _buildAppliedContent(context)
              : _buildNotAppliedContent(context),
    );
  }

  // ── Not applied ────────────────────────────────────────────────────────────
  Widget _buildNotAppliedContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFCCCC)),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 32, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Application Required',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You have not yet applied to Africa University. Travel & Visa services become available after you submit your application and receive an admission decision.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Start Application',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Applied but not admitted ───────────────────────────────────────────────
  Widget _buildAppliedContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: const Icon(Icons.lock_clock_outlined,
                  size: 32, color: Color(0xFFE65100)),
            ),
            const SizedBox(height: 20),
            Text(
              'Awaiting Admission',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Travel & Visa services are only available once you have been admitted. Your application is currently under review — check back after your admission decision.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ApplicationStatusScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Check Application Progress',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Admitted — full visa info ──────────────────────────────────────────────
  Widget _buildAdmittedContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admitted banner
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
                      Text(
                        'You are admitted!',
                        style: GoogleFonts.dmSerifDisplay(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'You can now begin your visa and travel preparations.',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Zimbabwe student visa
          const _SectionHeader(label: 'STUDENT VISA'),
          const _InfoCard(
            icon: Icons.article_outlined,
            title: 'Zimbabwe Student Visa (Class D)',
            subtitle:
                'Required for most non-SADC nationals. Apply at the nearest Zimbabwe embassy or consulate in your home country before travelling.',
          ),
          const SizedBox(height: 20),

          // Required documents
          const _SectionHeader(label: 'REQUIRED DOCUMENTS'),
          const _DocItem(
            label: 'Valid Passport',
            detail: 'Valid for at least 6 months beyond your study period',
          ),
          const _DocItem(
            label: 'Admission / Offer Letter',
            detail: 'Official letter from Africa University',
          ),
          const _DocItem(
            label: 'Completed Visa Application Form',
            detail: 'Available from your nearest Zimbabwe embassy',
          ),
          const _DocItem(
            label: 'Recent Passport-Sized Photos',
            detail: '2 colour photos against a white background',
          ),
          const _DocItem(
            label: 'Proof of Financial Means',
            detail:
                'Bank statement or sponsor letter (minimum USD 300/month)',
          ),
          const _DocItem(
            label: 'Medical Certificate',
            detail: 'Health certificate from a recognised institution',
          ),
          const _DocItem(
            label: 'Proof of Medical Insurance',
            detail: 'Valid international health insurance coverage',
          ),
          const SizedBox(height: 20),

          // Travel tips
          const _SectionHeader(label: 'TRAVEL TIPS'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0x21B91C1C), width: 1.5),
            ),
            child: const Column(
              children: [
                _TipRow(
                  icon: Icons.access_time_rounded,
                  tip:
                      'Apply for your visa at least 8 weeks before your intended travel date.',
                ),
                Divider(height: 20),
                _TipRow(
                  icon: Icons.flight_rounded,
                  tip:
                      'Harare International Airport (HRE) is the closest major airport to Africa University.',
                ),
                Divider(height: 20),
                _TipRow(
                  icon: Icons.local_hospital_outlined,
                  tip:
                      'Yellow fever vaccination may be required depending on your country of origin.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── helpers ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
            color: AppTheme.textMuted,
          ),
        ),
      );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoCard(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x21B91C1C), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFCCCC)),
              ),
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
                          color: const Color(0xFF1A0A0D))),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DocItem extends StatelessWidget {
  final String label;
  final String detail;
  const _DocItem({required this.label, required this.detail});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: const Color(0x21B91C1C), width: 1.5),
        ),
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
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(detail,
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String tip;
  const _TipRow({required this.icon, required this.tip});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(tip,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF1A0A0D),
                    height: 1.5)),
          ),
        ],
      );
}
