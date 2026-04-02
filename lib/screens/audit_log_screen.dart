import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
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
const _kBlue    = AppTheme.statusReview;
const _kGreen   = AppTheme.statusApproved;
const _kAmber   = AppTheme.statusPending;
const _kPurple  = Color(0xFF7040BB);

// ── enums / models ────────────────────────────────────────────────────────────
enum _AuditAction { approve, reject, note, verify, login, create }

class _LogEntry {
  final String time;
  final String date;
  final String adminInitials;
  final Color  adminGrad1;
  final Color  adminGrad2;
  final String adminName;
  final String adminRole;
  final String description;
  final String descSub;
  final String targetId;
  final String targetType;
  final _AuditAction action;
  final String ip;
  const _LogEntry({
    required this.time, required this.date,
    required this.adminInitials, required this.adminGrad1, required this.adminGrad2,
    required this.adminName, required this.adminRole,
    required this.description, required this.descSub,
    required this.targetId, required this.targetType,
    required this.action, required this.ip,
  });
}

const _kTabLabels = ['All', 'Approvals', 'Rejections', 'Documents', 'Notes', 'Logins'];

// ═══════════════════════════════════════════════════════════════════════════════
class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});
  @override State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  int _tab = 0;
  String _search = '';
  String _actionFilter = 'All Actions';
  String _staffFilter = 'All Staff';

  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = SupabaseService.streamAuditLogs().listen(
      (rows) => setState(() { _rows = rows; _loading = false; }),
      onError: (_) => setState(() => _loading = false),
    );
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  _LogEntry _toEntry(Map<String, dynamic> r) {
    final adminName = r['admin_name'] as String? ?? '';
    final parts = adminName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : adminName.isNotEmpty ? adminName[0].toUpperCase() : '?';
    final roleStr = r['admin_role'] as String? ?? '';
    final (grad1, grad2) = switch (roleStr) {
      'Super Admin' => (_kRed, _kRedDeep),
      'Admin'       => (_kBlue, const Color(0xFF2040AA)),
      'Reviewer'    => (_kGreen, const Color(0xFF145E32)),
      'Viewer'      => (_kPurple, const Color(0xFF4A2580)),
      _             => (_kAmber, const Color(0xFF885008)),
    };
    final actionStr = r['action_type'] as String? ?? '';
    final action = switch (actionStr) {
      'Approved'   => _AuditAction.approve,
      'Rejected'   => _AuditAction.reject,
      'Note Added' => _AuditAction.note,
      'Verified'   => _AuditAction.verify,
      'Login'      => _AuditAction.login,
      _            => _AuditAction.create,
    };
    final createdAt = DateTime.tryParse(r['created_at'] as String? ?? '')?.toLocal();
    String time = '', date = '';
    if (createdAt != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final entryDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final h = createdAt.hour, m = createdAt.minute;
      final hStr = h % 12 == 0 ? 12 : h % 12;
      final mStr = m.toString().padLeft(2, '0');
      time = '$hStr:$mStr ${h < 12 ? "AM" : "PM"}';
      if (entryDay == today) { date = 'Today'; }
      else if (entryDay == yesterday) { date = 'Yesterday'; }
      else {
        const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        date = '${mo[createdAt.month - 1]} ${createdAt.day}';
      }
    }
    final desc = r['description'] as String? ?? '';
    final descParts = desc.split('\n');
    return _LogEntry(
      time: time, date: date,
      adminInitials: initials, adminGrad1: grad1, adminGrad2: grad2,
      adminName: adminName, adminRole: roleStr,
      description: descParts.first,
      descSub: descParts.length > 1 ? descParts.skip(1).join('\n') : '',
      targetId: r['target_id'] as String? ?? '',
      targetType: r['target_type'] as String? ?? '',
      action: action,
      ip: r['ip_address'] as String? ?? '—',
    );
  }

  List<_LogEntry> get _entries => _rows.map(_toEntry).toList();

  List<_LogEntry> get _filtered {
    var list = _entries;
    switch (_tab) {
      case 1: list = list.where((e) => e.action == _AuditAction.approve).toList();
      case 2: list = list.where((e) => e.action == _AuditAction.reject).toList();
      case 3: list = list.where((e) => e.targetType == 'Document').toList();
      case 4: list = list.where((e) => e.action == _AuditAction.note).toList();
      case 5: list = list.where((e) => e.action == _AuditAction.login).toList();
    }
    if (_actionFilter != 'All Actions') {
      final map = {
        'Approve': _AuditAction.approve, 'Reject': _AuditAction.reject,
        'Add Note': _AuditAction.note,   'Verify Document': _AuditAction.verify,
        'Login': _AuditAction.login,     'Create': _AuditAction.create,
      };
      final a = map[_actionFilter];
      if (a != null) list = list.where((e) => e.action == a).toList();
    }
    if (_staffFilter != 'All Staff') {
      list = list.where((e) => e.adminName.contains(_staffFilter)).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((e) =>
        e.adminName.toLowerCase().contains(q) ||
        e.description.toLowerCase().contains(q) ||
        e.targetId.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  int _tabCount(int i) {
    final all = _entries;
    return switch (i) {
      0 => all.length,
      1 => all.where((e) => e.action == _AuditAction.approve).length,
      2 => all.where((e) => e.action == _AuditAction.reject).length,
      3 => all.where((e) => e.targetType == 'Document').length,
      4 => all.where((e) => e.action == _AuditAction.note).length,
      5 => all.where((e) => e.action == _AuditAction.login).length,
      _ => 0,
    };
  }

  void _exportLog() {
    final lines = ['Time,Admin,Role,Action,Description,Target'];
    for (final e in _filtered) {
      lines.add('"${e.date} ${e.time}","${e.adminName}","${e.adminRole}","${e.action.name}","${e.description}","${e.targetId}"');
    }
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audit log CSV copied to clipboard')));
  }

  Future<void> _showFilterDialog() async {
    String action = _actionFilter;
    String staff  = _staffFilter;
    final actionOptions = ['All Actions', 'Approve', 'Reject', 'Add Note', 'Verify Document', 'Login', 'Create'];
    final staffOptions  = ['All Staff', ..._entries.map((e) => e.adminName).toSet().toList()..sort()];
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Filter Audit Log', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 320,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: action,
                decoration: const InputDecoration(labelText: 'Action Type', border: OutlineInputBorder()),
                items: actionOptions.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setDlg(() => action = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: staffOptions.contains(staff) ? staff : 'All Staff',
                decoration: const InputDecoration(labelText: 'Staff Member', border: OutlineInputBorder()),
                items: staffOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setDlg(() => staff = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() { _actionFilter = 'All Actions'; _staffFilter = 'All Staff'; });
                Navigator.pop(ctx);
              },
              child: const Text('Clear Filters'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
              onPressed: () {
                setState(() { _actionFilter = action; _staffFilter = staff; });
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  int get _statToday {
    final todayStart = DateTime.now();
    final d = DateTime(todayStart.year, todayStart.month, todayStart.day);
    return _rows.where((r) {
      final dt = DateTime.tryParse(r['created_at'] as String? ?? '')?.toLocal();
      return dt != null && !dt.isBefore(d);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kRed));
    final filtered = _filtered;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── page header ───────────────────────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(text: TextSpan(
                style: GoogleFonts.dmSerifDisplay(fontSize: 24, fontWeight: FontWeight.w900,
                  color: _kDark, letterSpacing: -0.4),
                children: const [
                  TextSpan(text: 'Audit', style: TextStyle(color: _kRed, fontStyle: FontStyle.italic)),
                  TextSpan(text: ' Log'),
                ],
              )),
              const SizedBox(height: 3),
              Text('Complete record of all admin actions for accountability and compliance.',
                style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w300)),
            ])),
            _OutlineBtn(icon: Icons.download_rounded, label: 'Export Log', onTap: _exportLog),
            const SizedBox(width: 8),
            _OutlineBtn(icon: Icons.filter_list_rounded, label: 'Filter', onTap: _showFilterDialog),
          ]),
          const SizedBox(height: 18),

          // ── stat strip ────────────────────────────────────────────────────
          Row(children: [
            _StatChip(icon: Icons.shield_outlined,
              iconBg: _kRedSoft, iconBorder: _kRedMid, stroke: _kRed,
              val: '${_entries.length}', lbl: 'Total Actions'),
            const SizedBox(width: 10),
            _StatChip(icon: Icons.check_rounded,
              iconBg: const Color(0xFFE8F5EE), iconBorder: const Color(0xFFAADDBB), stroke: _kGreen,
              val: '${_entries.where((e) => e.action == _AuditAction.approve).length}', lbl: 'Approvals'),
            const SizedBox(width: 10),
            _StatChip(icon: Icons.people_outline_rounded,
              iconBg: const Color(0xFFFFF3E0), iconBorder: const Color(0xFFFFCC80), stroke: _kAmber,
              val: '${_entries.map((e) => e.adminName).toSet().length}', lbl: 'Staff Actions'),
            const SizedBox(width: 10),
            _StatChip(icon: Icons.schedule_rounded,
              iconBg: const Color(0xFFEAF0FF), iconBorder: const Color(0xFFC0CCFF), stroke: _kBlue,
              val: '$_statToday', lbl: 'Today'),
          ]),
          const SizedBox(height: 14),

          // ── toolbar ───────────────────────────────────────────────────────
          _Toolbar(
            onSearch: (v) => setState(() => _search = v),
            onAction: (v) => setState(() => _actionFilter = v),
            onStaff:  (v) => setState(() => _staffFilter = v),
          ),
          const SizedBox(height: 4),

          // ── tabs ──────────────────────────────────────────────────────────
          _buildTabs(),

          // ── log table ─────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder, width: 1.5),
              boxShadow: [BoxShadow(color: _kRed.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(children: [
              _TableHeader(),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text('No data yet',
                    style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted))),
                )
              else
                ...filtered.map((e) => _LogRow(entry: e)),
              _Pagination(total: _entries.length),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: List.generate(_kTabLabels.length, (i) {
          final label = _kTabLabels[i];
          final count = _tabCount(i);
          final active = i == _tab;
          return GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: active ? _kRed : Colors.transparent, width: 2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(label, style: GoogleFonts.dmSans(
                    fontSize: 12.5, fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                    color: active ? _kRed : _kMuted)),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: active ? _kRed : _kRedSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? _kRed : _kRedMid, width: 1),
                    ),
                    child: Text('$count', style: GoogleFonts.dmSans(
                      fontSize: 9.5, fontWeight: FontWeight.w600,
                      color: active ? Colors.white : _kRed)),
                  ),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── _Toolbar ──────────────────────────────────────────────────────────────────
class _Toolbar extends StatefulWidget {
  final ValueChanged<String>? onSearch;
  final ValueChanged<String>? onAction;
  final ValueChanged<String>? onStaff;
  const _Toolbar({this.onSearch, this.onAction, this.onStaff});
  @override State<_Toolbar> createState() => _ToolbarState();
}
class _ToolbarState extends State<_Toolbar> {
  bool _searchFocus = false;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        flex: 3,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _searchFocus ? _kRed : _kBorder, width: 1.5),
            boxShadow: _searchFocus
                ? [BoxShadow(color: _kRed.withValues(alpha: 0.08), blurRadius: 0, spreadRadius: 3)]
                : [],
          ),
          child: Row(children: [
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.search_rounded, size: 16, color: _kMuted),
            ),
            Expanded(
              child: TextField(
                onTap:        () => setState(() => _searchFocus = true),
                onTapOutside: (_) => setState(() => _searchFocus = false),
                onChanged:    widget.onSearch,
                style: GoogleFonts.dmSans(fontSize: 13, color: _kDark),
                decoration: InputDecoration(
                  hintText: 'Search by admin, applicant, or action type…',
                  hintStyle: GoogleFonts.dmSans(fontSize: 13,
                    color: const Color(0xFFC8B8BB), fontWeight: FontWeight.w300),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                  isDense: true,
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      _DropSel(
        items: const ['All Actions','Approve','Reject','Add Note','Verify Document','Login','Create'],
        onChange: widget.onAction,
      ),
      const SizedBox(width: 8),
      _DropSel(
        items: const ['All Staff','Tapiwa Mutasa','Nyasha Kambarami','Faith Mufaro'],
        onChange: widget.onStaff,
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _kBorder, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today_outlined, size: 13, color: _kMuted),
          const SizedBox(width: 6),
          Text('Mar 15, 2025', style: GoogleFonts.dmSans(fontSize: 12.5, color: _kDark)),
        ]),
      ),
    ]);
  }
}

