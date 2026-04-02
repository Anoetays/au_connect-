import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/theme/app_theme.dart';

// ── colour tokens ─────────────────────────────────────────────────────────────
const _kRed     = AppTheme.primaryCrimson;
const _kRedDeep = AppTheme.primaryDark;
const _kRedSoft = AppTheme.primaryLight;
const _kRedMid  = Color(0xFFE8C0C8);
const _kDark    = AppTheme.textPrimary;
const _kMuted   = AppTheme.textMuted;
const _kBorder  = Color(0x21B91C1C);
const _kGreen   = AppTheme.statusApproved;
const _kAmber   = AppTheme.statusPending;
const _kBlue    = AppTheme.statusReview;
const _kPurple  = Color(0xFF7040BB);

// ── data model ────────────────────────────────────────────────────────────────
enum _DocStatus  { pending, underReview, verified, rejected }
enum _FileType   { pdf, image, word }

class _DocEntry {
  final String id;
  final String fileName, fileSize, fileExt;
  final String applicantName, applicantId;
  final String docType, applicantType;
  final String uploadedDate, timeAgo;
  final _DocStatus status;
  final _FileType fileType;
  const _DocEntry({
    required this.id,
    required this.fileName, required this.fileSize, required this.fileExt,
    required this.applicantName, required this.applicantId,
    required this.docType, required this.applicantType,
    required this.uploadedDate, required this.timeAgo,
    required this.status, required this.fileType,
  });
}


