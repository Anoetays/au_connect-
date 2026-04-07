import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/theme/app_theme.dart';

// ── colour tokens (shared with admin dashboard theme) ────────────────────────
const _kRed     = AppTheme.primaryCrimson;
const _kRedDeep = AppTheme.primaryDark;
const _kRedSoft = AppTheme.primaryLight;
const _kRedMid  = Color(0xFFE8C0C8);
const _kDark    = AppTheme.textPrimary;
const _kMuted   = AppTheme.textMuted;
const _kBorder  = Color(0x21B91C1C);
const _kGreen   = AppTheme.statusApproved;
const _kBlue    = AppTheme.statusReview;
const _kAmber   = AppTheme.statusPending;

// ── data models ──────────────────────────────────────────────────────────────
enum _StaffRole { superAdmin, admin, reviewer, viewer, support }
enum _StaffStatus { active, inactive, pendingInvite }

class _StaffEntry {
  final String initials;
  final String name;
  final String email;
  final String department;
  final String subRole;
  final _StaffRole role;
  final String lastActive;
  final String lastActiveDetail;
  final _StaffStatus status;
  final Color avatarColor;

  const _StaffEntry({
    required this.initials,
    required this.name,
    required this.email,
    required this.department,
    required this.subRole,
    required this.role,
    required this.lastActive,
    required this.lastActiveDetail,
    required this.status,
    required this.avatarColor,
  });
}



// ── page widget ───────────────────────────────────────────────────────────────
class UsersStaffPage extends StatefulWidget {
  const UsersStaffPage({super.key});

  @override
  State<UsersStaffPage> createState() => _UsersStaffPageState();
}

class _UsersStaffPageState extends State<UsersStaffPage> {
  String _search = '';
  String _roleFilter = 'All Roles';
  String _statusFilter = 'All Statuses';
  String _deptFilter = 'All Departments';
  int _tabIdx = 0;

  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  static const _tabs = [
    ('All Staff', null),
    ('Super Admin', _StaffRole.superAdmin),
    ('Admin', _StaffRole.admin),
    ('Reviewer', _StaffRole.reviewer),
    ('Viewer', _StaffRole.viewer),
  ];