// ── _DropSel ──────────────────────────────────────────────────────────────────
class _DropSel extends StatefulWidget {
  final List<String> items;
  final ValueChanged<String>? onChange;
  const _DropSel({required this.items, this.onChange});
  @override State<_DropSel> createState() => _DropSelState();
}
class _DropSelState extends State<_DropSel> {
  late String _val;
  @override void initState() { super.initState(); _val = widget.items.first; }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _kBorder, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _val,
          isDense: true,
          style: GoogleFonts.dmSans(fontSize: 12.5, color: _kDark),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: _kMuted),
          items: widget.items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) { if (v != null) { setState(() => _val = v); widget.onChange?.call(v); } },
        ),
      ),
    );
  }
}

// ── _TableHeader ──────────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const cols = <(String, int)>[
      ('Time', 1), ('Admin', 2), ('Description', 4), ('Target', 2), ('Action', 2), ('IP Address', 2),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed.withValues(alpha: 0.04), Colors.transparent],
          end: Alignment.centerRight,
        ),
        border: const Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: cols.map((c) => Expanded(
          flex: c.$2,
          child: Text(c.$1, style: GoogleFonts.dmSans(
            fontSize: 10, fontWeight: FontWeight.w600,
            letterSpacing: 0.9, color: _kMuted,
          ).copyWith(fontSize: 10)),
        )).toList(),
      ),
    );
  }
}

