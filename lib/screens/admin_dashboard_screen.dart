import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:au_connect/services/export_csv.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/screens/programmes_screen.dart';
import 'package:au_connect/screens/documents_screen.dart';
import 'package:au_connect/screens/users_staff_screen.dart';
import 'package:au_connect/screens/notifications_screen.dart';
import 'package:au_connect/screens/announcements_screen.dart';
import 'package:au_connect/screens/interviews_screen.dart';
import 'package:au_connect/screens/reports_screen.dart';
import 'package:au_connect/screens/audit_log_screen.dart';
import 'package:au_connect/l10n/app_localizations.dart';

// ── colour tokens ─────────────────────────────────────────────────────────────
const _kRed     = AppTheme.primaryCrimson;
const _kRedDeep = AppTheme.primaryDark;
const _kRedSoft = AppTheme.primaryLight;
const _kRedMid  = Color(0xFFE8C0C8);
const _kDark    = AppTheme.textPrimary;
const _kMuted   = AppTheme.textMuted;
const _kBorder  = Color(0x21B91C1C);
const _kBg      = AppTheme.background;
const _kGreen   = AppTheme.statusApproved;
const _kAmber   = AppTheme.statusPending;
const _kBlue    = AppTheme.statusReview;

const _kSidebarW   = 220.0;
const _kBreakpoint = 800.0;

// ── data models ───────────────────────────────────────────────────────────────
enum _AppStatus { pending, review, approved, rejected }

String _fmtDate(DateTime dt) {
  const mo = ['Jan','Feb','Mar','Apr','May','Jun',
               'Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${mo[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String _timeAgo(DateTime dt) {
  final d = DateTime.now().difference(dt);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inHours < 1)   return '${d.inMinutes} min ago';
  if (d.inDays < 1)    return '${d.inHours} hr${d.inHours > 1 ? "s" : ""} ago';
  if (d.inDays < 7)    return '${d.inDays} day${d.inDays > 1 ? "s" : ""} ago';
  return _fmtDate(dt);
}

String _s(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  final text = v.toString();
  return text.isEmpty ? fallback : text;
}

DateTime _dt(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString()) ?? DateTime.now();
}

