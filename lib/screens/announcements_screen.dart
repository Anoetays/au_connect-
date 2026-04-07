import 'dart:async';
import 'package:flutter/material.dart';
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
const _kBlue    = AppTheme.statusReview;
const _kAmber   = AppTheme.statusPending;

// ── data models ──────────────────────────────────────────────────────────────
enum _AnnPriority { normal, urgent, critical }
enum _AnnStatus   { live, scheduled, draft }
enum _AnnAudience { everyone, applicant, student, international, postgraduate }

class _AnnEntry {
  final String id;
  final String title;
  final String body;
  final String time;
  final _AnnPriority priority;
  final _AnnStatus status;
  final _AnnAudience audience;
  final String? statusDetail;
  final int? recipients;

  const _AnnEntry({
    this.id = '',
    required this.title,
    required this.body,
    required this.time,
    required this.priority,
    required this.status,
    required this.audience,
    this.statusDetail,
    this.recipients,
  });
}

String _annTimeAgo(String? isoString) {
  if (isoString == null) return '';
  final dt = DateTime.tryParse(isoString)?.toLocal();
  if (dt == null) return '';
  final d = DateTime.now().difference(dt);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} hr${d.inHours > 1 ? "s" : ""} ago';
  if (d.inDays == 1) return 'Yesterday';
  return '${d.inDays} days ago';
}

_AnnEntry _rowToEntry(Map<String, dynamic> r) {
  final statusStr = (r['status'] as String? ?? 'draft').toLowerCase();
  final status = switch (statusStr) {
    'live'      => _AnnStatus.live,
    'scheduled' => _AnnStatus.scheduled,
    _           => _AnnStatus.draft,
  };
  final priorityStr = (r['priority'] as String? ?? 'normal').toLowerCase();
  final priority = switch (priorityStr) {
    'critical' => _AnnPriority.critical,
    'urgent'   => _AnnPriority.urgent,
    _          => _AnnPriority.normal,
  };
  final audienceStr = (r['target_audience'] ?? r['audience'] ?? 'Everyone')
      .toString().toLowerCase();
  final audience = switch (audienceStr) {
    'applicant'     => _AnnAudience.applicant,
    'student'       => _AnnAudience.student,
    'international' => _AnnAudience.international,
    'postgraduate'  => _AnnAudience.postgraduate,
    _               => _AnnAudience.everyone,
  };
  final scheduledFor = r['scheduled_for'] as String?;
  String? statusDetail;
  if (status == _AnnStatus.scheduled && scheduledFor != null) {
    final dt = DateTime.tryParse(scheduledFor)?.toLocal();
    if (dt != null) {
      const mo = ['Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'];
      final h = dt.hour, m = dt.minute;
      statusDetail = '${mo[dt.month - 1]} ${dt.day} · ${h.toString().padLeft(2,"0")}:${m.toString().padLeft(2,"0")}';
    }
  } else if (status == _AnnStatus.draft) {
    statusDetail = 'Draft — not yet published';
  }
  return _AnnEntry(
    id: r['id']?.toString() ?? '',
    title: r['title'] as String? ?? '',
    body: r['message'] as String? ?? '',
    time: _annTimeAgo(r['created_at'] as String?),
    priority: priority,
    status: status,
    audience: audience,
    statusDetail: statusDetail,
    recipients: r['recipient_count'] as int?,
  );
}