// ── page widget ───────────────────────────────────────────────────────────────
class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});
  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final _searchCtrl = TextEditingController();
  String _tab           = 'All';
  String _typeFilter    = 'All Types';
  String _statusFilter  = 'All Statuses';
  String _appTypeFilter = 'All Applicant Types';
  bool   _showAlert     = true;
  int    _page          = 1;
  final Set<String> _selected = {};
  static const _perPage = 5;

  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = SupabaseService.streamAllDocuments().listen((rows) {
      setState(() { _rows = rows; _loading = false; });
    }, onError: (_) => setState(() => _loading = false));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Map a Supabase row to the local display model.
  _DocEntry _toEntry(Map<String, dynamic> r) {
    final statusStr = (r['status'] as String? ?? 'Pending');
    final status = switch (statusStr) {
      'Verified'     => _DocStatus.verified,
      'Rejected'     => _DocStatus.rejected,
      'Under Review' => _DocStatus.underReview,
      _              => _DocStatus.pending,
    };
    final fileName = r['file_name'] as String? ?? '';
    final ext = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : 'FILE';
    final fileType = switch (ext) {
      'PDF'                         => _FileType.pdf,
      'JPG' || 'JPEG' || 'PNG'      => _FileType.image,
      'DOC' || 'DOCX'               => _FileType.word,
      _                             => _FileType.pdf,
    };
    final uploaded = r['uploaded_at'] as String?;
    String uploadedDate = '';
    String timeAgo = '';
    if (uploaded != null) {
      final dt = DateTime.tryParse(uploaded)?.toLocal();
      if (dt != null) {
        const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        uploadedDate = '${mo[dt.month-1]} ${dt.day}, ${dt.year}';
        final diff = DateTime.now().difference(dt);
        timeAgo = diff.inDays == 0 ? 'Today'
            : diff.inDays == 1 ? 'Yesterday'
            : '${diff.inDays} days ago';
      }
    }
    return _DocEntry(
      fileName: fileName,
      fileSize: r['file_size'] as String? ?? '',
      fileExt: ext,
      applicantName: r['applicant_name'] as String? ?? '',
      applicantId: r['applicant_id'] as String? ?? '',
      docType: r['document_type'] as String? ?? '',
      applicantType: r['nationality_type'] as String? ?? '',
      uploadedDate: uploadedDate,
      timeAgo: timeAgo,
      status: status,
      fileType: fileType,
      id: r['id'] as String? ?? '',
    );
  }

  List<_DocEntry> get _docs => _rows.map(_toEntry).toList();

  List<_DocEntry> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    return _docs.where((d) {
      final matchTab = _tab == 'All' ||
          (_tab == 'Pending'      && d.status == _DocStatus.pending)      ||
          (_tab == 'Under Review' && d.status == _DocStatus.underReview)  ||
          (_tab == 'Verified'     && d.status == _DocStatus.verified)     ||
          (_tab == 'Rejected'     && d.status == _DocStatus.rejected);
      final matchType   = _typeFilter == 'All Types'     || d.docType == _typeFilter;
      final matchStatus = _statusFilter == 'All Statuses' ||
          (_statusFilter == 'Pending'      && d.status == _DocStatus.pending)     ||
          (_statusFilter == 'Under Review' && d.status == _DocStatus.underReview) ||
          (_statusFilter == 'Verified'     && d.status == _DocStatus.verified)    ||
          (_statusFilter == 'Rejected'     && d.status == _DocStatus.rejected);
      final matchApp    = _appTypeFilter == 'All Applicant Types' ||
          d.applicantType == _appTypeFilter;
      final matchQ      = q.isEmpty ||
          d.applicantName.toLowerCase().contains(q) ||
          d.applicantId.toLowerCase().contains(q)   ||
          d.docType.toLowerCase().contains(q)        ||
          d.fileName.toLowerCase().contains(q);
      return matchTab && matchType && matchStatus && matchApp && matchQ;
    }).toList();
  }

  int _tabCount(String tab) {
    final all = _docs;
    if (tab == 'All')          return all.length;
    if (tab == 'Pending')      return all.where((d) => d.status == _DocStatus.pending).length;
    if (tab == 'Under Review') return all.where((d) => d.status == _DocStatus.underReview).length;
    if (tab == 'Verified')     return all.where((d) => d.status == _DocStatus.verified).length;
    if (tab == 'Rejected')     return all.where((d) => d.status == _DocStatus.rejected).length;
    return 0;
  }

  // Stat values derived from live data.
  String get _statTotal      => '${_rows.length}';
  String get _statPending    => '${_rows.where((r) => r['status'] == 'Pending').length}';
  String get _statVerified   => '${_rows.where((r) => r['status'] == 'Verified').length}';
  String get _statRejected   => '${_rows.where((r) => r['status'] == 'Rejected').length}';
  String get _statToday {
    final today = DateTime.now();
    return '${_rows.where((r) {
      final dt = DateTime.tryParse(r['uploaded_at'] as String? ?? '');
      return dt != null && dt.year == today.year && dt.month == today.month && dt.day == today.day;
    }).length}';
  }

  @override
  Widget build(BuildContext context) {
    final all   = _filtered;
    final total = all.length;
    final pages = (total / _perPage).ceil().clamp(1, 99);
    final page  = _page.clamp(1, pages);
    final start = (page - 1) * _perPage;
    final end   = (start + _perPage).clamp(0, total);
    final visible = all.sublist(start, end);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kRed));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 64),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildHeader(),
        const SizedBox(height: 14),
        if (_showAlert) _buildAlert(),
        if (_showAlert) const SizedBox(height: 14),
        _buildStatStrip(),
        const SizedBox(height: 14),
        _buildToolbar(),
        const SizedBox(height: 10),
        _buildTabs(),
        const SizedBox(height: 10),
        _buildTable(visible, start + 1, end, total, page, pages),
      ]),
    );
  }

  // ── actions ────────────────────────────────────────────────────────────────

  void _exportCsv() {
    final lines = ['ID,Applicant,Doc Type,Status,Uploaded'];
    for (final d in _filtered) {
      lines.add('"${d.applicantId}","${d.applicantName}","${d.docType}","${d.status.name}","${d.uploadedDate}"');
    }
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV copied to clipboard')));
  }

  Future<void> _showBulkVerifyDialog() async {
    final pending = _filtered
        .where((d) => d.status == _DocStatus.pending || d.status == _DocStatus.underReview)
        .toList();
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending documents to verify')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bulk Verify', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Verify all ${pending.length} pending/under-review documents?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verify All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      for (final d in pending) {
        try {
          await SupabaseService.verifyDocument(d.id);
        } catch (_) {}
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pending.length} documents verified'))); }
    }
  }

  Future<void> _showRequestDocumentsDialog() async {
    final emailCtrl = TextEditingController();
    final msgCtrl   = TextEditingController(
        text: 'Please upload the required documents to complete your application.');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Documents', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Applicant Email', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: msgCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Message', border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              // Log the request as an audit entry
              try {
                final user = SupabaseService.currentUser;
                await SupabaseService.insertAuditLog(
                  adminName: user?.email ?? 'Admin',
                  adminRole: 'Admin',
                  actionType: 'Document Request',
                  description: 'Requested documents from $email',
                  targetId: email,
                  targetType: 'Applicant',
                );
              } catch (_) {}
              if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Document request sent to $email'))); }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
    emailCtrl.dispose();
    msgCtrl.dispose();
  }

  // ── header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Documents', style: GoogleFonts.dmSerifDisplay(
          fontSize: 24, fontWeight: FontWeight.w900,
          color: _kRed, fontStyle: FontStyle.italic, letterSpacing: -0.3)),
        const SizedBox(height: 3),
        Text('Verify and manage applicant uploaded documents.',
          style: GoogleFonts.dmSans(fontSize: 12.5, color: _kMuted, fontWeight: FontWeight.w300)),
      ])),
      const SizedBox(width: 12),
      Wrap(spacing: 8, children: [
        _OutlineBtn(icon: Icons.download_outlined,        label: 'Export',            onTap: _exportCsv),
        _OutlineBtn(icon: Icons.checklist_rounded,        label: 'Bulk Verify',       onTap: _showBulkVerifyDialog),
        _PrimaryBtn(icon: Icons.upload_file_outlined,     label: 'Request Documents', onTap: _showRequestDocumentsDialog),
      ]),
    ]);
  }

  // ── amber alert ────────────────────────────────────────────────────────────
  Widget _buildAlert() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x10C07010), Color(0x04C07010)]),
        border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            border: Border.all(color: const Color(0xFFFFCC80)),
            borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.info_outline_rounded, size: 13, color: _kAmber),
        ),
        const SizedBox(width: 10),
        Expanded(child: RichText(text: TextSpan(
          style: GoogleFonts.dmSans(fontSize: 12.5, color: _kDark),
          children: [
            TextSpan(text: '12 documents', style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600, color: _kAmber)),
            const TextSpan(text: ' are awaiting verification. Unverified documents may delay application processing.'),
          ],
        ))),
        const SizedBox(width: 10),
        _AlertCta(label: 'Review Now', onTap: () => setState(() => _showAlert = false)),
      ]),
    );
  }

  // ── stat strip ─────────────────────────────────────────────────────────────
  Widget _buildStatStrip() {
    return LayoutBuilder(builder: (_, cs) {
      final cols = cs.maxWidth >= 700 ? 5 : cs.maxWidth >= 500 ? 3 : 2;
      final w = (cs.maxWidth - 12.0 * (cols - 1)) / cols;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(width: w, child: _DocStatChip(
          iconBg: _kRedSoft, iconBorder: _kRedMid, iconColor: _kRed,
          icon: Icons.description_outlined, value: _statTotal, label: 'Total Documents')),
        SizedBox(width: w, child: _DocStatChip(
          iconBg: const Color(0xFFFFF3E0), iconBorder: const Color(0xFFFFCC80),
          iconColor: _kAmber,
          icon: Icons.info_outline_rounded, value: _statPending, label: 'Pending Review')),
        SizedBox(width: w, child: _DocStatChip(
          iconBg: const Color(0xFFE8F5EE), iconBorder: const Color(0xFFAADDBB),
          iconColor: _kGreen,
          icon: Icons.check_rounded, value: _statVerified, label: 'Verified')),
        SizedBox(width: w, child: _DocStatChip(
          iconBg: _kRedSoft, iconBorder: _kRedMid, iconColor: _kRed,
          icon: Icons.close_rounded, value: _statRejected, label: 'Rejected')),
        SizedBox(width: w, child: _DocStatChip(
          iconBg: const Color(0xFFEFE8F5), iconBorder: const Color(0xFFCCBBEE),
          iconColor: _kPurple,
          icon: Icons.upload_outlined, value: _statToday, label: 'Uploaded Today')),
      ]);
    });
  }

  // ── toolbar ────────────────────────────────────────────────────────────────
  Widget _buildToolbar() {
    return LayoutBuilder(builder: (_, cs) {
      final wide = cs.maxWidth >= 700;
      final search = _DocSearchField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() => _page = 1),
      );
      final drops = [
        _DocDrop(value: _typeFilter, items: const [
          'All Types','Transcript','National ID','Passport',
          'Birth Certificate','Medical Report','Research Proposal'],
          onChanged: (v) { if (v != null) setState(() { _typeFilter = v; _page = 1; }); }),
        _DocDrop(value: _statusFilter, items: const [
          'All Statuses','Pending','Under Review','Verified','Rejected'],
          onChanged: (v) { if (v != null) setState(() { _statusFilter = v; _page = 1; }); }),
        _DocDrop(value: _appTypeFilter, items: const [
          'All Applicant Types','Local','International','Masters / PG','Re-admission'],
          onChanged: (v) { if (v != null) setState(() { _appTypeFilter = v; _page = 1; }); }),
      ];
      if (wide) {
        return Row(children: [
          Expanded(child: search),
          ...drops.map((d) => Padding(padding: const EdgeInsets.only(left: 8), child: d)),
        ]);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        search,
        const SizedBox(height: 8),
        Row(children: drops
          .asMap().entries.map((e) => Expanded(child: Padding(
            padding: EdgeInsets.only(left: e.key > 0 ? 8 : 0), child: e.value)))
          .toList()),
      ]);
    });
  }

  // ── tabs ───────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    const tabs = ['All', 'Pending', 'Under Review', 'Verified', 'Rejected'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: tabs.map((t) => _DocTab(
          label: t, count: _tabCount(t), active: _tab == t,
          onTap: () => setState(() { _tab = t; _page = 1; }),
        )).toList()),
      ),
    );
  }

  // ── table ──────────────────────────────────────────────────────────────────
  Widget _buildTable(List<_DocEntry> rows, int from, int to, int total, int page, int pages) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: Column(children: [
          // ── header row ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x05C41E3A), Colors.transparent]),
              border: Border(bottom: BorderSide(color: _kBorder))),
            child: _TableRow(
              isHeader: true,
              checkbox: Checkbox(
                value: _docs.isNotEmpty && _selected.length == _docs.length,
                tristate: _selected.isNotEmpty && _selected.length < _docs.length,
                onChanged: (v) => setState(() => v == true
                    ? _selected.addAll(_docs.map((d) => d.id))
                    : _selected.clear()),
                side: const BorderSide(color: _kRedMid, width: 1.5),
                activeColor: _kRed,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              col1: _Th('Document', sorted: true),
              col2: _Th('Applicant'),
              col3: _Th('Type'),
              col4: _Th('Uploaded'),
              col5: _Th('Status'),
              col6: _Th('Actions'),
            ),
          ),
          // ── data rows ────────────────────────────────────────────────────
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No documents match your filters.',
                style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted))),
            )
          else
            ...rows.asMap().entries.map((e) => _DocRow(
              doc: e.value,
              isLast: e.key == rows.length - 1,
              selected: _selected.contains(e.value.id),
              onSelect: (v) => setState(() => v == true
                  ? _selected.add(e.value.id)
                  : _selected.remove(e.value.id)),
              onAction: (action, docId, newStatus) async {
                if (newStatus == 'Verified') {
                  await SupabaseService.verifyDocument(docId);
                } else if (newStatus == 'Rejected') {
                  // Show rejection reason dialog
                  if (!mounted) return;
                  final reasonCtrl = TextEditingController();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Reject Document',
                        style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: _kDark)),
                      content: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('Provide a reason for rejecting this document:',
                          style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: reasonCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'e.g. Document is blurry or invalid',
                            hintStyle: GoogleFonts.dmSans(color: _kMuted, fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: _kRed)),
                          ),
                        ),
                      ]),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: GoogleFonts.dmSans(color: _kMuted))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: _kRed),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Reject', style: GoogleFonts.dmSans(color: Colors.white))),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  await SupabaseService.rejectDocument(docId,
                      reason: reasonCtrl.text.trim().isEmpty
                          ? 'Rejected by admin'
                          : reasonCtrl.text.trim());
                  reasonCtrl.dispose();
                } else if (newStatus != null) {
                  await SupabaseService.updateDocumentStatus(docId, newStatus);
                }
                if (newStatus != null) {
                  try {
                    await SupabaseService.insertAuditLog(
                      adminName: SupabaseService.currentUser?.email ?? 'Admin',
                      adminRole: 'Admin',
                      actionType: action,
                      description: '$action — ${e.value.fileName}',
                      targetId: docId,
                      targetType: 'Document',
                    );
                    await SupabaseService.insertNotification(
                      title: 'Document $newStatus',
                      message: '${e.value.fileName} has been $newStatus.',
                      type: 'Documents',
                    );
                  } catch (_) {}
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(action),
                    duration: const Duration(seconds: 1),
                    backgroundColor: newStatus == 'Verified' ? _kGreen : _kDark));
                }
              },
            )),
          // ── pagination ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kBorder))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(text: TextSpan(
                  style: GoogleFonts.dmSans(fontSize: 11.5, color: _kMuted,
                    fontWeight: FontWeight.w300),
                  children: [
                    const TextSpan(text: 'Showing '),
                    TextSpan(text: '$from–$to',
                      style: GoogleFonts.dmSans(color: _kDark, fontWeight: FontWeight.w500)),
                    const TextSpan(text: ' of '),
                    TextSpan(text: '$total',
                      style: GoogleFonts.dmSans(color: _kDark, fontWeight: FontWeight.w500)),
                    const TextSpan(text: ' documents'),
                  ],
                )),
                Row(children: [
                  _PgBtn(icon: Icons.chevron_left_rounded,
                    onTap: page > 1 ? () => setState(() => _page = page - 1) : null),
                  for (int i = 1; i <= pages.clamp(1, 5); i++)
                    _PgBtn(label: '$i', active: i == page,
                      onTap: () => setState(() => _page = i)),
                  _PgBtn(icon: Icons.chevron_right_rounded,
                    onTap: page < pages ? () => setState(() => _page = page + 1) : null),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── _DocRow ───────────────────────────────────────────────────────────────────
typedef _OnAction = Future<void> Function(String action, String docId, String? newStatus);

class _DocRow extends StatefulWidget {
  final _DocEntry doc;
  final bool isLast, selected;
  final ValueChanged<bool?> onSelect;
  final _OnAction onAction;
  const _DocRow({
    required this.doc, required this.isLast,
    required this.selected, required this.onSelect, required this.onAction,
  });
  @override
  State<_DocRow> createState() => _DocRowState();
}

class _DocRowState extends State<_DocRow> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final d = widget.doc;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hover ? _kRedSoft : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: _hover ? _kRed : Colors.transparent, width: 3),
            bottom: BorderSide(
              color: widget.isLast ? Colors.transparent : const Color(0x0DC41E3A)),
          ),
        ),
        child: _TableRow(
          isHeader: false,
          checkbox: Checkbox(
            value: widget.selected,
            onChanged: widget.onSelect,
            side: const BorderSide(color: _kRedMid, width: 1.5),
            activeColor: _kRed,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          col1: _DocCell(doc: d, hover: _hover),
          col2: _TwoLine(top: d.applicantName, bottom: d.applicantId),
          col3: _TwoLine(top: d.docType, bottom: d.applicantType),
          col4: _TwoLine(top: d.uploadedDate, bottom: d.timeAgo),
          col5: _StatusPill(status: d.status),
          col6: _ActionRow(doc: d, onAction: widget.onAction),
        ),
      ),
    );
  }
}

