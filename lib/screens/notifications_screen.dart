import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
const _kBlue    = AppTheme.statusReview;
const _kAmber   = AppTheme.statusPending;
const _kPurple  = Color(0xFF7040BB);

// ── data models ──────────────────────────────────────────────────────────────
enum _NotifType { application, document, system, user }
enum _NotifStatus { unread, read }

class _NotifEntry {
  final String title;
  final String description;
  final String time;
  final _NotifType type;
  final _NotifStatus status;
  final IconData icon;
  final Color iconBg, iconBorder, iconColor;

  const _NotifEntry({
    required this.title,
    required this.description,
    required this.time,
    required this.type,
    required this.status,
    required this.icon,
    required this.iconBg,
    required this.iconBorder,
    required this.iconColor,
  });
}

final _kNotifs = <_NotifEntry>[
  _NotifEntry(
    title: 'New application submitted — Tariro Moyo',
    description: 'A new Local Applicant submission (AU-2025-0041) requires review. Programme: BSc Computer Science.',
    time: '2 minutes ago',
    type: _NotifType.application, status: _NotifStatus.unread,
    icon: Icons.description_outlined,
    iconBg: const Color(0xFFF5E8EB), iconBorder: const Color(0xFFE8C0C8), iconColor: _kRed,
  ),
  _NotifEntry(
    title: 'Deadline approaching — 2024 Local Intake closes Mar 31',
    description: '89 applications are still pending review. 4 days remaining until the deadline.',
    time: '15 minutes ago',
    type: _NotifType.system, status: _NotifStatus.unread,
    icon: Icons.info_outline_rounded,
    iconBg: const Color(0xFFFFF3E0), iconBorder: const Color(0xFFFFCC80), iconColor: _kAmber,
  ),
  _NotifEntry(
    title: 'Document rejected — Absence letter invalid format',
    description: "Rutendo Chikwanda's absence letter (Re-admission) was rejected. Applicant has been notified.",
    time: '1 hour ago',
    type: _NotifType.document, status: _NotifStatus.unread,
    icon: Icons.folder_outlined,
    iconBg: const Color(0xFFEAF0FF), iconBorder: const Color(0xFFC0CCFF), iconColor: _kBlue,
  ),
  _NotifEntry(
    title: 'New staff member invite accepted — Faith Mufaro',
    description: 'Faith Mufaro has accepted the Reviewer role invitation and their account is now active.',
    time: '3 hours ago',
    type: _NotifType.user, status: _NotifStatus.unread,
    icon: Icons.person_add_outlined,
    iconBg: const Color(0xFFEFE8F5), iconBorder: const Color(0xFFCCBBEE), iconColor: _kPurple,
  ),
  _NotifEntry(
    title: 'Application approved — Amara Diallo',
    description: 'MSc Public Health application approved. Acceptance offer email sent automatically.',
    time: '5 hours ago',
    type: _NotifType.application, status: _NotifStatus.unread,
    icon: Icons.check_circle_outline_rounded,
    iconBg: const Color(0xFFE8F5EE), iconBorder: const Color(0xFFAADDBB), iconColor: _kGreen,
  ),
  _NotifEntry(
    title: 'Application denied — James Ndlovu',
    description: 'LLB Transfer application (AU-2025-0044) denied. Applicant notified via email.',
    time: 'Yesterday · 3:12pm',
    type: _NotifType.application, status: _NotifStatus.read,
    icon: Icons.description_outlined,
    iconBg: const Color(0xFFF5E8EB), iconBorder: const Color(0xFFE8C0C8), iconColor: _kRed,
  ),
  _NotifEntry(
    title: '12 documents pending verification',
    description: 'Documents uploaded in the last 24 hours are awaiting admin review and verification.',
    time: 'Yesterday · 9:00am',
    type: _NotifType.document, status: _NotifStatus.read,
    icon: Icons.folder_outlined,
    iconBg: const Color(0xFFEAF0FF), iconBorder: const Color(0xFFC0CCFF), iconColor: _kBlue,
  ),
];