// ── page widget ───────────────────────────────────────────────────────────────
class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});
  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  // compose form state
  final _titleCtrl   = TextEditingController();
  final _bodyCtrl    = TextEditingController();
  _AnnPriority _priority = _AnnPriority.normal;
  final Set<_AnnAudience> _audiences = {_AnnAudience.everyone};
  bool _scheduleLater = false;

  // live data
  List<Map<String, dynamic>> _rows = [];
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  // recent list filters
  String _search = '';
  String _statusFilter = 'All Status';
  String _audienceFilter = 'All Audiences';

  List<_AnnEntry> get _anns => _rows.map(_rowToEntry).toList();

  @override
  void initState() {
    super.initState();
    _bodyCtrl.addListener(() => setState(() {}));
    _sub = SupabaseService.streamAdminAnnouncements().listen(
      (rows) { if (mounted) setState(() => _rows = rows); },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  List<_AnnEntry> get _filtered {
    var list = _anns.toList();
    if (_statusFilter != 'All Status') {
      final map = {'Live': _AnnStatus.live, 'Scheduled': _AnnStatus.scheduled,
        'Draft': _AnnStatus.draft};
      final s = map[_statusFilter];
      if (s != null) list = list.where((a) => a.status == s).toList();
    }
    if (_audienceFilter != 'All Audiences') {
      final map = {
        'Everyone': _AnnAudience.everyone, 'Applicant': _AnnAudience.applicant,
        'Student': _AnnAudience.student, 'International': _AnnAudience.international,
      };
      final a = map[_audienceFilter];
      if (a != null) list = list.where((e) => e.audience == a).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((e) =>
        e.title.toLowerCase().contains(q) ||
        e.body.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> _deleteAnn(String id) async {
    if (id.isEmpty) return;
    try {
      await SupabaseService.deleteAnnouncement(id);
    } catch (_) {}
  }

  Future<void> _postAnnouncement() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final body     = _bodyCtrl.text.trim();
    final priority = switch (_priority) {
      _AnnPriority.critical => 'Critical',
      _AnnPriority.urgent   => 'Urgent',
      _AnnPriority.normal   => 'Normal',
    };
    final isEveryone = _audiences.contains(_AnnAudience.everyone);
    final audience = isEveryone
        ? 'Everyone'
        : switch (_audiences.first) {
            _AnnAudience.applicant     => 'Applicant',
            _AnnAudience.student       => 'Student',
            _AnnAudience.international => 'International',
            _AnnAudience.postgraduate  => 'Postgraduate',
            _AnnAudience.everyone      => 'Everyone',
          };
    final status = _scheduleLater ? 'Scheduled' : 'Live';

    // Persist announcement row to Supabase
    try {
      await SupabaseService.postAnnouncement(
        title: title,
        message: body,
        priority: priority,
        audience: audience,
        status: status,
      );
      final user = SupabaseService.currentUser;
      await SupabaseService.insertAuditLog(
        adminName: user?.email ?? 'Admin',
        adminRole: 'Admin',
        actionType: 'Created',
        description: 'Announcement created — "$title"',
        targetId: title,
        targetType: 'Announcement',
      );
    } catch (_) {}

    // Broadcast notification rows to matching applicants (only when Live)
    if (!_scheduleLater) {
      try {
        // Determine audience type filter
        String? audienceFilter;
        if (!isEveryone && _audiences.isNotEmpty) {
          audienceFilter = switch (_audiences.first) {
            _AnnAudience.international => 'international',
            _AnnAudience.postgraduate  => 'masters',
            _AnnAudience.applicant     => null, // all applicants
            _AnnAudience.student       => null,
            _AnnAudience.everyone      => null,
          };
        }
        await SupabaseService.broadcastAnnouncementToApplicants(
          title: title,
          body: body.isNotEmpty ? body : title,
          audienceType: audienceFilter,
        );
      } catch (_) {}
    }

    // Stream will auto-refresh — just reset the form
    if (!mounted) return;
    setState(() {
      _titleCtrl.clear();
      _bodyCtrl.clear();
      _priority = _AnnPriority.normal;
      _audiences.clear();
      _audiences.add(_AnnAudience.everyone);
      _scheduleLater = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 64),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildHeader(),
        const SizedBox(height: 14),
        _buildStatStrip(),
        const SizedBox(height: 14),
        _buildTwoCol(),
      ]),
    );
  }

  // ── header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(text: TextSpan(
        style: GoogleFonts.dmSerifDisplay(fontSize: 22, fontWeight: FontWeight.w900, color: _kDark, letterSpacing: -0.4),
        children: const [
          TextSpan(text: 'Announcements', style: TextStyle(color: _kRed, fontStyle: FontStyle.italic)),
        ],
      )),
      const SizedBox(height: 3),
      Text('Broadcast messages to applicants and students.',
        style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w300)),
    ]);
  }

  // ── stat strip ──────────────────────────────────────────────────────────────
  Widget _buildStatStrip() {
    final live      = _anns.where((a) => a.status == _AnnStatus.live).length;
    final scheduled = _anns.where((a) => a.status == _AnnStatus.scheduled).length;
    return Row(children: [
      _StatChip(icon: Icons.campaign_outlined, iconBg: _kRedSoft, iconBorder: _kRedMid,
        iconColor: _kRed, value: '${_anns.length}', label: 'Total Sent'),
      const SizedBox(width: 10),
      _StatChip(icon: Icons.timer_outlined, iconBg: const Color(0xFFE8F5EE),
        iconBorder: const Color(0xFFAADDBB), iconColor: _kGreen, value: '$live', label: 'Live Now'),
      const SizedBox(width: 10),
      _StatChip(icon: Icons.event_outlined, iconBg: const Color(0xFFFFF3E0),
        iconBorder: const Color(0xFFFFCC80), iconColor: _kAmber, value: '$scheduled', label: 'Scheduled'),
      const SizedBox(width: 10),
      _StatChip(icon: Icons.visibility_outlined, iconBg: const Color(0xFFEAF0FF),
        iconBorder: const Color(0xFFC0CCFF), iconColor: _kBlue, value: '1,847', label: 'Total Reach'),
    ]);
  }

  // ── two-col layout ───────────────────────────────────────────────────────────
  Widget _buildTwoCol() {
    return LayoutBuilder(builder: (ctx, bc) {
      final wide = bc.maxWidth > 700;
      if (wide) {
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _buildComposeCard()),
            const SizedBox(width: 14),
            Expanded(child: _buildRecentCard()),
          ]),
        );
      }
      return Column(children: [
        _buildComposeCard(),
        const SizedBox(height: 14),
        _buildRecentCard(),
      ]);
    });
  }

  // ── compose card ─────────────────────────────────────────────────────────────
  Widget _buildComposeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x0DC41E3A), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // card header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF5E8EB))),
            gradient: LinearGradient(colors: [Color(0x08C41E3A), Colors.transparent]),
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: _kRedSoft, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kRedMid)),
              child: const Icon(Icons.edit_outlined, size: 15, color: _kRed),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('New Announcement', style: GoogleFonts.dmSerifDisplay(
                fontSize: 14, fontWeight: FontWeight.w700, color: _kDark)),
              Text('Compose and send to your audience', style: GoogleFonts.dmSans(
                fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
            ]),
          ]),
        ),
        // body
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // title
            _FieldLabel(label: 'Title'),
            const SizedBox(height: 6),
            _InputWrap(child: TextField(
              controller: _titleCtrl,
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w300, color: _kDark),
              decoration: InputDecoration(
                border: InputBorder.none, isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                hintText: 'Enter announcement title…',
                hintStyle: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFFC8B8BB), fontWeight: FontWeight.w300),
              ),
            )),
            const SizedBox(height: 14),
            // message
            _FieldLabel(label: 'Message'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder, width: 1.5),
              ),
              child: TextField(
                controller: _bodyCtrl,
                maxLines: 5,
                maxLength: 1000,
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w300, color: _kDark, height: 1.6),
                decoration: InputDecoration(
                  border: InputBorder.none, isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  counterText: '',
                  hintText: 'Write your announcement message here…',
                  hintStyle: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFFC8B8BB), fontWeight: FontWeight.w300),
                ),
              ),
            ),
            Align(alignment: Alignment.centerRight,
              child: Text('${_bodyCtrl.text.length} / 1000 characters',
                style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted, fontWeight: FontWeight.w300))),
            const SizedBox(height: 14),
            // priority
            _FieldLabel(label: 'Priority'),
            const SizedBox(height: 8),
            _buildPriorityRow(),
            const SizedBox(height: 14),
            // audience
            _FieldLabel(label: 'Target Audience'),
            const SizedBox(height: 8),
            _buildAudienceRow(),
            const SizedBox(height: 14),
            // delivery toggle
            _FieldLabel(label: 'Delivery'),
            const SizedBox(height: 8),
            Row(children: [
              _AnimToggle(value: _scheduleLater,
                onChanged: (v) => setState(() => _scheduleLater = v)),
              const SizedBox(width: 8),
              Text('Schedule for later', style: GoogleFonts.dmSans(
                fontSize: 12, color: _kMuted, fontWeight: FontWeight.w300)),
              if (_scheduleLater) ...[
                const SizedBox(width: 10),
                Expanded(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder, width: 1.5),
                  ),
                  child: Text('Pick date & time', style: GoogleFonts.dmSans(
                    fontSize: 12, color: _kMuted, fontWeight: FontWeight.w300)),
                )),
              ],
            ]),
            const SizedBox(height: 14),
            // attachment
            _FieldLabel(label: 'Attachment'),
            const SizedBox(height: 8),
            Row(children: [
              _AttachBtn(),
              const SizedBox(width: 10),
              Text('PDF, DOC, JPG up to 10MB', style: GoogleFonts.dmSans(
                fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
            ]),
            const SizedBox(height: 18),
            // action buttons
            Row(children: [
              _SmallBtn(icon: Icons.description_outlined, label: 'Save Draft'),
              const SizedBox(width: 8),
              _SmallBtn(icon: Icons.visibility_outlined, label: 'Preview'),
              const SizedBox(width: 8),
              Expanded(child: _PostBtn(onTap: _postAnnouncement)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPriorityRow() {
    return Wrap(spacing: 8, children: [
      _PriorityPill(
        label: 'Normal', icon: Icons.circle_outlined,
        active: _priority == _AnnPriority.normal,
        activeStyle: _PillStyle.normal,
        onTap: () => setState(() => _priority = _AnnPriority.normal),
      ),
      _PriorityPill(
        label: 'Urgent', icon: Icons.warning_amber_outlined,
        active: _priority == _AnnPriority.urgent,
        activeStyle: _PillStyle.urgent,
        onTap: () => setState(() => _priority = _AnnPriority.urgent),
      ),
      _PriorityPill(
        label: 'Critical', icon: Icons.bolt_outlined,
        active: _priority == _AnnPriority.critical,
        activeStyle: _PillStyle.critical,
        onTap: () => setState(() => _priority = _AnnPriority.critical),
      ),
    ]);
  }

  Widget _buildAudienceRow() {
    const pills = [
      ('Everyone', _AnnAudience.everyone, null),
      ('Applicant', _AnnAudience.applicant, _kBlue),
      ('Student', _AnnAudience.student, _kGreen),
      ('International', _AnnAudience.international, Color(0xFF7040BB)),
      ('Postgraduate', _AnnAudience.postgraduate, _kAmber),
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: pills.map((p) {
      final active = _audiences.contains(p.$2);
      final activeColor = p.$3 ?? _kRed;
      return GestureDetector(
        onTap: () => setState(() {
          if (active) { _audiences.remove(p.$2); }
          else { _audiences.add(p.$2); }
          if (_audiences.isEmpty) _audiences.add(_AnnAudience.everyone);
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? activeColor : _kBorder, width: 1.5),
          ),
          child: Text(p.$1, style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: active ? FontWeight.w500 : FontWeight.w400,
            color: active ? Colors.white : _kMuted)),
        ),
      );
    }).toList());
  }

  // ── recent card ──────────────────────────────────────────────────────────────
  Widget _buildRecentCard() {
    final items = _filtered;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x0DC41E3A), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(children: [
        // header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF5E8EB))),
            gradient: LinearGradient(colors: [Color(0x08C41E3A), Colors.transparent]),
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC0CCFF))),
              child: const Icon(Icons.campaign_outlined, size: 15, color: _kBlue),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recent Announcements', style: GoogleFonts.dmSerifDisplay(
                fontSize: 14, fontWeight: FontWeight.w700, color: _kDark)),
              Text('3 active · 2 scheduled · 7 archived', style: GoogleFonts.dmSans(
                fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
            ]),
          ]),
        ),
        // toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kBorder))),
          child: Row(children: [
            Expanded(child: Container(
              height: 36,
              decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _kBorder, width: 1.5)),
              child: Row(children: [
                const SizedBox(width: 8),
                const Icon(Icons.search, size: 13, color: _kMuted),
                const SizedBox(width: 6),
                Expanded(child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w300, color: _kDark),
                  decoration: InputDecoration(
                    border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                    hintText: 'Search announcements…',
                    hintStyle: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFFC8B8BB)),
                  ),
                )),
              ]),
            )),
            const SizedBox(width: 8),
            _SmFilterDrop(value: _statusFilter,
              items: const ['All Status','Live','Scheduled','Draft','Expired'],
              onChanged: (v) => setState(() => _statusFilter = v)),
            const SizedBox(width: 8),
            _SmFilterDrop(value: _audienceFilter,
              items: const ['All Audiences','Everyone','Applicant','Student','International'],
              onChanged: (v) => setState(() => _audienceFilter = v)),
          ]),
        ),
        // list
        ...List.generate(items.length, (i) => _AnnItemWidget(
          entry: items[i],
          onDelete: () => _deleteAnn(items[i].id),
        )),
        // footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: _kBorder))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            RichText(text: TextSpan(
              style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300),
              children: [
                const TextSpan(text: 'Showing '),
                TextSpan(text: '1–${items.length}',
                  style: const TextStyle(color: _kDark, fontWeight: FontWeight.w500)),
                const TextSpan(text: ' of '),
                TextSpan(text: '${_anns.length}',
                  style: const TextStyle(color: _kDark, fontWeight: FontWeight.w500)),
                const TextSpan(text: ' announcements'),
              ],
            )),
            Row(children: [
              _PgB(child: const Icon(Icons.chevron_left, size: 13)),
              const SizedBox(width: 4),
              _PgB(label: '1', active: true),
              const SizedBox(width: 4),
              _PgB(label: '2'),
              const SizedBox(width: 4),
              _PgB(label: '3'),
              const SizedBox(width: 4),
              _PgB(child: const Icon(Icons.chevron_right, size: 13)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ── announcement item widget ──────────────────────────────────────────────────
class _AnnItemWidget extends StatefulWidget {
  final _AnnEntry entry;
  final VoidCallback onDelete;
  const _AnnItemWidget({required this.entry, required this.onDelete});
  @override State<_AnnItemWidget> createState() => _AnnItemWidgetState();
}
class _AnnItemWidgetState extends State<_AnnItemWidget> {
  bool _hover = false;

  Color get _leftBorderColor => switch (widget.entry.priority) {
    _AnnPriority.critical => _kRedDeep,
    _AnnPriority.urgent   => _kAmber,
    _AnnPriority.normal   => _kRed,
  };

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
            left: BorderSide(color: _hover ? _leftBorderColor : Colors.transparent, width: 3),
            bottom: const BorderSide(color: Color(0x10C41E3A)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // top row
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Wrap(spacing: 6, runSpacing: 4, children: [
              Text(e.title, style: GoogleFonts.dmSerifDisplay(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: _hover ? _kRedDeep : _kDark)),
              if (e.priority == _AnnPriority.critical)
                _AnnBadge(label: 'Critical', bg: _kRed, fg: Colors.white, border: _kRedDeep),
              if (e.priority == _AnnPriority.urgent)
                _AnnBadge(label: 'Urgent',
                  bg: const Color(0xFFFFF3E0), fg: _kAmber, border: const Color(0xFFFFCC80)),
              _AudienceBadge(audience: e.audience),
            ])),
            const SizedBox(width: 8),
            // actions + time
            Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedOpacity(
                opacity: _hover ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Row(children: [
                  _AnnActBtn(icon: Icons.edit_outlined),
                  const SizedBox(width: 4),
                  _AnnActBtn(icon: Icons.copy_outlined),
                  const SizedBox(width: 4),
                  _AnnActBtn(icon: Icons.delete_outline_rounded, onTap: widget.onDelete),
                  const SizedBox(width: 6),
                ]),
              ),
              Text(e.time, style: GoogleFonts.dmSans(
                fontSize: 10, color: _kMuted, fontWeight: FontWeight.w300)),
            ]),
          ]),
          const SizedBox(height: 6),
          // body text (2 lines max)
          Text(e.body,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted,
              fontWeight: FontWeight.w300, height: 1.5)),
          const SizedBox(height: 8),
          // footer
          Row(children: [
            _StatusDot(status: e.status),
            const SizedBox(width: 5),
            Text(
              e.statusDetail ?? (e.status == _AnnStatus.live ? 'Live' : ''),
              style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w500,
                color: switch (e.status) {
                  _AnnStatus.live      => _kGreen,
                  _AnnStatus.scheduled => _kAmber,
                  _AnnStatus.draft     => _kMuted,
                }),
            ),
            if (e.recipients != null) ...[
              const SizedBox(width: 10),
              Icon(Icons.mail_outline_rounded, size: 11, color: _kMuted),
              const SizedBox(width: 3),
              Text('${e.recipients} recipients', style: GoogleFonts.dmSans(
                fontSize: 10, color: _kMuted, fontWeight: FontWeight.w300)),
            ],
            if (e.status == _AnnStatus.scheduled) ...[
              const SizedBox(width: 10),
              Icon(Icons.people_outline_rounded, size: 11, color: _kMuted),
              const SizedBox(width: 3),
              Text('Students only', style: GoogleFonts.dmSans(
                fontSize: 10, color: _kMuted, fontWeight: FontWeight.w300)),
            ],
          ]),
        ]),
      ),
    );
  }
}