// ── _TableRow ─────────────────────────────────────────────────────────────────
// Reusable row with consistent column proportions
class _TableRow extends StatelessWidget {
  final bool isHeader;
  final Widget checkbox, col1, col2, col3, col4, col5, col6;
  const _TableRow({
    required this.isHeader,
    required this.checkbox, required this.col1, required this.col2,
    required this.col3, required this.col4, required this.col5, required this.col6,
  });
  @override
  Widget build(BuildContext context) {
    final vPad = isHeader ? 0.0 : 10.0;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isHeader ? 0 : 3, vertical: vPad),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 924,
          child: Row(children: [
            SizedBox(width: 28, child: checkbox),
            const SizedBox(width: 8),
            SizedBox(width: 220, child: col1),
            const SizedBox(width: 8),
            SizedBox(width: 150, child: col2),
            const SizedBox(width: 8),
            SizedBox(width: 120, child: col3),
            const SizedBox(width: 8),
            SizedBox(width: 110, child: col4),
            const SizedBox(width: 8),
            SizedBox(width: 90, child: col5),
            const SizedBox(width: 8),
            SizedBox(width: 164, child: col6),
          ]),
        ),
      ),
    );
  }
}

// ── table cell components ─────────────────────────────────────────────────────
class _Th extends StatelessWidget {
  final String label;
  final bool sorted;
  const _Th(this.label, {this.sorted = false});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label.toUpperCase(), style: GoogleFonts.dmSans(
      fontSize: 9.5, fontWeight: FontWeight.w600,
      letterSpacing: 0.8, color: sorted ? _kRed : _kMuted)),
    if (sorted) ...[
      const SizedBox(width: 3),
      Icon(Icons.keyboard_arrow_down_rounded, size: 11, color: _kRed),
    ],
  ]);
}

