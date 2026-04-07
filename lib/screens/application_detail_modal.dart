import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:au_connect/theme/app_theme.dart';

const _kRed    = AppTheme.primaryCrimson;
const _kDark   = AppTheme.textPrimary;
const _kMuted  = AppTheme.textMuted;
const _kBorder = Color(0x21B91C1C);
const _kGreen  = AppTheme.statusApproved;
const _kAmber  = AppTheme.statusPending;

/// Opens a full-screen dialog showing all details of an application.
Future<void> showApplicationDetailModal(
  BuildContext context, {
  required String applicationId,
  required String applicantName,
  required VoidCallback onApprove,
  required VoidCallback onReject,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _ApplicationDetailModal(
      applicationId: applicationId,
      applicantName: applicantName,
      onApprove: onApprove,
      onReject: onReject,
    ),
  );
}

class _ApplicationDetailModal extends StatefulWidget {
  final String applicationId;
  final String applicantName;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApplicationDetailModal({
    required this.applicationId,
    required this.applicantName,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_ApplicationDetailModal> createState() => _ApplicationDetailModalState();
}

class _ApplicationDetailModalState extends State<_ApplicationDetailModal> {
  static final _db = Supabase.instance.client;

  Map<String, dynamic>? _app;
  List<Map<String, dynamic>> _docs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Fetch application
      final appRes = await _db
          .from('applications')
          .select()
          .eq('id', widget.applicationId)
          .maybeSingle();

      // Fetch documents
      List<Map<String, dynamic>> docs = [];
      try {
        final docRes = await _db
            .from('documents')
            .select()
            .eq('application_id', widget.applicationId)
            .order('uploaded_at', ascending: false);
        docs = (docRes as List).cast<Map<String, dynamic>>();
      } catch (_) {}

      setState(() {
        _app = appRes != null ? Map<String, dynamic>.from(appRes) : {};
        _docs = docs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _s(String key, [String fallback = '—']) {
    final v = _app?[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 820),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: _kRed))
                    : _error != null
                        ? Center(
                            child: Text('Error: $_error',
                                style: GoogleFonts.dmSans(color: _kRed)))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _section('Personal Information', [
                                  _row('Full Name', _s('applicant_name')),
                                  _row('Preferred Name', _s('preferred_name')),
                                  _row('Email', _s('email')),
                                  _row('Phone', _s('phone')),
                                  _row('Date of Birth', _s('date_of_birth')),
                                  _row('Gender', _s('gender')),
                                  _row('Country / Nationality', _s('nationality')),
                                  _row('Language Preference', _s('language')),
                                ]),
                                const SizedBox(height: 20),
                                _section('Application Details', [
                                  _row('Application ID', _s('application_code', _s('applicant_id'))),
                                  _row('Applicant Type', _s('type')),
                                  _row('Study Level', _s('study_level')),
                                  _row('Field of Study', _s('field_of_study')),
                                  _row('Faculty', _s('faculty')),
                                  _row('Programme', _s('programme')),
                                  _row('School Attended', _s('school_attended')),
                                  _row('Qualifications / Grades', _s('grades')),
                                ]),
                                const SizedBox(height: 20),
                                _section('Financial & Accommodation', [
                                  _row('Financing Method', _s('financing')),
                                  _row('Accommodation', _s('accommodation')),
                                  _row('Payment Method', _s('payment_method')),
                                ]),
                                const SizedBox(height: 20),
                                _section('Accessibility', [
                                  _row('Disability / Needs', _s('disability')),
                                  if (_app?['disability'] != null &&
                                      _app!['disability'].toString().toLowerCase() != 'none' &&
                                      _app!['disability'].toString().isNotEmpty)
                                    _row('Details', _s('disability_detail')),
                                ]),
                                const SizedBox(height: 20),
                                _section('Next of Kin', [
                                  _row('Full Name', _s('kin_name')),
                                  _row('Relationship', _s('kin_relationship')),
                                  _row('Phone', _s('kin_phone')),
                                ]),
                                const SizedBox(height: 20),
                                _section('Application Meta', [
                                  _row('Status', _s('status')),
                                  _row('Submitted', _s('submitted_at')),
                                  _row('Certificate File', _s('certificate_file_name')),
                                ]),
                                if (_docs.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  _docsSection(),
                                ],
                              ],
                            ),
                          ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, _kRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.applicantName,
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 18, color: _kDark, letterSpacing: -0.3),
                ),
                Text(
                  'Full Application Details',
                  style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: _kMuted),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onReject();
              },
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kRed,
                side: const BorderSide(color: _kRed),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onApprove();
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                  color: _kRed, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                  letterSpacing: 0.2)),
        ]),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8F8),
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _kBorder))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: _kMuted, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: _kDark, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _docsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                  color: _kRed, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text('Documents (${_docs.length})',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kDark)),
        ]),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8F8),
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: _docs.map((doc) {
              final status = doc['status']?.toString() ?? 'Pending';
              final statusColor = status == 'Approved' || status == 'Verified'
                  ? _kGreen
                  : status == 'Rejected'
                      ? _kRed
                      : _kAmber;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _kBorder))),
                child: Row(children: [
                  const Icon(Icons.attach_file_rounded,
                      size: 14, color: _kMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc['file_name']?.toString() ?? 'Unknown',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: _kDark)),
                          Text(doc['document_type']?.toString() ?? '',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: _kMuted)),
                        ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(status,
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
