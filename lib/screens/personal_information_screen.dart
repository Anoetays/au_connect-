import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'document_upload_screen.dart';
import 'package:au_connect/theme/app_theme.dart';

// ─── color tokens ─────────────────────────────────────────────────────────────
const _kCrimson      = AppTheme.primaryDark;
const _kCrimsonLight = AppTheme.primaryCrimson;
const _kInk          = AppTheme.textPrimary;
const _kInkMid       = AppTheme.textSecondary;
const _kParchment    = AppTheme.background;
const _kParchDeep    = Color(0xFFF0EBE1);
const _kBorder       = AppTheme.border;
const _kMuted        = AppTheme.textMuted;
const _kTintBg       = Color(0xFFF4F2FA);
const _kTintBd       = Color(0xFFE0DBF0);
const _kTintInput    = Color(0xFFD5CFE8);
const _kPlaceholder  = Color(0xFFC4BAB0);

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key, this.nextRoute});
  final WidgetBuilder? nextRoute;

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<PersonalInformationScreen> {
  // ── controllers ────────────────────────────────────────────────────────────
  final _firstNameCtrl    = TextEditingController();
  final _middleNameCtrl   = TextEditingController();
  final _lastNameCtrl     = TextEditingController();
  final _phoneCtrl        = TextEditingController();
  final _dobCtrl          = TextEditingController();
  final _nationalIdCtrl   = TextEditingController();
  final _kinNameCtrl      = TextEditingController();
  final _kinPhoneCtrl     = TextEditingController();
  final _school1Ctrl      = TextEditingController();
  final _grades1Ctrl      = TextEditingController();
  final _school2Ctrl      = TextEditingController();
  final _grades2Ctrl      = TextEditingController();
  final _hobbiesCtrl      = TextEditingController();

  String _country = 'Zimbabwe';

  static const _countries = [
    'Zimbabwe', 'South Africa', 'Zambia',
    'Kenya', 'Nigeria', 'Ghana', 'Other',
  ];

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _middleNameCtrl, _lastNameCtrl,
      _phoneCtrl, _dobCtrl, _nationalIdCtrl,
      _kinNameCtrl, _kinPhoneCtrl,
      _school1Ctrl, _grades1Ctrl, _school2Ctrl, _grades2Ctrl,
      _hobbiesCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: _kParchment,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 36 : 16,
                vertical: isDesktop ? 48 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 210,
                              child: _buildSidebar(),
                            ),
                            const SizedBox(width: 48),
                            Expanded(child: _buildMain(context)),
                          ],
                        )
                      : _buildMain(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xF5FAF7F2),
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_rounded,
                    size: 18, color: _kCrimson),
                const SizedBox(width: 8),
                Text(
                  'Back',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kCrimson,
                  ),
                ),
              ],
            ),
          ),
          // Title
          Flexible(
            child: Text(
              'Personal Information',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _kCrimson,
                letterSpacing: 0.04 * 18,
              ),
            ),
          ),
          // Right controls
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kBorder, width: 1.5),
                ),
                child: Text(
                  'Onboarding',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.08 * 11,
                    color: _kMuted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kBorder, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '?',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SIDEBAR ───────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR PROGRESS',
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.16 * 10,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '20%',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: _kCrimson,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: const LinearProgressIndicator(
            value: 0.20,
            minHeight: 3,
            backgroundColor: _kBorder,
            valueColor: AlwaysStoppedAnimation<Color>(_kCrimson),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Step 2 of 5',
          style: GoogleFonts.dmSans(fontSize: 11.5, color: _kMuted),
        ),
        const SizedBox(height: 24),
        // Tip card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D1A1208),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Complete your personal information to unlock program recommendations tailored to your background.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: _kInkMid,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── MAIN ──────────────────────────────────────────────────────────────────
  Widget _buildMain(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Milestone badge + heading
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _kParchDeep,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder),
          ),
          child: Text(
            'Application Milestone',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.06 * 11,
              color: _kMuted,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Personal Information',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: _kInk,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Provide your legal identity details and academic background to help us curate your student experience at Africa University.',
          style: GoogleFonts.dmSans(
            fontSize: 13.5,
            color: _kMuted,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),

        // Legal Identity
        _buildSection(
          title: 'Legal Identity',
          tinted: false,
          child: _buildLegalIdentity(),
        ),
        const SizedBox(height: 32),

        // Next of Kin
        _buildSection(
          title: 'Next of Kin',
          subtitle: 'Emergency contact information',
          tinted: true,
          child: _buildNextOfKin(),
        ),
        const SizedBox(height: 32),

        // Academic History 1
        _buildSection(
          title: 'Academic History',
          tinted: false,
          child: _buildAcademicHistory(
            schoolCtrl: _school1Ctrl,
            gradesCtrl: _grades1Ctrl,
          ),
        ),
        const SizedBox(height: 32),

        // Academic History 2
        _buildSection(
          title: 'Academic History',
          tinted: false,
          child: _buildAcademicHistory(
            schoolCtrl: _school2Ctrl,
            gradesCtrl: _grades2Ctrl,
          ),
        ),
        const SizedBox(height: 32),

        // Personal Interests
        _buildSection(
          title: 'Personal Interests',
          tinted: false,
          child: _buildPersonalInterests(),
        ),
        const SizedBox(height: 8),

        // Footer nav
        _buildFooterNav(context),
      ],
    );
  }

  // ── SECTION WRAPPER ───────────────────────────────────────────────────────
  Widget _buildSection({
    required String title,
    String? subtitle,
    required bool tinted,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      decoration: BoxDecoration(
        color: tinted ? _kTintBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tinted ? _kTintBd : _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1A1208),
            blurRadius: 16,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: subtitle != null ? 44 : 28,
                decoration: BoxDecoration(
                  color: _kCrimson,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _kCrimson,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        color: _kMuted,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: tinted ? _kTintBd : _kParchDeep,
              height: 1,
            ),
          ),
          child,
        ],
      ),
    );
  }

  // ── LEGAL IDENTITY ────────────────────────────────────────────────────────
  Widget _buildLegalIdentity() {
    return Column(
      children: [
        // Row 1: First, Middle, Last
        _threeCol([
          _FormField(
            label: 'First Name',
            placeholder: 'Enter first name',
            controller: _firstNameCtrl,
          ),
          _FormField(
            label: 'Middle Name',
            placeholder: 'Enter middle name',
            controller: _middleNameCtrl,
          ),
          _FormField(
            label: 'Last Name',
            placeholder: 'Enter last name',
            controller: _lastNameCtrl,
          ),
        ]),
        const SizedBox(height: 16),
        // Row 2: Phone, DOB, Country
        _threeCol([
          _FormField(
            label: 'Phone Number',
            placeholder: '+263 ...',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          _DateField(
            label: 'Date of Birth',
            controller: _dobCtrl,
          ),
          _DropdownField(
            label: 'Country of Origin',
            value: _country,
            items: _countries,
            onChanged: (v) => setState(() => _country = v!),
          ),
        ]),
        const SizedBox(height: 16),
        // National ID
        _FormField(
          label: 'National ID Number',
          placeholder: 'ID Number / Passport Number',
          controller: _nationalIdCtrl,
        ),
      ],
    );
  }

  // ── NEXT OF KIN ───────────────────────────────────────────────────────────
  Widget _buildNextOfKin() {
    return Row(
      children: [
        Expanded(
          child: _FormField(
            label: "Full Name",
            placeholder: "Kin's full name",
            controller: _kinNameCtrl,
            tinted: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _FormField(
            label: "Kin's Phone Number",
            placeholder: 'Contact number',
            controller: _kinPhoneCtrl,
            keyboardType: TextInputType.phone,
            tinted: true,
          ),
        ),
      ],
    );
  }

  // ── ACADEMIC HISTORY ──────────────────────────────────────────────────────
  Widget _buildAcademicHistory({
    required TextEditingController schoolCtrl,
    required TextEditingController gradesCtrl,
  }) {
    return Column(
      children: [
        _FormField(
          label: 'Previous School Attended',
          placeholder: 'Name of High School or College',
          controller: schoolCtrl,
        ),
        const SizedBox(height: 16),
        _TextareaField(
          label: 'Grades / Distinctions',
          placeholder:
              'List your key results (e.g., A-Level: Mathematics A, Physics B...)',
          controller: gradesCtrl,
        ),
      ],
    );
  }

  // ── PERSONAL INTERESTS ────────────────────────────────────────────────────
  Widget _buildPersonalInterests() {
    return _TextareaField(
      label: 'Hobbies & Extracurricular Activities',
      placeholder: 'Tell us about what you enjoy outside the classroom...',
      controller: _hobbiesCtrl,
    );
  }

  // ── FOOTER NAV ────────────────────────────────────────────────────────────
  Widget _buildFooterNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back step
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_rounded,
                    size: 15, color: _kMuted),
                const SizedBox(width: 8),
                Text(
                  'Back to step 1',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kMuted,
                  ),
                ),
              ],
            ),
          ),
          // Save & Continue
          _SaveButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: widget.nextRoute ?? (_) => const DocumentUploadScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _threeCol(List<Widget> children) {
    return LayoutBuilder(builder: (ctx, constraints) {
      if (constraints.maxWidth < 500) {
        return Column(
          children: children
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: c,
                  ))
              .toList(),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.asMap().entries.map((e) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: e.key < children.length - 1 ? 16 : 0),
              child: e.value,
            ),
          );
        }).toList(),
      );
    });
  }
}

