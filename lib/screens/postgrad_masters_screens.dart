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
// Routes in main.dart:
//   /postgrad_welcome  → PostgradWelcomeScreen
//   /masters_welcome   → MastersWelcomeScreen
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ───────────────────────────────────────────────────────────────────────────
// THEME CONSTANTS
// ───────────────────────────────────────────────────────────────────────────

const Color kCrimson        = Color(0xFFB22234);
const Color kCrimsonDark    = Color(0xFF8B1A27);
const Color kCrimsonLight   = Color(0xFFF9ECEE);
const Color kMastersPrimary = Color(0xFF5B21B6);
const Color kMastersLight   = Color(0xFFEDE9FE);
const Color kMastersDark    = Color(0xFF3B1D8A);
const Color kTextPrimary    = Color(0xFF1A1A2E);
const Color kTextMuted      = Color(0xFF6B7280);
const Color kBorder         = Color(0xFFE5E7EB);
const Color kSuccess        = Color(0xFF16A34A);
const Color kBg             = Color(0xFFF5F5F7);

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

// ─── Top App Bar ─────────────────────────────────────────────────────────────
class _AUTopBar extends StatelessWidget {
  final String title;
  final String stepLabel;
  final Color color;
  const _AUTopBar({required this.title, required this.stepLabel, this.color = kCrimson});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16, right: 16, bottom: 14,
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title,
              style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: Colors.white)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(stepLabel,
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ]),
    );
  }
}

// ─── Progress Bar ─────────────────────────────────────────────────────────────
class _AUProgressBar extends StatelessWidget {
  final int step;
  final int total;
  final Color color;
  final String? customLabel;
  const _AUProgressBar({required this.step, required this.total, this.color = kCrimson, this.customLabel});

  @override
  Widget build(BuildContext context) {
    final pct = (step / total * 100).round();
    return Container(
      color: color,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(customLabel ?? 'Step $step of $total',
              style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
          Text('$pct%',
              style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: step / total,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
      ]),
    );
  }
}

// ─── Form Label ───────────────────────────────────────────────────────────────
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
              fontSize: 12, fontWeight: FontWeight.w600, color: kTextPrimary, letterSpacing: 0.2),
          children: required
              ? [const TextSpan(text: ' *', style: TextStyle(color: kCrimson))]
              : [],
        ),
      ),
    );
  }
}

// ─── Text Field ───────────────────────────────────────────────────────────────
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
      style: GoogleFonts.dmSans(fontSize: 14, color: kTextPrimary, height: 1.6),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(fontSize: 14, color: kTextMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: focusColor, width: 1.5)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

// ─── Dropdown ─────────────────────────────────────────────────────────────────
class _AUDropdown extends StatefulWidget {
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final Color focusColor;
  const _AUDropdown({required this.items, this.value, this.onChanged, this.focusColor = kCrimson});

  @override
  State<_AUDropdown> createState() => _AUDropdownState();
}

class _AUDropdownState extends State<_AUDropdown> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.value ?? widget.items.first;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selected,
      onChanged: (v) { setState(() => _selected = v); widget.onChanged?.call(v); },
      items: widget.items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: GoogleFonts.dmSans(fontSize: 14, color: kTextPrimary)),
              ))
          .toList(),
      style: GoogleFonts.dmSans(fontSize: 14, color: kTextPrimary),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: widget.focusColor, width: 1.5)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

// ─── Primary Button ───────────────────────────────────────────────────────────
class _AUPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  const _AUPrimaryButton({required this.label, this.onPressed, this.color = kCrimson});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(label, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Secondary Button ─────────────────────────────────────────────────────────
class _AUSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  const _AUSecondaryButton({required this.label, this.onPressed, this.color = kCrimson});

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Bottom Actions ───────────────────────────────────────────────────────────
class _AUBottomActions extends StatelessWidget {
  final List<Widget> children;
  const _AUBottomActions({required this.children});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) items.add(const SizedBox(height: 10));
    }
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
          color: Colors.white, border: Border(top: BorderSide(color: kBorder))),
      child: Column(mainAxisSize: MainAxisSize.min, children: items),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────
class _AUInfoCard extends StatelessWidget {
  final String title;
  final String body;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  const _AUInfoCard({
    required this.title, required this.body,
    this.bgColor = kCrimsonLight, this.borderColor = kCrimson, this.textColor = kCrimsonDark,
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13, color: textColor)),
        const SizedBox(height: 4),
        Text(body, style: GoogleFonts.dmSans(fontSize: 12, color: textColor, height: 1.5)),
      ]),
    );
  }
}

// ─── Section Divider ──────────────────────────────────────────────────────────
class _AUDivider extends StatelessWidget {
  final String label;
  const _AUDivider(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        const Expanded(child: Divider(color: kBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: kTextMuted)),
        ),
        const Expanded(child: Divider(color: kBorder)),
      ]),
    );
  }
}

// ─── Document Status ──────────────────────────────────────────────────────────
enum _DocStatus { uploaded, pending, required, optional }

// ─── Document Row ─────────────────────────────────────────────────────────────
class _AUDocRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String subtitle;
  final _DocStatus status;
  const _AUDocRow({required this.icon, required this.name, required this.subtitle, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      _DocStatus.uploaded => ('✓ Done', const Color(0xFFDCFCE7), kSuccess),
      _DocStatus.pending  => ('Pending', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      _DocStatus.required => ('Required', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      _DocStatus.optional => ('Optional', const Color(0xFFF3F4F6), kTextMuted),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12), color: Colors.white),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: kCrimsonLight, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: kCrimson, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: kTextMuted)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(label, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ),
      ]),
    );
  }
}

// ─── Upload Area ──────────────────────────────────────────────────────────────
class _AUUploadArea extends StatelessWidget {
  final VoidCallback? onTap;
  const _AUUploadArea({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(color: kBorder, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFFAFAFA),
        ),
        child: Column(children: [
          const Text('📎', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(
                  text: 'Tap to upload',
                  style: GoogleFonts.dmSans(
                      color: kCrimson, fontWeight: FontWeight.w600, fontSize: 13)),
              TextSpan(
                  text: ' or drag and drop\nPDF, JPG, PNG · Max 5MB',
                  style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 13)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Programme Card ───────────────────────────────────────────────────────────
class _AUProgramCard extends StatelessWidget {
  final String name;
  final String dept;
  final String duration;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  const _AUProgramCard({
    required this.name, required this.dept, required this.duration,
    required this.selected, required this.onTap, this.selectedColor = kCrimson,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? selectedColor : kBorder, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: selected ? selectedColor.withValues(alpha: 0.06) : Colors.white,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 18, height: 18,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? selectedColor : kBorder, width: 2),
              color: selected ? selectedColor : Colors.transparent,
            ),
            child: selected ? const Icon(Icons.circle, size: 8, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(dept, style: GoogleFonts.dmSans(fontSize: 11, color: kTextMuted)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(8)),
              child: Text(duration, style: GoogleFonts.dmSans(fontSize: 11, color: kTextMuted)),
            ),
          ])),
        ]),
      ),
    );
  }
}