  @override
  void initState() {
    super.initState();
    _sub = SupabaseService.streamStaff().listen((rows) {
      setState(() { _rows = rows; _loading = false; });
    }, onError: (_) => setState(() => _loading = false));
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  _StaffEntry _toEntry(Map<String, dynamic> r) {
    final name = r['name'] as String? ?? '';
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';
    final roleStr = r['role'] as String? ?? '';
    final role = switch (roleStr) {
      'Super Admin' => _StaffRole.superAdmin,
      'Admin'       => _StaffRole.admin,
      'Reviewer'    => _StaffRole.reviewer,
      'Viewer'      => _StaffRole.viewer,
      _             => _StaffRole.support,
    };
    final statusStr = r['status'] as String? ?? 'Active';
    final status = switch (statusStr) {
      'Inactive'       => _StaffStatus.inactive,
      'Pending'        => _StaffStatus.pendingInvite,
      _                => _StaffStatus.active,
    };
    final avatarColor = switch (role) {
      _StaffRole.superAdmin => const Color(0xFFC41E3A),
      _StaffRole.admin      => const Color(0xFF3A5FCC),
      _StaffRole.reviewer   => const Color(0xFF1E8A4A),
      _StaffRole.viewer     => const Color(0xFF7040BB),
      _StaffRole.support    => const Color(0xFFC07010),
    };
    final lastActiveDt = DateTime.tryParse(r['last_active'] as String? ?? '')?.toLocal();
    String lastActive = '', lastActiveDetail = '';
    if (lastActiveDt != null) {
      final diff = DateTime.now().difference(lastActiveDt);
      if (diff.inMinutes < 5)       { lastActive = 'Today';     lastActiveDetail = 'Just now'; }
      else if (diff.inHours < 24)   { lastActive = 'Today';     lastActiveDetail = '${diff.inHours} hr${diff.inHours>1?"s":""} ago'; }
      else if (diff.inDays == 1)    { lastActive = 'Yesterday'; lastActiveDetail = 'Yesterday'; }
      else                          { lastActive = '${diff.inDays} days ago'; lastActiveDetail = '${diff.inDays} days ago'; }
    }
    return _StaffEntry(
      initials: initials, name: name,
      email: r['email'] as String? ?? '',
      department: r['department'] as String? ?? '',
      subRole: r['sub_role'] as String? ?? roleStr,
      role: role, lastActive: lastActive, lastActiveDetail: lastActiveDetail,
      status: status, avatarColor: avatarColor,
    );
  }

  List<_StaffEntry> get _staff => _rows.map(_toEntry).toList();

  List<_StaffEntry> get _filtered {
    var list = _staff;
    if (_tabIdx > 0) {
      final role = _tabs[_tabIdx].$2!;
      list = list.where((s) => s.role == role).toList();
    }
    if (_roleFilter != 'All Roles') {
      final map = {
        'Super Admin': _StaffRole.superAdmin, 'Admin': _StaffRole.admin,
        'Reviewer': _StaffRole.reviewer, 'Viewer': _StaffRole.viewer, 'Support': _StaffRole.support,
      };
      final r = map[_roleFilter];
      if (r != null) list = list.where((s) => s.role == r).toList();
    }
    if (_statusFilter != 'All Statuses') {
      final map = {
        'Active': _StaffStatus.active, 'Inactive': _StaffStatus.inactive,
        'Pending Invite': _StaffStatus.pendingInvite,
      };
      final st = map[_statusFilter];
      if (st != null) list = list.where((s) => s.status == st).toList();
    }
    if (_deptFilter != 'All Departments') {
      list = list.where((s) => s.department.contains(_deptFilter)).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((s) =>
        s.name.toLowerCase().contains(q) ||
        s.email.toLowerCase().contains(q) ||
        _roleName(s.role).toLowerCase().contains(q)).toList();
    }
    return list;
  }

  int _tabCount(_StaffRole? role) {
    final all = _staff;
    if (role == null) return all.length;
    return all.where((s) => s.role == role).length;
  }

  Future<void> _showInviteDialog() async {
    final nameCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl  = TextEditingController();
    String selectedRole = 'Reviewer';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: _kRedSoft, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.person_add_outlined, size: 16, color: _kRed)),
            const SizedBox(width: 12),
            Text('Invite Staff Member',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          content: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12)),
                style: GoogleFonts.dmSans(fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12)),
                style: GoogleFonts.dmSans(fontSize: 13),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12)),
                style: GoogleFonts.dmSans(fontSize: 13, color: _kDark),
                items: ['Super Admin','Admin','Reviewer','Viewer','Support']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) { if (v != null) setDlg(() => selectedRole = v); },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: deptCtrl,
                decoration: InputDecoration(
                  labelText: 'Department (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12)),
                style: GoogleFonts.dmSans(fontSize: 13),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.dmSans())),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
              onPressed: () async {
                final name  = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                if (name.isEmpty || email.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await SupabaseService.inviteStaff(
                    name: name,
                    email: email,
                    role: selectedRole,
                    department: deptCtrl.text.trim().isNotEmpty ? deptCtrl.text.trim() : null,
                  );
                  final user = SupabaseService.currentUser;
                  await SupabaseService.insertAuditLog(
                    adminName: user?.email ?? 'Admin',
                    adminRole: 'Admin',
                    actionType: 'Invite',
                    description: 'Staff invite sent to $email ($selectedRole)',
                    targetId: email,
                    targetType: 'Staff',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Invite sent to $email'),
                      backgroundColor: _kGreen));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'), backgroundColor: _kRed));
                  }
                }
              },
              child: Text('Send Invite', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    emailCtrl.dispose();
    deptCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kRed));
    final staff = _filtered;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildStatStrip(),
          const SizedBox(height: 14),
          _buildToolbar(),
          const SizedBox(height: 10),
          _buildTabs(),
          const SizedBox(height: 10),
          _buildTable(staff),
        ],
      ),
    );
  }

  // ── header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(text: TextSpan(
                style: GoogleFonts.dmSerifDisplay(fontSize: 22, fontWeight: FontWeight.w900, color: _kDark, letterSpacing: -0.4),
                children: const [
                  TextSpan(text: 'Users', style: TextStyle(color: _kRed, fontStyle: FontStyle.italic)),
                  TextSpan(text: ' / Staff'),
                ],
              )),
              const SizedBox(height: 3),
              Text('Manage admin accounts, roles and access permissions.',
                style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w300)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _OutlineBtn(icon: Icons.download_outlined, label: 'Export'),
        const SizedBox(width: 8),
        _OutlineBtn(icon: Icons.settings_outlined, label: 'Manage Roles'),
        const SizedBox(width: 8),
        _PrimaryBtn(label: 'Invite Staff', icon: Icons.add, onTap: _showInviteDialog),
      ],
    );
  }

  // ── stat strip ──────────────────────────────────────────────────────────────
  Widget _buildStatStrip() {
    return Row(children: [
      _StatChip(icon: Icons.people_outline_rounded, iconBg: _kRedSoft, iconBorder: _kRedMid, iconColor: _kRed,
        value: '${_staff.length}', label: 'Total Staff'),
      const SizedBox(width: 10),
      _StatChip(icon: Icons.check_circle_outline_rounded, iconBg: const Color(0xFFE8F5EE), iconBorder: const Color(0xFFAADDBB), iconColor: _kGreen,
        value: '${_staff.where((s) => s.status == _StaffStatus.active).length}', label: 'Active'),
      const SizedBox(width: 10),
      _StatChip(icon: Icons.shield_outlined, iconBg: const Color(0xFFEAF0FF), iconBorder: const Color(0xFFC0CCFF), iconColor: _kBlue,
        value: '5', label: 'Roles Defined'),
      const SizedBox(width: 10),
      _StatChip(icon: Icons.mail_outline_rounded, iconBg: const Color(0xFFFFF3E0), iconBorder: const Color(0xFFFFCC80), iconColor: _kAmber,
        value: '${_staff.where((s) => s.status == _StaffStatus.pendingInvite).length}', label: 'Pending Invites'),
    ]);
  }

  // ── toolbar ─────────────────────────────────────────────────────────────────
  Widget _buildToolbar() {
    return Row(children: [
      Expanded(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _kBorder, width: 1.5),
          ),
          child: Row(children: [
            const SizedBox(width: 10),
            const Icon(Icons.search, size: 16, color: _kMuted),
            const SizedBox(width: 6),
            Expanded(child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w300, color: _kDark),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search by name, email or role…',
                hintStyle: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFFC8B8BB), fontWeight: FontWeight.w300),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      _FilterDrop(value: _roleFilter, items: const ['All Roles','Super Admin','Admin','Reviewer','Viewer','Support'],
        onChanged: (v) => setState(() => _roleFilter = v)),
      const SizedBox(width: 8),
      _FilterDrop(value: _statusFilter, items: const ['All Statuses','Active','Inactive','Pending Invite'],
        onChanged: (v) => setState(() => _statusFilter = v)),
      const SizedBox(width: 8),
      _FilterDrop(value: _deptFilter, items: const ['All Departments','Admissions','Registry','Finance','IT'],
        onChanged: (v) => setState(() => _deptFilter = v)),
    ]);
  }

  // ── tabs ────────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kBorder))),
      child: Row(children: List.generate(_tabs.length, (i) {
        final active = _tabIdx == i;
        final count = _tabCount(_tabs[i].$2);
        return GestureDetector(
          onTap: () => setState(() => _tabIdx = i),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(
                color: active ? _kRed : Colors.transparent, width: 2)),
            ),
            child: Row(children: [
              Text(_tabs[i].$1, style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                color: active ? _kRed : _kMuted)),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? _kRed : _kRedSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? _kRedDeep : _kRedMid),
                ),
                child: Text('$count', style: GoogleFonts.dmSans(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: active ? Colors.white : _kRed)),
              ),
            ]),
          ),
        );
      })),
    );
  }

  // ── table ───────────────────────────────────────────────────────────────────
  Widget _buildTable(List<_StaffEntry> staff) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(children: [
        // header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0x08C41E3A), Colors.transparent]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            border: Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(children: [
            const SizedBox(width: 28),
            const SizedBox(width: 8),
            Expanded(flex: 20, child: _TH(label: 'Staff Member', sorted: true)),
            Expanded(flex: 12, child: _TH(label: 'Department')),
            Expanded(flex: 10, child: _TH(label: 'Role')),
            Expanded(flex: 9,  child: _TH(label: 'Last Active')),
            Expanded(flex: 8,  child: _TH(label: 'Status')),
            const SizedBox(width: 130),
          ]),
        ),
        // data rows
        ...staff.map((s) => _StaffRow(entry: s)),
        // pagination
        _buildPagination(staff.length),
      ]),
    );
  }

  Widget _buildPagination(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(text: TextSpan(
            style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300),
            children: [
              const TextSpan(text: 'Showing '),
              TextSpan(text: '$count', style: const TextStyle(color: _kDark, fontWeight: FontWeight.w500)),
              const TextSpan(text: ' of '),
              TextSpan(text: '${_staff.length}', style: const TextStyle(color: _kDark, fontWeight: FontWeight.w500)),
              const TextSpan(text: ' staff members'),
            ],
          )),
          Row(children: [
            _PgBtn(child: const Icon(Icons.chevron_left, size: 14)),
            const SizedBox(width: 4),
            _PgBtn(label: '1', active: true),
            const SizedBox(width: 4),
            _PgBtn(label: '2'),
            const SizedBox(width: 4),
            _PgBtn(child: const Icon(Icons.chevron_right, size: 14)),
          ]),
        ],
      ),
    );
  }
}

