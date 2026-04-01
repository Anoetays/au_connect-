import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'select_program_screen.dart';

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

// ─── step definitions ─────────────────────────────────────────────────────────
enum _StepStatus { done, current, upcoming }

class _StepDef {
  final String name;
  final _StepStatus status;
  const _StepDef(this.name, this.status);
}

const _kSteps = <_StepDef>[
  _StepDef('Personal Details',    _StepStatus.done),
  _StepDef('Documents Upload',    _StepStatus.done),
  _StepDef('Academic Portfolio',  _StepStatus.current),
  _StepDef('Select Program',      _StepStatus.upcoming),
  _StepDef('Payment',             _StepStatus.upcoming),
  _StepDef('Review & Submit',     _StepStatus.upcoming),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class MastersPostgradDocsScreen extends StatefulWidget {
  const MastersPostgradDocsScreen({super.key, this.nextRoute});
  final WidgetBuilder? nextRoute;

  @override
  State<MastersPostgradDocsScreen> createState() =>
      _MastersPostgradDocsScreenState();
}

class _MastersPostgradDocsScreenState extends State<MastersPostgradDocsScreen> {
  // Statement of purpose
  final _sopCtrl = TextEditingController();

  // CV / Resume sections — each entry is a text block
  final _eduCtrl        = TextEditingController();
  final _projectsCtrl   = TextEditingController();
  final _workCtrl       = TextEditingController();
  final _skillsCtrl     = TextEditingController();

  // Letter of recommendation
  String? _lorFileName;

  bool get _canContinue =>
      _sopCtrl.text.trim().isNotEmpty &&
      _eduCtrl.text.trim().isNotEmpty &&
      _lorFileName != null;

  @override
  void initState() {
    super.initState();
    _sopCtrl.addListener(() => setState(() {}));
    _eduCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _sopCtrl.dispose();
    _eduCtrl.dispose();
    _projectsCtrl.dispose();
    _workCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLOR() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _lorFileName = result.files.first.name);
    }
  }

  void _onContinue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: widget.nextRoute ?? (_) => const SelectProgramScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kParchment,
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: LayoutBuilder(builder: (_, cons) {
              final wide = cons.maxWidth >= 860;
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1020),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 80),
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
            }),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildMain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic Portfolio',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 30, fontWeight: FontWeight.w600, color: _kInk,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Complete all three sections below. Your statement, CV, and letter of recommendation will be reviewed by the admissions committee.',
          style: GoogleFonts.dmSans(fontSize: 13.5, color: _kMuted, height: 1.6),
        ),
        const SizedBox(height: 28),

        // ── 1. STATEMENT OF PURPOSE ───────────────────────────────────────────
        _SectionCard(
          number: '01',
          title: 'Statement of Purpose',
          subtitle: 'Write an essay explaining your motivation, goals, and academic background.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuidanceTip(
                bullets: [
                  'Why did you choose this specific programme?',
                  'What are your academic and career goals?',
                  'Describe relevant background, research, or work experience.',
                ],
              ),
              const SizedBox(height: 16),
              _TextArea(
                controller: _sopCtrl,
                hint: 'Begin your statement here… (minimum 300 words recommended)',
                minLines: 10,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_sopCtrl.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
                  style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── 2. CV / RESUME ────────────────────────────────────────────────────
        _SectionCard(
          number: '02',
          title: 'CV / Résumé',
          subtitle: 'Provide details for each section below.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CvSubSection(
                icon: Icons.school_outlined,
                label: 'Education',
                hint: 'e.g. BSc Computer Science — University of Zimbabwe (2018–2022), GPA 3.8',
                controller: _eduCtrl,
                required: true,
              ),
              const SizedBox(height: 16),
              _CvSubSection(
                icon: Icons.work_outline_rounded,
                label: 'Work Experience',
                hint: 'e.g. Software Engineer — TechCorp (2022–Present): Developed REST APIs…',
                controller: _workCtrl,
              ),
              const SizedBox(height: 16),
              _CvSubSection(
                icon: Icons.lightbulb_outline_rounded,
                label: 'Projects & Research',
                hint: 'e.g. Final-year thesis on machine learning in healthcare…',
                controller: _projectsCtrl,
              ),
              const SizedBox(height: 16),
              _CvSubSection(
                icon: Icons.tune_rounded,
                label: 'Skills',
                hint: 'e.g. Python, Data Analysis, Academic Writing, R, SPSS…',
                controller: _skillsCtrl,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── 3. LETTER OF RECOMMENDATION ──────────────────────────────────────
        _SectionCard(
          number: '03',
          title: 'Letter of Recommendation',
          subtitle: 'Upload a signed letter from a referee (academic or professional).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuidanceTip(
                bullets: [
                  'Must be signed and on official letterhead.',
                  'Accepted formats: PDF, DOC, DOCX.',
                  'Maximum file size: 5 MB.',
                ],
              ),
              const SizedBox(height: 16),
              _LorUploadZone(
                fileName: _lorFileName,
                onTap: _pickLOR,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      decoration: BoxDecoration(
        color: _kInk,
        boxShadow: [
          BoxShadow(
            color: _kInk.withValues(alpha: 0.3),
            blurRadius: 20, offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Academic Portfolio',
                style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _canContinue
                    ? 'Ready to continue'
                    : 'Complete all required fields to proceed',
                style: GoogleFonts.dmSans(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const Spacer(),
          _BarButton(enabled: _canContinue, onTap: _onContinue),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Text(
            'AU',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 19, fontWeight: FontWeight.w600,
              color: _kInk, letterSpacing: 0.04 * 19,
            ),
          ),
          Text(
            'Connect',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 19, fontWeight: FontWeight.w600,
              color: _kCrimson, letterSpacing: 0.04 * 19,
            ),
          ),
          const Spacer(),
          _CircleBtn(
            child: const Icon(Icons.info_outline_rounded, size: 14, color: _kMuted),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: _kCrimsonPale,
              border: Border.all(color: _kCrimson.withValues(alpha: 0.2), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              'A',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 13, fontWeight: FontWeight.w600, color: _kCrimson,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatefulWidget {
  final Widget child;
  const _CircleBtn({required this.child});

  @override
  State<_CircleBtn> createState() => _CircleBtnState();
}

class _CircleBtnState extends State<_CircleBtn> {
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
          border: Border.all(color: _hover ? _kCrimson : _kBorder, width: 1.5),
        ),
        child: widget.child,
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
          boxShadow: const [
            BoxShadow(color: Color(0x0D1A1208), blurRadius: 12, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PROGRESS',
                  style: GoogleFonts.dmSans(
                    fontSize: 9, fontWeight: FontWeight.w500,
                    letterSpacing: 0.18 * 9, color: _kMuted,
                  ),
                ),
                Text(
                  '40%',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 18, fontWeight: FontWeight.w600, color: _kCrimson,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 3,
              decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                widthFactor: 0.4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kCrimsonLight, _kCrimson]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                Positioned(
                  left: 10, top: 20, bottom: 20,
                  child: Container(
                    width: 1.5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_kGreen, _kBorder],
                        stops: [0.35, 0.7],
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    for (int i = 0; i < _kSteps.length; i++)
                      _StepRow(step: _kSteps[i], number: i + 1),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final _StepDef step;
  final int number;
  const _StepRow({required this.step, required this.number});

  @override
  Widget build(BuildContext context) {
    final current = step.status == _StepStatus.current;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: current ? _kCrimsonPale : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _StepDot(step: step, number: number),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              step.name,
              style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: step.status == _StepStatus.done
                    ? _kInkMid
                    : current
                        ? _kCrimson
                        : _kMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final _StepDef step;
  final int number;
  const _StepDot({required this.step, required this.number});

  @override
  Widget build(BuildContext context) {
    switch (step.status) {
      case _StepStatus.done:
        return Container(
          width: 22, height: 22,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: _kGreen),
          child: const Icon(Icons.check_rounded, size: 11, color: Colors.white),
        );
      case _StepStatus.current:
        return Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: _kCrimson,
            boxShadow: [BoxShadow(color: _kCrimson.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          alignment: Alignment.center,
          child: Text('$number', style: GoogleFonts.cormorantGaramond(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        );
      case _StepStatus.upcoming:
        return Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: _kParchDeep,
            border: Border.all(color: _kBorder, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text('$number', style: GoogleFonts.cormorantGaramond(fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section card
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String number, title, subtitle;
  final Widget child;
  const _SectionCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0A1A1208), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _kCrimsonPale, borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _kCrimson.withValues(alpha: 0.2)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 14, fontWeight: FontWeight.w600, color: _kCrimson,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 20, fontWeight: FontWeight.w600, color: _kInk,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.dmSans(fontSize: 12.5, color: _kMuted, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(padding: const EdgeInsets.fromLTRB(22, 20, 22, 22), child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Guidance tip
// ─────────────────────────────────────────────────────────────────────────────
class _GuidanceTip extends StatelessWidget {
  final List<String> bullets;
  const _GuidanceTip({required this.bullets});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _kParchDeep, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined, size: 13, color: _kCrimson),
              const SizedBox(width: 6),
              Text(
                'Guidance',
                style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: _kCrimson, letterSpacing: 0.08 * 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final b in bullets) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4, height: 4,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: _kCrimson),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(b, style: GoogleFonts.dmSans(fontSize: 12, color: _kInkMid, height: 1.5)),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text area
// ─────────────────────────────────────────────────────────────────────────────
class _TextArea extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  const _TextArea({required this.controller, required this.hint, this.minLines = 6});

  @override
  State<_TextArea> createState() => _TextAreaState();
}

class _TextAreaState extends State<_TextArea> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focused ? _kCrimson : _kBorder,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: _kCrimson.withValues(alpha: 0.08), blurRadius: 0, spreadRadius: 3)]
            : [],
      ),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: TextField(
          controller: widget.controller,
          minLines: widget.minLines,
          maxLines: null,
          style: GoogleFonts.dmSans(fontSize: 13.5, color: _kInk, height: 1.65),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(16),
            border: InputBorder.none,
            hintText: widget.hint,
            hintStyle: GoogleFonts.dmSans(fontSize: 13.5, color: const Color(0xFFC4BAB0), height: 1.65),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CV sub-section
// ─────────────────────────────────────────────────────────────────────────────
class _CvSubSection extends StatelessWidget {
  final IconData icon;
  final String label, hint;
  final TextEditingController controller;
  final bool required;
  const _CvSubSection({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: _kCrimson),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: _kInk,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 5),
              Text(
                '*',
                style: GoogleFonts.dmSans(fontSize: 13, color: _kCrimson, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _TextArea(controller: controller, hint: hint, minLines: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOR upload zone
// ─────────────────────────────────────────────────────────────────────────────
class _LorUploadZone extends StatefulWidget {
  final String? fileName;
  final VoidCallback onTap;
  const _LorUploadZone({required this.fileName, required this.onTap});

  @override
  State<_LorUploadZone> createState() => _LorUploadZoneState();
}

class _LorUploadZoneState extends State<_LorUploadZone> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final uploaded = widget.fileName != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: uploaded
                ? _kGreenPale
                : (_hover ? _kCrimsonPale : _kParchment),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: uploaded
                  ? _kGreen.withValues(alpha: 0.35)
                  : (_hover ? _kCrimson : _kBorder),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: uploaded ? _kGreenPale : _kParchDeep,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: uploaded ? _kGreen.withValues(alpha: 0.3) : _kBorder),
                ),
                child: Icon(
                  uploaded ? Icons.check_circle_outline_rounded : Icons.upload_file_outlined,
                  size: 20,
                  color: uploaded ? _kGreen : (_hover ? _kCrimson : _kMuted),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uploaded ? widget.fileName! : 'Upload Letter of Recommendation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5, fontWeight: FontWeight.w500,
                        color: uploaded ? _kGreen : (_hover ? _kCrimson : _kInk),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      uploaded
                          ? 'Tap to replace file'
                          : 'PDF, DOC, DOCX — max 5 MB',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        color: uploaded ? _kGreen.withValues(alpha: 0.7) : _kMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: uploaded ? _kGreen : _kMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom bar button
// ─────────────────────────────────────────────────────────────────────────────
class _BarButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _BarButton({required this.enabled, required this.onTap});

  @override
  State<_BarButton> createState() => _BarButtonState();
}

class _BarButtonState extends State<_BarButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          transform: _hover && widget.enabled
              ? Matrix4.translationValues(0, -1, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kCrimsonLight, _kCrimson],
                  )
                : const LinearGradient(colors: [Color(0xFF6B6060), Color(0xFF5A5050)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: widget.enabled
                ? [BoxShadow(color: _kCrimson.withValues(alpha: _hover ? 0.4 : 0.25), blurRadius: _hover ? 18 : 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Continue',
                style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
