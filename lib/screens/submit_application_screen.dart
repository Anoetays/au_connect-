import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/l10n/app_localizations.dart';
import 'package:au_connect/theme/app_theme.dart';

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
const _kGreen        = AppTheme.statusApproved;
const _kGreenPale    = Color(0xFFEBF7F1);
const _kGold         = Color(0xFFC89B3C);

// ─── step definitions ─────────────────────────────────────────────────────────
class _StepDef {
  final String name, sub;
  final bool done;
  final bool current;
  const _StepDef(this.name, this.sub, {this.done = false, this.current = false});
}

const _kSteps = <_StepDef>[
  _StepDef('Profile',         'Step 1 Completed', done: true),
  _StepDef('Info',            'Step 2 Completed', done: true),
  _StepDef('Docs',            'Step 3 Completed', done: true),
  _StepDef('Program',         'Step 4 Completed', done: true),
  _StepDef('Application Fee', 'Step 5 Completed', done: true),
  _StepDef('Submit',          'Current Step',     current: true),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class SubmitApplicationScreen extends StatefulWidget {
  const SubmitApplicationScreen({super.key});

  @override
  State<SubmitApplicationScreen> createState() =>
      _SubmitApplicationScreenState();
}

class _SubmitApplicationScreenState extends State<SubmitApplicationScreen> {
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kParchment,
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (_, cons) {
                final wide = cons.maxWidth >= 860;
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1060),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(36, 40, 36, 60),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _Sidebar(),
                                  const SizedBox(width: 32),
                                  Expanded(child: _buildMain()),
                                ],
                              )
                            : _buildMain(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading
        Text(
          'Final Review & Submission',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 32, fontWeight: FontWeight.w600, color: _kInk,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Text(
            'Please verify all the details below. Once submitted, your application will enter the curation phase and changes cannot be made without advisor intervention.',
            style: GoogleFonts.dmSans(
              fontSize: 13.5, color: _kMuted, height: 1.65,
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Identity + Program row
        LayoutBuilder(builder: (_, cons) {
          final wide = cons.maxWidth >= 560;
          if (wide) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _IdentityCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _ProgramCard()),
                ],
              ),
            );
          }
          return Column(children: [
            _IdentityCard(),
            const SizedBox(height: 16),
            _ProgramCard(),
          ]);
        }),
        const SizedBox(height: 16),

        // Docs card
        _DocsCard(),
        const SizedBox(height: 16),

        // Fees + Declaration row
        LayoutBuilder(builder: (_, cons) {
          final wide = cons.maxWidth >= 560;
          if (wide) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _FeesCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _DeclarationCard()),
                ],
              ),
            );
          }
          return Column(children: [
            _FeesCard(),
            const SizedBox(height: 16),
            _DeclarationCard(),
          ]);
        }),
        const SizedBox(height: 18),

        // Submit banner
        _SubmitBanner(
          submitted: _submitted,
          onSubmit: () {
            setState(() => _submitted = true);
            _showSuccessDialog();
          },
        ),
      ],
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: _kGreenPale, shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: _kGreen, size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Application Submitted!',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 24, fontWeight: FontWeight.w600, color: _kInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your application for the 2024 academic year has been officially submitted. You will receive a confirmation email shortly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13.5, color: _kMuted, height: 1.55,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kCrimson,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Back to Dashboard',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w500, fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _kParchment.withValues(alpha: 0.96),
        border: const Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        children: [
          Text(
            'AU Connect',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20, fontWeight: FontWeight.w600,
              letterSpacing: 0.06 * 20, color: _kInk,
            ),
          ),
          const Spacer(),
          _TopBtn(label: '?'),
          const SizedBox(width: 8),
          _TopAvatar(),
        ],
      ),
    );
  }
}

class _TopBtn extends StatefulWidget {
  final String label;
  const _TopBtn({required this.label});

  @override
  State<_TopBtn> createState() => _TopBtnState();
}

class _TopBtnState extends State<_TopBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 30, height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: Colors.white,
          border: Border.all(
            color: _hover ? _kCrimson : _kBorder, width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: _hover ? _kCrimson : _kMuted,
          ),
        ),
      ),
    );
  }
}