// ── helpers ──────────────────────────────────────────────────────────────────
String _roleName(_StaffRole r) => switch (r) {
  _StaffRole.superAdmin   => 'Super Admin',
  _StaffRole.admin        => 'Admin',
  _StaffRole.reviewer     => 'Reviewer',
  _StaffRole.viewer       => 'Viewer',
  _StaffRole.support      => 'Support',
};

// ── reusable small widgets ───────────────────────────────────────────────────

class _StatChip extends StatefulWidget {
  final IconData icon;
  final Color iconBg, iconBorder, iconColor;
  final String value, label;
  const _StatChip({required this.icon, required this.iconBg, required this.iconBorder,
    required this.iconColor, required this.value, required this.label});
  @override State<_StatChip> createState() => _StatChipState();
}
class _StatChipState extends State<_StatChip> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hover ? const Color(0x47C41E3A) : _kBorder, width: 1.5),
            boxShadow: [BoxShadow(
              color: _hover ? const Color(0x1AC41E3A) : const Color(0x0AC41E3A),
              blurRadius: _hover ? 20 : 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              transform: Matrix4.rotationZ(_hover ? -0.087 : 0)..scaleByDouble(_hover ? 1.08 : 1.0, _hover ? 1.08 : 1.0, _hover ? 1.08 : 1.0, 1.0),
              transformAlignment: Alignment.center,
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: widget.iconBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.iconBorder),
              ),
              child: Icon(widget.icon, size: 15, color: widget.iconColor),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.value, style: GoogleFonts.dmSerifDisplay(
                fontSize: 18, fontWeight: FontWeight.w900, color: _kDark, letterSpacing: -0.3, height: 1)),
              const SizedBox(height: 2),
              Text(widget.label, style: GoogleFonts.dmSans(
                fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final bool sorted;
  const _TH({required this.label, this.sorted = false});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: GoogleFonts.dmSans(
        fontSize: 10, fontWeight: FontWeight.w600,
        letterSpacing: 0.1, color: sorted ? _kRed : _kMuted)),
      if (sorted) ...[
        const SizedBox(width: 3),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: _kRed),
      ],
    ]);
  }
}