// ── _LogRow ───────────────────────────────────────────────────────────────────
class _LogRow extends StatefulWidget {
  final _LogEntry entry;
  const _LogRow({required this.entry});
  @override State<_LogRow> createState() => _LogRowState();
}
class _LogRowState extends State<_LogRow> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final (pillBg, pillBorder, pillColor, pillLabel) = _actionStyle(e.action);
    final accentColor = _actionAccent(e.action);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hov ? _kRedSoft : Colors.white,
          border: Border(
            left: BorderSide(color: _hov ? accentColor : Colors.transparent, width: 3),
            bottom: const BorderSide(color: Color(0x0DC41E3A), width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Time
            Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.time, style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: _kDark)),
              Text(e.date, style: GoogleFonts.dmSans(fontSize: 10.5, color: _kMuted, fontWeight: FontWeight.w300)),
            ])),
            // Admin
            Expanded(flex: 2, child: Row(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [e.adminGrad1, e.adminGrad2],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Center(child: Text(e.adminInitials,
                  style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
              ),
              const SizedBox(width: 7),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.adminName, style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: _kDark)),
                Text(e.adminRole, style: GoogleFonts.dmSans(fontSize: 10.5, color: _kMuted, fontWeight: FontWeight.w300)),
              ])),
            ])),
            // Description
            Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.description, style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: _kDark)),
              Text(e.descSub, style: GoogleFonts.dmSans(fontSize: 10.5, color: _kMuted, fontWeight: FontWeight.w300)),
            ])),
            // Target
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.targetId, style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: _kDark)),
              Text(e.targetType, style: GoogleFonts.dmSans(fontSize: 10.5, color: _kMuted, fontWeight: FontWeight.w300)),
            ])),
            // Action pill
            Expanded(flex: 2, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pillBg, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pillBorder, width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 4, height: 4,
                  decoration: BoxDecoration(color: pillColor, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(pillLabel, style: GoogleFonts.dmSans(
                  fontSize: 9.5, fontWeight: FontWeight.w600,
                  color: pillColor, letterSpacing: 0.6)),
              ]),
            )),
            // IP
            Expanded(flex: 2, child:
              Text(e.ip, style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.w400, color: _kDark))),
          ]),
        ),
      ),
    );
  }
}