// Returns 1–2 uppercase initials from the admin's name or email.
String _adminInitials() {
  final user = SupabaseService.currentUser;
  final fullName = _s(user?.userMetadata?['full_name']);
  if (fullName.isNotEmpty) {
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
  final email = user?.email ?? '';
  final local = email.split('@').first;
  final parts = local.split(RegExp(r'[._\-+]')).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return local.isNotEmpty ? local[0].toUpperCase() : 'AU';
}

// Returns a friendly display name for the admin.
String _adminDisplayName() {
  final user = SupabaseService.currentUser;
  final fullName = _s(user?.userMetadata?['full_name']);
  if (fullName.isNotEmpty) {
    return fullName.split(' ').first;
  }
  final email = user?.email ?? '';
  final local = email.split('@').first;
  final first = local.split(RegExp(r'[._\-+]')).firstWhere(
    (p) => p.isNotEmpty, orElse: () => 'Admin');
  return first[0].toUpperCase() + first.substring(1).toLowerCase();
}

class _AppEntry {
  final String id; // Supabase UUID
  final String userId; // applicant's auth user_id
  final String initials, name, appId, type, country, programme, faculty,
      submitted, timeAgo;
  final _AppStatus status;
  final Color grad1, grad2;
  const _AppEntry({
    this.id = '',
    this.userId = '',
    required this.initials,
    required this.name,
    required this.appId,
    required this.type,
    required this.country,
    required this.programme,
    required this.faculty,
    required this.submitted,
    required this.timeAgo,
    required this.status,
    required this.grad1,
    required this.grad2,
  });

  factory _AppEntry.fromMap(Map<String, dynamic> m) {
    final name = _s(m['applicant_name']).trim();
    final parts = name.split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';

    final statusStr = _s(m['status'], 'Pending');
    final status = statusStr == 'Approved'    ? _AppStatus.approved
        : statusStr == 'Rejected'             ? _AppStatus.rejected
        : statusStr == 'Under Review'         ? _AppStatus.review
        : _AppStatus.pending;

    final submittedAt = _dt(m['submitted_at']);

    final type = _s(m['type']);
    Color grad1, grad2;
    switch (type.toLowerCase()) {
      case 'international': grad1 = const Color(0xFF3A5FCC); grad2 = const Color(0xFF2040AA); break;
      case 'masters / pg':  grad1 = const Color(0xFF1E8A4A); grad2 = const Color(0xFF145E32); break;
      case 'transfer':      grad1 = const Color(0xFF7040BB); grad2 = const Color(0xFF4E2B88); break;
      case 're-admission':  grad1 = const Color(0xFFC07010); grad2 = const Color(0xFF8A4E0A); break;
      default:              grad1 = _kRed;                   grad2 = _kRedDeep;
    }

    return _AppEntry(
      id:        _s(m['id']),
      userId:    _s(m['user_id']),
      initials:  initials,
      name:      name,
      appId:     _s(m['application_code'] ?? m['applicant_id'], 'AU-????'),
      type:      type,
      country:   _s(m['nationality']),
      programme: _s(m['programme']),
      faculty:   _s(m['faculty']),
      submitted: _fmtDate(submittedAt),
      timeAgo:   _timeAgo(submittedAt),
      status:    status,
      grad1:     grad1,
      grad2:     grad2,
    );
  }
}


// ── main widget ───────────────────────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _navIdx   = 1;
  int _tabIdx   = 0;
  bool _alert   = true;
  final _search = TextEditingController();

  // ── live data ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _liveApps = [];
  bool _dataLoading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _streamSub;

  // ── filter dropdowns ───────────────────────────────────────────────────────
  String _filterStatus    = 'All Statuses';
  String _filterType      = 'All Types';
  String _filterProgramme = 'All Programmes';

  @override
  void initState() {
    super.initState();
    _streamSub = SupabaseService.streamAllApplications().listen((apps) {
      if (mounted) setState(() { _liveApps = apps; _dataLoading = false; });
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _streamSub?.cancel();
    super.dispose();
  }

  // ── computed stats ─────────────────────────────────────────────────────────
  int get _total       => _liveApps.length;
  int get _pending     => _liveApps.where((a) => a['status'] == 'Pending').length;
  int get _underReview => _liveApps.where((a) => a['status'] == 'Under Review').length;
  int get _approved    => _liveApps.where((a) => a['status'] == 'Approved').length;
  int get _rejected    => _liveApps.where((a) => a['status'] == 'Rejected').length;

  int get _thisWeek {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _liveApps.where((a) {
      final dt = DateTime.tryParse(_s(a['submitted_at']));
      return dt != null && dt.isAfter(cutoff);
    }).length;
  }

  List<int> get _weeklyTrends {
    final now = DateTime.now();
    final counts = List.filled(8, 0);
    for (final a in _liveApps) {
      final dt = DateTime.tryParse(_s(a['submitted_at']));
      if (dt == null) continue;
      final weeksAgo = now.difference(dt).inDays ~/ 7;
      if (weeksAgo >= 0 && weeksAgo < 8) counts[7 - weeksAgo]++;
    }
    return counts;
  }

  List<Map<String, dynamic>> get _recentApps {
    final sorted = _liveApps.toList()
      ..sort((a, b) {
        final sa = _s(a['submitted_at']);
        final sb = _s(b['submitted_at']);
        return sb.compareTo(sa);
      });
    return sorted.take(5).toList();
  }

  // counts per applicant type (case-insensitive key)
  Map<String, int> get _byType {
    final counts = <String, int>{};
    for (final a in _liveApps) {
      final t = _s(a['type'], 'Other').trim();
      counts[t] = (counts[t] ?? 0) + 1;
    }
    return counts;
  }

  // top-4 countries by count
  List<(String, int, double)> get _topCountries {
    final counts = <String, int>{};
    for (final a in _liveApps) {
      final c = _s(a['nationality'], 'Unknown').trim();
      if (c.isEmpty) continue;
      counts[c] = (counts[c] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top4 = sorted.take(4).toList();
    final maxVal = top4.isNotEmpty ? top4.first.value : 1;
    return top4.map((e) => (e.key, e.value, e.value / maxVal)).toList();
  }

  // ── filtered table rows ────────────────────────────────────────────────────
  static String _statusStr(_AppStatus s) {
    switch (s) {
      case _AppStatus.pending:  return 'Pending';
      case _AppStatus.review:   return 'Under Review';
      case _AppStatus.approved: return 'Approved';
      case _AppStatus.rejected: return 'Rejected';
    }
  }

  List<_AppEntry> get _filtered {
    const byTab = [null, 'Pending', 'Under Review', 'Approved', 'Rejected'];
    final tabStatus = _tabIdx < byTab.length ? byTab[_tabIdx] : null;
    final q = _search.text.toLowerCase();
    return _liveApps.map(_AppEntry.fromMap).where((a) {
      final st = _statusStr(a.status);
      final matchTab    = tabStatus == null || st == tabStatus;
      final matchStatus = _filterStatus == 'All Statuses' || st == _filterStatus;
      final matchType   = _filterType == 'All Types' || a.type == _filterType;
      final matchProg   = _filterProgramme == 'All Programmes' ||
          a.programme.toLowerCase().contains(_filterProgramme.toLowerCase()) ||
          a.faculty.toLowerCase().contains(_filterProgramme.toLowerCase());
      final matchQ = q.isEmpty ||
          a.name.toLowerCase().contains(q) ||
          a.appId.toLowerCase().contains(q);
      return matchTab && matchStatus && matchType && matchProg && matchQ;
    }).toList();
  }

  // ── export / bulk / add ────────────────────────────────────────────────────

  void _exportCsv(List<_AppEntry> rows) {
    final lines = ['ID,Name,Type,Country,Programme,Faculty,Status,Submitted'];
    for (final a in rows) {
      lines.add('"${a.appId}","${a.name}","${a.type}","${a.country}","${a.programme}","${a.faculty}","${_statusStr(a.status)}","${a.submitted}"');
    }
    final csv = lines.join('\n');
    final now = DateTime.now();
    final fname = 'applications_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';

    try {
      ExportCsv.downloadCsv(csv, fname);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading ${rows.length} applications as CSV…')));
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV export is available on web only.')));
    }
  }

  Future<void> _showAddApplicationDialog() async {
    final firstNameCtrl = TextEditingController();
    final surnameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final natCtrl = TextEditingController();
    String type = 'Local';
    String? selectedProgramme;
    String faculty = '';
    List<PlatformFile> selectedFiles = [];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Add Application', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: surnameCtrl,
                  decoration: const InputDecoration(labelText: 'Surname', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: natCtrl,
                  decoration: const InputDecoration(labelText: 'Nationality', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Applicant Type', border: OutlineInputBorder()),
                  items: ['Local', 'International', 'Masters / PG', 'Transfer', 'Re-Admission']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDlg(() => type = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setDlg(() => selectedProgramme = v),
                  decoration: const InputDecoration(labelText: 'Programme', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setDlg(() => faculty = v),
                  decoration: const InputDecoration(labelText: 'Faculty', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: Text('Documents: ${selectedFiles.length} selected')),
                  TextButton(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                      if (result != null) {
                        setDlg(() => selectedFiles = result.files);
                      }
                    },
                    child: const Text('Select Files'),
                  ),
                ]),
                if (selectedFiles.isNotEmpty)
                  Column(children: selectedFiles.map((f) => Text(f.name)).toList()),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
              onPressed: () async {
                final firstName = firstNameCtrl.text.trim();
                final surname = surnameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (firstName.isEmpty || surname.isEmpty || email.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  final fullName = '$firstName $surname';
                  final id = await SupabaseService.submitApplication(
                    applicantName: fullName,
                    email: email,
                    type: type,
                    programme: selectedProgramme ?? '',
                    faculty: faculty,
                    nationality: natCtrl.text.trim(),
                    phone: phone,
                    source: 'admin_manual',
                  );
                  // Upload documents if any
                  for (final file in selectedFiles) {
                    if (file.bytes != null) {
                      await SupabaseService.uploadDocument(
                        applicationId: id,
                        documentType: 'admin_uploaded',
                        fileName: file.name,
                        fileBytes: file.bytes!,
                      );
                    }
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Application $id added with ${selectedFiles.length} documents')));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Add Application'),
            ),
          ],
        ),
      ),
    );
    firstNameCtrl.dispose();
    surnameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    natCtrl.dispose();
  }

  Future<void> _showBulkActionsDialog() async {
    final pending = _filtered.where((a) => a.status == _AppStatus.pending).toList();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bulk Actions', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${_filtered.length} applications currently visible.'),
          const SizedBox(height: 14),
          ListTile(
            leading: const Icon(Icons.check_circle_outline, color: _kGreen),
            title: Text('Move ${pending.length} Pending → Under Review'),
            onTap: () async {
              Navigator.pop(ctx);
              for (final a in pending) {
                await _setStatus(a.id, 'Under Review');
              }
              if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${pending.length} applications moved to Under Review'))); }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded, color: _kBlue),
            title: const Text('Export visible as CSV'),
            onTap: () {
              Navigator.pop(ctx);
              _exportCsv(_filtered);
            },
          ),
        ]),
      ),
    );
  }

  // ── status change ──────────────────────────────────────────────────────────
  Future<void> _setStatus(String supabaseId, String status) async {
    if (supabaseId.isEmpty) return;
    final user = SupabaseService.currentUser;
    await SupabaseService.updateApplicationStatusWithHistory(
      supabaseId,
      status,
      changedBy: user?.email ?? 'Admin',
    );
    try {
      await SupabaseService.insertAuditLog(
        adminName: user?.email ?? 'Admin',
        adminRole: 'Admin',
        actionType: 'Status Change',
        description: 'Application status set to $status — ID: $supabaseId',
        targetId: supabaseId,
        targetType: 'Application',
      );
    } catch (_) {}
  }

  // ── application action handlers ────────────────────────────────────────────

  /// Dispatch action from table row — routes to typed handlers.
  Future<void> _handleAction(_AppEntry entry, String action) async {
    if (action == 'Approve') {
      await _handleApprove(entry);
    } else if (action == 'Reject' || action == 'Deny') {
      await _handleDeny(entry);
    } else if (action == 'Under Review') {
      await _handleReview(entry);
    } else {
      // Generic status change from popup
      await _setStatus(entry.id, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status → $action: ${entry.name}'),
          duration: const Duration(seconds: 2)));
      }
    }
  }

  Future<void> _handleApprove(_AppEntry entry) async {
    if (entry.id.isEmpty) return;
    try {
      if (entry.userId.isNotEmpty) {
        await SupabaseService.approveApplication(
          applicationId: entry.id,
          applicantUserId: entry.userId,
          applicantName: entry.name,
          programme: entry.programme,
          applicantType: entry.type,
        );
      } else {
        await _setStatus(entry.id, 'Approved');
      }
      // Also send an admin notification for the audit trail
      try {
        await SupabaseService.insertAdminNotification(
          type: 'status_update',
          title: 'Application Approved — ${entry.name}',
          body: '${entry.programme} application (${entry.appId}) has been approved.',
        );
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Application approved: ${entry.name}'),
          backgroundColor: _kGreen,
          duration: const Duration(seconds: 2)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _kRed));
      }
    }
  }

  Future<void> _handleDeny(_AppEntry entry) async {
    if (entry.id.isEmpty) return;
    final reasonCtrl = TextEditingController();
    final suggestedCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _kRedSoft, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.close_rounded, size: 16, color: _kRed)),
          const SizedBox(width: 12),
          Text('Deny Application',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Provide a reason for denying ${entry.name}\'s application.',
              style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason for denial *',
                hintText: 'e.g. Insufficient academic qualifications',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12)),
              style: GoogleFonts.dmSans(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: suggestedCtrl,
              decoration: InputDecoration(
                labelText: 'Suggested programmes (optional)',
                hintText: 'e.g. Diploma in Business Administration',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12)),
              style: GoogleFonts.dmSans(fontSize: 13),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.dmSans())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text('Deny Application', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (entry.userId.isNotEmpty) {
          await SupabaseService.denyApplication(
            applicationId: entry.id,
            applicantUserId: entry.userId,
            reason: reasonCtrl.text.trim(),
            suggestedProgrammes: suggestedCtrl.text.trim().isNotEmpty
                ? suggestedCtrl.text.trim()
                : null,
          );
        } else {
          await _setStatus(entry.id, 'Rejected');
        }
        try {
          await SupabaseService.insertAdminNotification(
            type: 'status_update',
            title: 'Application Denied — ${entry.name}',
            body: '${entry.programme} application (${entry.appId}) denied. Reason: ${reasonCtrl.text.trim()}',
          );
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Application denied: ${entry.name}'),
            backgroundColor: _kRed,
            duration: const Duration(seconds: 2)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: _kRed));
        }
      }
    }
    reasonCtrl.dispose();
    suggestedCtrl.dispose();
  }

  Future<void> _handleReview(_AppEntry entry) async {
    if (entry.id.isEmpty) return;
    try {
      if (entry.userId.isNotEmpty) {
        await SupabaseService.putApplicationUnderReview(
          applicationId: entry.id,
          applicantUserId: entry.userId,
        );
      } else {
        await _setStatus(entry.id, 'Under Review');
      }
      try {
        await SupabaseService.insertAdminNotification(
          type: 'status_update',
          title: 'Application Under Review — ${entry.name}',
          body: '${entry.programme} application (${entry.appId}) moved to under review.',
        );
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🔍 Under review: ${entry.name}'),
          backgroundColor: _kAmber,
          duration: const Duration(seconds: 2)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _kRed));
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout, style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: _kDark)),
        content: Text('Are you sure you want to sign out of the Admin Portal?',
            style: GoogleFonts.dmSans(fontSize: 14, color: _kMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: GoogleFonts.dmSans(color: _kMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kRed, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.logout, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await SupabaseService.signOut();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _kBg,
      body: LayoutBuilder(builder: (context, cs) {
        final wide = cs.maxWidth >= _kBreakpoint;
        return Column(children: [
          // 3-px accent stripe
          Container(height: 3, decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kRedDeep, _kRed, Color(0xFFE85070), _kRed]),
          )),
          Expanded(child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide)
                _Sidebar(
                  selected: _navIdx,
                  onSelect: (i) {
                    if (i == 12) { _showLogoutDialog(); return; }
                    setState(() => _navIdx = i);
                  },
                ),
              Expanded(child: Column(children: [
                _TopBar(subtitle: _navIdx == 0
                    ? '${l10n.dashboard} Overview'
                    : _navIdx == 2 ? 'Students'
                    : _navIdx == 3 ? 'Programmes'
                    : _navIdx == 4 ? l10n.documents
                    : _navIdx == 5 ? 'Users / Staff'
                    : _navIdx == 6 ? l10n.notifications
                    : _navIdx == 7 ? l10n.announcements
                    : _navIdx == 8 ? 'Interviews'
                    : _navIdx == 9 ? 'Reports'
                    : _navIdx == 10 ? 'Audit Log'
                    : _navIdx == 11 ? l10n.settings
                    : '${l10n.application} Review',
                  initials: _adminInitials()),
                Expanded(child: SingleChildScrollView(
                  child: _navIdx == 0
                      ? _buildOverviewContent()
                      : _navIdx == 2
                          ? const StudentsPage()
                          : _navIdx == 3
                              ? const ProgrammesPage()
                              : _navIdx == 4
                                  ? const DocumentsPage()
                                  : _navIdx == 5
                                      ? const UsersStaffPage()
                                      : _navIdx == 6
                                          ? const NotificationsPage()
                                          : _navIdx == 7
                                              ? const AnnouncementsPage()
                                              : _navIdx == 8
                                                  ? const InterviewsPage()
                                                  : _navIdx == 9
                                                      ? const ReportsPage()
                                                      : _navIdx == 10
                                                          ? const AuditLogPage()
                                                          : _navIdx == 11
                                                              ? const AdminSettingsPage()
                                                              : Padding(
                              padding: const EdgeInsets.fromLTRB(22, 18, 22, 64),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_alert) _buildAlert(),
                                  _buildHeader(),
                                  const SizedBox(height: 18),
                                  _buildStatStrip(),
                                  const SizedBox(height: 16),
                                  _buildTwoCol(),
                                  const SizedBox(height: 18),
                                  _buildToolbar(),
                                  const SizedBox(height: 10),
                                  _buildTabs(),
                                  const SizedBox(height: 10),
                                  _buildTable(),
                                  _buildPagination(),
                                ],
                              ),
                            ),
                )),
              ])),
            ],
          )),
        ]);
      }),
    );
  }

  // ── deadline alert ──────────────────────────────────────────────────────────
  Widget _buildAlert() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          _kRed.withValues(alpha: 0.06), _kRed.withValues(alpha: 0.02),
        ]),
        border: Border.all(color: _kRedMid, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: _kRed, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(child: RichText(text: TextSpan(
          style: GoogleFonts.dmSans(fontSize: 13, color: _kDark),
          children: [
            TextSpan(text: 'Deadline approaching: ',
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: _kRed)),
            const TextSpan(text: '2024 Local Applicant intake closes on '),
            TextSpan(text: 'Mar 31, 2025',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: _kRed)),
            const TextSpan(text: '. 89 applications are still pending review.'),
          ],
        ))),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => setState(() => _alert = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Dismiss',
              style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
          ),
        ),
      ]),
    );
  }

  // ── page header ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: l10n.application,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 26, fontWeight: FontWeight.w900,
                color: _kRed, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
            TextSpan(text: ' Review',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 26, fontWeight: FontWeight.w900,
                color: _kDark, letterSpacing: -0.5)),
          ])),
          const SizedBox(height: 4),
          Text('Review and process student applications for 2024 intake.',
            style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted,
                fontWeight: FontWeight.w300)),
        ])),
        const SizedBox(width: 16),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
          _OutlineBtn(label: 'Bulk Actions', icon: Icons.list_rounded, onTap: _showBulkActionsDialog),
          _OutlineBtn(label: 'Export CSV',   icon: Icons.download_rounded, onTap: () => _exportCsv(_filtered)),
          _PrimaryBtn(label: 'Add Application', icon: Icons.add_rounded, onTap: _showAddApplicationDialog),
        ]),
      ],
    );
  }

  // ── stat strip ──────────────────────────────────────────────────────────────
  Widget _buildStatStrip() {
    return LayoutBuilder(builder: (_, cs) {
      final cols = cs.maxWidth >= 560 ? 4 : 2;
      final w = (cs.maxWidth - 12 * (cols - 1)) / cols;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(width: w, child: _StatChip(
          iconBg: _kRedSoft, iconBorder: _kRedMid, icon: Icons.description_outlined,
          iconColor: _kRed, value: '$_total', label: 'Total Applications',
          delta: '↑ $_thisWeek this week', up: true)),
        SizedBox(width: w, child: _StatChip(
          iconBg: const Color(0xFFFFF3E0), iconBorder: const Color(0xFFFFCC80),
          icon: Icons.info_outline_rounded, iconColor: _kAmber,
          value: '$_pending', label: 'Pending Review',
          delta: '$_pending awaiting action', up: false)),
        SizedBox(width: w, child: _StatChip(
          iconBg: const Color(0xFFE8F5EE), iconBorder: const Color(0xFFAADDBB),
          icon: Icons.check_rounded, iconColor: _kGreen,
          value: '$_approved', label: 'Approved',
          delta: '↑ $_thisWeek this week', up: true)),
        SizedBox(width: w, child: _StatChip(
          iconBg: const Color(0xFFEAF0FF), iconBorder: const Color(0xFFC0CCFF),
          icon: Icons.close_rounded, iconColor: _kBlue,
          value: '$_rejected', label: 'Rejected',
          delta: '$_rejected total', up: false)),
      ]);
    });
  }

  // ── trend chart + audit log ─────────────────────────────────────────────────
  Widget _buildTwoCol() {
    return LayoutBuilder(builder: (_, cs) {
      if (cs.maxWidth >= 660) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _TrendChartCard(data: _weeklyTrends)),
          const SizedBox(width: 12),
          SizedBox(width: 300, child: _ActivityCard(recentApps: _recentApps)),
        ]);
      }
      return Column(children: [
        _TrendChartCard(data: _weeklyTrends),
        const SizedBox(height: 12),
        _ActivityCard(recentApps: _recentApps),
      ]);
    });
  }

  // ── toolbar ─────────────────────────────────────────────────────────────────
  Widget _buildToolbar() {
    return Column(children: [
      // Search
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.dmSans(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search by name, ID or email…',
          hintStyle: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFFC8B8BB)),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _kMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      ),
      const SizedBox(height: 10),
      // Filters
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _FilterPill(value: _filterStatus,
            items: ['All Statuses', 'Pending', 'Under Review', 'Approved', 'Rejected'],
            onChanged: (v) { if (v != null) setState(() { _filterStatus = v; _tabIdx = 0; }); }),
          const SizedBox(width: 8),
          _FilterPill(value: _filterType,
            items: ['All Types', 'Local', 'International', 'Masters / PG', 'Re-admission', 'Transfer'],
            onChanged: (v) { if (v != null) setState(() => _filterType = v); }),
          const SizedBox(width: 8),
          _FilterPill(value: _filterProgramme,
            items: ['All Programmes', 'Engineering', 'Business', 'Law', 'Medicine', 'Theology'],
            onChanged: (v) { if (v != null) setState(() => _filterProgramme = v); }),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _kBorder, width: 1.5),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: _kMuted),
              const SizedBox(width: 6),
              Text('Jan – Mar 2025',
                style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
            ]),
          ),
        ]),
      ),
    ]);
  }

  // ── tabs ────────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    final tabs = [
      ('All',          _total),
      ('Pending',      _pending),
      ('Under Review', _underReview),
      ('Approved',     _approved),
      ('Rejected',     _rejected),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: tabs.asMap().entries.map((e) {
          final active = _tabIdx == e.key;
          final (label, count) = e.value;
          return GestureDetector(
            onTap: () => setState(() => _tabIdx = e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: active ? _kRed : Colors.transparent, width: 2))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                  color: active ? _kRed : _kMuted)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: active ? _kRed : _kRedSoft,
                    border: Border.all(color: active ? _kRed : _kRedMid),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text('$count', style: GoogleFonts.dmSans(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: active ? Colors.white : _kRed)),
                ),
              ]),
            ),
          );
        }).toList()),
      ),
    );
  }

  // ── table ───────────────────────────────────────────────────────────────────
  Widget _buildTable() {
    final apps = _filtered;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 860,
          child: Column(children: [
            _TableHeader(),
            if (_dataLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: _kRed)))
            else if (apps.isEmpty)
              const _EmptyState()
            else
              ...apps.asMap().entries.map((e) => _AppRow(
                entry: e.value,
                isLast: e.key == apps.length - 1,
                onAction: (action) => _handleAction(e.value, action),
              )),
          ]),
        ),
      ),
    );
  }

  // ── pagination ──────────────────────────────────────────────────────────────
  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(text: TextSpan(
            style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted),
            children: [
              const TextSpan(text: 'Showing '),
              TextSpan(text: '1–${_filtered.length}', style: GoogleFonts.dmSans(
                  color: _kDark, fontWeight: FontWeight.w500)),
              const TextSpan(text: ' of '),
              TextSpan(text: '$_total', style: GoogleFonts.dmSans(
                  color: _kDark, fontWeight: FontWeight.w500)),
              const TextSpan(text: ' applications'),
            ],
          )),
          Row(children: [
            _PgBtn(icon: Icons.chevron_left_rounded),
            _PgBtn(label: '1', active: true),
            _PgBtn(label: '2'),
            _PgBtn(label: '3'),
            _PgBtn(icon: Icons.chevron_right_rounded),
          ]),
        ],
      ),
    );
  }

  // ── OVERVIEW PAGE ────────────────────────────────────────────────────────────
  Widget _buildOverviewContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_alert) _buildAlert(),
          _buildOverviewHeader(),
          const SizedBox(height: 18),
          _buildStat5Strip(),
          const SizedBox(height: 16),
          _buildThreeColRow(),
          const SizedBox(height: 16),
          _buildOverviewBottomRow(),
        ],
      ),
    );
  }

  Widget _buildOverviewHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: l10n.dashboard,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 26, fontWeight: FontWeight.w900,
                color: _kRed, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
            TextSpan(text: ' Overview',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 26, fontWeight: FontWeight.w900,
                color: _kDark, letterSpacing: -0.5)),
          ])),
          const SizedBox(height: 4),
          Text('Africa University — 2024 Academic Year',
            style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted,
                fontWeight: FontWeight.w300)),
        ])),
        const SizedBox(width: 16),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
          _OutlineBtn(label: 'Export Report', icon: Icons.download_rounded, onTap: () => _exportCsv(_liveApps.map(_AppEntry.fromMap).toList())),
          _PrimaryBtn(label: 'Add Application', icon: Icons.add_rounded, onTap: _showAddApplicationDialog),
        ]),
      ],
    );
  }

  Widget _buildStat5Strip() {
    return LayoutBuilder(builder: (_, cs) {
      final cols = cs.maxWidth >= 650 ? 5 : (cs.maxWidth >= 400 ? 3 : 2);
      final w = (cs.maxWidth - 10.0 * (cols - 1)) / cols;
      return Wrap(spacing: 10, runSpacing: 10, children: [
        SizedBox(width: w, child: _OvStatCard(
          accent: _kRed, iconBg: _kRedSoft, iconBorder: _kRedMid,
          icon: Icons.description_outlined, iconColor: _kRed,
          value: '$_total', label: 'Total Applications',
          delta: '↑ $_thisWeek this week', deltaUp: true)),
        SizedBox(width: w, child: _OvStatCard(
          accent: const Color(0xFFC07010),
          iconBg: const Color(0xFFFFF3E0), iconBorder: const Color(0xFFFFCC80),
          icon: Icons.info_outline_rounded, iconColor: const Color(0xFFC07010),
          value: '$_pending', label: 'Pending Review',
          delta: '$_pending awaiting action', deltaUp: false)),
        SizedBox(width: w, child: _OvStatCard(
          accent: const Color(0xFF3A5FCC),
          iconBg: const Color(0xFFEAF0FF), iconBorder: const Color(0xFFC0CCFF),
          icon: Icons.people_outline_rounded, iconColor: const Color(0xFF3A5FCC),
          value: '$_underReview', label: 'Under Review',
          delta: 'No change', neutral: true)),
        SizedBox(width: w, child: _OvStatCard(
          accent: const Color(0xFF1E8A4A),
          iconBg: const Color(0xFFE8F5EE), iconBorder: const Color(0xFFAADDBB),
          icon: Icons.check_rounded, iconColor: const Color(0xFF1E8A4A),
          value: '$_approved', label: 'Approved',
          delta: '↑ $_approved total', deltaUp: true)),
        SizedBox(width: w, child: _OvStatCard(
          accent: _kRedDeep, iconBg: _kRedSoft, iconBorder: _kRedMid,
          icon: Icons.close_rounded, iconColor: _kRedDeep,
          value: '$_rejected', label: 'Denied',
          delta: '$_rejected total', deltaUp: false)),
      ]);
    });
  }

  Widget _buildThreeColRow() {
    return LayoutBuilder(builder: (_, cs) {
      if (cs.maxWidth >= 720) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _OvTrendsCard(data: _weeklyTrends)),
          const SizedBox(width: 10),
          Expanded(child: _OvByTypeCard(typeCounts: _byType)),
          const SizedBox(width: 10),
          Expanded(child: _OvApprovalCard(total: _total, approved: _approved, pending: _pending, rejected: _rejected, underReview: _underReview)),
        ]);
      }
      return Column(children: [
        _OvTrendsCard(data: _weeklyTrends), const SizedBox(height: 10),
        _OvByTypeCard(typeCounts: _byType), const SizedBox(height: 10),
        _OvApprovalCard(total: _total, approved: _approved, pending: _pending, rejected: _rejected, underReview: _underReview),
      ]);
    });
  }

  Widget _buildOverviewBottomRow() {
    return LayoutBuilder(builder: (_, cs) {
      if (cs.maxWidth >= 680) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _OvRecentAppsCard(
            apps: _recentApps,
            onAction: (a) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(a), duration: const Duration(seconds: 1))),
            onViewAll: () => setState(() { _navIdx = 1; _tabIdx = 0; }))),
          const SizedBox(width: 10),
          SizedBox(width: 290, child: Column(children: [
            _OvAuditCard(recentApps: _recentApps), const SizedBox(height: 10), _OvGeoCard(topCountries: _topCountries),
          ])),
        ]);
      }
      return Column(children: [
        _OvRecentAppsCard(apps: _recentApps, onAction: (_) {},
          onViewAll: () => setState(() { _navIdx = 1; _tabIdx = 0; })),
        const SizedBox(height: 10),
        _OvAuditCard(recentApps: _recentApps),
        const SizedBox(height: 10),
        _OvGeoCard(topCountries: _topCountries),
      ]);
    });
  }
}