class _DocCell extends StatelessWidget {
  final _DocEntry doc;
  final bool hover;
  const _DocCell({required this.doc, required this.hover});
  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color icon) = switch (doc.fileType) {
      _FileType.pdf   => (_kRedSoft,              _kRedMid,              _kRed),
      _FileType.image => (const Color(0xFFEAF0FF), const Color(0xFFC0CCFF), _kBlue),
      _FileType.word  => (const Color(0xFFEFE8F5), const Color(0xFFCCBBEE), _kPurple),
    };
    final icn = switch (doc.fileType) {
      _FileType.pdf   => Icons.picture_as_pdf_outlined,
      _FileType.image => Icons.image_outlined,
      _FileType.word  => Icons.article_outlined,
    };
    return Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: hover ? Matrix4.diagonal3Values(1.08, 1.08, 1) : Matrix4.identity(),
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: bg, border: Border.all(color: border),
          borderRadius: BorderRadius.circular(9)),
        child: Icon(icn, size: 16, color: icon),
      ),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(doc.fileName, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: _kDark)),
        Text('${doc.fileSize} · ${doc.fileExt}',
          style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted, fontWeight: FontWeight.w300)),
      ])),
    ]);
  }
}

class _TwoLine extends StatelessWidget {
  final String top, bottom;
  const _TwoLine({required this.top, required this.bottom});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(top, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: GoogleFonts.dmSans(fontSize: 12.5, color: _kDark)),
      Text(bottom, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  final _DocStatus status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg, Color border) = switch (status) {
      _DocStatus.pending     => ('Pending',      const Color(0xFFFFF3E0), _kAmber,  const Color(0xFFFFCC80)),
      _DocStatus.underReview => ('Under Review', const Color(0xFFEAF0FF), _kBlue,   const Color(0xFFC0CCFF)),
      _DocStatus.verified    => ('Verified',     const Color(0xFFE8F5EE), _kGreen,  const Color(0xFFAADDBB)),
      _DocStatus.rejected    => ('Rejected',     _kRedSoft,               _kRed,    _kRedMid),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 4, height: 4,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fg)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 9.5, fontWeight: FontWeight.w600,
          letterSpacing: 0.5, color: fg)),
      ]),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final _DocEntry doc;
  final _OnAction onAction;
  const _ActionRow({required this.doc, required this.onAction});
  @override
  Widget build(BuildContext context) => Row(children: [
    _QBtn(Icons.visibility_outlined,        'View',     onTap: () => onAction('Viewed', doc.id, null)),
    const SizedBox(width: 4),
    _QBtn(Icons.check_rounded,              'Verify',   isGreen: true,
        onTap: () => onAction('Verified', doc.id, 'Verified')),
    const SizedBox(width: 4),
    _QBtn(Icons.download_outlined,          'Download', onTap: () => onAction('Downloaded', doc.id, null)),
    const SizedBox(width: 4),
    _QBtn(Icons.close_rounded,              'Reject',   onTap: () => onAction('Rejected', doc.id, 'Rejected')),
    const SizedBox(width: 4),
    _QBtn(Icons.chat_bubble_outline_rounded,'Note',     onTap: () => onAction('Note added', doc.id, null)),
  ]);
}