// ── _Pagination ───────────────────────────────────────────────────────────────
class _Pagination extends StatefulWidget {
  final int total;
  const _Pagination({required this.total});
  @override State<_Pagination> createState() => _PaginationState();
}
class _PaginationState extends State<_Pagination> {
  int _page = 1;
  @override
  Widget build(BuildContext context) {
    final total = widget.total;
    final pages = (total / 20).ceil().clamp(1, 9999);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(children: [
        Text('Showing ', style: GoogleFonts.dmSans(fontSize: 11.5, color: _kMuted, fontWeight: FontWeight.w300)),
        Text(total == 0 ? '0' : '${(_page - 1) * 20 + 1}–${(_page * 20).clamp(1, total)}',
          style: GoogleFonts.dmSans(fontSize: 11.5, color: _kDark, fontWeight: FontWeight.w500)),
        Text(' of ', style: GoogleFonts.dmSans(fontSize: 11.5, color: _kMuted, fontWeight: FontWeight.w300)),
        Text('$total', style: GoogleFonts.dmSans(fontSize: 11.5, color: _kDark, fontWeight: FontWeight.w500)),
        Text(' log entries', style: GoogleFonts.dmSans(fontSize: 11.5, color: _kMuted, fontWeight: FontWeight.w300)),
        const Spacer(),
        _PgBtn(label: null, icon: Icons.chevron_left_rounded, active: false,
          onTap: () => setState(() => _page = (_page - 1).clamp(1, pages))),
        const SizedBox(width: 4),
        ...[1, 2, 3].where((n) => n <= pages).map((n) {
          final active = n == _page;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _PgBtn(
              label: '$n', icon: null, active: active,
              onTap: () => setState(() => _page = n),
            ),
          );
        }),
        if (pages > 3) ...[
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _PgBtn(label: '…', icon: null, active: false, onTap: () {}),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _PgBtn(label: '$pages', icon: null, active: _page == pages,
              onTap: () => setState(() => _page = pages)),
          ),
        ],
        _PgBtn(label: null, icon: Icons.chevron_right_rounded, active: false,
          onTap: () => setState(() => _page = (_page + 1).clamp(1, pages))),
      ]),
    );
  }
}

