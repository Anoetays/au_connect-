import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:au_connect/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/services/supabase_service.dart';

// ── colour tokens (mirrors admin dashboard palette) ───────────────────────────
const _kRed      = AppTheme.primaryCrimson;
const _kRedDeep  = AppTheme.primaryDark;
const _kRedSoft  = AppTheme.primaryLight;
const _kRedMid   = Color(0xFFE8C0C8);
const _kDark     = AppTheme.textPrimary;
const _kMuted    = AppTheme.textMuted;
const _kBorder   = Color(0x21B91C1C);

// ── faculty colour config ─────────────────────────────────────────────────────
enum _Faculty { engineering, business, law, medicine, education, theology }

const _facultyAccent = <_Faculty, Color>{
  _Faculty.engineering: Color(0xFFC41E3A),
  _Faculty.business:    Color(0xFF3A5FCC),
  _Faculty.law:         Color(0xFF7040BB),
  _Faculty.medicine:    Color(0xFF1E8A4A),
  _Faculty.education:   Color(0xFFC07010),
  _Faculty.theology:    Color(0xFF8B0F25),
};

const _facultyIconBg = <_Faculty, Color>{
  _Faculty.engineering: Color(0xFFF5E8EB),
  _Faculty.business:    Color(0xFFEAF0FF),
  _Faculty.law:         Color(0xFFEFE8F5),
  _Faculty.medicine:    Color(0xFFE8F5EE),
  _Faculty.education:   Color(0xFFFFF3E0),
  _Faculty.theology:    Color(0xFFF5E8EB),
};

const _facultyIconBorder = <_Faculty, Color>{
  _Faculty.engineering: Color(0xFFE8C0C8),
  _Faculty.business:    Color(0xFFC0CCFF),
  _Faculty.law:         Color(0xFFCCBBEE),
  _Faculty.medicine:    Color(0xFFAADDBB),
  _Faculty.education:   Color(0xFFFFCC80),
  _Faculty.theology:    Color(0xFFE8C0C8),
};

// ── data model ────────────────────────────────────────────────────────────────
enum _ProgStatus { active, inactive, newProg }

class _Programme {
  final String id, name, code, faculty, level, duration;
  final _Faculty fac;
  final _ProgStatus status;
  final int enrolled, applicants, durationYears;
  final IconData icon;
  const _Programme({
    this.id = '',
    required this.name,
    required this.code,
    required this.faculty,
    required this.level,
    required this.duration,
    required this.fac,
    required this.status,
    required this.enrolled,
    required this.applicants,
    required this.durationYears,
    required this.icon,
  });
}


// ── main page widget ──────────────────────────────────────────────────────────
class ProgrammesPage extends StatefulWidget {
  const ProgrammesPage({super.key});
  @override
  State<ProgrammesPage> createState() => _ProgrammesPageState();
}

class _ProgrammesPageState extends State<ProgrammesPage> {
  static final List<Map<String, dynamic>> _defaultProgrammes = [
    {
      'id': 'demo-1',
      'name': 'Bachelor of Computer Science',
      'code': 'BCS101',
      'faculty': 'Engineering',
      'level': 'Undergraduate',
      'duration_years': 4,
      'status': 'Active',
      'enrolled': 120,
      'applicants': 520,
    },
    {
      'id': 'demo-2',
      'name': 'Master of Business Administration',
      'code': 'MBA201',
      'faculty': 'Business',
      'level': 'Postgraduate',
      'duration_years': 2,
      'status': 'Active',
      'enrolled': 68,
      'applicants': 198,
    },
    {
      'id': 'demo-3',
      'name': 'LLB Law',
      'code': 'LLB301',
      'faculty': 'Law',
      'level': 'Undergraduate',
      'duration_years': 4,
      'status': 'Active',
      'enrolled': 74,
      'applicants': 210,
    },
  ];