// ─── Payment Method Card ──────────────────────────────────────────────────────
class _AUPaymentCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String desc;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  const _AUPaymentCard({
    required this.emoji, required this.name, required this.desc,
    required this.selected, required this.onTap, this.selectedColor = kCrimson,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? selectedColor : kBorder, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: selected ? selectedColor.withValues(alpha: 0.06) : Colors.white,
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(desc, style: GoogleFonts.dmSans(fontSize: 11, color: kTextMuted)),
          ]),
        ]),
      ),
    );
  }
}

// ─── Review Section ───────────────────────────────────────────────────────────
class _ReviewSection extends StatelessWidget {
  final String title;
  final List<List<String>> items;
  final VoidCallback? onEdit;
  final Color editColor;
  const _ReviewSection({required this.title, required this.items, this.onEdit, this.editColor = kCrimson});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title.toUpperCase(),
              style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: kTextMuted)),
          GestureDetector(
            onTap: onEdit,
            child: Text('Edit',
                style: GoogleFonts.dmSans(
                    fontSize: 11, fontWeight: FontWeight.w600, color: editColor)),
          ),
        ]),
        const SizedBox(height: 10),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item[0], style: GoogleFonts.dmSans(fontSize: 13, color: kTextPrimary)),
                if (item.length > 1)
                  Text(item[1], style: GoogleFonts.dmSans(fontSize: 12, color: kTextMuted)),
              ]),
            )),
      ]),
    );
  }
}

// ─── Checklist Section ────────────────────────────────────────────────────────
class _ChecklistSection extends StatelessWidget {
  final String title;
  final List<List<String>> items;
  final Color editColor;
  const _ChecklistSection({required this.title, required this.items, this.editColor = kCrimson});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title.toUpperCase(),
              style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: kTextMuted)),
          Text('Edit',
              style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w600, color: editColor)),
        ]),
        const SizedBox(height: 10),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Text(item[0], style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 10),
                Text(item[1], style: GoogleFonts.dmSans(fontSize: 13, color: kTextPrimary)),
              ]),
            )),
      ]),
    );
  }
}

// ─── Fee Summary Card ─────────────────────────────────────────────────────────
class _FeeSummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final String subtitle;
  final List<Color> gradientColors;
  const _FeeSummaryCard({
    required this.label, required this.amount,
    required this.subtitle, required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
            children: [
          Text(amount, style: GoogleFonts.dmSerifDisplay(fontSize: 40, color: Colors.white)),
          const SizedBox(width: 6),
          Text('USD',
              style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
        ]),
        Text(subtitle,
            style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
      ]),
    );
  }
}

// ─── Fee Breakdown ────────────────────────────────────────────────────────────
class _FeeBreakdown extends StatelessWidget {
  final List<List<String>> rows;
  final String total;
  final Color totalColor;
  const _FeeBreakdown({required this.rows, required this.total, this.totalColor = kCrimson});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(r[0], style: GoogleFonts.dmSans(fontSize: 13, color: kTextPrimary)),
                Text(r[1], style: GoogleFonts.dmSans(fontSize: 13, color: kTextPrimary)),
              ]),
            )),
        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: kBorder)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
          Text(total,
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700, fontSize: 14, color: totalColor)),
        ]),
      ]),
    );
  }
}

// ─── Success Body ─────────────────────────────────────────────────────────────
class _SuccessBody extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  final String refNumber;
  final Color accentColor;
  final Color accentLight;
  final VoidCallback onDashboard;
  final VoidCallback onTrack;
  const _SuccessBody({
    required this.emoji, required this.title, required this.body, required this.refNumber,
    required this.accentColor, required this.accentLight,
    required this.onDashboard, required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(height: 4, color: accentColor),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 40))),
              ),
              const SizedBox(height: 20),
              Text(title,
                  style: GoogleFonts.dmSerifDisplay(fontSize: 26, color: kTextPrimary)),
              const SizedBox(height: 10),
              Text(body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 14, color: kTextMuted, height: 1.6)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                    color: accentLight, borderRadius: BorderRadius.circular(10)),
                child: Text(refNumber,
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: accentColor,
                        letterSpacing: 1)),
              ),
              const SizedBox(height: 16),
              Text('Confirmation sent to your email.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
            ]),
          ),
        ),
      ),
      _AUBottomActions(children: [
        _AUPrimaryButton(
            label: 'Go to Dashboard', color: accentColor, onPressed: onDashboard),
        _AUSecondaryButton(
            label: 'Track Application', color: accentColor, onPressed: onTrack),
      ]),
    ]);
  }
}

// ─── Checkbox Row ─────────────────────────────────────────────────────────────
class _AUCheckbox extends StatelessWidget {
  final bool value;
  final Color activeColor;
  final String label;
  final VoidCallback onTap;
  const _AUCheckbox({required this.value, required this.label, required this.onTap, this.activeColor = kCrimson});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20, height: 20, margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: value ? activeColor : kBorder, width: 1.5),
            color: value ? activeColor : Colors.white,
          ),
          child: value ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: GoogleFonts.dmSans(fontSize: 13, color: kTextPrimary, height: 1.5)),
        ),
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// POSTGRAD SCREENS
// ═══════════════════════════════════════════════════════════════════════════

// ─── PG 1: Welcome ───────────────────────────────────────────────────────────
class PostgradWelcomeScreen extends StatelessWidget {
  const PostgradWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [kCrimson, kCrimsonDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 40,
            bottom: 32, left: 24, right: 24,
          ),
          child: Column(children: [
            const Text('🎓', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Postgraduate\nApplication',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 30, color: Colors.white, height: 1.2)),
            const SizedBox(height: 8),
            Text('Africa University – 2024/25 Academic Year',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const _AUInfoCard(
                title: '📋 Before you begin',
                body:
                    'You\'ll need your undergraduate degree certificate, transcripts, and a personal statement. The process takes about 15 minutes.',
              ),
              ...[
                ['📄', 'Undergraduate degree certificate'],
                ['📊', 'Official academic transcripts'],
                ['✍️', 'Personal statement (500–800 words)'],
                ['🪪', 'National ID / Passport'],
                ['💳', 'Application fee: USD \$30'],
              ].map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(children: [
                      Text(e[0], style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(e[1],
                              style: GoogleFonts.dmSans(
                                  fontSize: 14, color: kTextPrimary))),
                    ]),
                  )),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Start Application →',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const PostgradPersonalInfoScreen())),
          ),
          _AUSecondaryButton(label: 'Save & Continue Later', onPressed: () {}),
        ]),
      ]),
    );
  }
}