// ── status dot with pulse ─────────────────────────────────────────────────────
class _StatusDot extends StatefulWidget {
  final _AnnStatus status;
  const _StatusDot({required this.status});
  @override State<_StatusDot> createState() => _StatusDotState();
}
class _StatusDotState extends State<_StatusDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _anim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1), weight: 50),
    ]).animate(_ctrl);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final color = switch (widget.status) {
      _AnnStatus.live      => _kGreen,
      _AnnStatus.scheduled => _kAmber,
      _AnnStatus.draft     => _kMuted,
    };
    if (widget.status == _AnnStatus.live) {
      return AnimatedBuilder(animation: _anim, builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5)])),
      ));
    }
    return Container(width: 6, height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

// ── small reusable widgets ────────────────────────────────────────────────────
class _AnnBadge extends StatelessWidget {
  final String label;
  final Color bg, fg, border;
  const _AnnBadge({required this.label, required this.bg, required this.fg, required this.border});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: border)),
    child: Text(label, style: GoogleFonts.dmSans(
      fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: fg)),
  );
}

class _AudienceBadge extends StatelessWidget {
  final _AnnAudience audience;
  const _AudienceBadge({required this.audience});
  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, border) = switch (audience) {
      _AnnAudience.everyone     => ('Everyone', _kRedSoft, _kRed, _kRedMid),
      _AnnAudience.applicant    => ('Applicant', const Color(0xFFEAF0FF), _kBlue, const Color(0xFFC0CCFF)),
      _AnnAudience.student      => ('Student', const Color(0xFFE8F5EE), _kGreen, const Color(0xFFAADDBB)),
      _AnnAudience.international=> ('International', const Color(0xFFEFE8F5), const Color(0xFF7040BB), const Color(0xFFCCBBEE)),
      _AnnAudience.postgraduate => ('Postgraduate', const Color(0xFFFFF3E0), _kAmber, const Color(0xFFFFCC80)),
    };
    return _AnnBadge(label: label, bg: bg, fg: fg, border: border);
  }
}

