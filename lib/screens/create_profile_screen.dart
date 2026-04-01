import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'personal_information_screen.dart';
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
const _kStepPending  = Color(0xFFBDB3A8);

const _steps = [
  _Step(id: 1, label: 'Create Profile',   sub: 'Personal details'),
  _Step(id: 2, label: 'Academic Info',    sub: 'Program & year'),
  _Step(id: 3, label: 'Verify Documents', sub: 'ID & records'),
];

class _Step {
  final int id;
  final String label, sub;
  const _Step({required this.id, required this.label, required this.sub});
}

// ─────────────────────────────────────────────────────────────────────────────
class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _surnameCtrl   = TextEditingController();
  final _phoneCtrl     = TextEditingController();

  String? _photoPath;
  String? _photoName;

  bool get _canSubmit =>
      _firstNameCtrl.text.trim().isNotEmpty &&
      _surnameCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().isNotEmpty;

  int get _filledCount => [
        _firstNameCtrl.text.trim(),
        _surnameCtrl.text.trim(),
        _phoneCtrl.text.trim(),
      ].where((s) => s.isNotEmpty).length;

  int get _pct => ((_filledCount / 3) * 100).round();

  @override
  void initState() {
    super.initState();
    _firstNameCtrl.addListener(() => setState(() {}));
    _surnameCtrl.addListener(()   => setState(() {}));
    _phoneCtrl.addListener(()     => setState(() {}));
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _surnameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _photoPath = file.path;
      _photoName = file.name;
    });
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PersonalInformationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;

    return Scaffold(
      backgroundColor: _kParchment,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 36 : 16,
                vertical: isDesktop ? 52 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 220,
                              child: _buildSidebar(),
                            ),
                            const SizedBox(width: 48),
                            Expanded(child: _buildFormCard(context)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildFormCard(context),
                            const SizedBox(height: 20),
                            _buildMobileProgress(),
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

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xF5FAF7F2),
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_rounded,
                    size: 18, color: _kCrimson),
                const SizedBox(width: 8),
                Text(
                  'Create Profile',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kCrimson,
                    letterSpacing: 0.02 * 13,
                  ),
                ),
              ],
            ),
          ),
          // Brand
          Flexible(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'AU',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                      letterSpacing: 0.06 * 20,
                    ),
                  ),
                  TextSpan(
                    text: 'Connect',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _kCrimson,
                      letterSpacing: 0.06 * 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Help button
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kBorder, width: 1.5),
            ),
            child: Center(
              child: Text(
                '?',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kMuted,
                ),
              ),
            ),
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
          'ONBOARDING PROGRESS',
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: _kMuted,
            letterSpacing: 0.18 * 9,
          ),
        ),
        const SizedBox(height: 12),
        // Steps with vertical connector
        _buildStepsColumn(),
        const SizedBox(height: 12),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _pct / 100,
            minHeight: 3,
            backgroundColor: _kBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(_kCrimson),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Step 1 of 3 — $_pct% complete',
          style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted),
        ),
        const SizedBox(height: 24),
        // Tip card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D1A1208),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              Text(
                "Complete your profile to unlock access to the university's digital program guides and student community.",
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: _kInkMid,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepsColumn() {
    return Stack(
      children: [
        // Vertical connector line
        Positioned(
          left: 13,
          top: 28,
          bottom: 28,
          width: 1.5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_kCrimson, _kBorder],
                stops: [0.0, 0.5],
              ),
            ),
          ),
        ),
        Column(
          children: List.generate(_steps.length, (i) {
            final step = _steps[i];
            final isActive = step.id == 1;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0x0F9B1B30)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step circle
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? _kCrimson : _kParchDeep,
                      border: isActive
                          ? null
                          : Border.all(color: _kBorder, width: 1.5),
                      boxShadow: isActive
                          ? const [
                              BoxShadow(
                                color: Color(0x599B1B30),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${step.id}',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : _kStepPending,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isActive ? _kInk : _kMuted,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActive
                            ? 'In Progress — $_pct%'
                            : 'Pending',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: isActive ? _kCrimson : _kStepPending,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── FORM CARD ─────────────────────────────────────────────────────────────
  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(48, 44, 48, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1A1208),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x0A1A1208),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set up your profile',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: _kInk,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Let's get started by creating your AU Connect identity. This information will be used for your official student records.",
            style: GoogleFonts.dmSans(
              fontSize: 13.5,
              color: _kMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          // Gradient divider rule
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kBorder, Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // First name + Surname row
          Row(
            children: [
              Expanded(
                child: _InputField(
                  label: 'First Name',
                  placeholder: 'Enter first name',
                  controller: _firstNameCtrl,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _InputField(
                  label: 'Surname',
                  placeholder: 'Enter surname',
                  controller: _surnameCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Phone with +263 prefix
          _PhoneField(controller: _phoneCtrl),
          const SizedBox(height: 24),

          // Profile photo
          _buildPhotoUpload(),
          const SizedBox(height: 32),

          // CTA button
          _SubmitButton(enabled: _canSubmit, onTap: _submit),
          const SizedBox(height: 24),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© Africa University. All rights reserved.',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: _kStepPending),
              ),
              Row(
                children: [
                  _FooterLink(label: 'Privacy Policy'),
                  const SizedBox(width: 16),
                  _FooterLink(label: 'Terms of Service'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PHOTO UPLOAD ──────────────────────────────────────────────────────────
  Widget _buildPhotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'PROFILE PHOTO',
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1 * 11.5,
                color: _kInkMid,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'optional',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: _kMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        _PhotoDropZone(
          photoPath: _photoPath,
          photoName: _photoName,
          onTap: _pickPhoto,
        ),
      ],
    );
  }

  // ── MOBILE PROGRESS ───────────────────────────────────────────────────────
  Widget _buildMobileProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STEP 1 OF 3',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: _kMuted,
                  letterSpacing: 0.18 * 9,
                ),
              ),
              Text(
                'Create Profile',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kCrimson,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _pct / 100,
                minHeight: 3,
                backgroundColor: _kBorder,
                valueColor: const AlwaysStoppedAnimation(_kCrimson),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _InputField ─────────────────────────────────────────────────────────────
class _InputField extends StatefulWidget {
  final String label, placeholder;
  final TextEditingController controller;
  const _InputField({
    required this.label,
    required this.placeholder,
    required this.controller,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1 * 11.5,
            color: _kInkMid,
          ),
        ),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 46,
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
            style: GoogleFonts.dmSans(fontSize: 14, color: _kInk),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle:
                  GoogleFonts.dmSans(fontSize: 14, color: _kStepPending),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── _PhoneField ─────────────────────────────────────────────────────────────
class _PhoneField extends StatefulWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHONE NUMBER',
          style: GoogleFonts.dmSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1 * 11.5,
            color: _kInkMid,
          ),
        ),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 46,
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
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 4),
                child: Text(
                  '+263',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kMuted,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Container(width: 1, height: 20, color: _kBorder),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.dmSans(fontSize: 14, color: _kInk),
                  decoration: InputDecoration(
                    hintText: '77 000 0000',
                    hintStyle: GoogleFonts.dmSans(
                        fontSize: 14, color: _kStepPending),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Zimbabwe number preferred (e.g. 77 123 4567)',
          style: GoogleFonts.dmSans(fontSize: 11, color: _kStepPending),
        ),
      ],
    );
  }
}

// ─── _PhotoDropZone ──────────────────────────────────────────────────────────
class _PhotoDropZone extends StatefulWidget {
  final String? photoPath;
  final String? photoName;
  final VoidCallback onTap;

  const _PhotoDropZone({
    this.photoPath,
    this.photoName,
    required this.onTap,
  });

  @override
  State<_PhotoDropZone> createState() => _PhotoDropZoneState();
}

class _PhotoDropZoneState extends State<_PhotoDropZone> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: _hover ? _kCrimsonPale : _kParchment,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover ? _kCrimson : _kBorder,
              width: 1.5,
              // dashed look via strokeAlign workaround — solid border matches design closely enough
            ),
          ),
          child: Row(
            children: [
              // avatar / icon
              widget.photoPath != null
                  ? Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: _kCrimson, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(
                        File(widget.photoPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kCrimsonPale,
                        border: Border.all(
                          color: _kCrimson.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(Icons.photo_camera_outlined,
                          size: 20, color: _kCrimson),
                    ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.photoName ?? 'Upload photo',
                    style: GoogleFonts.dmSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: _kCrimson,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PNG or JPG, max 5MB',
                    style: GoogleFonts.dmSans(
                        fontSize: 11.5, color: _kMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _SubmitButton ────────────────────────────────────────────────────────────
class _SubmitButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _SubmitButton({required this.enabled, required this.onTap});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 50,
          transform: (widget.enabled && _hover)
              ? Matrix4.translationValues(0, -1, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? const LinearGradient(
                    colors: [_kCrimsonLight, _kCrimson],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFC9BDB5), Color(0xFFB5A99E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: _kCrimson.withValues(alpha: 0.30),
                      blurRadius: _hover ? 20 : 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
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
                    size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── _FooterLink ─────────────────────────────────────────────────────────────
class _FooterLink extends StatefulWidget {
  final String label;
  const _FooterLink({required this.label});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: Text(
        widget.label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          color: _hover ? _kCrimson : _kMuted,
        ),
      ),
    );
  }
}