  final _searchCtrl = TextEditingController();
  String _tabLevel   = 'All';
  String _facFilter  = 'All Faculties';
  String _lvlFilter  = 'All Levels';
  String _stFilter   = 'All Statuses';
  int _page = 1;
  static const _perPage = 6;

  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = SupabaseService.streamProgrammes().listen((rows) {
      if (mounted) {
        setState(() {
          _rows = rows;
          _loading = false;
        });
      }
    }, onError: (_) {
      if (mounted) {
        setState(() {
          _rows = [];
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _text(dynamic value) => value?.toString() ?? '';

  _Programme _toEntry(Map<String, dynamic> r) {
    final facStr = _text(r['faculty']).toLowerCase();
    final fac = facStr.contains('engineering') ? _Faculty.engineering
        : facStr.contains('business')          ? _Faculty.business
        : facStr.contains('law')               ? _Faculty.law
        : facStr.contains('medicine') || facStr.contains('health') ? _Faculty.medicine
        : facStr.contains('education')         ? _Faculty.education
        : _Faculty.theology;
    final icon = switch (fac) {
      _Faculty.engineering => Icons.engineering_outlined,
      _Faculty.business    => Icons.business_center_outlined,
      _Faculty.law         => Icons.balance_outlined,
      _Faculty.medicine    => Icons.monitor_heart_outlined,
      _Faculty.education   => Icons.menu_book_outlined,
      _Faculty.theology    => Icons.church_outlined,
    };
    final statusStr = _text(r['status']).isEmpty ? 'Active' : _text(r['status']);
    final status = statusStr == 'Inactive' ? _ProgStatus.inactive
        : statusStr == 'New'              ? _ProgStatus.newProg
        : _ProgStatus.active;
    final dyears = (r['duration_years'] as int?) ?? 3;
    return _Programme(
      id:           _text(r['id']),
      name:         _text(r['name']),
      code:         _text(r['code']),
      faculty:      _text(r['faculty']),
      level:        _text(r['level']),
      duration:     '$dyears Years',
      durationYears: dyears,
      fac:          fac,
      status:       status,
      enrolled:     (r['enrolled']   as int?) ?? 0,
      applicants:   (r['applicants'] as int?) ?? 0,
      icon:         icon,
    );
  }

  List<_Programme> get _progs {
    final source = _rows.isNotEmpty ? _rows : _defaultProgrammes;
    return source.map(_toEntry).toList();
  }

  List<_Programme> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    return _progs.where((p) {
      final matchTab = _tabLevel == 'All' || p.level == _tabLevel;
      final matchFac = _facFilter == 'All Faculties' || p.faculty.contains(_facFilter);
      final matchLvl = _lvlFilter == 'All Levels' || p.level == _lvlFilter;
      final matchSt  = _stFilter == 'All Statuses' ||
          (_stFilter == 'Active'   && p.status == _ProgStatus.active)  ||
          (_stFilter == 'Inactive' && p.status == _ProgStatus.inactive) ||
          (_stFilter == 'New'      && p.status == _ProgStatus.newProg);
      final matchQ   = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q) ||
          p.faculty.toLowerCase().contains(q);
      return matchTab && matchFac && matchLvl && matchSt && matchQ;
    }).toList();
  }

  int _tabCount(String level) {
    final all = _progs;
    if (level == 'All') return all.length;
    return all.where((p) => p.level == level).length;
  }

  // ── dialogs / actions ────────────────────────────────────────────────────────

  void _exportCsv() {
    final lines = <String>['Name,Faculty,Level,Duration,Status'];
    for (final p in _filtered) {
      lines.add('"${p.name}","${p.faculty}","${p.level}","${p.duration}","${p.status.name}"');
    }
    final csv = lines.join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV copied to clipboard')),
    );
  }

  Future<void> _showAddProgrammeDialog() async {
    final nameCtrl     = TextEditingController();
    final facCtrl      = TextEditingController();
    String level       = 'Undergraduate';
    int    durationYrs = 4;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Add Programme', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Programme Name', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: facCtrl,
                decoration: const InputDecoration(labelText: 'Faculty', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: level,
                decoration: const InputDecoration(labelText: 'Level', border: OutlineInputBorder()),
                items: ['Undergraduate', 'Postgraduate']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setDlg(() => level = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Duration (years)', border: OutlineInputBorder()),
                items: [1, 2, 3, 4, 5]
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n Year${n > 1 ? "s" : ""}'))).toList(),
                onChanged: (v) => setDlg(() => durationYrs = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: _kMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final fac  = facCtrl.text.trim();
                if (name.isEmpty || fac.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await SupabaseService.insertProgramme(
                    name: name, faculty: fac, level: level, durationYears: durationYrs);
                } catch (e) {
                  if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'))); }
                }
              },
              child: const Text('Add Programme'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    facCtrl.dispose();
  }

  Future<void> _showEditProgrammeDialog(_Programme p) async {
    if (p.id.isEmpty) return;
    final nameCtrl = TextEditingController(text: p.name);
    final facCtrl  = TextEditingController(text: p.faculty);
    String level       = p.level.isNotEmpty ? p.level : 'Undergraduate';
    int    durationYrs = p.durationYears;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Edit Programme', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Programme Name', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: facCtrl,
                decoration: const InputDecoration(labelText: 'Faculty', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: ['Undergraduate', 'Postgraduate'].contains(level) ? level : 'Undergraduate',
                decoration: const InputDecoration(labelText: 'Level', border: OutlineInputBorder()),
                items: ['Undergraduate', 'Postgraduate']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setDlg(() => level = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: [1, 2, 3, 4, 5].contains(durationYrs) ? durationYrs : 4,
                decoration: const InputDecoration(labelText: 'Duration (years)', border: OutlineInputBorder()),
                items: [1, 2, 3, 4, 5]
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n Year${n > 1 ? "s" : ""}'))).toList(),
                onChanged: (v) => setDlg(() => durationYrs = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: _kMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final fac  = facCtrl.text.trim();
                if (name.isEmpty || fac.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await SupabaseService.updateProgramme(p.id,
                    name: name, faculty: fac, level: level, durationYears: durationYrs);
                } catch (e) {
                  if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'))); }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    facCtrl.dispose();
  }

  Future<void> _showDeleteConfirmDialog(_Programme p) async {
    if (p.id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Programme', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${p.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: _kMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await SupabaseService.deleteProgramme(p.id);
      } catch (e) {
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))); }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _filtered;
    final totalPages = (all.length / _perPage).ceil().clamp(1, 99);
    final page = _page.clamp(1, totalPages);
    final start = (page - 1) * _perPage;
    final end   = (start + _perPage).clamp(0, all.length);
    final visible = all.sublist(start, end);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kRed));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 64),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildStatStrip(),
        const SizedBox(height: 14),
        _buildToolbar(),
        const SizedBox(height: 10),
        _buildTabs(),
        const SizedBox(height: 12),
        _buildGrid(visible),
        const SizedBox(height: 14),
        _buildPagination(all.length, start + 1, end, page, totalPages),
      ]),
    );
  }