class _TopAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kCrimsonPale,
        border: Border.all(color: _kCrimson.withValues(alpha: 0.2), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        'A',
        style: GoogleFonts.cormorantGaramond(
          fontSize: 13, fontWeight: FontWeight.w600, color: _kCrimson,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          // Progress card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
              boxShadow: const [
                BoxShadow(color: Color(0x0D1A1208), blurRadius: 12, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ONBOARDING PROGRESS',
                  style: GoogleFonts.dmSans(
                    fontSize: 9, fontWeight: FontWeight.w500,
                    letterSpacing: 0.18 * 9, color: _kMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox.shrink(),
                    Text(
                      '80%',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18, fontWeight: FontWeight.w600, color: _kCrimson,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress bar
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: _kBorder, borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kCrimsonLight, _kCrimson],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Steps
                _buildSteps(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Assist card
          _AssistCard(),
        ],
      ),
    );
  }

  Widget _buildSteps() {
    return Stack(
      children: [
        Positioned(
          left: 10,
          top: 18,
          bottom: 18,
          child: Container(
            width: 1.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_kGreen, _kBorder],
                stops: [0.7, 0.9],
              ),
            ),
          ),
        ),
        Column(
          children: [
            for (int i = 0; i < _kSteps.length; i++)
              _SideStepRow(step: _kSteps[i], number: i + 1),
          ],
        ),
      ],
    );
  }
}

class _SideStepRow extends StatelessWidget {
  final _StepDef step;
  final int number;
  const _SideStepRow({required this.step, required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: step.current ? _kCrimsonPale : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _SideStepDot(step: step, number: number),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: step.current ? _kCrimson : _kInk,
                  ),
                ),
                Text(
                  step.sub,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: step.current
                        ? _kCrimson.withValues(alpha: 0.6)
                        : _kMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideStepDot extends StatelessWidget {
  final _StepDef step;
  final int number;
  const _SideStepDot({required this.step, required this.number});

  @override
  Widget build(BuildContext context) {
    if (step.done) {
      return Container(
        width: 22, height: 22,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: _kGreen),
        child: const Icon(Icons.check_rounded, size: 11, color: Colors.white),
      );
    }
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kCrimson,
        boxShadow: [
          BoxShadow(
            color: _kCrimson.withValues(alpha: 0.3),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: GoogleFonts.cormorantGaramond(
          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white,
        ),
      ),
    );
  }
}

class _AssistCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: _kInk,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x261A1208), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need Assistance?',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Our admissions curators are available for a live chat.',
            style: GoogleFonts.dmSans(
              fontSize: 11.5, color: Colors.white.withValues(alpha: 0.55), height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/chatbot_dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)),
                elevation: 0,
              ),
              child: Text(
                'Contact Advisor',
                style: GoogleFonts.dmSans(
                  fontSize: 12.5, fontWeight: FontWeight.w500,
                  letterSpacing: 0.03 * 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card shell
// ─────────────────────────────────────────────────────────────────────────────
class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _CardShell({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 22, 24, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0D1A1208), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Applicant identity card
// ─────────────────────────────────────────────────────────────────────────────
class _IdentityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _kParchDeep, borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _kBorder),
                ),
                child: const Icon(Icons.person_outline_rounded,
                    size: 16, color: _kInkMid),
              ),
              Text(
                'EDIT STEP 1',
                style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  letterSpacing: 0.08 * 11, color: _kCrimson,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Applicant Identity',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18, fontWeight: FontWeight.w600, color: _kInk,
            ),
          ),
          const SizedBox(height: 16),
          _FieldGroup(label: 'Full Legal Name', value: 'Amara Chidubem Okafor'),
          const SizedBox(height: 12),
          _FieldGroup(label: 'Email Address',   value: 'a.okafor@connect.africa.edu'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _FieldGroup(label: 'Nationality', value: 'Nigeria')),
              const SizedBox(width: 16),
              Expanded(child: _FieldGroup(label: 'D.O.B', value: '12 May 2002')),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selected program card
// ─────────────────────────────────────────────────────────────────────────────
class _ProgramCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kCrimsonLight, _kCrimson],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('★ ',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: Colors.white)),
                    Text(
                      'Selected Program',
                      style: GoogleFonts.dmSans(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        letterSpacing: 0.08 * 10, color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'EDIT STEP 4',
                style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  letterSpacing: 0.08 * 11,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Selected Program',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          _ProgField(label: 'Faculty', value: 'Faculty of Computer Science'),
          const SizedBox(height: 10),
          _ProgField(
            label: 'Degree Major',
            value: 'BSc. Artificial Intelligence & Data Science',
            large: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Fall Semester 2024 Intake',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgField extends StatelessWidget {
  final String label, value;
  final bool large;
  const _ProgField({required this.label, required this.value, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 9.5, fontWeight: FontWeight.w500,
            letterSpacing: 0.14 * 9.5,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 3),
        large
            ? Text(
                value,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
                ),
              )
            : Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white,
                ),
              ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Verified documents card
// ─────────────────────────────────────────────────────────────────────────────
class _DocsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verified Documents',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 18, fontWeight: FontWeight.w600, color: _kInk,
                ),
              ),
              Text(
                'MANAGE DOCS',
                style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  letterSpacing: 0.08 * 11, color: _kCrimson,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (_, cons) {
            final cols = cons.maxWidth >= 480 ? 2 : 1;
            if (cols == 2) {
              return Row(
                children: [
                  Expanded(
                    child: _DocItem(
                      icon: Icons.shield_outlined,
                      name: 'National ID / Passport',
                      status: '✓ Verified (PDF)',
                      statusColor: _kGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DocItem(
                      icon: Icons.insert_drive_file_outlined,
                      name: 'Academic Transcripts',
                      status: '↑ Uploaded',
                      statusColor: AppTheme.statusReview,
                    ),
                  ),
                ],
              );
            }
            return Column(children: [
              _DocItem(
                icon: Icons.shield_outlined,
                name: 'National ID / Passport',
                status: '✓ Verified (PDF)',
                statusColor: _kGreen,
              ),
              const SizedBox(height: 12),
              _DocItem(
                icon: Icons.insert_drive_file_outlined,
                name: 'Academic Transcripts',
                status: '↑ Uploaded',
                statusColor: AppTheme.statusReview,
              ),
            ]);
          }),
        ],
      ),
    );
  }
}