// ── _Sidebar ──────────────────────────────────────────────────────────────────
List<(String, List<(int, IconData, String, int?, Color?)>)> _buildSidebarGroups(AppLocalizations l10n) => [
  (
    'MAIN',
    <(int, IconData, String, int?, Color?)>[
      (0,  Icons.grid_view_rounded,       'Overview',       null, null),
      (1,  Icons.description_outlined,    'Applications',   247,  null),
      (2,  Icons.people_outline_rounded,  'Students',       1204, null),
      (3,  Icons.school_outlined,         'Programmes',     null, null),
      (4,  Icons.folder_outlined,         l10n.documents,   12,   null),
      (5,  Icons.manage_accounts_outlined,'Users / Staff',  null, null),
    ]
  ),
  (
    'TOOLS',
    <(int, IconData, String, int?, Color?)>[
      (6,  Icons.notifications_outlined, l10n.notifications, 5,  AppTheme.primaryCrimson),
      (7,  Icons.campaign_outlined,      l10n.announcements, 3,  AppTheme.primaryCrimson),
      (8,  Icons.event_outlined,         'Interviews',    null, null),
      (9,  Icons.bar_chart_rounded,      'Reports',       null, null),
      (10, Icons.shield_outlined,        'Audit Log',     null, null),
    ]
  ),
  (
    'SYSTEM',
    <(int, IconData, String, int?, Color?)>[
      (11, Icons.settings_outlined, l10n.settings, null, null),
      (12, Icons.logout_rounded,    l10n.logout,   null, null),
    ]
  ),
];