// ─── _FormField ──────────────────────────────────────────────────────────────
class _FormField extends StatefulWidget {
  final String label, placeholder;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool tinted;

  const _FormField({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.tinted = false,
  });

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(widget.label),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          decoration: BoxDecoration(
            color: _focused
                ? Colors.white
                : (widget.tinted ? Colors.white : _kParchment),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused
                  ? _kCrimson
                  : (widget.tinted ? _kTintInput : _kBorder),
              width: 1.5,
            ),
            boxShadow: _focused
                ? const [
                    BoxShadow(
                      color: Color(0x149B1B30),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            keyboardType: widget.keyboardType,
            style: GoogleFonts.dmSans(fontSize: 13.5, color: _kInk),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle:
                  GoogleFonts.dmSans(fontSize: 13.5, color: _kPlaceholder),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── _TextareaField ───────────────────────────────────────────────────────────
class _TextareaField extends StatefulWidget {
  final String label, placeholder;
  final TextEditingController controller;

  const _TextareaField({
    required this.label,
    required this.placeholder,
    required this.controller,
  });

  @override
  State<_TextareaField> createState() => _TextareaFieldState();
}

class _TextareaFieldState extends State<_TextareaField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(widget.label),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _focused ? Colors.white : _kParchment,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused ? _kCrimson : _kBorder,
              width: 1.5,
            ),
            boxShadow: _focused
                ? const [
                    BoxShadow(
                      color: Color(0x149B1B30),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            minLines: 3,
            maxLines: 6,
            style: GoogleFonts.dmSans(fontSize: 13.5, color: _kInk),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle:
                  GoogleFonts.dmSans(fontSize: 13.5, color: _kPlaceholder),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── _DateField ───────────────────────────────────────────────────────────────
class _DateField extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const _DateField({required this.label, required this.controller});

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _kCrimson),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      widget.controller.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(widget.label),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: () => _pick(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _kParchment,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.controller.text.isEmpty
                      ? 'DD / MM / YYYY'
                      : widget.controller.text,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    color: widget.controller.text.isEmpty
                        ? _kPlaceholder
                        : _kInk,
                  ),
                ),
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: _kMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── _DropdownField ───────────────────────────────────────────────────────────
class _DropdownField extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 7),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _kParchment,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: _kMuted),
              style: GoogleFonts.dmSans(fontSize: 13.5, color: _kInk),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(10),
              onChanged: onChanged,
              items: items
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── _FieldLabel ─────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1 * 11,
        color: _kInkMid,
      ),
    );
  }
}

// ─── _SaveButton ─────────────────────────────────────────────────────────────
class _SaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SaveButton({required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          transform: _hover
              ? Matrix4.translationValues(0, -1, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kCrimsonLight, _kCrimson],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _kCrimson.withValues(alpha: _hover ? 0.38 : 0.28),
                blurRadius: _hover ? 20 : 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Save & Continue',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.04 * 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