  // ── header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: 'Programmes', style: GoogleFonts.dmSerifDisplay(
              fontSize: 24, fontWeight: FontWeight.w900,
              color: _kRed, fontStyle: FontStyle.italic, letterSpacing: -0.3)),
          ])),
          const SizedBox(height: 3),
          Text('Manage academic programmes across all faculties — 8 faculties · 40+ degrees',
            style: GoogleFonts.dmSans(fontSize: 12.5, color: _kMuted, fontWeight: FontWeight.w300)),
        ])),
        const SizedBox(width: 12),
        Row(children: [
          _OutlineBtn(
            icon: Icons.download_outlined,
            label: 'Export',
            onTap: _exportCsv,
          ),
          const SizedBox(width: 8),
          _PrimaryBtn(
            icon: Icons.add_rounded,
            label: 'Add Programme',
            onTap: _showAddProgrammeDialog,
          ),
        ]),
      ],
    );
  }

  // ── stat strip ─────────────────────────────────────────────────────────────
  Widget _buildStatStrip() {
    return LayoutBuilder(builder: (_, cs) {
      final cols = cs.maxWidth >= 600 ? 4 : 2;
      final w = (cs.maxWidth - 12.0 * (cols - 1)) / cols;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(width: w, child: _StatChip(
          iconBg: _kRedSoft, iconBorder: _kRedMid, iconColor: _kRed,
          icon: Icons.school_outlined,
          value: '${_progs.length}', label: 'Total Programmes',
        )),
        SizedBox(width: w, child: _StatChip(
          iconBg: const Color(0xFFE8F5EE), iconBorder: const Color(0xFFAADDBB),
          iconColor: const Color(0xFF1E8A4A),
          icon: Icons.check_circle_outline_rounded,
          value: '${_progs.where((p) => p.status == _ProgStatus.active).length}',
          label: 'Active',
        )),
        SizedBox(width: w, child: _StatChip(
          iconBg: const Color(0xFFEAF0FF), iconBorder: const Color(0xFFC0CCFF),
          iconColor: const Color(0xFF3A5FCC),
          icon: Icons.account_balance_outlined,
          value: '${_progs.map((p) => p.faculty).toSet().length}', label: 'Faculties',
        )),
        SizedBox(width: w, child: _StatChip(
          iconBg: const Color(0xFFFFF3E0), iconBorder: const Color(0xFFFFCC80),
          iconColor: const Color(0xFFC07010),
          icon: Icons.add_circle_outline_rounded,
          value: '${_rows.where((r) {
            final dt = DateTime.tryParse(_text(r['created_at']));
            return dt != null && dt.year == DateTime.now().year;
          }).length}',
          label: 'New This Year',
        )),
      ]);
    });
  }

  // ── toolbar ────────────────────────────────────────────────────────────────
  Widget _buildToolbar() {
    return LayoutBuilder(builder: (_, cs) {
      final narrow = cs.maxWidth < 650;
      final row1 = Row(children: [
        Expanded(child: _SearchField(controller: _searchCtrl, onChanged: (_) => setState(() { _page = 1; }))),
        if (!narrow) ...[
          const SizedBox(width: 8),
          _FilterDrop(
            value: _facFilter,
            items: const ['All Faculties', 'Engineering', 'Business', 'Law', 'Medicine', 'Education', 'Theology'],
            onChanged: (v) { if (v != null) setState(() { _facFilter = v; _page = 1; }); },
          ),
          const SizedBox(width: 8),
          _FilterDrop(
            value: _lvlFilter,
            items: const ['All Levels', 'Undergraduate', 'Postgraduate', 'Diploma', 'PhD'],
            onChanged: (v) { if (v != null) setState(() { _lvlFilter = v; _page = 1; }); },
          ),
          const SizedBox(width: 8),
          _FilterDrop(
            value: _stFilter,
            items: const ['All Statuses', 'Active', 'Inactive', 'New'],
            onChanged: (v) { if (v != null) setState(() { _stFilter = v; _page = 1; }); },
          ),
        ],
      ]);
      if (!narrow) return row1;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        row1,
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _FilterDrop(
            value: _facFilter,
            items: const ['All Faculties', 'Engineering', 'Business', 'Law', 'Medicine', 'Education', 'Theology'],
            onChanged: (v) { if (v != null) setState(() { _facFilter = v; _page = 1; }); },
          )),
          const SizedBox(width: 8),
          Expanded(child: _FilterDrop(
            value: _lvlFilter,
            items: const ['All Levels', 'Undergraduate', 'Postgraduate', 'Diploma', 'PhD'],
            onChanged: (v) { if (v != null) setState(() { _lvlFilter = v; _page = 1; }); },
          )),
          const SizedBox(width: 8),
          Expanded(child: _FilterDrop(
            value: _stFilter,
            items: const ['All Statuses', 'Active', 'Inactive', 'New'],
            onChanged: (v) { if (v != null) setState(() { _stFilter = v; _page = 1; }); },
          )),
        ]),
      ]);
    });
  }

  // ── tabs ───────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    const levels = ['All', 'Undergraduate', 'Postgraduate', 'Diploma', 'PhD'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: levels.map((lv) {
          final active = _tabLevel == lv;
          return _Tab(
            label: lv,
            count: _tabCount(lv),
            active: active,
            onTap: () => setState(() { _tabLevel = lv; _page = 1; }),
          );
        }).toList()),
      ),
    );
  }

  // ── grid ───────────────────────────────────────────────────────────────────
  Widget _buildGrid(List<_Programme> progs) {
    if (progs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text('No programmes match your filters.',
            style: GoogleFonts.dmSans(fontSize: 14, color: _kMuted)),
        ),
      );
    }
    return LayoutBuilder(builder: (_, cs) {
      final cols = cs.maxWidth >= 900 ? 3 : cs.maxWidth >= 580 ? 2 : 1;
      final gap  = 12.0;
      final cardW = (cs.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap,
        children: progs.map((p) => SizedBox(width: cardW, child: _ProgCard(
          prog: p,
          onEdit:   () => _showEditProgrammeDialog(p),
          onDelete: () => _showDeleteConfirmDialog(p),
        ))).toList(),
      );
    });
  }

  // ── pagination ─────────────────────────────────────────────────────────────
  Widget _buildPagination(int total, int from, int to, int page, int totalPages) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      RichText(text: TextSpan(
        style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w300),
        children: [
          const TextSpan(text: 'Showing '),
          TextSpan(text: '$from–$to',
            style: GoogleFonts.dmSans(color: _kDark, fontWeight: FontWeight.w500)),
          const TextSpan(text: ' of '),
          TextSpan(text: '$total',
            style: GoogleFonts.dmSans(color: _kDark, fontWeight: FontWeight.w500)),
          const TextSpan(text: ' programmes'),
        ],
      )),
      Row(children: [
        _PgBtn(icon: Icons.chevron_left_rounded, onTap: page > 1 ? () => setState(() => _page = page - 1) : null),
        for (int i = 1; i <= totalPages.clamp(1, 8); i++)
          _PgBtn(label: '$i', active: i == page, onTap: () => setState(() => _page = i)),
        _PgBtn(icon: Icons.chevron_right_rounded, onTap: page < totalPages ? () => setState(() => _page = page + 1) : null),
      ]),
    ]);
  }
}