// ── reusable small widgets ────────────────────────────────────────────────────
class _QBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isGreen;
  final VoidCallback onTap;
  const _QBtn(this.icon, this.tooltip, {this.isGreen = false, required this.onTap});
  @override
  State<_QBtn> createState() => _QBtnState();
}

class _QBtnState extends State<_QBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final hoverBg     = widget.isGreen ? const Color(0xFFE8F5EE) : _kRedSoft;
    final hoverBorder = widget.isGreen ? const Color(0xFF1E8A4A) : _kRed;
    final hoverIcon   = widget.isGreen ? const Color(0xFF1E8A4A) : _kRed;
    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      textStyle: GoogleFonts.dmSans(fontSize: 10, color: Colors.white),
      decoration: BoxDecoration(color: _kDark, borderRadius: BorderRadius.circular(5)),
      child: MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit:  (_) => setState(() => _h = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _h ? hoverBg : Colors.white,
              border: Border.all(color: _h ? hoverBorder : _kBorder, width: 1.5),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(widget.icon, size: 12, color: _h ? hoverIcon : _kMuted),
          ),
        ),
      ),
    );
  }
}

class _DocStatChip extends StatefulWidget {
  final Color iconBg, iconBorder, iconColor;
  final IconData icon;
  final String value, label;
  const _DocStatChip({
    required this.iconBg, required this.iconBorder, required this.iconColor,
    required this.icon,   required this.value,      required this.label,
  });
  @override
  State<_DocStatChip> createState() => _DocStatChipState();
}