class _AnnActBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _AnnActBtn({required this.icon, this.onTap});
  @override State<_AnnActBtn> createState() => _AnnActBtnState();
}
class _AnnActBtnState extends State<_AnnActBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit:  (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: _hover ? _kRedSoft : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _hover ? _kRed : _kBorder, width: 1.5),
        ),
        child: Icon(widget.icon, size: 10, color: _hover ? _kRed : _kMuted),
      ),
    ),
  );
}

enum _PillStyle { normal, urgent, critical }

class _PriorityPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final _PillStyle activeStyle;
  final VoidCallback onTap;
  const _PriorityPill({required this.label, required this.icon,
    required this.active, required this.activeStyle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = active ? switch (activeStyle) {
      _PillStyle.normal   => (_kRedSoft, _kRed, _kRedMid),
      _PillStyle.urgent   => (const Color(0xFFFFF3E0), _kAmber, const Color(0xFFFFCC80)),
      _PillStyle.critical => (_kRed, Colors.white, _kRedDeep),
    } : (Colors.white, _kMuted, _kBorder);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: fg)),
        ]),
      ),
    );
  }
}

class _AnimToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AnimToggle({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36, height: 20,
        decoration: BoxDecoration(
          color: value ? _kRed : _kRedMid,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Container(width: 16, height: 16,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1))]),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachBtn extends StatefulWidget {
  const _AttachBtn();
  @override State<_AttachBtn> createState() => _AttachBtnState();
}
class _AttachBtnState extends State<_AttachBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit:  (_) => setState(() => _hover = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _hover ? _kRedMid : _kRedSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _hover ? _kRed : _kRedMid,
          width: 1.5, style: BorderStyle.solid),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.attach_file_rounded, size: 13, color: _kRed),
        const SizedBox(width: 5),
        Text('Attach File', style: GoogleFonts.dmSans(
          fontSize: 12, color: _kRed, fontWeight: FontWeight.w400)),
      ]),
    ),
  );
}