// ── _ProgCard ─────────────────────────────────────────────────────────────────
class _ProgCard extends StatefulWidget {
  final _Programme prog;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _ProgCard({required this.prog, this.onEdit, this.onDelete});
  @override
  State<_ProgCard> createState() => _ProgCardState();
}

class _ProgCardState extends State<_ProgCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p     = widget.prog;
    final accent = _facultyAccent[p.fac]!;
    final iconBg  = _facultyIconBg[p.fac]!;
    final iconBorder = _facultyIconBorder[p.fac]!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: _hover
            ? Matrix4.translationValues(0, -3, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _hover ? _kRed.withValues(alpha: 0.28) : _kBorder,
            width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: _hover
                ? const Color(0x1EC41E3A)
                : const Color(0x0AC41E3A),
            blurRadius: _hover ? 32 : 8,
            offset: const Offset(0, 4),
          )],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── top accent bar ────────────────────────────────────────────────
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── icon + action buttons ─────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    transform: _hover
                        ? (Matrix4.identity()..rotateZ(-0.087)..scaleByDouble(1.1, 1.1, 1.1, 1.0))
                        : Matrix4.identity(),
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      border: Border.all(color: iconBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(p.icon, size: 18, color: accent),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _hover ? 1.0 : 0.0,
                    child: Row(children: [
                      _ActionBtn(icon: Icons.edit_outlined,
                        onTap: widget.onEdit),
                      const SizedBox(width: 4),
                      _ActionBtn(icon: Icons.delete_outline_rounded,
                        onTap: widget.onDelete),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── faculty label ─────────────────────────────────────────────
              Text(p.faculty.toUpperCase(), style: GoogleFonts.dmSans(
                fontSize: 9.5, fontWeight: FontWeight.w500,
                letterSpacing: 0.8, color: _kMuted)),
              const SizedBox(height: 3),
              // ── programme name ────────────────────────────────────────────
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2,
                  color: _hover ? _kRedDeep : _kDark, height: 1.2),
                child: Text(p.name),
              ),
              const SizedBox(height: 3),
              // ── code + duration ───────────────────────────────────────────
              Text('${p.code} · ${p.duration}', style: GoogleFonts.dmSans(
                fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
              const SizedBox(height: 10),
              // ── stats ─────────────────────────────────────────────────────
              Row(children: [
                _ProgStat(icon: Icons.people_outline_rounded,
                  value: '${p.enrolled}', label: 'enrolled'),
                const SizedBox(width: 14),
                _ProgStat(icon: Icons.description_outlined,
                  value: '${p.applicants}', label: 'applicants'),
              ]),
              const SizedBox(height: 10),
              // ── footer ────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _kRedSoft, width: 1.5))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatusBadge(status: p.status),
                    Text(p.level, style: GoogleFonts.dmSans(
                      fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
                  ],
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── sub-widgets ───────────────────────────────────────────────────────────────

class _StatChip extends StatefulWidget {
  final Color iconBg, iconBorder, iconColor;
  final IconData icon;
  final String value, label;
  const _StatChip({
    required this.iconBg, required this.iconBorder, required this.iconColor,
    required this.icon, required this.value, required this.label,
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
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: _hover
            ? Matrix4.translationValues(0, -2, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _hover ? _kRed.withValues(alpha: 0.28) : _kBorder, width: 1.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: _hover ? const Color(0x10C41E3A) : const Color(0x04C41E3A),
            blurRadius: _hover ? 24 : 8,
            offset: const Offset(0, 2),
          )],
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: widget.iconBg,
              border: Border.all(color: widget.iconBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, size: 15, color: widget.iconColor),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.value, style: GoogleFonts.dmSerifDisplay(
              fontSize: 19, fontWeight: FontWeight.w900,
              color: _kDark, letterSpacing: -0.3, height: 1)),
            const SizedBox(height: 1),
            Text(widget.label, style: GoogleFonts.dmSans(
              fontSize: 10.5, color: _kMuted, fontWeight: FontWeight.w300)),
          ]),
        ]),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.count, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count', style: GoogleFonts.dmSans(
              fontSize: 9.5, fontWeight: FontWeight.w600,
              color: active ? Colors.white : _kRed)),
          ),
        ]),
      ),
      ),
    );
  }
}

