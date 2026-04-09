import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:au_connect/models/document.dart';
import 'package:au_connect/providers/application_form_provider.dart';
import 'package:au_connect/services/application_state.dart';
import 'package:au_connect/services/document_service.dart';
import 'package:au_connect/theme/app_theme.dart';

import 'select_program_screen.dart';

// ─── color tokens ─────────────────────────────────────────────────────────────
const _kCrimsonLight = AppTheme.primaryCrimson;
const _kInk          = AppTheme.textPrimary;
const _kInkMid       = AppTheme.textSecondary;
const _kParchment    = AppTheme.background;
const _kBorder       = AppTheme.border;
const _kMuted        = AppTheme.textMuted;
const _kGreen        = AppTheme.statusApproved;
const _kGreenPale    = Color(0xFFEBF7F1);

// ─── keyword hints used for wrong-document detection ──────────────────────────
const _kDocKeywords = <String, List<String>>{
  'transcript':   ['transcript', 'result', 'academic', 'grade', 'mark', 'school'],
  'passport':     ['passport', 'travel', 'document'],
  'birth':        ['birth', 'certificate', 'dob'],
  'id':           ['id', 'identity', 'national'],
  'visa':         ['visa', 'permit', 'immigration'],
  'photo':        ['photo', 'picture', 'selfie', 'portrait'],
  'medical':      ['medical', 'health', 'insurance'],
  'reference':    ['reference', 'recommendation', 'letter'],
  'statement':    ['statement', 'bank', 'finance', 'financial'],
};

// ─────────────────────────────────────────────────────────────────────────────

const _kDocumentTypes = [
  'National ID',
  'Transcript',
  'Birth Certificate',
  'Proof of Residence',
  'Passport Photo',
  'Visa Document',
  'Other',
];

class _DocEntry {
  String? documentType;
  PlatformFile? file;

  _DocEntry();

  void dispose() {}
}