// ─── PG 2: Personal Info ──────────────────────────────────────────────────────
class PostgradPersonalInfoScreen extends StatefulWidget {
  const PostgradPersonalInfoScreen({super.key});

  @override
  State<PostgradPersonalInfoScreen> createState() =>
      _PostgradPersonalInfoState();
}

class _PostgradPersonalInfoState extends State<PostgradPersonalInfoScreen> {
  String _gender = 'Male';
  String _nationality = 'Zimbabwean';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        const _AUTopBar(title: 'Personal Information', stepLabel: '1 of 7'),
        const _AUProgressBar(step: 1, total: 7),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Personal Details',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Tell us about yourself.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  _AULabel('First Name', required: true),
                  _AUTextField(hint: 'First name'),
                ])),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  _AULabel('Last Name', required: true),
                  _AUTextField(hint: 'Last name'),
                ])),
              ]),
              const SizedBox(height: 16),
              const _AULabel('Date of Birth', required: true),
              const _AUTextField(
                  hint: 'DD / MM / YYYY', keyboardType: TextInputType.datetime),
              const SizedBox(height: 16),
              const _AULabel('Gender', required: true),
              _AUDropdown(
                items: const ['Male', 'Female', 'Prefer not to say'],
                value: _gender,
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 16),
              const _AULabel('Nationality', required: true),
              _AUDropdown(
                items: const ['Zimbabwean', 'Other'],
                value: _nationality,
                onChanged: (v) => setState(() => _nationality = v!),
              ),
              const SizedBox(height: 16),
              const _AULabel('Email Address', required: true),
              const _AUTextField(
                  hint: 'your@email.com',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              const _AULabel('Phone Number', required: true),
              const _AUTextField(
                  hint: '+263 77 123 4567', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              const _AULabel('Home Address'),
              const _AUTextField(hint: 'Enter your address'),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Continue →',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const PostgradAcademicScreen())),
          ),
        ]),
      ]),
    );
  }
}

// ─── PG 3: Academic Background ────────────────────────────────────────────────
class PostgradAcademicScreen extends StatefulWidget {
  const PostgradAcademicScreen({super.key});

  @override
  State<PostgradAcademicScreen> createState() => _PostgradAcademicState();
}

class _PostgradAcademicState extends State<PostgradAcademicScreen> {
  String _grade = 'Upper Second (2:1)';
  String _startYear = '2019';
  String _endYear = '2023';
  String _experience = '1–2 years';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        const _AUTopBar(title: 'Academic Background', stepLabel: '2 of 7'),
        const _AUProgressBar(step: 2, total: 7),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Undergraduate Degree',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Tell us about your previous studies.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
              const SizedBox(height: 20),
              const _AULabel('Institution Name', required: true),
              const _AUTextField(hint: 'e.g. University of Zimbabwe'),
              const SizedBox(height: 16),
              const _AULabel('Degree Title', required: true),
              const _AUTextField(hint: 'e.g. BSc Computer Science'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _AULabel('Start Year'),
                  _AUDropdown(
                    items: const ['2016', '2017', '2018', '2019', '2020'],
                    value: _startYear,
                    onChanged: (v) => setState(() => _startYear = v!),
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _AULabel('End Year'),
                  _AUDropdown(
                    items: const ['2020', '2021', '2022', '2023', '2024'],
                    value: _endYear,
                    onChanged: (v) => setState(() => _endYear = v!),
                  ),
                ])),
              ]),
              const SizedBox(height: 16),
              const _AULabel('Grade / Classification', required: true),
              _AUDropdown(
                items: const [
                  'First Class Honours', 'Upper Second (2:1)',
                  'Lower Second (2:2)', 'Third Class', 'Pass'
                ],
                value: _grade,
                onChanged: (v) => setState(() => _grade = v!),
              ),
              const SizedBox(height: 16),
              const _AULabel('GPA (if applicable)'),
              const _AUTextField(hint: 'e.g. 3.8 / 4.0'),
              const _AUDivider('Work Experience (Optional)'),
              const _AULabel('Current Employer / Organisation'),
              const _AUTextField(hint: 'Company or organisation name'),
              const SizedBox(height: 16),
              const _AULabel('Years of Experience'),
              _AUDropdown(
                items: const ['Less than 1 year', '1–2 years', '3–5 years', '5+ years'],
                value: _experience,
                onChanged: (v) => setState(() => _experience = v!),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Continue →',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PostgradProgramScreen())),
          ),
        ]),
      ]),
    );
  }
}

// ─── PG 4: Programme Selection ────────────────────────────────────────────────
class PostgradProgramScreen extends StatefulWidget {
  const PostgradProgramScreen({super.key});

  @override
  State<PostgradProgramScreen> createState() => _PostgradProgramState();
}

class _PostgradProgramState extends State<PostgradProgramScreen> {
  int _selected = 0;
  String _mode = 'Full-time';
  String _intake = 'January 2025';
  String _faculty = 'All Faculties';

  static const _programs = [
    ['PGDip in Business Administration', 'Faculty of Business & Management', '1 Year · Full-time'],
    ['PGDip in Public Health', 'Faculty of Health Sciences', '1 Year · Part-time available'],
    ['PGDip in Development Studies', 'Faculty of Social Sciences', '1 Year · Full-time'],
    ['PGDip in Information Technology', 'Faculty of Engineering & Technology', '1 Year · Full-time'],
    ['PGDip in Theology & Ministry', 'Faculty of Theology', '1 Year · Full-time'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        const _AUTopBar(title: 'Choose Programme', stepLabel: '3 of 7'),
        const _AUProgressBar(step: 3, total: 7),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Postgraduate Programme',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Select the programme you wish to apply for.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
              const SizedBox(height: 20),
              const _AULabel('Faculty'),
              _AUDropdown(
                items: const [
                  'All Faculties', 'Business & Management',
                  'Engineering & Technology', 'Health Sciences',
                  'Social Sciences', 'Theology',
                ],
                value: _faculty,
                onChanged: (v) => setState(() => _faculty = v!),
              ),
              const SizedBox(height: 16),
              ..._programs.asMap().entries.map((e) => _AUProgramCard(
                    name: e.value[0],
                    dept: e.value[1],
                    duration: e.value[2],
                    selected: _selected == e.key,
                    onTap: () => setState(() => _selected = e.key),
                  )),
              const _AUDivider('Study Options'),
              const _AULabel('Study Mode'),
              _AUDropdown(
                items: const ['Full-time', 'Part-time', 'Distance Learning'],
                value: _mode,
                onChanged: (v) => setState(() => _mode = v!),
              ),
              const SizedBox(height: 16),
              const _AULabel('Preferred Intake'),
              _AUDropdown(
                items: const ['January 2025', 'August 2025', 'January 2026'],
                value: _intake,
                onChanged: (v) => setState(() => _intake = v!),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Continue →',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const PostgradStatementScreen())),
          ),
        ]),
      ]),
    );
  }
}

