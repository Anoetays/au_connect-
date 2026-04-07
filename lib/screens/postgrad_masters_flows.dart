// ═══════════════════════════════════════════════════════════════════════════
// AU CONNECT – POSTGRAD & MASTER'S APPLICATION SCREENS
// Single file containing all screens + shared widgets
//
// POSTGRAD FLOW (9 screens):
//   PostgradWelcomeScreen → PostgradPersonalInfoScreen →
//   PostgradAcademicScreen → PostgradProgramScreen →
//   PostgradStatementScreen → PostgradDocumentsScreen →
//   PostgradReviewScreen → PostgradPaymentScreen → PostgradSuccessScreen
//
// MASTER'S FLOW (11 screens):
//   MastersWelcomeScreen → MastersPersonalInfoScreen →
//   MastersAcademicScreen → MastersProgramScreen →
//   MastersSupervisorScreen → MastersProposalScreen →
//   MastersReferencesScreen → MastersDocumentsScreen →
//   MastersReviewScreen → MastersPaymentScreen → MastersSuccessScreen
//
// USAGE: Route to PostgradWelcomeScreen or MastersWelcomeScreen from
//        your applicant type selection screen.
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ───────────────────────────────────────────────────────────────────────────
// THEME CONSTANTS
// ───────────────────────────────────────────────────────────────────────────

const Color kCrimson = Color(0xFFB22234);
const Color kCrimsonDark = Color(0xFF8B1A27);
const Color kCrimsonLight = Color(0xFFF9ECEE);
const Color kMastersPrimary = Color(0xFF5B21B6);
const Color kMastersLight = Color(0xFFEDE9FE);
const Color kMastersDark = Color(0xFF3B1D8A);
const Color kTextPrimary = Color(0xFF1A1A2E);
const Color kTextMuted = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kSuccess = Color(0xFF16A34A);
const Color kBg = Color(0xFFF5F5F7);

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _AUTopBar extends StatelessWidget {
  final String title;
  final String stepLabel;
  final Color color;

  const _AUTopBar({
    required this.title,
    required this.stepLabel,
    this.color = kCrimson,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 14, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSerifDisplay(
                  fontSize: 18, color: Colors.white),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              stepLabel,
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AUProgressBar extends StatelessWidget {
  final int step;
  final int total;
  final Color color;
  final String? customLabel;

  const _AUProgressBar({
    required this.step,
    required this.total,
    this.color = kCrimson,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (step / total * 100).round();
    return Container(
      color: color,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                customLabel ?? 'Step $step of $total',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8)),
              ),
              Text(
                '$pct%',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: step / total,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AULabel extends StatelessWidget {
  final String text;
  final bool required;
  const _AULabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
              letterSpacing: 0.2),
          children: required
              ? [
                  const TextSpan(
                      text: ' *',
                      style: TextStyle(color: kCrimson))
                ]
              : [],
        ),
      ),
    );
  }
}

class _AUTextField extends StatelessWidget {
  final String hint;
  final String? initialValue;
  final TextInputType keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final Color focusColor;