class _Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _Sidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final sidebarGroups = _buildSidebarGroups(AppLocalizations.of(context)!);
    return Container(
      width: _kSidebarW,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFF0F0F0))),
        boxShadow: [BoxShadow(
          color: Color(0x0A000000), blurRadius: 12, offset: Offset(2, 0))],
      ),
      child: Column(children: [
        // ── Logo ─────────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5)))),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primaryCrimson],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(
                  color: Color(0x44B91C1C), blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 17),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(text: TextSpan(children: [
                TextSpan(text: 'AU ', style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                TextSpan(text: 'Admin', style: GoogleFonts.dmSerifDisplay(
                  fontSize: 14, fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic, color: AppTheme.primaryCrimson)),
              ])),
              Text('Portal', style: GoogleFonts.dmSans(
                fontSize: 10, color: AppTheme.textMuted,
                fontWeight: FontWeight.w400, letterSpacing: 0.3)),
            ]),
          ]),
        ),
        // ── Nav ──────────────────────────────────────────────────────────────
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 14, bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final group in sidebarGroups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 5),
                child: Text(group.$1, style: GoogleFonts.dmSans(
                  fontSize: 9, fontWeight: FontWeight.w800,
                  color: const Color(0xFFC4C9D4), letterSpacing: 1.4)),
              ),
              for (final item in group.$2)
                _NavItem(
                  index: item.$1,
                  icon: item.$2,
                  label: item.$3,
                  badge: item.$4,
                  badgeColor: item.$5,
                  selected: selected,
                  onSelect: onSelect,
                ),
              const SizedBox(height: 6),
            ],
          ]),
        )),
        // ── Divider ──────────────────────────────────────────────────────────
        Container(height: 1, color: const Color(0xFFF5F5F5),
            margin: const EdgeInsets.symmetric(horizontal: 16)),
        // ── User footer ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F1D1D), Color(0xFFB91C1C)]),
                boxShadow: const [BoxShadow(
                  color: Color(0x33B91C1C), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Center(child: Text('TM', style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Admin', style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
              Text('Super Administrator', style: GoogleFonts.dmSans(
                fontSize: 10, color: const Color(0xFF94A3B8))),
            ])),
            Text('···', style: TextStyle(
              fontSize: 14, color: const Color(0xFFCBD5E1), letterSpacing: 2,
              fontFamily: GoogleFonts.dmSans().fontFamily)),
          ]),
        ),
      ]),
    );
  }
}