// ─── PG 5: Personal Statement ─────────────────────────────────────────────────
class PostgradStatementScreen extends StatefulWidget {
  const PostgradStatementScreen({super.key});

  @override
  State<PostgradStatementScreen> createState() => _PostgradStatementState();
}

class _PostgradStatementState extends State<PostgradStatementScreen> {
  final _ctrl = TextEditingController();
  int _wordCount = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _update(String text) {
    setState(() {
      _wordCount =
          text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tooShort = _wordCount > 0 && _wordCount < 500;
    final tooLong = _wordCount > 800;
    final ok = _wordCount >= 500 && _wordCount <= 800;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        const _AUTopBar(title: 'Personal Statement', stepLabel: '4 of 7'),
        const _AUProgressBar(step: 4, total: 7),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Personal Statement',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                'Explain why you want to pursue this programme and how it aligns with your career goals.',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: kTextMuted, height: 1.5),
              ),
              const SizedBox(height: 20),
              const _AUInfoCard(
                title: '✍️ Writing tips',
                body:
                    '• Why you want to study this programme\n• Your relevant experience and skills\n• Your future career aspirations\n• Why Africa University is your choice',
              ),
              const _AULabel('Statement', required: true),
              TextFormField(
                controller: _ctrl,
                maxLines: 14,
                onChanged: _update,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: kTextPrimary, height: 1.6),
                decoration: InputDecoration(
                  hintText:
                      'Write your personal statement here (500–800 words)...',
                  hintStyle:
                      GoogleFonts.dmSans(fontSize: 14, color: kTextMuted),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: kCrimson, width: 1.5)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  tooShort
                      ? 'Too short – add more detail'
                      : tooLong
                          ? 'Too long – please trim'
                          : ok
                              ? '✓ Good length'
                              : 'Minimum 500 words',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: (tooShort || tooLong) ? kCrimson : ok ? kSuccess : kTextMuted),
                ),
                Text('$_wordCount / 800 words',
                    style: GoogleFonts.dmSans(fontSize: 12, color: kTextMuted)),
              ]),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Continue →',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const PostgradDocumentsScreen())),
          ),
        ]),
      ]),
    );
  }
}

// ─── PG 6: Documents ──────────────────────────────────────────────────────────
class PostgradDocumentsScreen extends StatelessWidget {
  const PostgradDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        const _AUTopBar(title: 'Upload Documents', stepLabel: '5 of 7'),
        const _AUProgressBar(step: 5, total: 7),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Supporting Documents',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Upload the required documents. Max file size: 5MB each.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
              const SizedBox(height: 20),
              const _AUInfoCard(
                title: '📄 Accepted formats',
                body:
                    'PDF, JPG, PNG. Each file must be clear and legible. Certified copies are recommended.',
              ),
              const _AULabel('Required Documents'),
              const SizedBox(height: 8),
              const _AUDocRow(
                  icon: Icons.school_rounded,
                  name: 'Degree Certificate',
                  subtitle: 'Undergraduate degree certificate',
                  status: _DocStatus.required),
              const _AUDocRow(
                  icon: Icons.insert_drive_file_rounded,
                  name: 'Academic Transcripts',
                  subtitle: 'Official transcripts from your institution',
                  status: _DocStatus.required),
              const _AUDocRow(
                  icon: Icons.badge_rounded,
                  name: 'National ID / Passport',
                  subtitle: 'Valid government-issued ID',
                  status: _DocStatus.required),
              const _AUDocRow(
                  icon: Icons.description_rounded,
                  name: 'Personal Statement',
                  subtitle: 'PDF of your personal statement',
                  status: _DocStatus.pending),
              const SizedBox(height: 16),
              const _AULabel('Optional Documents'),
              const SizedBox(height: 8),
              const _AUDocRow(
                  icon: Icons.work_rounded,
                  name: 'CV / Resume',
                  subtitle: 'Optional but recommended',
                  status: _DocStatus.optional),
              const _AUDocRow(
                  icon: Icons.recommend_rounded,
                  name: 'Reference Letter',
                  subtitle: 'From an academic or employer',
                  status: _DocStatus.optional),
              const SizedBox(height: 16),
              const _AULabel('Upload Additional Files'),
              const SizedBox(height: 8),
              _AUUploadArea(onTap: () {}),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Continue →',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const PostgradReviewScreen())),
          ),
        ]),
      ]),
    );
  }
}

// ─── PG 7: Review ─────────────────────────────────────────────────────────────
class PostgradReviewScreen extends StatefulWidget {
  const PostgradReviewScreen({super.key});

  @override
  State<PostgradReviewScreen> createState() => _PostgradReviewState();
}

class _PostgradReviewState extends State<PostgradReviewScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        const _AUTopBar(title: 'Review Application', stepLabel: '6 of 7'),
        const _AUProgressBar(step: 6, total: 7),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Review & Confirm',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Please review your application before submitting.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
              const SizedBox(height: 20),
              _ReviewSection(title: 'Personal Information', items: const [
                ['Tendai Moyo', 'Full Name'],
                ['15 / 03 / 1998', 'Date of Birth'],
                ['Male · Zimbabwean', 'Gender · Nationality'],
                ['tendai@email.com', 'Email'],
                ['+263 77 123 4567', 'Phone'],
              ]),
              _ReviewSection(title: 'Academic Background', items: const [
                ['University of Zimbabwe', 'Institution'],
                ['BSc Computer Science', 'Degree'],
                ['Upper Second (2:1)', 'Classification'],
                ['2019 – 2023', 'Study Period'],
              ]),
              _ReviewSection(title: 'Programme', items: const [
                ['PGDip in Business Administration', 'Programme'],
                ['Faculty of Business & Management', 'Faculty'],
                ['Full-time · January 2025', 'Mode · Intake'],
              ]),
              _ChecklistSection(title: 'Documents Uploaded', items: const [
                ['✅', 'Degree Certificate'],
                ['✅', 'Academic Transcripts'],
                ['✅', 'National ID / Passport'],
                ['⏳', 'Personal Statement'],
              ]),
              const SizedBox(height: 8),
              _AUCheckbox(
                value: _agreed,
                activeColor: kCrimson,
                label:
                    'I confirm that the information provided is accurate and complete. I understand that providing false information may result in my application being disqualified.',
                onTap: () => setState(() => _agreed = !_agreed),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Proceed to Payment →',
            color: _agreed ? kCrimson : kBorder,
            onPressed: _agreed
                ? () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const PostgradPaymentScreen()))
                : null,
          ),
        ]),
      ]),
    );
  }
}

// ─── PG 8: Payment ────────────────────────────────────────────────────────────
class PostgradPaymentScreen extends StatefulWidget {
  const PostgradPaymentScreen({super.key});

  @override
  State<PostgradPaymentScreen> createState() => _PostgradPaymentState();
}