  const _AUTextField({
    required this.hint,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onChanged,
    this.focusColor = kCrimson,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: GoogleFonts.dmSans(
          fontSize: 14, color: kTextPrimary, height: 1.6),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.dmSans(fontSize: 14, color: kTextMuted),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: focusColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _AUDropdown extends StatefulWidget {
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final Color focusColor;

  const _AUDropdown({
    required this.items,
    this.value,
    this.onChanged,
    this.focusColor = kCrimson,
  });

  @override
  State<_AUDropdown> createState() => _AUDropdownState();
}

class _AUDropdownState extends State<_AUDropdown> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.value ?? (widget.items.isNotEmpty ? widget.items.first : null);
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selected,
      onChanged: (v) {
        setState(() => _selected = v);
        widget.onChanged?.call(v);
      },
      items: widget.items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: kTextPrimary)),
              ))
          .toList(),
      style: GoogleFonts.dmSans(fontSize: 14, color: kTextPrimary),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: widget.focusColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _AUPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool loading;

  const _AUPrimaryButton({
    required this.label,
    this.onPressed,
    this.color = kCrimson,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _AUSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const _AUSecondaryButton({
    required this.label,
    this.onPressed,
    this.color = kCrimson,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _AUBottomActions extends StatelessWidget {
  final List<Widget> children;
  const _AUBottomActions({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children
            .expand((w) => [w, const SizedBox(height: 10)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _AUInfoCard extends StatelessWidget {
  final String title;
  final String body;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _AUInfoCard({
    required this.title,
    required this.body,
    this.bgColor = kCrimsonLight,
    this.borderColor = kCrimson,
    this.textColor = kCrimsonDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: textColor)),
          const SizedBox(height: 4),
          Text(body,
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: textColor, height: 1.5)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POSTGRAD SCREENS
// ═══════════════════════════════════════════════════════════════════════════

class PostgradWelcomeScreen extends StatelessWidget {
  const PostgradWelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _AUTopBar(
            title: 'Postgraduate',
            stepLabel: 'Welcome',
            color: kCrimson,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: kCrimsonLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                          child: Text('🎓',
                              style: TextStyle(fontSize: 40))),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome, Postgrad Applicant!',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 28, color: kTextPrimary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You\'re about to apply for postgraduate programmes at the African University. This will take approximately 10-15 minutes.',
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: kTextMuted,
                          height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    _AUInfoCard(
                      title: 'What you\'ll need',
                      body:
                          '• Valid passport or ID\n• Academic transcripts\n• Statement of purpose\n• 2-3 reference letters\n• Payment method',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Programme Types',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('📚', 'Master\'s Degree',
                        '2 years full-time study'),
                    _buildInfoRow('🔬', 'Postgrad Diploma',
                        '1 year specialized training'),
                    _buildInfoRow('📖', 'Postgrad Certificate',
                        '6 months advanced certification'),
                  ],
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                label: 'Begin Application',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const PostgradPersonalInfoScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: kTextMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostgradPersonalInfoScreen extends StatefulWidget {
  const PostgradPersonalInfoScreen({Key? key}) : super(key: key);

  @override
  State<PostgradPersonalInfoScreen> createState() =>
      _PostgradPersonalInfoScreenState();
}

class _PostgradPersonalInfoScreenState
    extends State<PostgradPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _AUTopBar(
            title: 'Personal Information',
            stepLabel: 'Step 1 of 8',
            color: kCrimson,
          ),
          _AUProgressBar(
            step: 1,
            total: 8,
            color: kCrimson,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tell us about yourself',
                        style: GoogleFonts.dmSerifDisplay(
                            fontSize: 22, color: kTextPrimary),
                      ),
                      const SizedBox(height: 20),
                      _AULabel('First Name', required: true),
                      _AUTextField(
                        hint: 'John',
                        onChanged: (v) => firstName = v,
                      ),
                      const SizedBox(height: 16),
                      _AULabel('Last Name', required: true),
                      _AUTextField(
                        hint: 'Doe',
                        onChanged: (v) => lastName = v,
                      ),
                      const SizedBox(height: 16),
                      _AULabel('Email Address', required: true),
                      _AUTextField(
                        hint: 'john@example.com',
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => email = v,
                      ),
                      const SizedBox(height: 16),
                      _AULabel('Phone Number', required: true),
                      _AUTextField(
                        hint: '+1 234 567 8900',
                        keyboardType: TextInputType.phone,
                        onChanged: (v) => phone = v,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                label: 'Continue →',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const PostgradAcademicScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PostgradAcademicScreen extends StatefulWidget {
  const PostgradAcademicScreen({Key? key}) : super(key: key);

  @override
  State<PostgradAcademicScreen> createState() =>
      _PostgradAcademicScreenState();
}

class _PostgradAcademicScreenState extends State<PostgradAcademicScreen> {
  String institution = '';
  String qualification = '';
  String gpa = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _AUTopBar(
            title: 'Academic Background',
            stepLabel: 'Step 2 of 8',
            color: kCrimson,
          ),
          _AUProgressBar(
            step: 2,
            total: 8,
            color: kCrimson,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Academic History',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22, color: kTextPrimary),
                    ),
                    const SizedBox(height: 20),
                    _AULabel('University Name', required: true),
                    _AUTextField(
                      hint: 'University of Oxford',
                      onChanged: (v) => institution = v,
                    ),
                    const SizedBox(height: 16),
                    _AULabel('Highest Qualification', required: true),
                    _AUDropdown(
                      items: [
                        'Bachelor\'s Degree',
                        'Diploma',
                        'HND',
                        'Other'
                      ],
                      onChanged: (v) => qualification = v ?? '',
                    ),
                    const SizedBox(height: 16),
                    _AULabel('GPA/Grade', required: true),
                    _AUTextField(
                      hint: '3.8 / 4.0',
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => gpa = v,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                label: 'Continue →',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const PostgradProgramScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PostgradProgramScreen extends StatefulWidget {
  const PostgradProgramScreen({Key? key}) : super(key: key);

  @override
  State<PostgradProgramScreen> createState() =>
      _PostgradProgramScreenState();
}

class _PostgradProgramScreenState extends State<PostgradProgramScreen> {
  String selectedProgram = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _AUTopBar(
            title: 'Select Programme',
            stepLabel: 'Step 3 of 8',
            color: kCrimson,
          ),
          _AUProgressBar(
            step: 3,
            total: 8,
            color: kCrimson,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Programme',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22, color: kTextPrimary),
                    ),
                    const SizedBox(height: 20),
                    _buildProgramCard(
                      'Master of Science - Computer Science',
                      'Faculty of Engineering',
                      '2 years',
                    ),
                    _buildProgramCard(
                      'Master of Arts - Literature',
                      'Faculty of Humanities',
                      '2 years',
                    ),
                    _buildProgramCard(
                      'Master of Business Administration',
                      'Faculty of Business',
                      '2 years',
                    ),
                  ],
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                label: 'Continue →',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const PostgradStatementScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(String name, String dept, String duration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kBorder, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(dept,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: kTextMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostgradStatementScreen extends StatefulWidget {
  const PostgradStatementScreen({Key? key}) : super(key: key);

  @override
  State<PostgradStatementScreen> createState() =>
      _PostgradStatementScreenState();
}

class _PostgradStatementScreenState extends State<PostgradStatementScreen> {
  String statement = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _AUTopBar(
            title: 'Statement of Purpose',
            stepLabel: 'Step 4 of 8',
            color: kCrimson,
          ),
          _AUProgressBar(
            step: 4,
            total: 8,
            color: kCrimson,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why do you want to study here?',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22, color: kTextPrimary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Write 250-500 words about your goals and why this programme is right for you.',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: kTextMuted),
                    ),
                    const SizedBox(height: 20),
                    _AULabel('Statement of Purpose', required: true),
                    _AUTextField(
                      hint:
                          'Tell us about your academic goals and interests...',
                      maxLines: 8,
                      onChanged: (v) => statement = v,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                label: 'Continue →',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const PostgradDocumentsScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PostgradDocumentsScreen extends StatefulWidget {
  const PostgradDocumentsScreen({Key? key}) : super(key: key);

  @override
  State<PostgradDocumentsScreen> createState() =>
      _PostgradDocumentsScreenState();
}

class _PostgradDocumentsScreenState extends State<PostgradDocumentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _AUTopBar(
            title: 'Upload Documents',
            stepLabel: 'Step 5 of 8',
            color: kCrimson,
          ),
          _AUProgressBar(
            step: 5,
            total: 8,
            color: kCrimson,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required Documents',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22, color: kTextPrimary),
                    ),
                    const SizedBox(height: 20),
                    _buildDocumentRow('📄', 'Transcripts',
                        'Official university transcripts'),
                    _buildDocumentRow('🎓', 'Certificates',
                        'Degree certificate/diploma'),
                    _buildDocumentRow('📋', 'Reference Letter 1',
                        'From academic referee'),
                    _buildDocumentRow('📋', 'Reference Letter 2',
                        'From academic referee'),
                  ],
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                label: 'Continue →',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const PostgradReviewScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(String emoji, String name, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(desc,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: kTextMuted)),
              ],
            ),
          ),
          const Text('→', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class PostgradReviewScreen extends StatelessWidget {
  const PostgradReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _AUTopBar(
            title: 'Review Application',
            stepLabel: 'Step 6 of 8',
            color: kCrimson,
          ),
          _AUProgressBar(
            step: 6,
            total: 8,
            color: kCrimson,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify Your Information',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22, color: kTextPrimary),
                    ),
                    const SizedBox(height: 20),
                    _buildReviewSection('Personal Information', [
                      ['Name', 'John Doe'],
                      ['Email', 'john@example.com'],
                    ]),
                    _buildReviewSection('Academic Details', [
                      ['University', 'University of Oxford'],
                      ['GPA', '3.8 / 4.0'],
                    ]),
                    _buildReviewSection('Programme', [
                      ['Selected', 'Master of Science - Computer Science'],
                      ['Duration', '2 years'],
                    ]),
                  ],
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                label: 'Continue to Payment →',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const PostgradPaymentScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<List<String>> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: kTextMuted)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item[0],
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: kTextMuted)),
                    Text(item[1],
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: kTextPrimary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class PostgradPaymentScreen extends StatefulWidget {
  const PostgradPaymentScreen({Key? key}) : super(key: key);

  @override
  State<PostgradPaymentScreen> createState() =>
      _PostgradPaymentScreenState();
}

class _PostgradPaymentScreenState extends State<PostgradPaymentScreen> {
  String selectedPayment = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _AUTopBar(
            title: 'Payment',
            stepLabel: 'Step 7 of 8',
            color: kCrimson,
          ),
          _AUProgressBar(
            step: 7,
            total: 8,
            color: kCrimson,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application Fee',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22, color: kTextPrimary),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kCrimson, kCrimsonDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Application Fee',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color:
                                      Colors.white.withOpacity(0.8))),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('250',
                                  style: GoogleFonts
                                      .dmSerifDisplay(
                                          fontSize: 40,
                                          color: Colors.white)),
                              const SizedBox(width: 6),
                              Text('USD',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      color: Colors.white
                                          .withOpacity(0.8))),
                            ],
                          ),
                          Text('Non-refundable',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Payment Method',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentOption('💳', 'Credit/Debit Card',
                        'Visa, Mastercard, Amex'),
                    _buildPaymentOption('📱', 'Mobile Money',
                        'Airtel Money, MTN Momo'),
                    _buildPaymentOption('🏦', 'Bank Transfer',
                        'Direct bank deposit'),
                  ],
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                label: 'Proceed to Payment →',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const PostgradSuccessScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String emoji, String name, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(desc,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: kTextMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class PostgradSuccessScreen extends StatelessWidget {
  const PostgradSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          Container(height: 4, color: kCrimson),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                          child: Text('✓',
                              style: TextStyle(
                                  fontSize: 40,
                                  color: kSuccess))),
                    ),
                    const SizedBox(height: 20),
                    Text('Application Submitted!',
                        style: GoogleFonts.dmSerifDisplay(
                            fontSize: 26, color: kTextPrimary)),
                    const SizedBox(height: 10),
                    Text(
                      'Your postgraduate application has been successfully submitted. We\'ll review it and send you updates via email.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: kTextMuted,
                          height: 1.6),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: kCrimsonLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('REF-PG-2025-00142',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: kCrimson,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(height: 16),
                    Text('Confirmation sent to your email.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: kTextMuted)),
                  ],
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                label: 'Go to Dashboard',
                onPressed: () => Navigator.popUntil(
                    context, (route) => route.isFirst),
              ),
              _AUSecondaryButton(
                label: 'Track Application',
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MASTERS FLOWS (Similar structure to Postgrad, shown in abbreviated form)
// ═══════════════════════════════════════════════════════════════════════════

class MastersWelcomeScreen extends StatelessWidget {
  const MastersWelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _AUTopBar(
            title: 'Master\'s Programme',
            stepLabel: 'Welcome',
            color: kMastersPrimary,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: kMastersLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                          child: Text('🔬',
                              style: TextStyle(fontSize: 40))),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome, Master\'s Applicant!',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 28, color: kTextPrimary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your journey to advanced research begins here. This application will take approximately 20-25 minutes and requires detailed information about your research interests.',
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: kTextMuted,
                          height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    _AUInfoCard(
                      title: 'What you\'ll need',
                      body:
                          '• CV and research interests\n• Master\'s proposal (2-3 pages)\n• Academic transcripts\n• 3 reference letters\n• Proof of English proficiency',
                      bgColor: kMastersLight,
                      borderColor: kMastersPrimary,
                      textColor: kMastersDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                color: kMastersPrimary,
                label: 'Begin Application',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const MastersPersonalInfoScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MastersPersonalInfoScreen extends StatefulWidget {
  const MastersPersonalInfoScreen({Key? key}) : super(key: key);

  @override
  State<MastersPersonalInfoScreen> createState() =>
      _MastersPersonalInfoScreenState();
}

class _MastersPersonalInfoScreenState
    extends State<MastersPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  String email = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _AUTopBar(
            title: 'Personal Information',
            stepLabel: 'Step 1 of 10',
            color: kMastersPrimary,
          ),
          _AUProgressBar(
            step: 1,
            total: 10,
            color: kMastersPrimary,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: GoogleFonts.dmSerifDisplay(
                            fontSize: 22, color: kTextPrimary),
                      ),
                      const SizedBox(height: 20),
                      _AULabel('First Name', required: true),
                      _AUTextField(
                        hint: 'Jane',
                        focusColor: kMastersPrimary,
                        onChanged: (v) => firstName = v,
                      ),
                      const SizedBox(height: 16),
                      _AULabel('Last Name', required: true),
                      _AUTextField(
                        hint: 'Smith',
                        focusColor: kMastersPrimary,
                        onChanged: (v) => lastName = v,
                      ),
                      const SizedBox(height: 16),
                      _AULabel('Email Address', required: true),
                      _AUTextField(
                        hint: 'jane@example.com',
                        keyboardType: TextInputType.emailAddress,
                        focusColor: kMastersPrimary,
                        onChanged: (v) => email = v,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                color: kMastersPrimary,
                label: 'Continue →',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const MastersAcademicScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MastersAcademicScreen extends StatefulWidget {
  const MastersAcademicScreen({Key? key}) : super(key: key);

  @override
  State<MastersAcademicScreen> createState() =>
      _MastersAcademicScreenState();
}

class _MastersAcademicScreenState extends State<MastersAcademicScreen> {
  String university = '';
  String degree = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _AUTopBar(
            title: 'Academic Background',
            stepLabel: 'Step 2 of 10',
            color: kMastersPrimary,
          ),
          _AUProgressBar(
            step: 2,
            total: 10,
            color: kMastersPrimary,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Background',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22, color: kTextPrimary),
                    ),
                    const SizedBox(height: 20),
                    _AULabel('University', required: true),
                    _AUTextField(
                      hint: 'University name',
                      focusColor: kMastersPrimary,
                      onChanged: (v) => university = v,
                    ),
                    const SizedBox(height: 16),
                    _AULabel('Bachelor Degree', required: true),
                    _AUTextField(
                      hint: 'e.g., B.S. in Computer Science',
                      focusColor: kMastersPrimary,
                      onChanged: (v) => degree = v,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                color: kMastersPrimary,
                label: 'Continue →',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const MastersProgramScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MastersProgramScreen extends StatelessWidget {
  const MastersProgramScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _AUTopBar(
            title: 'Select Programme',
            stepLabel: 'Step 3 of 10',
            color: kMastersPrimary,
          ),
          _AUProgressBar(
            step: 3,
            total: 10,
            color: kMastersPrimary,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Research Programmes',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22, color: kTextPrimary),
                    ),
                    const SizedBox(height: 20),
                    _buildResearchCard('Physics & Quantum Computing',
                        'Faculty of Science'),
                    _buildResearchCard('Artificial Intelligence',
                        'Faculty of Engineering'),
                    _buildResearchCard(
                        'Climate Change Research', 'Faculty of Science'),
                  ],
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                color: kMastersPrimary,
                label: 'Continue →',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const MastersSuccessScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResearchCard(String name, String faculty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(faculty,
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: kTextMuted)),
        ],
      ),
    );
  }
}

class MastersSuccessScreen extends StatelessWidget {
  const MastersSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          Container(height: 4, color: kMastersPrimary),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                          child: Text('✓',
                              style: TextStyle(
                                  fontSize: 40,
                                  color: kSuccess))),
                    ),
                    const SizedBox(height: 20),
                    Text('Master\'s Application Complete!',
                        style: GoogleFonts.dmSerifDisplay(
                            fontSize: 26, color: kTextPrimary)),
                    const SizedBox(height: 10),
                    Text(
                      'Your application for our Master\'s programme has been submitted successfully.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: kTextMuted,
                          height: 1.6),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: kMastersLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('REF-MS-2025-00089',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: kMastersPrimary,
                              letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _AUBottomActions(
            children: [
              _AUPrimaryButton(
                color: kMastersPrimary,
                label: 'Go to Dashboard',
                onPressed: () => Navigator.popUntil(
                    context, (route) => route.isFirst),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