// ── page widget ───────────────────────────────────────────────────────────────
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _search = '';
  String _typeFilter = 'All Types';
  String _statusFilter = 'All Status';
  int _tabIdx = 0;
  late List<_NotifEntry> _notifs;

  @override
  void initState() {
    super.initState();
    _notifs = List<_NotifEntry>.from(_kNotifs);
  }


  List<_NotifEntry> get _filtered {
    var list = _notifs.toList();
    // tab filter
    if (_tabIdx == 1) {
      list = list.where((n) => n.status == _NotifStatus.unread).toList();
    } else if (_tabIdx > 1) {
      final types = [
        null,
        null,
        [_NotifType.application],
        [_NotifType.document],
        [_NotifType.system],
      ][_tabIdx];
      if (types != null) list = list.where((n) => types.contains(n.type)).toList();
    }
    // dropdown filters
    if (_typeFilter != 'All Types') {
      final map = {
        'Application': _NotifType.application,
        'Document': _NotifType.document,
        'System': _NotifType.system,
        'User': _NotifType.user,
      };
      final t = map[_typeFilter];
      if (t != null) list = list.where((n) => n.type == t).toList();
    }
    if (_statusFilter == 'Unread') {
      list = list.where((n) => n.status == _NotifStatus.unread).toList();
    } else if (_statusFilter == 'Read') {
      list = list.where((n) => n.status == _NotifStatus.read).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((n) =>
        n.title.toLowerCase().contains(q) ||
        n.description.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  int _tabCount(int idx) {
    if (idx == 0) return _notifs.length;
    if (idx == 1) return _notifs.where((n) => n.status == _NotifStatus.unread).length;
    final types = [[_NotifType.application], [_NotifType.document], [_NotifType.system]][idx - 2];
    return _notifs.where((n) => types.contains(n.type)).length;
  }

  void _dismiss(int idx) {
    final item = _filtered[idx];
    setState(() => _notifs.removeWhere((n) => n.title == item.title));
  }

  void _markAllRead() {
    setState(() {
      _notifs = _notifs.map((n) => n.status == _NotifStatus.unread
        ? _NotifEntry(
            title: n.title, description: n.description, time: n.time,
            type: n.type, status: _NotifStatus.read,
            icon: n.icon, iconBg: n.iconBg, iconBorder: n.iconBorder, iconColor: n.iconColor)
        : n).toList();
    });
  }

  void _clearAll() => setState(() => _notifs.clear());

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
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
          _buildList(items),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RichText(text: TextSpan(
              style: GoogleFonts.dmSerifDisplay(fontSize: 22, fontWeight: FontWeight.w900, color: _kDark, letterSpacing: -0.4),
              children: const [
                TextSpan(text: 'Notifications', style: TextStyle(color: _kRed, fontStyle: FontStyle.italic)),
              ],
            )),
            const SizedBox(height: 3),
            Text('System alerts, application updates and activity notifications.',
              style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w300)),
          ]),
        ),
        const SizedBox(width: 12),
        _OutlineBtn(icon: Icons.check_outlined, label: 'Mark All Read', onTap: _markAllRead),
        const SizedBox(width: 8),
        _OutlineBtn(icon: Icons.delete_outline_rounded, label: 'Clear All', onTap: _clearAll),
      ],
    );
  }

  // ── stat strip ──────────────────────────────────────────────────────────────
  Widget _buildStatStrip() {
    final unread = _notifs.where((n) => n.status == _NotifStatus.unread).length;
    final apps   = _notifs.where((n) => n.type == _NotifType.application).length;
    final docs   = _notifs.where((n) => n.type == _NotifType.document).length;
    return Row(children: [
      _StatChip(icon: Icons.notifications_outlined, iconBg: _kRedSoft, iconBorder: _kRedMid,
        iconColor: _kRed, value: '${_notifs.length}', label: 'Total'),
      const SizedBox(width: 10),
      _StatChip(icon: Icons.info_outline_rounded, iconBg: const Color(0xFFFFF3E0),
        iconBorder: const Color(0xFFFFCC80), iconColor: _kAmber, value: '$unread', label: 'Unread'),
      const SizedBox(width: 10),
      _StatChip(icon: Icons.description_outlined, iconBg: const Color(0xFFEAF0FF),
        iconBorder: const Color(0xFFC0CCFF), iconColor: _kBlue, value: '$apps', label: 'Applications'),
      const SizedBox(width: 10),
      _StatChip(icon: Icons.folder_outlined, iconBg: const Color(0xFFE8F5EE),
        iconBorder: const Color(0xFFAADDBB), iconColor: _kGreen, value: '$docs', label: 'Documents'),
    ]);
  }

  // ── toolbar ─────────────────────────────────────────────────────────────────
  Widget _buildToolbar() {
    return Row(children: [
      Expanded(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surface,
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
                hintText: 'Search notifications…',
                hintStyle: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFFC8B8BB), fontWeight: FontWeight.w300),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      _FilterDrop(value: _typeFilter,
        items: const ['All Types','Application','Document','System','User'],
        onChanged: (v) => setState(() => _typeFilter = v)),
      const SizedBox(width: 8),
      _FilterDrop(value: _statusFilter,
        items: const ['All Status','Unread','Read'],
        onChanged: (v) => setState(() => _statusFilter = v)),
    ]);
  }

  // ── tabs ────────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kBorder))),
      child: Row(children: List.generate(5, (i) {
        final active = _tabIdx == i;
        final label = ['All','Unread','Applications','Documents','System'][i];
        final count = _tabCount(i);
        return GestureDetector(
          onTap: () => setState(() => _tabIdx = i),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(
              color: active ? _kRed : Colors.transparent, width: 2))),
            child: Row(children: [
              Text(label, style: GoogleFonts.dmSans(
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

  // ── notification list ────────────────────────────────────────────────────────
  Widget _buildList(List<_NotifEntry> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder, width: 1.5),
        ),
        child: Column(children: [
          const Icon(Icons.notifications_off_outlined, size: 36, color: _kMuted),
          const SizedBox(height: 10),
          Text('No notifications', style: GoogleFonts.dmSerifDisplay(
            fontSize: 16, fontWeight: FontWeight.w700, color: _kDark)),
          const SizedBox(height: 4),
          Text('Nothing to show for the selected filters.',
            style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w300)),
        ]),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(children: [
        ...List.generate(items.length, (i) => _NotifItemWidget(
          entry: items[i],
          onDismiss: () => _dismiss(i),
        )),
        _buildPagination(items.length),
      ]),
    );
  }

  Widget _buildPagination(int showing) {
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
              TextSpan(text: '1–$showing', style: const TextStyle(color: _kDark, fontWeight: FontWeight.w500)),
              const TextSpan(text: ' of '),
              TextSpan(text: '${_notifs.length}', style: const TextStyle(color: _kDark, fontWeight: FontWeight.w500)),
              const TextSpan(text: ' notifications'),
            ],
          )),
          Row(children: [
            _PgBtn(child: const Icon(Icons.chevron_left, size: 14)),
            const SizedBox(width: 4),
            _PgBtn(label: '1', active: true),
            const SizedBox(width: 4),
            _PgBtn(label: '2'),
            const SizedBox(width: 4),
            _PgBtn(label: '3'),
            const SizedBox(width: 4),
            _PgBtn(child: const Icon(Icons.chevron_right, size: 14)),
          ]),
        ],
      ),
    );
  }
}