class _PostgradPaymentState extends State<PostgradPaymentScreen> {
  int _method = 0;

  @override
  Widget build(BuildContext context) {
    const methods = [
      ['📱', 'EcoCash (Paynow)', 'Pay with your mobile wallet'],
      ['💳', 'Visa / Mastercard', 'Powered by Flutterwave'],
      ['🏦', 'Bank Transfer', 'CABS or CBZ bank'],
    ];

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        const _AUTopBar(title: 'Application Fee', stepLabel: '7 of 7'),
        const _AUProgressBar(step: 7, total: 7),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pay Application Fee',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('A non-refundable fee to process your application.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
              const SizedBox(height: 20),
              const _FeeSummaryCard(
                label: 'Total Amount Due',
                amount: '\$30',
                subtitle: 'Postgraduate application fee · One-time payment',
                gradientColors: [kCrimson, kCrimsonDark],
              ),
              _FeeBreakdown(
                rows: const [
                  ['Application Processing', '\$25.00'],
                  ['Online Platform Fee', '\$5.00'],
                ],
                total: '\$30.00',
              ),
              const _AULabel('Select Payment Method'),
              const SizedBox(height: 8),
              ...methods.asMap().entries.map((e) => _AUPaymentCard(
                    emoji: e.value[0],
                    name: e.value[1],
                    desc: e.value[2],
                    selected: _method == e.key,
                    onTap: () => setState(() => _method = e.key),
                  )),
              const _AUInfoCard(
                title: '🔒 Secure Payment',
                body:
                    'Your payment is encrypted and secure. You will receive a confirmation email once payment is processed.',
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Pay \$30 Now →',
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const PostgradSuccessScreen()),
              (route) => route.isFirst,
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─── PG 9: Success ────────────────────────────────────────────────────────────
class PostgradSuccessScreen extends StatelessWidget {
  const PostgradSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _SuccessBody(
          emoji: '🎓',
          title: 'Application Submitted!',
          body:
              'Your postgraduate application has been received. We will review it and notify you within 10–14 working days.',
          refNumber: 'REF: AU-PG-2025-0042',
          accentColor: kCrimson,
          accentLight: kCrimsonLight,
          onDashboard: () => Navigator.pushNamedAndRemoveUntil(
              context, '/onboarding_dashboard', (_) => false),
          onTrack: () => Navigator.pushNamedAndRemoveUntil(
              context, '/application_progress', (_) => false),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// MASTER'S SCREENS
// ═══════════════════════════════════════════════════════════════════════════

// ─── M 1: Welcome ─────────────────────────────────────────────────────────────
class MastersWelcomeScreen extends StatelessWidget {
  const MastersWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [kMastersPrimary, kMastersDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 40,
            bottom: 32, left: 24, right: 24,
          ),
          child: Column(children: [
            const Text('📚', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Master\'s\nApplication',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 30, color: Colors.white, height: 1.2)),
            const SizedBox(height: 8),
            Text('Africa University – 2024/25 Academic Year',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _AUInfoCard(
                title: '📋 Before you begin',
                body:
                    'You\'ll need a good undergraduate degree, a research proposal, two academic references, and certified transcripts. The process takes about 25 minutes.',
                bgColor: kMastersLight,
                borderColor: kMastersPrimary,
                textColor: kMastersDark,
              ),
              ...[
                ['📄', 'Undergraduate degree (minimum 2:1)'],
                ['📊', 'Certified academic transcripts'],
                ['🔬', 'Research proposal (1,000–1,500 words)'],
                ['👥', 'Two academic reference contacts'],
                ['🪪', 'National ID / Passport'],
                ['💳', 'Application fee: USD \$50'],
              ].map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(children: [
                      Text(e[0], style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(e[1],
                              style: GoogleFonts.dmSans(
                                  fontSize: 14, color: kTextPrimary))),
                    ]),
                  )),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Start Application →',
            color: kMastersPrimary,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const MastersPersonalInfoScreen())),
          ),
          _AUSecondaryButton(
              label: 'Save & Continue Later',
              color: kMastersPrimary,
              onPressed: () {}),
        ]),
      ]),
    );
  }
}

// ─── M 2: Personal Info ────────────────────────────────────────────────────────
class MastersPersonalInfoScreen extends StatefulWidget {
  const MastersPersonalInfoScreen({super.key});

  @override
  State<MastersPersonalInfoScreen> createState() =>
      _MastersPersonalInfoState();
}

class _MastersPersonalInfoState extends State<MastersPersonalInfoScreen> {
  String _gender = 'Male';
  String _nationality = 'Zimbabwean';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _AUTopBar(
            title: 'Personal Information',
            stepLabel: '1 of 9',
            color: kMastersPrimary),
        _AUProgressBar(step: 1, total: 9, color: kMastersPrimary),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Personal Details',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Tell us about yourself.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  _AULabel('First Name', required: true),
                  _AUTextField(hint: 'First name', focusColor: kMastersPrimary),
                ])),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  _AULabel('Last Name', required: true),
                  _AUTextField(hint: 'Last name', focusColor: kMastersPrimary),
                ])),
              ]),
              const SizedBox(height: 16),
              const _AULabel('Date of Birth', required: true),
              const _AUTextField(
                  hint: 'DD / MM / YYYY',
                  keyboardType: TextInputType.datetime,
                  focusColor: kMastersPrimary),
              const SizedBox(height: 16),
              const _AULabel('Gender', required: true),
              _AUDropdown(
                items: const ['Male', 'Female', 'Prefer not to say'],
                value: _gender,
                focusColor: kMastersPrimary,
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 16),
              const _AULabel('Nationality', required: true),
              _AUDropdown(
                items: const ['Zimbabwean', 'Other'],
                value: _nationality,
                focusColor: kMastersPrimary,
                onChanged: (v) => setState(() => _nationality = v!),
              ),
              const SizedBox(height: 16),
              const _AULabel('Email Address', required: true),
              const _AUTextField(
                  hint: 'your@email.com',
                  keyboardType: TextInputType.emailAddress,
                  focusColor: kMastersPrimary),
              const SizedBox(height: 16),
              const _AULabel('Phone Number', required: true),
              const _AUTextField(
                  hint: '+263 77 123 4567',
                  keyboardType: TextInputType.phone,
                  focusColor: kMastersPrimary),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Continue →',
            color: kMastersPrimary,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const MastersAcademicScreen())),
          ),
        ]),
      ]),
    );
  }
}

// ─── M 3: Academic Background ──────────────────────────────────────────────────
class MastersAcademicScreen extends StatefulWidget {
  const MastersAcademicScreen({super.key});

  @override
  State<MastersAcademicScreen> createState() => _MastersAcademicState();
}

