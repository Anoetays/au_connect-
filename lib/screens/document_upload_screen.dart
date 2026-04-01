import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/services/application_state.dart';

// ─── color tokens ─────────────────────────────────────────────────────────────
const _kCrimsonLight = AppTheme.primaryCrimson;
const _kInk          = AppTheme.textPrimary;
const _kInkMid       = AppTheme.textSecondary;
const _kParchment    = AppTheme.background;
const _kBorder       = AppTheme.border;
const _kMuted        = AppTheme.textMuted;
const _kGreen        = AppTheme.statusApproved;
const _kGreenPale    = Color(0xFFEBF7F1);

// ─────────────────────────────────────────────────────────────────────────────

class _DocEntry {
  final TextEditingController labelCtrl;
  PlatformFile? file;

  _DocEntry() : labelCtrl = TextEditingController();

  void dispose() => labelCtrl.dispose();
}

// ─────────────────────────────────────────────────────────────────────────────
class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key, this.nextRoute});
  final WidgetBuilder? nextRoute;

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final List<_DocEntry> _entries = [];

  // Verification status from Supabase — keyed by document label
  final Map<String, String?> _verificationStatus = {};
  final Map<String, String?> _verificationNotes = {};
  StreamSubscription<List<Map<String, dynamic>>>? _docSub;

  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _entries.add(_DocEntry()); // start with one card
    _docSub = SupabaseService.streamMyDocuments().listen((rows) {
      if (!mounted) return;
      final statuses = <String, String?>{};
      final notes = <String, String?>{};
      for (final r in rows) {
        final docType =
            r['document_type'] as String? ?? r['file_name'] as String? ?? '';
        statuses[docType] = r['verification_status'] as String?;
        notes[docType] = r['verification_note'] as String?;
      }
      setState(() {
        _verificationStatus
          ..clear()
          ..addAll(statuses);
        _verificationNotes
          ..clear()
          ..addAll(notes);
      });
    });
  }

  @override
  void dispose() {
    _docSub?.cancel();
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  void _addEntry() {
    setState(() => _entries.add(_DocEntry()));
  }

  void _removeEntry(int index) {
    setState(() {
      _entries[index].dispose();
      _entries.removeAt(index);
    });
  }

  Future<void> _pickFile(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _entries[index].file = result.files.first);
  }

  bool _validate() {
    for (final e in _entries) {
      if (e.labelCtrl.text.trim().isEmpty || e.file == null) return false;
    }
    return true;
  }

  Future<void> _handleNext() async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one document.')),
      );
      return;
    }
    if (!_validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Each document card needs a label and a selected file.')),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      // Upload each document to Supabase storage / documents table
      for (final e in _entries) {
        final file = e.file!;
        final label = e.labelCtrl.text.trim();
        await SupabaseService.uploadDocument(
          fileName: file.name,
          documentType: label,
          filePath: file.path ?? '',
        );
      }

      // Mark documents step complete in shared state
      ApplicationState.instance.setDocumentsUploaded(true);

      if (!mounted) return;
      setState(() => _uploading = false);

      if (widget.nextRoute != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: widget.nextRoute!),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kParchment,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildContent(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(children: [
                const Icon(Icons.arrow_back_ios_new,
                    size: 16, color: _kCrimsonLight),
                const SizedBox(width: 6),
                Text('Back',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kCrimsonLight)),
              ]),
            ),
            const Spacer(),
            Text('Upload Documents',
                style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kInk)),
            const Spacer(),
            const SizedBox(width: 60),
          ],
        ),
      ),
    );
  }

  // ── Main Content ──────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Upload Required Documents',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 26,
                  color: _kInk,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add document cards below. Each card needs a label and a file.',
                style:
                    GoogleFonts.dmSans(fontSize: 14, color: _kMuted),
              ),
              const SizedBox(height: 28),

              // Document cards
              ...List.generate(_entries.length, (i) => _buildDocCard(i)),

              // Plus button
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addEntry,
                icon: const Icon(Icons.add_circle_outline,
                    size: 20, color: _kCrimsonLight),
                label: Text(
                  'Add Another Document',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: _kCrimsonLight,
                      fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: _kCrimsonLight, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 32),

              // Next button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _uploading ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kCrimsonLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _uploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white)))
                      : Text(
                          widget.nextRoute != null
                              ? 'Save & Continue'
                              : 'Save Documents',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Document Card ─────────────────────────────────────────────────────────

  Widget _buildDocCard(int index) {
    final entry = _entries[index];
    final label = entry.labelCtrl.text;
    final verif = _verificationStatus[label];
    final note = _verificationNotes[label];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _kParchment,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined,
                    size: 18, color: _kMuted),
                const SizedBox(width: 8),
                Text(
                  'Document ${index + 1}',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kInkMid),
                ),
                const Spacer(),
                if (_entries.length > 1)
                  GestureDetector(
                    onTap: () => _removeEntry(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline,
                          size: 16, color: _kCrimsonLight),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Label field
                Text('Document Name / Label',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kInkMid,
                        letterSpacing: 0.3)),
                const SizedBox(height: 6),
                TextField(
                  controller: entry.labelCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Birth Certificate, Transcript, Passport…',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: _kCrimsonLight, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 14),
                  ),
                ),
                const SizedBox(height: 14),

                // File picker
                Text('File',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kInkMid,
                        letterSpacing: 0.3)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _pickFile(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: entry.file != null
                          ? _kGreenPale
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: entry.file != null
                            ? _kGreen
                            : _kBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          entry.file != null
                              ? Icons.check_circle_outline
                              : Icons.upload_file_outlined,
                          size: 18,
                          color: entry.file != null ? _kGreen : _kMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.file != null
                                ? entry.file!.name
                                : 'Choose File  (PDF, JPG, PNG)',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: entry.file != null
                                  ? _kGreen
                                  : _kMuted,
                              fontWeight: entry.file != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Browse',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kCrimsonLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Verification status chip
                if (verif != null) ...[
                  const SizedBox(height: 10),
                  _buildVerifChip(verif, note),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Verification chip ─────────────────────────────────────────────────────

  Widget _buildVerifChip(String status, String? note) {
    final isVerified =
        status.toLowerCase() == 'verified' || status.toLowerCase() == 'approved';
    final isRejected = status.toLowerCase() == 'rejected';

    Color bg, fg;
    IconData icon;

    if (isVerified) {
      bg = _kGreenPale;
      fg = _kGreen;
      icon = Icons.verified_outlined;
    } else if (isRejected) {
      bg = AppTheme.primaryLight;
      fg = _kCrimsonLight;
      icon = Icons.cancel_outlined;
    } else {
      bg = const Color(0xFFFFF7ED);
      fg = AppTheme.statusPending;
      icon = Icons.hourglass_empty_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            status,
            style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '· $note',
                style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