// ─────────────────────────────────────────────────────────────────────────────
class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key, this.nextRoute});
  final WidgetBuilder? nextRoute;

  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  final List<_DocEntry> _entries = [];

  // Verification status from Supabase — keyed by document label
  final Map<String, String?> _verificationStatus = {};
  final Map<String, String?> _verificationNotes = {};
  StreamSubscription<List<Document>>? _docSub;

  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _entries.add(_DocEntry()); // start with one card
    _docSub = DocumentService.streamMyDocuments().listen((rows) {
      if (!mounted) return;
      final statuses = <String, String?>{};
      final notes   = <String, String?>{};
      for (final doc in rows) {
        statuses[doc.documentType] = doc.verificationStatus;
        notes[doc.documentType]    = null;
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
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;

    // ── validate file type ────────────────────────────────────────────────
    final ext = (picked.extension ?? '').toLowerCase();
    if (!['pdf', 'jpg', 'jpeg', 'png'].contains(ext)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Only PDF, JPG and PNG files are accepted. You selected: .$ext'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }

    setState(() => _entries[index].file = picked);

    // ── warn if file name looks wrong for the selected type ───────────────
    final docType = _entries[index].documentType;
    if (docType != null) {
      _checkDocumentMismatch(index, docType.toLowerCase(), picked.name.toLowerCase());
    }
  }

  /// Heuristic: if the file name contains keywords that contradict the label,
  /// show a warning dialog.
  void _checkDocumentMismatch(int index, String label, String fileName) {
    // Find which category the label belongs to
    String? labelCategory;
    for (final entry in _kDocKeywords.entries) {
      if (entry.value.any((kw) => label.contains(kw))) {
        labelCategory = entry.key;
        break;
      }
    }
    if (labelCategory == null) return; // unknown category — skip check

    // Find which category the file name belongs to
    String? fileCategory;
    for (final entry in _kDocKeywords.entries) {
      if (entry.value.any((kw) => fileName.contains(kw))) {
        fileCategory = entry.key;
        break;
      }
    }
    if (fileCategory == null || fileCategory == labelCategory) return;

    // Mismatch detected
    final friendlyLabel = _entries[index].documentType == null
        ? 'this slot'
        : '"${_entries[index].documentType}"';
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange.shade700, size: 22),
              const SizedBox(width: 8),
              const Text('Wrong Document?'),
            ],
          ),
          content: Text(
            'The file "${_entries[index].file!.name}" doesn\'t appear to match $friendlyLabel.\n\n'
            'Please make sure you\'re uploading the correct document.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep It'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kCrimsonLight,
                  foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                setState(() => _entries[index].file = null);
              },
              child: const Text('Remove & Re-upload'),
            ),
          ],
        ),
      );
    }
  }

  bool _validate() {
    for (final e in _entries) {
      if (e.documentType == null || e.file == null) return false;
    }
    return true;
  }

  Future<void> _saveDocuments() async {
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
                'Each document row needs a type selected and a file chosen.')),
      );
      return;
    }

    setState(() => _saving = true);

    final errors = <String>[];
    final uploadedDocuments = <UploadedDocument>[];

    for (final e in _entries) {
      try {
        final url = await DocumentService.uploadDocument(
          fileName: e.file!.name,
          documentType: e.documentType!,
          fileBytes: e.file!.bytes,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException(
              'Upload timed out for "${e.file!.name}". Please try again.'),
        );

        if (url != null) {
          uploadedDocuments.add(UploadedDocument(
            type: e.documentType!,
            fileName: e.file!.name,
            url: url,
            uploadedAt: DateTime.now(),
          ));
        }
      } catch (err) {
        errors.add('${e.documentType ?? 'Document'}: $err');
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Some documents failed to upload:\n${errors.join('\n')}'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 6),
        ),
      );
    } else {
      // Update the global provider with uploaded documents
      ref.read(applicationFormProvider.notifier).updateDocuments(uploadedDocuments);

      ApplicationState.instance.setDocumentsUploaded(true);
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documents saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _goNext() {
    final route = widget.nextRoute ?? (_) => const SelectProgramScreen();
    Navigator.push(context, MaterialPageRoute(builder: route));
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
                'Select a document type and attach a file for each row (PDF, JPG or PNG).',
                style: GoogleFonts.dmSans(fontSize: 14, color: _kMuted),
              ),
              const SizedBox(height: 28),

              // Document cards
              ...List.generate(_entries.length, (i) => _buildDocCard(i)),

              // Add document button
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addEntry,
                icon: const Icon(Icons.add_circle_outline,
                    size: 20, color: _kCrimsonLight),
                label: Text(
                  '+ Add Document',
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

              // Save Documents button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveDocuments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saved ? _kGreen : _kCrimsonLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white)))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _saved
                                  ? Icons.check_circle_outline
                                  : Icons.save_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _saved
                                  ? 'Documents Saved'
                                  : 'Save Documents',
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Next button → Select Programme
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _goNext,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kCrimsonLight,
                    side: const BorderSide(
                        color: _kCrimsonLight, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next: Select Programme',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
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
    final verif = _verificationStatus[entry.documentType ?? ''];
    final note  = _verificationNotes[entry.documentType ?? ''];

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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
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
                // Document type dropdown
                Text('Document Type',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kInkMid,
                        letterSpacing: 0.3)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: entry.documentType != null
                          ? _kCrimsonLight
                          : _kBorder,
                      width: entry.documentType != null ? 1.5 : 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: entry.documentType,
                      isExpanded: true,
                      hint: Text(
                        'Select document type…',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: _kMuted),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: _kMuted),
                      items: _kDocumentTypes
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 13, color: _kInk)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => entry.documentType = val);
                      },
                    ),
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
                          color: entry.file != null
                              ? _kGreen
                              : _kMuted,
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
        status.toLowerCase() == 'verified' ||
        status.toLowerCase() == 'approved';
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
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: _kMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