class _NavItem extends StatefulWidget {
  final int index, selected;
  final IconData icon;
  final String label;
  final int? badge;
  final Color? badgeColor;
  final ValueChanged<int> onSelect;
  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onSelect,
    this.badge,
    this.badgeColor,
  });
  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final active = widget.index == widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onSelect(widget.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 10, bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: active ? const Color(0xFFB91C1C) : Colors.transparent,
                width: 3),
            ),
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFFFEF2F2), Color(0xFFFFF5F5)],
                    begin: Alignment.centerLeft, end: Alignment.centerRight)
                : _hover
                    ? const LinearGradient(colors: [Color(0xFFFAFAFA), Color(0xFFFAFAFA)])
                    : null,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
          ),
          child: Row(children: [
            Icon(widget.icon,
              size: 15,
              color: active
                  ? const Color(0xFFB91C1C)
                  : _hover
                      ? const Color(0xFF374151)
                      : const Color(0xFF4B5563),
            ),
            const SizedBox(width: 11),
            Expanded(child: Text(widget.label, style: GoogleFonts.dmSans(
              fontSize: 13.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? const Color(0xFFB91C1C)
                  : _hover
                      ? const Color(0xFF374151)
                      : const Color(0xFF4B5563),
              letterSpacing: 0.1,
            ))),
            if (widget.badge != null)
              _SidebarBadge(
                count: widget.badge!,
                active: active,
                color: widget.badgeColor,
              ),
          ]),
        ),
      ),
    );
  }
}

class _SidebarBadge extends StatelessWidget {
  final int count;
  final bool active;
  final Color? color;
  const _SidebarBadge({required this.count, required this.active, this.color});
  @override
  Widget build(BuildContext context) {
    const Color defaultFg = Color(0xFF64748B);
    const Color defaultBg = Color(0xFFF1F5F9);
    final Color fg = active
        ? Colors.white
        : color ?? defaultFg;
    final Color bg = active
        ? const Color(0xFFB91C1C)
        : color != null
            ? color!.withValues(alpha: 0.094) // ~18/255
            : defaultBg;
    final border = !active && color != null
        ? Border.all(color: color!.withValues(alpha: 0.25), width: 1)
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: border,
      ),
      child: Text(
        count >= 1000
            ? '${(count / 1000).toStringAsFixed(1)}k'
            : '$count',
        style: GoogleFonts.dmSans(
          fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ── _TopBar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String subtitle;
  final String initials;
  const _TopBar({this.subtitle = 'Application Review', required this.initials});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Color(0xF5FFFFFF),
        border: Border(bottom: BorderSide(color: _kBorder))),
      child: Row(children: [
        RichText(text: TextSpan(
          style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted),
          children: [
            const TextSpan(text: 'Admin Portal  /  '),
            TextSpan(text: subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 13, color: _kDark, fontWeight: FontWeight.w500)),
          ],
        )),
        const Spacer(),
        _IBtn(icon: Icons.notifications_none_rounded, dot: true),
        const SizedBox(width: 8),
        _IBtn(icon: Icons.search_rounded),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorder, width: 1.5),
            borderRadius: BorderRadius.circular(9)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.download_rounded, size: 13, color: _kDark),
            const SizedBox(width: 6),
            Text('Export', style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w500, color: _kDark)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_kRed, _kRedDeep])),
          child: Center(child: Text(initials, style: GoogleFonts.dmSans(
            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
        ),
      ]),
    );
  }
}

class _IBtn extends StatelessWidget {
  final IconData icon;
  final bool dot;
  const _IBtn({required this.icon, this.dot = false});
  @override
  Widget build(BuildContext context) => Stack(children: [
    Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 16, color: _kMuted)),
    if (dot)
      Positioned(top: 6, right: 6, child: Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: _kRed,
          border: Border.all(color: Colors.white, width: 1.5)),
      )),
  ]);
}

// ── _StatChip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatefulWidget {
  final Color iconBg, iconBorder, iconColor;
  final IconData icon;
  final String value, label, delta;
  final bool up;
  const _StatChip({
    required this.iconBg, required this.iconBorder,
    required this.icon, required this.iconColor,
    required this.value, required this.label,
    required this.delta, required this.up,
  });
  @override
  State<_StatChip> createState() => _StatChipState();
}

class _StatChipState extends State<_StatChip> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _hover ? _kRedMid : _kBorder, width: 1.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: _hover
                ? _kRed.withValues(alpha: 0.10)
                : _kRed.withValues(alpha: 0.04),
            blurRadius: _hover ? 20 : 8,
            offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: widget.iconBg,
              border: Border.all(color: widget.iconBorder),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(widget.icon, size: 16, color: widget.iconColor),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.value, style: GoogleFonts.dmSerifDisplay(
              fontSize: 20, fontWeight: FontWeight.w900,
              color: _kDark, letterSpacing: -0.5)),
            Text(widget.label, style: GoogleFonts.dmSans(
              fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
            Text(widget.delta, style: GoogleFonts.dmSans(
              fontSize: 10, fontWeight: FontWeight.w500,
              color: widget.up ? _kGreen : _kRed)),
          ]),
        ]),
      ),
    );
  }
}

// ── _TrendChartCard ───────────────────────────────────────────────────────────
class _TrendChartCard extends StatelessWidget {
  final List<int> data;
  const _TrendChartCard({required this.data});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _kRedSoft,
                border: Border.all(color: _kRedMid),
                borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.bar_chart_rounded, size: 14, color: _kRed)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Application Trends', style: GoogleFonts.dmSerifDisplay(
                fontSize: 14, fontWeight: FontWeight.w700, color: _kDark)),
              Text('Submissions per week · last 8 weeks',
                style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
            ]),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _kBorder, width: 1.5),
              borderRadius: BorderRadius.circular(8)),
            child: Text('Live data',
              style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
          ),
        ]),
        const SizedBox(height: 18),
        SizedBox(
          height: 120,
          child: CustomPaint(
            painter: _BarPainter(data: data),
            size: const Size(double.infinity, 120)),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['W1','W2','W3','W4','W5','W6','W7','W8']
              .map((w) => Text(w, style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted)))
              .toList()),
      ]),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<int> data;
  const _BarPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final gp = Paint()..color = const Color(0xFFF5E8EB)..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
    }
    if (data.isEmpty) return;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final slotW = size.width / data.length;
    final gap   = slotW * 0.22;
    final barW  = slotW - gap * 2;
    for (int i = 0; i < data.length; i++) {
      final pct = maxVal > 0 ? data[i] / maxVal : 0.0;
      final h = size.height * pct * 0.85 + (data[i] > 0 ? 4 : 0);
      final color = pct > 0.7 ? _kRedDeep : pct > 0.4 ? _kRed : _kRedMid;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * slotW + gap, size.height - h, barW, h),
          const Radius.circular(4)),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.data != data;
}