class _MastersAcademicState extends State<MastersAcademicScreen> {
  String _grade = 'Upper Second (2:1)';
  String _startYear = '2019';
  String _endYear = '2023';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _AUTopBar(
            title: 'Academic Background',
            stepLabel: '2 of 9',
            color: kMastersPrimary),
        _AUProgressBar(step: 2, total: 9, color: kMastersPrimary),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Undergraduate Qualifications',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('A minimum of an Upper Second Class Honours is required.',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: kTextMuted, height: 1.5)),
              const SizedBox(height: 20),
              _AUInfoCard(
                title: '⚠️ Entry Requirements',
                body:
                    'Master\'s programmes require a minimum 2:1 (Upper Second Class) honours degree or equivalent qualification.',
                bgColor: kMastersLight,
                borderColor: kMastersPrimary,
                textColor: kMastersDark,
              ),
              const _AULabel('Institution Name', required: true),
              const _AUTextField(
                  hint: 'e.g. University of Zimbabwe',
                  focusColor: kMastersPrimary),
              const SizedBox(height: 16),
              const _AULabel('Degree Title', required: true),
              const _AUTextField(
                  hint: 'e.g. BSc Computer Science',
                  focusColor: kMastersPrimary),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _AULabel('Start Year'),
                  _AUDropdown(
                    items: const ['2016', '2017', '2018', '2019', '2020'],
                    value: _startYear,
                    focusColor: kMastersPrimary,
                    onChanged: (v) => setState(() => _startYear = v!),
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _AULabel('End Year'),
                  _AUDropdown(
                    items: const ['2020', '2021', '2022', '2023', '2024'],
                    value: _endYear,
                    focusColor: kMastersPrimary,
                    onChanged: (v) => setState(() => _endYear = v!),
                  ),
                ])),
              ]),
              const SizedBox(height: 16),
              const _AULabel('Grade / Classification', required: true),
              _AUDropdown(
                items: const [
                  'First Class Honours', 'Upper Second (2:1)',
                  'Lower Second (2:2)', 'Pass'
                ],
                value: _grade,
                focusColor: kMastersPrimary,
                onChanged: (v) => setState(() => _grade = v!),
              ),
              const SizedBox(height: 16),
              const _AULabel('GPA (if applicable)'),
              const _AUTextField(
                  hint: 'e.g. 3.8 / 4.0', focusColor: kMastersPrimary),
              const SizedBox(height: 16),
              const _AULabel('Any Previous Postgraduate Study?'),
              const _AUTextField(
                  hint: 'Degree title and institution (if any)',
                  focusColor: kMastersPrimary),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Continue →',
            color: kMastersPrimary,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const MastersProgramScreen())),
          ),
        ]),
      ]),
    );
  }
}

// ─── M 4: Programme ────────────────────────────────────────────────────────────
class MastersProgramScreen extends StatefulWidget {
  const MastersProgramScreen({super.key});

  @override
  State<MastersProgramScreen> createState() => _MastersProgramState();
}

class _MastersProgramState extends State<MastersProgramScreen> {
  int _selected = 0;
  String _mode = 'Full-time';
  String _intake = 'January 2025';

  static const _programs = [
    ['Master of Business Administration (MBA)', 'Faculty of Business & Management', '2 Years · Full-time'],
    ['MSc in Computer Science', 'Faculty of Engineering & Technology', '2 Years · Full-time'],
    ['MSc in Public Health', 'Faculty of Health Sciences', '2 Years · Part-time available'],
    ['MA in Development Studies', 'Faculty of Social Sciences', '2 Years · Full-time'],
    ['MA in Peace & Governance', 'Faculty of Social Sciences', '2 Years · Full-time'],
    ['MTh in Theology', 'Faculty of Theology', '2 Years · Full-time'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _AUTopBar(
            title: 'Choose Programme',
            stepLabel: '3 of 9',
            color: kMastersPrimary),
        _AUProgressBar(step: 3, total: 9, color: kMastersPrimary),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Master\'s Programme',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Select the programme you wish to apply for.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
              const SizedBox(height: 20),
              ..._programs.asMap().entries.map((e) => _AUProgramCard(
                    name: e.value[0],
                    dept: e.value[1],
                    duration: e.value[2],
                    selected: _selected == e.key,
                    selectedColor: kMastersPrimary,
                    onTap: () => setState(() => _selected = e.key),
                  )),
              const _AUDivider('Study Options'),
              const _AULabel('Study Mode'),
              _AUDropdown(
                items: const ['Full-time', 'Part-time'],
                value: _mode,
                focusColor: kMastersPrimary,
                onChanged: (v) => setState(() => _mode = v!),
              ),
              const SizedBox(height: 16),
              const _AULabel('Preferred Intake'),
              _AUDropdown(
                items: const ['January 2025', 'August 2025', 'January 2026'],
                value: _intake,
                focusColor: kMastersPrimary,
                onChanged: (v) => setState(() => _intake = v!),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Continue →',
            color: kMastersPrimary,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const MastersSupervisorScreen())),
          ),
        ]),
      ]),
    );
  }
}

// ─── M 5: Supervisor & Research Area ──────────────────────────────────────────
class MastersSupervisorScreen extends StatefulWidget {
  const MastersSupervisorScreen({super.key});

  @override
  State<MastersSupervisorScreen> createState() => _MastersSupervisorState();
}

class _MastersSupervisorState extends State<MastersSupervisorScreen> {
  String _area = 'Business & Management';
  bool _hasSupervisor = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _AUTopBar(
            title: 'Research Area & Supervisor',
            stepLabel: '4 of 9',
            color: kMastersPrimary),
        _AUProgressBar(step: 4, total: 9, color: kMastersPrimary),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Research Area', style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Tell us about your research interests.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
              const SizedBox(height: 20),
              const _AULabel('Research Area / Specialisation', required: true),
              _AUDropdown(
                items: const [
                  'Business & Management', 'Computer Science & IT',
                  'Public Health', 'Development Studies',
                  'Peace & Governance', 'Theology',
                ],
                value: _area,
                focusColor: kMastersPrimary,
                onChanged: (v) => setState(() => _area = v!),
              ),
              const SizedBox(height: 16),
              const _AULabel('Research Title / Topic (Provisional)', required: true),
              const _AUTextField(
                hint: 'e.g. Impact of Mobile Banking on Financial Inclusion in Zimbabwe',
                focusColor: kMastersPrimary,
              ),
              const _AUDivider('Preferred Supervisor (Optional)'),
              _AUInfoCard(
                title: '👨‍🏫 About supervisors',
                body:
                    'If you have a preferred supervisor at Africa University, list them here. Otherwise one will be assigned based on your research area.',
                bgColor: kMastersLight,
                borderColor: kMastersPrimary,
                textColor: kMastersDark,
              ),
              _AUCheckbox(
                value: _hasSupervisor,
                activeColor: kMastersPrimary,
                label: 'I have a preferred supervisor in mind',
                onTap: () => setState(() => _hasSupervisor = !_hasSupervisor),
              ),
              if (_hasSupervisor) ...[
                const SizedBox(height: 16),
                const _AULabel('Supervisor Name'),
                const _AUTextField(
                    hint: 'Dr. / Prof. Full Name', focusColor: kMastersPrimary),
                const SizedBox(height: 16),
                const _AULabel('Department'),
                const _AUTextField(
                    hint: 'e.g. Department of Economics',
                    focusColor: kMastersPrimary),
              ],
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Continue →',
            color: kMastersPrimary,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const MastersProposalScreen())),
          ),
        ]),
      ]),
    );
  }
}