class _DocItem extends StatelessWidget {
  final IconData icon;
  final String name, status;
  final Color statusColor;
  const _DocItem({
    required this.icon,
    required this.name,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _kParchment,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _kMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5, fontWeight: FontWeight.w500, color: _kInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 10, fontWeight: FontWeight.w600,
              letterSpacing: 0.1 * 10, color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fees card
// ─────────────────────────────────────────────────────────────────────────────
class _FeesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Fees',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18, fontWeight: FontWeight.w600, color: _kInk,
            ),
          ),
          const SizedBox(height: 16),
          _FeeRow(label: 'Processing Fee', value: '\$25.00'),
          _FeeRow(label: 'Portal Access',   value: 'Included'),
          const SizedBox(height: 6),
          const Divider(color: _kParchDeep, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5, fontWeight: FontWeight.w500, color: _kInk,
                  ),
                ),
                Text(
                  '\$25.00',
                  style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w500, color: _kInk,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.check_rounded, size: 12, color: _kGreen),
              const SizedBox(width: 5),
              Text(
                'Paid via Visa ending in 4242',
                style: GoogleFonts.dmSans(fontSize: 11, color: _kGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label, value;
  const _FeeRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kParchDeep)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w500, color: _kInk)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Declaration card
// ─────────────────────────────────────────────────────────────────────────────
class _DeclarationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final Declaration',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18, fontWeight: FontWeight.w600, color: _kInk,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: _kGreen, borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: _kGreen, width: 1.5),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 11, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'I hereby certify that the information provided in this application is accurate and complete to the best of my knowledge. I understand that any false statements or omissions may result in the disqualification of my application or expulsion from Africa University.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5, color: _kInkMid, height: 1.65,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit banner
// ─────────────────────────────────────────────────────────────────────────────
class _SubmitBanner extends StatefulWidget {
  final bool submitted;
  final VoidCallback onSubmit;
  const _SubmitBanner({required this.submitted, required this.onSubmit});

  @override
  State<_SubmitBanner> createState() => _SubmitBannerState();
}

class _SubmitBannerState extends State<_SubmitBanner> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        color: _kCrimsonPale,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _kCrimson.withValues(alpha: 0.3), width: 1.5,
          // dashed not natively supported — solid with reduced alpha achieves similar feel
        ),
      ),
      child: LayoutBuilder(builder: (_, cons) {
        final wide = cons.maxWidth >= 480;
        final btn = _buildSubmitBtn();
        if (wide) {
          return Row(
            children: [
              Expanded(child: _buildText()),
              const SizedBox(width: 20),
              btn,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_buildText(), const SizedBox(height: 16), btn],
        );
      }),
    );
  }

  Widget _buildText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to Submit?',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20, fontWeight: FontWeight.w600, color: _kCrimson,
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            'By clicking the button, you officially submit your application for the 2024 academic year.',
            style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitBtn() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.submitted ? null : widget.onSubmit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          transform: _hover && !widget.submitted
              ? Matrix4.translationValues(0, -1, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: widget.submitted
                ? const LinearGradient(colors: [_kGreen, _kGreen])
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kCrimsonLight, _kCrimson],
                  ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: (_hover && !widget.submitted ? _kCrimson : _kCrimson)
                    .withValues(alpha: _hover ? 0.42 : 0.3),
                blurRadius: _hover ? 22 : 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.submitted ? 'Submitted ✓' : AppLocalizations.of(context)!.submitApplication,
                style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  letterSpacing: 0.04 * 14, color: Colors.white,
                ),
              ),
              if (!widget.submitted) ...[
                const SizedBox(width: 9),
                const Icon(Icons.send_rounded, size: 16, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
class _FieldGroup extends StatelessWidget {
  final String label, value;
  const _FieldGroup({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 9.5, fontWeight: FontWeight.w500,
            letterSpacing: 0.14 * 9.5, color: _kMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 13.5, fontWeight: FontWeight.w500, color: _kInk,
          ),
        ),
      ],
    );
  }
}