// ── _ActivityCard ─────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> recentApps;
  const _ActivityCard({required this.recentApps});
  @override
  Widget build(BuildContext context) {
    final dotColors = {
      'Pending': _kAmber,
      'Approved': _kGreen,
      'Rejected': _kRed,
      'Under Review': _kBlue,
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              border: Border.all(color: const Color(0xFFC0CCFF)),
              borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.shield_outlined,
                size: 14, color: Color(0xFF3A5FCC))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Audit Log', style: GoogleFonts.dmSerifDisplay(
              fontSize: 14, fontWeight: FontWeight.w700, color: _kDark)),
            Text('Recent submissions',
              style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
          ]),
        ]),
        const SizedBox(height: 14),
        if (recentApps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No recent activity',
              style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
          )
        else
          ...recentApps.asMap().entries.map((entry) {
            final i = entry.key;
            final app = entry.value;
            final name = _s(app['applicant_name'], 'Unknown');
            final type = _s(app['type']);
            final status = _s(app['status'], 'Pending');
            final submittedAt = DateTime.tryParse(_s(app['submitted_at']));
            final timeStr = submittedAt != null ? _timeAgo(submittedAt) : '';
            final dot = dotColors[status] ?? _kAmber;
            final isLast = i == recentApps.length - 1;
            return _AItem(dot, RichText(text: TextSpan(
              style: GoogleFonts.dmSans(fontSize: 13, color: _kDark),
              children: [
                TextSpan(text: name,
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                TextSpan(text: ' submitted'),
              ])), '$timeStr · $type', isLast);
          }),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder, width: 1.5),
            borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('View full audit log',
              style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 13, color: _kMuted),
          ]),
        ),
      ]),
    );
  }
}

class _AItem extends StatelessWidget {
  final Color dot;
  final Widget text;
  final String time;
  final bool isLast;
  const _AItem(this.dot, this.text, this.time, this.isLast);
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 8, height: 8,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: dot,
            boxShadow: [BoxShadow(
              color: dot.withValues(alpha: 0.4), blurRadius: 4)]),
        ),
        if (!isLast)
          Container(
            width: 1, height: 36,
            margin: const EdgeInsets.only(top: 3),
            color: _kBorder),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          text,
          Text(time, style: GoogleFonts.dmSans(
            fontSize: 10, color: _kMuted)),
        ]),
      )),
    ]);
  }
}

// ── table widgets ─────────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  const _TableHeader();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [
          Color(0x05C41E3A), Colors.transparent]),
        border: Border(bottom: BorderSide(color: _kBorder))),
      child: Row(children: [
        SizedBox(width: 24,
          child: Checkbox(
            value: false, onChanged: (_) {},
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(color: _kRedMid, width: 1.5),
            fillColor: WidgetStateProperty.all(_kRedSoft))),
        const SizedBox(width: 8),
        _TH('Applicant', flex: 5),
        _TH('Type', flex: 2),
        _TH('Programme', flex: 3),
        _TH('Submitted', flex: 2),
        _TH('Status', flex: 2),
        _TH('Actions', flex: 4),
      ]),
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final int flex;
  const _TH(this.label, {required this.flex});
  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(label.toUpperCase(), style: GoogleFonts.dmSans(
      fontSize: 10, fontWeight: FontWeight.w600,
      letterSpacing: 0.8, color: _kMuted)),
  );
}

class _AppRow extends StatefulWidget {
  final _AppEntry entry;
  final bool isLast;
  final ValueChanged<String> onAction;
  const _AppRow({required this.entry, required this.isLast,
      required this.onAction});
  @override
  State<_AppRow> createState() => _AppRowState();
}

class _AppRowState extends State<_AppRow> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _hover ? _kRedSoft : Colors.transparent,
          border: Border(bottom: BorderSide(
            color: widget.isLast ? Colors.transparent : _kBorder.withValues(alpha: 0.4)))),
        child: Row(children: [
          SizedBox(width: 24,
            child: Checkbox(
              value: false, onChanged: (_) {},
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: _kRedMid, width: 1.5),
              fillColor: WidgetStateProperty.all(_kRedSoft))),
          const SizedBox(width: 8),
          // Applicant
          Expanded(flex: 5, child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [e.grad1, e.grad2])),
              child: Center(child: Text(e.initials,
                style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: Colors.white)))),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w500, color: _kDark)),
              Text(e.appId, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
            ])),
          ])),
          // Type
          Expanded(flex: 2, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.type, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(fontSize: 13, color: _kDark)),
              Text(e.country, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
            ])),
          // Programme
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.programme, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(fontSize: 13, color: _kDark)),
              Text(e.faculty, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
            ])),
          // Submitted
          Expanded(flex: 2, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.submitted, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(fontSize: 13, color: _kDark)),
              Text(e.timeAgo, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
            ])),
          // Status
          Expanded(flex: 2, child: _StatusPill(e.status)),
          // Actions
          Expanded(flex: 4, child: Row(children: [
            _QBtn(Icons.check_rounded, 'Accept',
                color: _kGreen, onTap: () => widget.onAction('Approve')),
            _QBtn(Icons.close_rounded, 'Deny',
                color: _kRed, onTap: () => widget.onAction('Reject')),
            _QBtn(Icons.manage_search_rounded, 'Under Review',
                color: _kAmber, onTap: () => widget.onAction('Under Review')),
            // More options
            PopupMenuButton<String>(
              tooltip: 'More options',
              icon: const Icon(Icons.more_vert_rounded, size: 16, color: _kMuted),
              onSelected: (s) => widget.onAction(s),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'Pending',      child: Text('Set Pending')),
                const PopupMenuItem(value: 'Approved',     child: Text('Set Approved')),
                const PopupMenuItem(value: 'Rejected',     child: Text('Set Rejected')),
              ],
            ),
          ])),
        ]),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final _AppStatus status;
  const _StatusPill(this.status);
  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg, Color border) = switch (status) {
      _AppStatus.pending  => ('Pending',      const Color(0xFFFFF3E0), _kAmber, const Color(0xFFFFCC80)),
      _AppStatus.review   => ('Under Review', const Color(0xFFEAF0FF), _kBlue,  const Color(0xFFC0CCFF)),
      _AppStatus.approved => ('Approved',     const Color(0xFFE8F5EE), _kGreen, const Color(0xFFAADDBB)),
      _AppStatus.rejected => ('Rejected',     _kRedSoft,               _kRed,   _kRedMid),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 5, height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fg)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: fg, letterSpacing: 0.4)),
      ]),
    );
  }
}

class _QBtn extends StatefulWidget {
  final IconData icon;
  final String tip;
  final Color? color;
  final VoidCallback onTap;
  const _QBtn(this.icon, this.tip, {this.color, required this.onTap});
  @override
  State<_QBtn> createState() => _QBtnState();
}

class _QBtnState extends State<_QBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final hColor = widget.color ?? _kRed;
    return Tooltip(
      message: widget.tip,
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28, height: 28,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: _hover ? hColor.withValues(alpha: 0.1) : Colors.white,
              border: Border.all(
                color: _hover ? hColor : _kBorder, width: 1.5),
              borderRadius: BorderRadius.circular(7)),
            child: Icon(widget.icon, size: 13,
              color: _hover ? hColor : _kMuted),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _kRedSoft,
            border: Border.all(color: _kRedMid, width: 2),
            borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.description_outlined,
              size: 30, color: _kRed)),
        const SizedBox(height: 16),
        Text('No applications found', style: GoogleFonts.dmSerifDisplay(
          fontSize: 18, fontWeight: FontWeight.w700, color: _kDark)),
        const SizedBox(height: 6),
        Text('Try adjusting your search or filter criteria.',
          style: GoogleFonts.dmSans(
            fontSize: 13, color: _kMuted, fontWeight: FontWeight.w300),
          textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── misc small widgets ────────────────────────────────────────────────────────
class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: _kDark),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w400, color: _kDark)),
      ]),
    ),
  );
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kRed, _kRedDeep],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(
          color: Color(0x52C41E3A), blurRadius: 14, offset: Offset(0, 4))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
      ]),
    ),
  );
}

class _FilterPill extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _FilterPill({required this.value, required this.items,
      required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(11)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s, style: GoogleFonts.dmSans(
              fontSize: 13, color: _kDark)))).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: _kMuted),
          style: GoogleFonts.dmSans(fontSize: 13, color: _kDark),
          isDense: true,
        ),
      ),
    );
  }
}

class _PgBtn extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final bool active;
  const _PgBtn({this.icon, this.label, this.active = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30, height: 30,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: active ? _kRed : Colors.white,
        border: Border.all(
          color: active ? _kRed : _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(8)),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 13, color: active ? Colors.white : _kMuted)
            : Text(label!, style: GoogleFonts.dmSans(
                fontSize: 13,
                color: active ? Colors.white : _kMuted)),
      ),
    );
  }
}

// ── _OvStatCard ───────────────────────────────────────────────────────────────
class _OvStatCard extends StatefulWidget {
  final Color accent, iconBg, iconBorder, iconColor;
  final IconData icon;
  final String value, label, delta;
  final bool deltaUp;
  final bool neutral;
  const _OvStatCard({
    required this.accent,
    required this.iconBg, required this.iconBorder,
    required this.icon, required this.iconColor,
    required this.value, required this.label, required this.delta,
    this.deltaUp = true, this.neutral = false,
  });
  @override
  State<_OvStatCard> createState() => _OvStatCardState();
}