// ─── M 6: Research Proposal ────────────────────────────────────────────────────
class MastersProposalScreen extends StatefulWidget {
  const MastersProposalScreen({super.key});

  @override
  State<MastersProposalScreen> createState() => _MastersProposalState();
}

class _MastersProposalState extends State<MastersProposalScreen> {
  final _ctrl = TextEditingController();
  int _wordCount = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _update(String text) {
    setState(() {
      _wordCount =
          text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tooShort = _wordCount > 0 && _wordCount < 1000;
    final tooLong = _wordCount > 1500;
    final ok = _wordCount >= 1000 && _wordCount <= 1500;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _AUTopBar(
            title: 'Research Proposal',
            stepLabel: '5 of 9',
            color: kMastersPrimary),
        _AUProgressBar(step: 5, total: 9, color: kMastersPrimary),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Research Proposal',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Describe your proposed research in 1,000–1,500 words.',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: kTextMuted, height: 1.5)),
              const SizedBox(height: 20),
              _AUInfoCard(
                title: '🔬 What to include',
                body:
                    '• Background and rationale\n• Research objectives\n• Proposed methodology\n• Expected outcomes\n• Significance of the study',
                bgColor: kMastersLight,
                borderColor: kMastersPrimary,
                textColor: kMastersDark,
              ),
              const _AULabel('Research Proposal', required: true),
              TextFormField(
                controller: _ctrl,
                maxLines: 18,
                onChanged: _update,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: kTextPrimary, height: 1.6),
                decoration: InputDecoration(
                  hintText:
                      'Write your research proposal here (1,000–1,500 words)...',
                  hintStyle:
                      GoogleFonts.dmSans(fontSize: 14, color: kTextMuted),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: kMastersPrimary, width: 1.5)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  tooShort
                      ? 'Too short – add more detail'
                      : tooLong
                          ? 'Too long – please trim'
                          : ok
                              ? '✓ Good length'
                              : 'Minimum 1,000 words',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: (tooShort || tooLong)
                          ? kMastersPrimary
                          : ok
                              ? kSuccess
                              : kTextMuted),
                ),
                Text('$_wordCount / 1,500 words',
                    style: GoogleFonts.dmSans(fontSize: 12, color: kTextMuted)),
              ]),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Continue →',
            color: kMastersPrimary,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const MastersReferencesScreen())),
          ),
        ]),
      ]),
    );
  }
}

// ─── M 7: References ───────────────────────────────────────────────────────────
class MastersReferencesScreen extends StatelessWidget {
  const MastersReferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _AUTopBar(
            title: 'Academic References',
            stepLabel: '6 of 9',
            color: kMastersPrimary),
        _AUProgressBar(step: 6, total: 9, color: kMastersPrimary),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Academic References',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Provide two academic or professional referees.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
              const SizedBox(height: 20),
              _AUInfoCard(
                title: '👥 Reference guidelines',
                body:
                    'Referees should be academics who taught you, or senior professionals who can speak to your abilities. Personal references are not accepted.',
                bgColor: kMastersLight,
                borderColor: kMastersPrimary,
                textColor: kMastersDark,
              ),
              Text('Referee 1',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: kMastersPrimary)),
              const SizedBox(height: 12),
              const _AULabel('Full Name', required: true),
              const _AUTextField(
                  hint: 'Dr. / Prof. Full Name', focusColor: kMastersPrimary),
              const SizedBox(height: 12),
              const _AULabel('Position / Title'),
              const _AUTextField(
                  hint: 'e.g. Associate Professor', focusColor: kMastersPrimary),
              const SizedBox(height: 12),
              const _AULabel('Institution / Organisation'),
              const _AUTextField(
                  hint: 'e.g. University of Zimbabwe',
                  focusColor: kMastersPrimary),
              const SizedBox(height: 12),
              const _AULabel('Email Address', required: true),
              const _AUTextField(
                  hint: 'referee@institution.ac.zw',
                  keyboardType: TextInputType.emailAddress,
                  focusColor: kMastersPrimary),
              const _AUDivider('Referee 2'),
              Text('Referee 2',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: kMastersPrimary)),
              const SizedBox(height: 12),
              const _AULabel('Full Name', required: true),
              const _AUTextField(
                  hint: 'Dr. / Prof. Full Name', focusColor: kMastersPrimary),
              const SizedBox(height: 12),
              const _AULabel('Position / Title'),
              const _AUTextField(
                  hint: 'e.g. Senior Lecturer', focusColor: kMastersPrimary),
              const SizedBox(height: 12),
              const _AULabel('Institution / Organisation'),
              const _AUTextField(
                  hint: 'e.g. Harare Institute of Technology',
                  focusColor: kMastersPrimary),
              const SizedBox(height: 12),
              const _AULabel('Email Address', required: true),
              const _AUTextField(
                  hint: 'referee2@institution.ac.zw',
                  keyboardType: TextInputType.emailAddress,
                  focusColor: kMastersPrimary),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Continue →',
            color: kMastersPrimary,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const MastersDocumentsScreen())),
          ),
        ]),
      ]),
    );
  }
}

// ─── M 8: Documents ────────────────────────────────────────────────────────────
class MastersDocumentsScreen extends StatelessWidget {
  const MastersDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _AUTopBar(
            title: 'Upload Documents',
            stepLabel: '7 of 9',
            color: kMastersPrimary),
        _AUProgressBar(step: 7, total: 9, color: kMastersPrimary),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Supporting Documents',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Upload certified copies. Max file size: 5MB each.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
              const SizedBox(height: 20),
              const _AULabel('Required Documents'),
              const SizedBox(height: 8),
              const _AUDocRow(
                  icon: Icons.school_rounded,
                  name: 'Degree Certificate',
                  subtitle: 'Certified copy of undergraduate degree',
                  status: _DocStatus.required),
              const _AUDocRow(
                  icon: Icons.insert_drive_file_rounded,
                  name: 'Academic Transcripts',
                  subtitle: 'Certified official transcripts',
                  status: _DocStatus.required),
              const _AUDocRow(
                  icon: Icons.badge_rounded,
                  name: 'National ID / Passport',
                  subtitle: 'Valid government-issued ID',
                  status: _DocStatus.required),
              const _AUDocRow(
                  icon: Icons.article_rounded,
                  name: 'Research Proposal',
                  subtitle: 'PDF of your research proposal',
                  status: _DocStatus.pending),
              const SizedBox(height: 16),
              const _AULabel('Optional Documents'),
              const SizedBox(height: 8),
              const _AUDocRow(
                  icon: Icons.work_rounded,
                  name: 'CV / Resume',
                  subtitle: 'Academic or professional CV',
                  status: _DocStatus.optional),
              const _AUDocRow(
                  icon: Icons.recommend_rounded,
                  name: 'Letters of Reference',
                  subtitle: 'From your nominated referees',
                  status: _DocStatus.optional),
              const SizedBox(height: 16),
              const _AULabel('Upload Additional Files'),
              const SizedBox(height: 8),
              _AUUploadArea(onTap: () {}),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Continue →',
            color: kMastersPrimary,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const MastersReviewScreen())),
          ),
        ]),
      ]),
    );
  }
}