class _PgBtn extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;
  const _PgBtn({required this.label, required this.icon, required this.active, required this.onTap});
  @override State<_PgBtn> createState() => _PgBtnState();
}
class _PgBtnState extends State<_PgBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final highlight = widget.active || _hov;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: highlight ? _kRed : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: highlight ? _kRed : _kBorder, width: 1.5),
          ),
          child: Center(
            child: widget.icon != null
              ? Icon(widget.icon, size: 14,
                  color: highlight ? Colors.white : _kMuted)
              : Text(widget.label!, style: GoogleFonts.dmSans(
                  fontSize: 12, color: highlight ? Colors.white : _kMuted)),
          ),
        ),
      ),
    );
  }
}

// ── _StatChip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatefulWidget {
  final IconData icon;
  final Color iconBg, iconBorder, stroke;
  final String val, lbl;
  const _StatChip({required this.icon, required this.iconBg, required this.iconBorder,
    required this.stroke, required this.val, required this.lbl});
  @override State<_StatChip> createState() => _StatChipState();
}
class _StatChipState extends State<_StatChip> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hov = true),
        onExit:  (_) => setState(() => _hov = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hov ? -2 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hov ? _kRed.withValues(alpha: 0.28) : _kBorder, width: 1.5),
            boxShadow: [BoxShadow(color: _kRed.withValues(alpha: _hov ? 0.10 : 0.04),
              blurRadius: _hov ? 20 : 8, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: 34, height: 34,
              decoration: BoxDecoration(color: widget.iconBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.iconBorder, width: 1)),
              child: Transform.rotate(
                angle: _hov ? -0.09 : 0,
                child: Icon(widget.icon, size: 15, color: widget.stroke),
              ),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.val, style: GoogleFonts.dmSerifDisplay(
                fontSize: 19, fontWeight: FontWeight.w900, color: _kDark, height: 1)),
              const SizedBox(height: 1),
              Text(widget.lbl, style: GoogleFonts.dmSans(
                fontSize: 10.5, color: _kMuted, fontWeight: FontWeight.w300)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── _OutlineBtn ───────────────────────────────────────────────────────────────
class _OutlineBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.onTap});
  @override State<_OutlineBtn> createState() => _OutlineBtnState();
}
class _OutlineBtnState extends State<_OutlineBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hov ? _kRed : _kBorder, width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 13, color: _hov ? _kRed : _kDark),
            const SizedBox(width: 6),
            Text(widget.label, style: GoogleFonts.dmSans(
              fontSize: 12.5, fontWeight: FontWeight.w400,
              color: _hov ? _kRed : _kDark)),
          ]),
        ),
      ),
    );
  }
}

// ── helpers ───────────────────────────────────────────────────────────────────
(Color bg, Color border, Color text, String label) _actionStyle(_AuditAction a) =>
  switch (a) {
    _AuditAction.approve => (const Color(0xFFE8F5EE), const Color(0xFFAADDBB), _kGreen,  'Approved'),
    _AuditAction.reject  => (_kRedSoft,                _kRedMid,               _kRed,    'Rejected'),
    _AuditAction.note    => (const Color(0xFFEAF0FF),  const Color(0xFFC0CCFF), _kBlue,   'Note Added'),
    _AuditAction.verify  => (const Color(0xFFEFE8F5),  const Color(0xFFCCBBEE), _kPurple, 'Verified'),
    _AuditAction.login   => (const Color(0xFFFFF3E0),  const Color(0xFFFFCC80), _kAmber,  'Login'),
    _AuditAction.create  => (_kRedSoft,                _kRedMid,               _kRedDeep,'Created'),
  };

Color _actionAccent(_AuditAction a) => switch (a) {
  _AuditAction.approve => _kGreen,
  _AuditAction.reject  => _kRed,
  _AuditAction.note    => _kBlue,
  _AuditAction.verify  => _kPurple,
  _AuditAction.login   => _kAmber,
  _AuditAction.create  => _kRedDeep,
};