class _OvStatCardState extends State<_OvStatCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _hover ? _kRedMid : _kBorder, width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: _hover
                ? _kRed.withValues(alpha: 0.10)
                : _kRed.withValues(alpha: 0.04),
            blurRadius: _hover ? 24 : 8,
            offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 3, color: widget.accent),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: widget.iconBg,
                    border: Border.all(color: widget.iconBorder),
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(widget.icon, size: 16, color: widget.iconColor)),
                const SizedBox(height: 12),
                Text(widget.value, style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22, fontWeight: FontWeight.w900,
                  color: _kDark, letterSpacing: -0.5)),
                Text(widget.label, style: GoogleFonts.dmSans(
                  fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
                const SizedBox(height: 4),
                Text(widget.delta, style: GoogleFonts.dmSans(
                  fontSize: 10, fontWeight: FontWeight.w500,
                  color: widget.neutral
                      ? _kMuted
                      : (widget.deltaUp ? _kGreen : _kRed))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── _OvTrendsCard ─────────────────────────────────────────────────────────────
class _OvTrendsCard extends StatelessWidget {
  final List<int> data;
  const _OvTrendsCard({required this.data});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _kRedSoft, border: Border.all(color: _kRedMid),
              borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.bar_chart_rounded, size: 14, color: _kRed)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Weekly Trends', style: GoogleFonts.dmSerifDisplay(
              fontSize: 13, fontWeight: FontWeight.w700, color: _kDark)),
            Text('Submissions · 2025',
              style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted)),
          ]),
        ]),
        const SizedBox(height: 16),
        SizedBox(height: 110,
          child: CustomPaint(
            painter: _BarPainter(data: data),
            size: const Size(double.infinity, 110))),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['W1','W2','W3','W4','W5','W6','W7','W8']
              .map((w) => Text(w, style: GoogleFonts.dmSans(fontSize: 9, color: _kMuted)))
              .toList()),
      ]),
    );
  }
}

// ── _OvByTypeCard ─────────────────────────────────────────────────────────────
class _OvByTypeCard extends StatelessWidget {
  final Map<String, int> typeCounts;
  const _OvByTypeCard({required this.typeCounts});

  static const _typeColors = <String, (Color, Color)>{
    'undergraduate': (Color(0xFFC41E3A), Color(0xFF8B0F25)),
    'international': (Color(0xFF3A5FCC), Color(0xFF2040AA)),
    'masters / pg':  (Color(0xFF7040BB), Color(0xFF4E2B88)),
    're-admission':  (Color(0xFFC07010), Color(0xFF8A4E0A)),
    'transfer':      (Color(0xFF1E8A4A), Color(0xFF145E32)),
  };

  @override
  Widget build(BuildContext context) {
    final sorted = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.isNotEmpty ? sorted.first.value : 1;
    final rows = sorted.map((e) {
      final key = e.key.toLowerCase();
      final colors = _typeColors[key] ?? (const Color(0xFF888888), const Color(0xFF555555));
      return (e.key, e.value, colors.$1, colors.$2, e.value / maxVal);
    }).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              border: Border.all(color: const Color(0xFFC0CCFF)),
              borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.list_rounded, size: 14,
                color: Color(0xFF3A5FCC))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('By Type', style: GoogleFonts.dmSerifDisplay(
              fontSize: 13, fontWeight: FontWeight.w700, color: _kDark)),
            Text('Application breakdown',
              style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted)),
          ]),
        ]),
        const SizedBox(height: 16),
        ...rows.map((r) {
          final (label, count, c1, c2, pct) = r;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: _kDark)),
                Text('$count', style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w600, color: c1)),
              ]),
              const SizedBox(height: 4),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: _kRedSoft, borderRadius: BorderRadius.circular(20)),
                child: FractionallySizedBox(
                  widthFactor: pct,
                  alignment: Alignment.centerLeft,
                  child: Container(decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [c1, c2]),
                    borderRadius: BorderRadius.circular(20))),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ── _OvApprovalCard + _DonutPainter + _DLItem ─────────────────────────────────
class _OvApprovalCard extends StatelessWidget {
  final int total, approved, pending, rejected, underReview;
  const _OvApprovalCard({
    required this.total,
    required this.approved,
    required this.pending,
    required this.rejected,
    required this.underReview,
  });
  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? approved / total : 0.0;
    final pctLabel = '${(pct * 100).round()}%';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              border: Border.all(color: const Color(0xFFAADDBB)),
              borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.show_chart_rounded, size: 14,
                color: Color(0xFF1E8A4A))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Approval Rate', style: GoogleFonts.dmSerifDisplay(
              fontSize: 13, fontWeight: FontWeight.w700, color: _kDark)),
            Text('Current intake',
              style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted)),
          ]),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 90, height: 90,
            child: Stack(alignment: Alignment.center, children: [
              CustomPaint(
                painter: _DonutPainter(progress: pct, color: _kGreen),
                size: const Size(90, 90)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(pctLabel, style: GoogleFonts.dmSerifDisplay(
                  fontSize: 16, fontWeight: FontWeight.w900, color: _kDark)),
                Text('Approved',
                  style: GoogleFonts.dmSans(fontSize: 9, color: _kMuted)),
              ]),
            ]),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _DLItem(dot: _kGreen, text: 'Approved · $approved'),
            const SizedBox(height: 6),
            _DLItem(dot: _kAmber, text: 'Pending · $pending'),
            const SizedBox(height: 6),
            _DLItem(dot: _kRed,   text: 'Denied · $rejected'),
            const SizedBox(height: 6),
            _DLItem(dot: _kBlue,  text: 'Review · $underReview'),
          ]),
        ]),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _DonutPainter({required this.progress, required this.color});
  static const _pi = 3.1415926535;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r  = size.width * 0.38;
    final sw = size.width * 0.11;
    canvas.drawCircle(center, r,
      Paint()
        ..color = _kRedSoft
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -_pi / 2,
      2 * _pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }
  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

class _DLItem extends StatelessWidget {
  final Color dot;
  final String text;
  const _DLItem({required this.dot, required this.text});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: dot)),
    const SizedBox(width: 6),
    Text(text, style: GoogleFonts.dmSans(fontSize: 11, color: _kDark)),
  ]);
}

// ── _OvRecentAppsCard ─────────────────────────────────────────────────────────
class _OvRecentAppsCard extends StatelessWidget {
  final List<Map<String, dynamic>> apps;
  final ValueChanged<String> onAction;
  final VoidCallback? onViewAll;
  const _OvRecentAppsCard({required this.apps, required this.onAction, this.onViewAll});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _kRedSoft, border: Border.all(color: _kRedMid),
                borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.description_outlined, size: 14, color: _kRed)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recent Applications', style: GoogleFonts.dmSerifDisplay(
                fontSize: 13, fontWeight: FontWeight.w700, color: _kDark)),
              Text('Latest submissions',
                style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted)),
            ]),
          ]),
          GestureDetector(
            onTap: onViewAll,
            child: Row(children: [
              Text('View all', style: GoogleFonts.dmSans(fontSize: 12, color: _kRed)),
              const Icon(Icons.chevron_right_rounded, size: 14, color: _kRed),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 620,
            child: Column(children: [
              // header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x05C41E3A), Colors.transparent]),
                  border: Border(bottom: BorderSide(color: _kBorder))),
                child: Row(children: [
                  Expanded(flex: 5, child: _RTh('Applicant')),
                  Expanded(flex: 2, child: _RTh('Type')),
                  Expanded(flex: 3, child: _RTh('Programme')),
                  Expanded(flex: 2, child: _RTh('Status')),
                  Expanded(flex: 4, child: _RTh('Actions')),
                ]),
              ),
              // rows
              ...apps.map(_AppEntry.fromMap).toList().asMap().entries.map((e) => _OvAppRow(
                entry: e.value,
                isLast: e.key == apps.length - 1,
                onAction: onAction)),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          RichText(text: TextSpan(
            style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted),
            children: [
              const TextSpan(text: 'Showing '),
              TextSpan(text: '1–5',
                style: GoogleFonts.dmSans(color: _kDark, fontWeight: FontWeight.w500)),
              const TextSpan(text: ' of '),
              TextSpan(text: '247',
                style: GoogleFonts.dmSans(color: _kDark, fontWeight: FontWeight.w500)),
            ],
          )),
          Row(children: [
            _PgBtn(icon: Icons.chevron_left_rounded),
            _PgBtn(label: '1', active: true),
            _PgBtn(label: '2'),
            _PgBtn(label: '3'),
            _PgBtn(icon: Icons.chevron_right_rounded),
          ]),
        ]),
      ]),
    );
  }
}

class _RTh extends StatelessWidget {
  final String text;
  const _RTh(this.text);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
    style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600,
        letterSpacing: 0.8, color: _kMuted));
}

class _OvAppRow extends StatefulWidget {
  final _AppEntry entry;
  final bool isLast;
  final ValueChanged<String> onAction;
  const _OvAppRow({required this.entry, required this.isLast, required this.onAction});
  @override
  State<_OvAppRow> createState() => _OvAppRowState();
}