// ─── M 9: Review ───────────────────────────────────────────────────────────────
class MastersReviewScreen extends StatefulWidget {
  const MastersReviewScreen({super.key});

  @override
  State<MastersReviewScreen> createState() => _MastersReviewState();
}

class _MastersReviewState extends State<MastersReviewScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _AUTopBar(
            title: 'Review Application',
            stepLabel: '8 of 9',
            color: kMastersPrimary),
        _AUProgressBar(step: 8, total: 9, color: kMastersPrimary),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Review & Confirm',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('Please review your application before submitting.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
              const SizedBox(height: 20),
              _ReviewSection(
                  title: 'Personal Information',
                  editColor: kMastersPrimary,
                  items: const [
                    ['Tendai Moyo', 'Full Name'],
                    ['Male · Zimbabwean', 'Gender · Nationality'],
                    ['tendai@email.com', 'Email'],
                  ]),
              _ReviewSection(
                  title: 'Academic Background',
                  editColor: kMastersPrimary,
                  items: const [
                    ['University of Zimbabwe', 'Institution'],
                    ['BSc Computer Science', 'Degree'],
                    ['Upper Second (2:1)', 'Classification'],
                  ]),
              _ReviewSection(
                  title: 'Programme',
                  editColor: kMastersPrimary,
                  items: const [
                    ['Master of Business Administration (MBA)', 'Programme'],
                    ['Full-time · January 2025', 'Mode · Intake'],
                  ]),
              _ReviewSection(
                  title: 'Research',
                  editColor: kMastersPrimary,
                  items: const [
                    ['Impact of Mobile Banking on Financial Inclusion', 'Provisional Title'],
                    ['Business & Management', 'Research Area'],
                  ]),
              _ReviewSection(
                  title: 'References',
                  editColor: kMastersPrimary,
                  items: const [
                    ['Dr. Jane Mutasa – UZ', 'Referee 1'],
                    ['Prof. John Banda – HIT', 'Referee 2'],
                  ]),
              _ChecklistSection(
                  title: 'Documents Uploaded',
                  editColor: kMastersPrimary,
                  items: const [
                    ['✅', 'Degree Certificate'],
                    ['✅', 'Academic Transcripts'],
                    ['✅', 'National ID'],
                    ['⏳', 'Research Proposal'],
                  ]),
              const SizedBox(height: 8),
              _AUCheckbox(
                value: _agreed,
                activeColor: kMastersPrimary,
                label:
                    'I confirm that all information provided is accurate. I understand that false information may lead to disqualification.',
                onTap: () => setState(() => _agreed = !_agreed),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Proceed to Payment →',
            color: _agreed ? kMastersPrimary : kBorder,
            onPressed: _agreed
                ? () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const MastersPaymentScreen()))
                : null,
          ),
        ]),
      ]),
    );
  }
}

// ─── M 10: Payment ─────────────────────────────────────────────────────────────
class MastersPaymentScreen extends StatefulWidget {
  const MastersPaymentScreen({super.key});

  @override
  State<MastersPaymentScreen> createState() => _MastersPaymentState();
}

class _MastersPaymentState extends State<MastersPaymentScreen> {
  int _method = 0;

  @override
  Widget build(BuildContext context) {
    const methods = [
      ['📱', 'EcoCash (Paynow)', 'Pay with your mobile wallet'],
      ['💳', 'Visa / Mastercard', 'Powered by Flutterwave'],
      ['🏦', 'Bank Transfer', 'CABS or CBZ bank'],
    ];

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        _AUTopBar(
            title: 'Application Fee',
            stepLabel: '9 of 9',
            color: kMastersPrimary),
        _AUProgressBar(step: 9, total: 9, color: kMastersPrimary),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pay Application Fee',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
              const SizedBox(height: 4),
              Text('A non-refundable fee to process your application.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: kTextMuted)),
              const SizedBox(height: 20),
              const _FeeSummaryCard(
                label: 'Total Amount Due',
                amount: '\$50',
                subtitle: 'Master\'s application fee · One-time payment',
                gradientColors: [kMastersPrimary, kMastersDark],
              ),
              _FeeBreakdown(
                rows: const [
                  ['Application Processing', '\$40.00'],
                  ['Online Platform Fee', '\$10.00'],
                ],
                total: '\$50.00',
                totalColor: kMastersPrimary,
              ),
              const _AULabel('Select Payment Method'),
              const SizedBox(height: 8),
              ...methods.asMap().entries.map((e) => _AUPaymentCard(
                    emoji: e.value[0],
                    name: e.value[1],
                    desc: e.value[2],
                    selected: _method == e.key,
                    selectedColor: kMastersPrimary,
                    onTap: () => setState(() => _method = e.key),
                  )),
              _AUInfoCard(
                title: '🔒 Secure Payment',
                body:
                    'Your payment is encrypted and secure. You will receive a confirmation email once payment is processed.',
                bgColor: kMastersLight,
                borderColor: kMastersPrimary,
                textColor: kMastersDark,
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
        _AUBottomActions(children: [
          _AUPrimaryButton(
            label: 'Pay \$50 Now →',
            color: kMastersPrimary,
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MastersSuccessScreen()),
              (route) => route.isFirst,
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─── M 11: Success ─────────────────────────────────────────────────────────────
class MastersSuccessScreen extends StatelessWidget {
  const MastersSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _SuccessBody(
          emoji: '📚',
          title: 'Application Submitted!',
          body:
              'Your Master\'s application has been received. The admissions committee will review your proposal and notify you within 21 working days.',
          refNumber: 'REF: AU-MSC-2025-0018',
          accentColor: kMastersPrimary,
          accentLight: kMastersLight,
          onDashboard: () => Navigator.pushNamedAndRemoveUntil(
              context, '/masters_dashboard', (_) => false),
          onTrack: () => Navigator.pushNamedAndRemoveUntil(
              context, '/application_progress', (_) => false),
        ),
      ),
    );
  }
}