// ── notification item ─────────────────────────────────────────────────────────
class _NotifItemWidget extends StatefulWidget {
  final _NotifEntry entry;
  final VoidCallback onDismiss;
  const _NotifItemWidget({required this.entry, required this.onDismiss});
  @override
  State<_NotifItemWidget> createState() => _NotifItemWidgetState();
}

class _NotifItemWidgetState extends State<_NotifItemWidget> {
  bool _hover = false;

  String get _tagLabel => switch (widget.entry.type) {
    _NotifType.application => 'Application',
    _NotifType.document    => 'Document',
    _NotifType.system      => 'System',
    _NotifType.user        => 'User',
  };

  (Color, Color, Color) get _tagColors => switch (widget.entry.type) {
    _NotifType.application => (_kRedSoft, _kRed, _kRedMid),
    _NotifType.document    => (const Color(0xFFEAF0FF), _kBlue, const Color(0xFFC0CCFF)),
    _NotifType.system      => (const Color(0xFFEFE8F5), _kPurple, const Color(0xFFCCBBEE)),
    _NotifType.user        => (const Color(0xFFE8F5EE), _kGreen, const Color(0xFFAADDBB)),
  };

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isUnread = e.status == _NotifStatus.unread;
    final tagC = _tagColors;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hover
              ? _kRedSoft
              : isUnread
                  ? const Color(0x08C41E3A)
                  : AppTheme.surface,
          border: Border(
            left: BorderSide(color: isUnread ? _kRed : Colors.transparent, width: 3),
            bottom: const BorderSide(color: Color(0x10C41E3A)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // icon
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: e.iconBg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: e.iconBorder),
            ),
            child: Icon(e.icon, size: 16, color: e.iconColor),
          ),
          const SizedBox(width: 12),
          // body
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.title, style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: _hover ? _kRedDeep : _kDark)),
            const SizedBox(height: 3),
            Text(e.description, style: GoogleFonts.dmSans(
              fontSize: 12, color: _kMuted, fontWeight: FontWeight.w300, height: 1.5)),
            const SizedBox(height: 5),
            Row(children: [
              Text(e.time, style: GoogleFonts.dmSans(
                fontSize: 10, color: _kMuted, fontWeight: FontWeight.w300)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: tagC.$1,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tagC.$3),
                ),
                child: Text(_tagLabel, style: GoogleFonts.dmSans(
                  fontSize: 9, fontWeight: FontWeight.w500,
                  letterSpacing: 0.08, color: tagC.$2)),
              ),
            ]),
          ])),
          const SizedBox(width: 10),
          // right side
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (isUnread)
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: _kRed, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _kRed.withValues(alpha: 0.5), blurRadius: 5)],
                ),
              ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              opacity: _hover ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: _DismissBtn(onTap: widget.onDismiss),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _DismissBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _DismissBtn({required this.onTap});
  @override State<_DismissBtn> createState() => _DismissBtnState();
}
class _DismissBtnState extends State<_DismissBtn> {
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
          duration: const Duration(milliseconds: 150),
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: _hover ? _kRedSoft : AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kBorder, width: 1.5),
          ),
          child: Icon(Icons.close, size: 11, color: _hover ? _kRed : _kMuted),
        ),
      ),
    );
  }
}

// ── shared small widgets ──────────────────────────────────────────────────────
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
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hover ? const Color(0x47C41E3A) : _kBorder, width: 1.5),
            boxShadow: [BoxShadow(
              color: _hover ? const Color(0x1AC41E3A) : const Color(0x0AC41E3A),
              blurRadius: _hover ? 20 : 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              transform: Matrix4.rotationZ(_hover ? -0.087 : 0)
                ..scaleByDouble(_hover ? 1.08 : 1.0, _hover ? 1.08 : 1.0, _hover ? 1.08 : 1.0, 1.0),
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

class _OutlineBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _OutlineBtn({required this.label, required this.icon, this.onTap});
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
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppTheme.surface,
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
        color: AppTheme.surface,
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
          color: on ? _kRed : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: on ? _kRed : _kBorder, width: 1.5),
        ),
        child: Center(child: widget.child != null
          ? IconTheme(data: IconThemeData(color: on ? Colors.white : _kMuted, size: 14),
              child: widget.child!)
          : Text(widget.label ?? '', style: GoogleFonts.dmSans(
              fontSize: 12, color: on ? Colors.white : _kMuted))),
      ),
    );
  }
}