class _OvAppRowState extends State<_OvAppRow> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: _hover ? _kRedSoft : Colors.transparent,
          border: Border(bottom: BorderSide(
            color: widget.isLast
                ? Colors.transparent
                : _kBorder.withValues(alpha: 0.4)))),
        child: Row(children: [
          Expanded(flex: 5, child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [e.grad1, e.grad2])),
              child: Center(child: Text(e.initials,
                style: GoogleFonts.dmSans(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: Colors.white)))),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w500, color: _kDark)),
              Text(e.appId, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 10, color: _kMuted, fontWeight: FontWeight.w300)),
            ])),
          ])),
          Expanded(flex: 2, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.type, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(fontSize: 12, color: _kDark)),
              Text(e.country, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 10, color: _kMuted, fontWeight: FontWeight.w300)),
            ])),
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.programme.split(' ').take(3).join(' '),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(fontSize: 12, color: _kDark)),
              Text(e.faculty.replaceFirst('Faculty of ', ''),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 10, color: _kMuted, fontWeight: FontWeight.w300)),
            ])),
          Expanded(flex: 2, child: _StatusPill(e.status)),
          Expanded(flex: 4, child: Row(children: [
            _QBtn(Icons.visibility_outlined, 'View',
              onTap: () => widget.onAction('View ${e.name}')),
            _QBtn(Icons.check_rounded, 'Approve', color: _kGreen,
              onTap: () => widget.onAction('Approve ${e.name}')),
            _QBtn(Icons.email_outlined, 'Email',
              onTap: () => widget.onAction('Email ${e.name}')),
            _QBtn(Icons.chat_bubble_outline_rounded, 'Note',
              onTap: () => widget.onAction('Note ${e.name}')),
          ])),
        ]),
      ),
    );
  }
}

// ── _OvAuditCard ──────────────────────────────────────────────────────────────
class _OvAuditCard extends StatelessWidget {
  final List<Map<String, dynamic>> recentApps;
  const _OvAuditCard({required this.recentApps});
  @override
  Widget build(BuildContext context) {
    final dotColors = {
      'Pending': _kAmber,
      'Approved': _kGreen,
      'Rejected': _kRed,
      'Under Review': _kBlue,
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                border: Border.all(color: const Color(0xFFC0CCFF)),
                borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.shield_outlined, size: 14,
                  color: Color(0xFF3A5FCC))),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Audit Log', style: GoogleFonts.dmSerifDisplay(
                fontSize: 13, fontWeight: FontWeight.w700, color: _kDark)),
              Text('Recent submissions',
                style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted)),
            ]),
          ]),
          Row(children: [
            Text('All', style: GoogleFonts.dmSans(fontSize: 12, color: _kRed)),
            const Icon(Icons.chevron_right_rounded, size: 14, color: _kRed),
          ]),
        ]),
        const SizedBox(height: 12),
        if (recentApps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No recent activity',
              style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
          )
        else
          ...recentApps.asMap().entries.map((entry) {
            final i = entry.key;
            final app = entry.value;
            final name = app['applicant_name'] as String? ?? 'Unknown';
            final type = app['type'] as String? ?? '';
            final status = app['status'] as String? ?? 'Pending';
            final submittedAt = app['submitted_at'] != null
                ? DateTime.tryParse(app['submitted_at'] as String)
                : null;
            final timeStr = submittedAt != null ? _timeAgo(submittedAt) : '';
            final dot = dotColors[status] ?? _kAmber;
            final isLast = i == recentApps.length - 1;
            return _AItem(dot, RichText(text: TextSpan(
              style: GoogleFonts.dmSans(fontSize: 12, color: _kDark),
              children: [
                TextSpan(text: name,
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                const TextSpan(text: ' submitted'),
              ])), '$timeStr · $type', isLast);
          }),
      ]),
    );
  }
}

// ── _OvGeoCard ────────────────────────────────────────────────────────────────
class _OvGeoCard extends StatelessWidget {
  final List<(String, int, double)> topCountries;
  const _OvGeoCard({required this.topCountries});

  static const _flagColors = <String, List<Color>>{
    'zimbabwe': [Color(0xFF009A00), Color(0xFF000000), Color(0xFFFFD200)],
    'kenya':    [Color(0xFF006600), Color(0xFFCC0000), Color(0xFFFFFFFF)],
    'nigeria':  [Color(0xFF008751), Color(0xFFFFFFFF), Color(0xFF008751)],
    'ghana':    [Color(0xFF006B3F), Color(0xFFFCD116), Color(0xFFCE1126)],
    'south africa': [Color(0xFF007A4D), Color(0xFFFFB612), Color(0xFF001489)],
    'ethiopia': [Color(0xFF009A44), Color(0xFFFCDD09), Color(0xFFEF3340)],
    'tanzania': [Color(0xFF1EB53A), Color(0xFF000000), Color(0xFFFCD116)],
    'uganda':   [Color(0xFF000000), Color(0xFFFFCC00), Color(0xFFD90000)],
  };

  static const _fallbackColors = [Color(0xFF888888), Color(0xFF555555), Color(0xFF333333)];

  @override
  Widget build(BuildContext context) {
    final countries = topCountries;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEFE8F5),
              border: Border.all(color: const Color(0xFFCCBBEE)),
              borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.language_rounded, size: 14,
                color: Color(0xFF7040BB))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Top Countries', style: GoogleFonts.dmSerifDisplay(
              fontSize: 13, fontWeight: FontWeight.w700, color: _kDark)),
            Text('By applications',
              style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted)),
          ]),
        ]),
        const SizedBox(height: 14),
        if (countries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No data yet',
              style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
          )
        else
          ...countries.map((c) {
            final name = c.$1;
            final _ = c.$2;
            final pct = c.$3;
            final flagColors = _flagColors[name.toLowerCase()] ?? _fallbackColors;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 20, height: 13,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: flagColors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(name,
                  style: GoogleFonts.dmSans(fontSize: 12, color: _kDark))),
                Expanded(flex: 2, child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: _kRedSoft, borderRadius: BorderRadius.circular(20)),
                  child: FractionallySizedBox(
                    widthFactor: pct.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [_kRed, _kRedDeep]),
                      borderRadius: BorderRadius.all(Radius.circular(20)))),
                  ),
                )),
                const SizedBox(width: 8),
]),
            );
          }),
      ]),
    );
  }
}

// ── StudentsPage ───────────────────────────────────────────────────────────
class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});
  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _streamSub;

  @override
  void initState() {
    super.initState();
    _streamSub = SupabaseService.streamAllApplications().listen((apps) {
      if (mounted) {
        setState(() {
          _students = apps.where((a) => a['status'] == 'Approved').toList();
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Students', style: GoogleFonts.dmSerifDisplay(
            fontSize: 28, fontWeight: FontWeight.w900, color: _kDark)),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_students.isEmpty)
            Center(child: Text('No students yet', style: TextStyle(color: _kMuted)))
          else
            ..._students.map((s) => _StudentCard(student: s)),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  const _StudentCard({required this.student});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_kGreen, _kGreen.withValues(alpha: 0.7)])),
          child: Center(child: Text(
            (student['applicant_name'] as String? ?? '')[0].toUpperCase(),
            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student['applicant_name'] as String? ?? '', style: GoogleFonts.dmSans(
              fontSize: 16, fontWeight: FontWeight.w600, color: _kDark)),
            Text(student['programme'] as String? ?? '', style: GoogleFonts.dmSans(
              fontSize: 14, color: _kMuted)),
          ],
        )),
        Text('Enrolled', style: GoogleFonts.dmSans(
          fontSize: 12, color: _kGreen, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── AdminSettingsPage ─────────────────────────────────────────────────────────
class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});
  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _isDark = false;
  String? _name, _email;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    final user = SupabaseService.currentUser;
    setState(() {
      _email = user?.email ?? '';
      _name = user?.userMetadata?['full_name'] as String? ?? _adminDisplayName();
    });
  }

  Future<void> _logout() async {
    await SupabaseService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: GoogleFonts.dmSerifDisplay(
            fontSize: 28, fontWeight: FontWeight.w900, color: _kDark)),
          const SizedBox(height: 24),
          // Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile', style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _kDark)),
                const SizedBox(height: 16),
                Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [_kRed, _kRedDeep])),
                    child: Center(child: Text(_adminInitials(), style: GoogleFonts.dmSans(
                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name ?? 'Loading...', style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w500, color: _kDark)),
                      Text(_email ?? '', style: GoogleFonts.dmSans(
                        fontSize: 14, color: _kMuted)),
                    ],
                  )),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Theme Toggle
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appearance', style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _kDark)),
                const SizedBox(height: 16),
                Row(children: [
                  const Icon(Icons.brightness_6, color: _kMuted),
                  const SizedBox(width: 12),
                  Text('Theme', style: GoogleFonts.dmSans(
                    fontSize: 14, color: _kDark)),
                  const Spacer(),
                  Switch(
                    value: _isDark,
                    onChanged: (v) => setState(() => _isDark = v),
                    activeThumbColor: _kRed,
                  ),
                  const SizedBox(width: 8),
                  Text(_isDark ? 'Dark' : 'Light', style: GoogleFonts.dmSans(
                    fontSize: 14, color: _kMuted)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Logout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account', style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _kDark)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text('Logout', style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w500)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