class _ProgStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _ProgStat({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 11, color: _kMuted),
    const SizedBox(width: 4),
    Text(value, style: GoogleFonts.dmSans(
      fontSize: 11, fontWeight: FontWeight.w500, color: _kDark)),
    const SizedBox(width: 2),
    Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
  ]);
}

class _StatusBadge extends StatelessWidget {
  final _ProgStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg, Color border) = switch (status) {
      _ProgStatus.active   => ('Active',   const Color(0xFFE8F5EE), const Color(0xFF1E8A4A), const Color(0xFFAADDBB)),
      _ProgStatus.inactive => ('Inactive', _kRedSoft, _kMuted, _kRedMid),
      _ProgStatus.newProg  => ('New',      const Color(0xFFEAF0FF), const Color(0xFF3A5FCC), const Color(0xFFC0CCFF)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border)),
      child: Text(label, style: GoogleFonts.dmSans(
        fontSize: 9.5, fontWeight: FontWeight.w600,
        letterSpacing: 0.5, color: fg)),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _ActionBtn({required this.icon, this.onTap});
  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
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
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: _h ? _kRedSoft : Colors.white,
          border: Border.all(color: _h ? _kRed : _kBorder, width: 1.5),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(widget.icon, size: 11,
          color: _h ? _kRed : _kMuted),
      ),
    ),
  );
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.dmSans(fontSize: 13, color: _kDark),
      decoration: InputDecoration(
        hintText: 'Search programmes…',
        hintStyle: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFFC8B8BB)),
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
}

class _FilterDrop extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _FilterDrop({required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(11),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: GoogleFonts.dmSans(fontSize: 12.5, color: _kDark),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _kMuted),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
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
        curve: Curves.easeOutCubic,
        transform: _h ? Matrix4.translationValues(0, -1, 0) : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kRed, _kRedDeep],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(
            color: _h ? const Color(0x60C41E3A) : const Color(0x40C41E3A),
            blurRadius: _h ? 20 : 14, offset: const Offset(0, 4))],
        ),
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
          border: Border.all(
            color: _h ? _kRed : _kBorder, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
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
            borderRadius: BorderRadius.circular(8),
          ),
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