class _StaffRow extends StatefulWidget {
  final _StaffEntry entry;
  const _StaffRow({required this.entry});
  @override State<_StaffRow> createState() => _StaffRowState();
}
class _StaffRowState extends State<_StaffRow> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hover ? _kRedSoft : Colors.white,
          border: Border(
            left: BorderSide(color: _hover ? _kRed : Colors.transparent, width: 3),
            bottom: const BorderSide(color: Color(0x0DC41E3A)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 28, child: Checkbox(
            value: false, onChanged: (_) {},
            activeColor: _kRed,
            side: const BorderSide(color: _kRedMid, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          )),
          const SizedBox(width: 8),
          // Name + avatar
          Expanded(flex: 20, child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [e.avatarColor, Color.lerp(e.avatarColor, Colors.black, 0.3)!]),
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Center(child: Text(e.initials, style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: _kDark)),
              Text(e.email, style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted, fontWeight: FontWeight.w300)),
            ]),
          ])),
          // Department
          Expanded(flex: 12, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.department, style: GoogleFonts.dmSans(fontSize: 12, color: _kDark)),
            Text(e.subRole, style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
          ])),
          // Role badge
          Expanded(flex: 10, child: _RoleBadge(role: e.role)),
          // Last active
          Expanded(flex: 9, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.lastActive, style: GoogleFonts.dmSans(fontSize: 12, color: _kDark)),
            Text(e.lastActiveDetail, style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
          ])),
          // Status
          Expanded(flex: 8, child: _StatusPill(status: e.status)),
          // Actions
          SizedBox(width: 130, child: _ActionRow(status: e.status)),
        ]),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final _StaffRole role;
  const _RoleBadge({required this.role});
  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, label) = switch (role) {
      _StaffRole.superAdmin => (_kRed, Colors.white, _kRedDeep, 'Super Admin'),
      _StaffRole.admin      => (_kRedSoft, _kRed, _kRedMid, 'Admin'),
      _StaffRole.reviewer   => (const Color(0xFFEAF0FF), _kBlue, const Color(0xFFC0CCFF), 'Reviewer'),
      _StaffRole.viewer     => (const Color(0xFFE8F5EE), _kGreen, const Color(0xFFAADDBB), 'Viewer'),
      _StaffRole.support    => (const Color(0xFFFFF3E0), _kAmber, const Color(0xFFFFCC80), 'Support'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(label, style: GoogleFonts.dmSans(
        fontSize: 10, fontWeight: FontWeight.w600,
        letterSpacing: 0.08, color: fg)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final _StaffStatus status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, label, pulse) = switch (status) {
      _StaffStatus.active       => (const Color(0xFFE8F5EE), _kGreen, const Color(0xFFAADDBB), 'Active', true),
      _StaffStatus.inactive     => (_kRedSoft, _kMuted, _kRedMid, 'Inactive', false),
      _StaffStatus.pendingInvite=> (const Color(0xFFFFF3E0), _kAmber, const Color(0xFFFFCC80), 'Pending', false),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _PulseDot(color: fg, pulse: pulse),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 9, fontWeight: FontWeight.w600,
          letterSpacing: 0.08, color: fg)),
      ]),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  final bool pulse;
  const _PulseDot({required this.color, required this.pulse});
  @override State<_PulseDot> createState() => _PulseDotState();
}
class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _anim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.6), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1), weight: 50),
    ]).animate(_ctrl);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) {
      return Container(width: 4, height: 4,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle));
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(width: 4, height: 4,
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final _StaffStatus status;
  const _ActionRow({required this.status});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _QBtn(icon: Icons.visibility_outlined, tip: 'View'),
      const SizedBox(width: 4),
      _QBtn(icon: Icons.edit_outlined, tip: 'Edit Role'),
      const SizedBox(width: 4),
      _QBtn(icon: Icons.mail_outline_rounded, tip: 'Email'),
      const SizedBox(width: 4),
      if (status == _StaffStatus.inactive)
        _QBtn(icon: Icons.refresh_rounded, tip: 'Reactivate', green: true)
      else
        _QBtn(icon: Icons.close_rounded, tip: 'Deactivate', red: true),
    ]);
  }
}