class _SmallBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  const _SmallBtn({required this.icon, required this.label});
  @override State<_SmallBtn> createState() => _SmallBtnState();
}
class _SmallBtnState extends State<_SmallBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit:  (_) => setState(() => _hover = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _hover ? _kRed : _kBorder, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(widget.icon, size: 13, color: _hover ? _kRed : _kMuted),
        const SizedBox(width: 5),
        Text(widget.label, style: GoogleFonts.dmSans(
          fontSize: 12, color: _hover ? _kRed : _kMuted)),
      ]),
    ),
  );
}

class _PostBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _PostBtn({required this.onTap});
  @override State<_PostBtn> createState() => _PostBtnState();
}
class _PostBtnState extends State<_PostBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit:  (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [_kRed, _kRedDeep]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
            color: const Color(0x60C41E3A),
            blurRadius: _hover ? 26 : 18, offset: const Offset(0, 5))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.send_rounded, size: 15, color: Colors.white),
          const SizedBox(width: 7),
          Text('Post Announcement', style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
        ]),
      ),
    ),
  );
}

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
  Widget build(BuildContext context) => Expanded(
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
          color: Colors.white, borderRadius: BorderRadius.circular(14),
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
            decoration: BoxDecoration(color: widget.iconBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.iconBorder)),
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

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label, style: GoogleFonts.dmSans(
    fontSize: 10, fontWeight: FontWeight.w500, color: _kDark, letterSpacing: 0.04));
}

class _InputWrap extends StatelessWidget {
  final Widget child;
  const _InputWrap({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kBorder, width: 1.5)),
    child: child,
  );
}

class _SmFilterDrop extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _SmFilterDrop({required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: _kBorder, width: 1.5)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e,
          child: Text(e, style: GoogleFonts.dmSans(fontSize: 11, color: _kDark)))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: _kMuted),
        style: GoogleFonts.dmSans(fontSize: 11, color: _kDark),
        isDense: true,
      ),
    ),
  );
}

class _PgB extends StatefulWidget {
  final String? label;
  final Widget? child;
  final bool active;
  const _PgB({this.label, this.child, this.active = false});
  @override State<_PgB> createState() => _PgBState();
}
class _PgBState extends State<_PgB> {
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
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: on ? _kRed : Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: on ? _kRed : _kBorder, width: 1.5),
        ),
        child: Center(child: widget.child != null
          ? IconTheme(data: IconThemeData(color: on ? Colors.white : _kMuted, size: 13),
              child: widget.child!)
          : Text(widget.label ?? '', style: GoogleFonts.dmSans(
              fontSize: 11, color: on ? Colors.white : _kMuted))),
      ),
    );
  }
}