class _DocStatChipState extends State<_DocStatChip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit:  (_) => setState(() => _h = false),
    cursor: SystemMouseCursors.click,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: _h ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _h ? _kRed.withValues(alpha: 0.28) : _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: _h ? const Color(0x10C41E3A) : const Color(0x04C41E3A),
          blurRadius: _h ? 24 : 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: widget.iconBg,
            border: Border.all(color: widget.iconBorder),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(widget.icon, size: 15, color: widget.iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.value, style: GoogleFonts.dmSerifDisplay(
            fontSize: 18, fontWeight: FontWeight.w900,
            color: _kDark, letterSpacing: -0.3, height: 1.1)),
          Text(widget.label, style: GoogleFonts.dmSans(
            fontSize: 10.5, color: _kMuted, fontWeight: FontWeight.w300)),
        ])),
      ]),
    ),
  );
}

class _DocTab extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _DocTab({required this.label, required this.count, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Transform.translate(
      offset: const Offset(0, 1),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
            color: active ? _kRed : Colors.transparent, width: 2))),
        child: Row(children: [
          Text(label, style: GoogleFonts.dmSans(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w500 : FontWeight.w400,
            color: active ? _kRed : _kMuted)),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: active ? _kRed : _kRedSoft,
              border: Border.all(color: active ? _kRed : _kRedMid),
              borderRadius: BorderRadius.circular(20)),
            child: Text('$count', style: GoogleFonts.dmSans(
              fontSize: 9.5, fontWeight: FontWeight.w600,
              color: active ? Colors.white : _kRed)),
          ),
        ]),
      ),
    ),
  );
}