class _QBtn extends StatefulWidget {
  final IconData icon;
  final String tip;
  final bool red, green;
  const _QBtn({required this.icon, required this.tip, this.red = false, this.green = false});
  @override State<_QBtn> createState() => _QBtnState();
}
class _QBtnState extends State<_QBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    Color borderC = _hover
        ? (widget.green ? _kGreen : _kRed)
        : _kBorder;
    Color bgC = _hover
        ? (widget.green ? const Color(0xFFE8F5EE) : _kRedSoft)
        : Colors.white;
    Color iconC = _hover
        ? (widget.green ? _kGreen : _kRed)
        : _kMuted;
    return Tooltip(
      message: widget.tip,
      preferBelow: false,
      textStyle: GoogleFonts.dmSans(fontSize: 9, color: Colors.white),
      decoration: BoxDecoration(color: _kDark, borderRadius: BorderRadius.circular(5)),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: bgC,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: borderC, width: 1.5),
          ),
          child: Icon(widget.icon, size: 13, color: iconC),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _PrimaryBtn({required this.label, required this.icon, this.onTap});
  @override State<_PrimaryBtn> createState() => _PrimaryBtnState();
}
class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hover ? -1 : 0, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_kRed, _kRedDeep]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(
              color: const Color(0x52C41E3A),
              blurRadius: _hover ? 20 : 14, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 13, color: Colors.white),
            const SizedBox(width: 6),
            Text(widget.label, style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
          ]),
        ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  const _OutlineBtn({required this.label, required this.icon});
  @override State<_OutlineBtn> createState() => _OutlineBtnState();
}
class _OutlineBtnState extends State<_OutlineBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _hover ? _kRed : _kBorder, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, size: 13, color: _hover ? _kRed : _kDark),
          const SizedBox(width: 6),
          Text(widget.label, style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w400,
            color: _hover ? _kRed : _kDark)),
        ]),
      ),
    );
  }
}

class _FilterDrop extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _FilterDrop({required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _kBorder, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: GoogleFonts.dmSans(fontSize: 12, color: _kDark)))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _kMuted),
          style: GoogleFonts.dmSans(fontSize: 12, color: _kDark),
          isDense: true,
        ),
      ),
    );
  }
}

class _PgBtn extends StatefulWidget {
  final String? label;
  final Widget? child;
  final bool active;
  const _PgBtn({this.label, this.child, this.active = false});
  @override State<_PgBtn> createState() => _PgBtnState();
}
class _PgBtnState extends State<_PgBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final on = widget.active || _hover;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: on ? _kRed : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: on ? _kRed : _kBorder, width: 1.5),
        ),
        child: Center(child: widget.child ?? Text(widget.label ?? '',
          style: GoogleFonts.dmSans(fontSize: 12,
            color: on ? Colors.white : _kMuted))),
      ),
    );
  }
}