class _AlertCta extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _AlertCta({required this.label, required this.onTap});
  @override
  State<_AlertCta> createState() => _AlertCtaState();
}

class _AlertCtaState extends State<_AlertCta> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit:  (_) => setState(() => _h = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _h ? _kRedMid : _kRedSoft,
          border: Border.all(color: _kRedMid),
          borderRadius: BorderRadius.circular(6)),
        child: Text(widget.label, style: GoogleFonts.dmSans(
          fontSize: 11.5, fontWeight: FontWeight.w500, color: _kRed)),
      ),
    ),
  );
}

class _DocSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _DocSearchField({required this.controller, required this.onChanged});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    style: GoogleFonts.dmSans(fontSize: 13, color: _kDark),
    decoration: InputDecoration(
      hintText: 'Search by applicant name, ID or document type…',
      hintStyle: GoogleFonts.dmSans(fontSize: 12.5, color: const Color(0xFFC8B8BB)),
      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: _kMuted),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _kBorder, width: 1.5)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _kBorder, width: 1.5)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _kRed, width: 1.5)),
      filled: true, fillColor: Colors.white,
    ),
  );
}

class _DocDrop extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _DocDrop({required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _kBorder, width: 1.5),
      borderRadius: BorderRadius.circular(11)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value, isDense: true,
        style: GoogleFonts.dmSans(fontSize: 12.5, color: _kDark),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _kMuted),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

class _PrimaryBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.icon, required this.label, required this.onTap});
  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit:  (_) => setState(() => _h = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _h ? Matrix4.translationValues(0, -1, 0) : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kRed, _kRedDeep],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(
            color: _h ? const Color(0x60C41E3A) : const Color(0x40C41E3A),
            blurRadius: _h ? 20 : 14, offset: const Offset(0, 4))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(widget.label, style: GoogleFonts.dmSans(
            fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.white)),
        ]),
      ),
    ),
  );
}

class _OutlineBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.onTap});
  @override
  State<_OutlineBtn> createState() => _OutlineBtnState();
}

class _OutlineBtnState extends State<_OutlineBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit:  (_) => setState(() => _h = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _h ? _kRed : _kBorder, width: 1.5),
          borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, size: 13, color: _h ? _kRed : _kDark),
          const SizedBox(width: 5),
          Text(widget.label, style: GoogleFonts.dmSans(
            fontSize: 12.5, color: _h ? _kRed : _kDark)),
        ]),
      ),
    ),
  );
}

class _PgBtn extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final bool active;
  final VoidCallback? onTap;
  const _PgBtn({this.label, this.icon, this.active = false, this.onTap});
  @override
  State<_PgBtn> createState() => _PgBtnState();
}

class _PgBtnState extends State<_PgBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final lit = widget.active || _h;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: lit ? _kRed : Colors.white,
            border: Border.all(color: lit ? _kRed : _kBorder, width: 1.5),
            borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: widget.icon != null
                ? Icon(widget.icon, size: 13, color: lit ? Colors.white : _kMuted)
                : Text(widget.label ?? '', style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: lit ? Colors.white : _kMuted)),
          ),
        ),
      ),
    );
  }
}
