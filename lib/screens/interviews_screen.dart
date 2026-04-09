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
enum _IvStatus   { scheduled, upcoming, completed, cancelled, rescheduled }
enum _IvFormat   { inPerson, virtual, phone }
enum _IvCardType { today, upcoming, done }

class _Interview {
  final String id;
  final String applicant;
  final String applicantId;
  final String programme;
  final String applicantType;
  final String date;
  final String time;
  final String location;
  final _IvFormat format;
  final _IvStatus status;
  final _IvCardType? cardType;
  final Color avatarColor;
  final String initials;
  final String interviewerInitials;
  final Color interviewerColor;

  const _Interview({
    required this.id,
    required this.applicant,
    required this.applicantId,
    required this.programme,
    required this.applicantType,
    required this.date,
    required this.time,
    required this.location,
    required this.format,
    required this.status,
    this.cardType,
    required this.avatarColor,
    required this.initials,
    required this.interviewerInitials,
    required this.interviewerColor,
  });
}

// ── page ──────────────────────────────────────────────────────────────────────
class InterviewsPage extends StatefulWidget {
  const InterviewsPage({super.key});
  @override
  State<InterviewsPage> createState() => _InterviewsPageState();
}

class _InterviewsPageState extends State<InterviewsPage> {
  String _search = '';
  String _typeFilter = 'All Types';
  String _statusFilter = 'All Status';
  String _progFilter = 'All Programmes';
  int _tabIdx = 0;

  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  static const _avatarColors = [
    Color(0xFFC41E3A), Color(0xFF3A5FCC), Color(0xFF1E8A4A),
    Color(0xFF7040BB), Color(0xFFC07010),
  ];

  @override
  void initState() {
    super.initState();
    _sub = SupabaseService.streamInterviews().listen((rows) {
      setState(() { _rows = rows; _loading = false; });
    }, onError: (_) => setState(() => _loading = false));
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  _Interview _toEntry(Map<String, dynamic> r, int idx) {
    final name = r['applicant_name'] as String? ?? '';
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarColor = _avatarColors[idx % _avatarColors.length];

    final statusStr = r['status'] as String? ?? 'Scheduled';
    final status = switch (statusStr) {
      'Completed'   => _IvStatus.completed,
      'Cancelled'   => _IvStatus.cancelled,
      'Rescheduled' => _IvStatus.rescheduled,
      'Upcoming'    => _IvStatus.upcoming,
      _             => _IvStatus.scheduled,
    };

    final formatStr = r['format'] as String? ?? '';
    final format = switch (formatStr) {
      'Virtual' => _IvFormat.virtual,
      'Phone'   => _IvFormat.phone,
      _         => _IvFormat.inPerson,
    };

    final scheduledDt = DateTime.tryParse(r['scheduled_date'] as String? ?? '')?.toLocal();
    String date = '', time = '';
    _IvCardType? cardType;
    if (scheduledDt != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dt   = DateTime(scheduledDt.year, scheduledDt.month, scheduledDt.day);
      final diff = dt.difference(today).inDays;
      final h = scheduledDt.hour, m = scheduledDt.minute;
      final hStr = h % 12 == 0 ? 12 : h % 12;
      final mStr = m.toString().padLeft(2, '0');
      final ampm = h < 12 ? 'AM' : 'PM';
      time = '$hStr:$mStr $ampm';
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      date = '${months[scheduledDt.month - 1]} ${scheduledDt.day}, ${scheduledDt.year}';
      if (status == _IvStatus.completed) {
        cardType = _IvCardType.done;
      } else if (diff == 0) {
        cardType = _IvCardType.today;
        time = 'Today · $time';
      } else if (diff > 0 && diff <= 7) {
        cardType = _IvCardType.upcoming;
      }
    }

    return _Interview(
      id: r['id']?.toString() ?? '',
      applicant: name,
      applicantId: r['applicant_id'] as String? ?? '',
      programme: r['programme'] as String? ?? '',
      applicantType: r['applicant_type'] as String? ?? '',
      date: date, time: time, location: r['location'] as String? ?? '',
      format: format, status: status, cardType: cardType,
      avatarColor: avatarColor, initials: initials,
      interviewerInitials: r['interviewer_initials'] as String? ?? 'AU',
      interviewerColor: _avatarColors[(idx + 2) % _avatarColors.length],
    );
  }

  List<_Interview> get _interviews =>
      _rows.indexed.map((e) => _toEntry(e.$2, e.$1)).toList();

  List<_Interview> get _filtered {
    var list = _interviews;
    if (_tabIdx == 1) list = list.where((i) => i.cardType == _IvCardType.today).toList();
    if (_tabIdx == 2) list = list.where((i) => i.cardType == _IvCardType.upcoming || i.cardType == _IvCardType.today).toList();
    if (_tabIdx == 3) list = list.where((i) => i.status == _IvStatus.completed).toList();
    if (_tabIdx == 4) list = list.where((i) => i.status == _IvStatus.cancelled).toList();
    if (_typeFilter != 'All Types') {
      final map = {'In-Person': _IvFormat.inPerson, 'Virtual': _IvFormat.virtual, 'Phone': _IvFormat.phone};
      final f = map[_typeFilter];
      if (f != null) list = list.where((i) => i.format == f).toList();
    }
    if (_statusFilter != 'All Status') {
      final map = {'Scheduled': _IvStatus.scheduled, 'Completed': _IvStatus.completed,
        'Cancelled': _IvStatus.cancelled, 'Rescheduled': _IvStatus.rescheduled,
        'Upcoming': _IvStatus.upcoming};
      final s = map[_statusFilter];
      if (s != null) list = list.where((i) => i.status == s).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((i) =>
        i.applicant.toLowerCase().contains(q) ||
        i.programme.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  int _tabCount(int i) {
    final all = _interviews;
    return switch (i) {
      0 => all.length,
      1 => all.where((x) => x.cardType == _IvCardType.today).length,
      2 => all.where((x) => x.cardType == _IvCardType.upcoming || x.cardType == _IvCardType.today).length,
      3 => all.where((x) => x.status == _IvStatus.completed).length,
      4 => all.where((x) => x.status == _IvStatus.cancelled).length,
      _ => 0,
    };
  }

  Future<void> _showScheduleDialog() async {
    final nameCtrl      = TextEditingController();
    final progCtrl      = TextEditingController();
    final locationCtrl  = TextEditingController();
    final interviewerCtrl = TextEditingController();
    final notesCtrl     = TextEditingController();
    String selectedFormat = 'In-Person';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: _kRedSoft, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.event_outlined, size: 16, color: _kRed)),
            const SizedBox(width: 12),
            Text('Schedule Interview',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Applicant Name *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12)),
                  style: GoogleFonts.dmSans(fontSize: 13),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: progCtrl,
                  decoration: InputDecoration(
                    labelText: 'Programme *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12)),
                  style: GoogleFonts.dmSans(fontSize: 13),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedFormat,
                  decoration: InputDecoration(
                    labelText: 'Format',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12)),
                  style: GoogleFonts.dmSans(fontSize: 13, color: _kDark),
                  items: ['In-Person', 'Virtual', 'Phone']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) { if (v != null) setDlg(() => selectedFormat = v); },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    labelText: selectedFormat == 'Virtual' ? 'Meeting Link' : 'Location / Room',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12)),
                  style: GoogleFonts.dmSans(fontSize: 13),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: interviewerCtrl,
                  decoration: InputDecoration(
                    labelText: 'Interviewer Name *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12)),
                  style: GoogleFonts.dmSans(fontSize: 13),
                ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      setDlg(() {
                        selectedDate = time != null
                            ? DateTime(picked.year, picked.month, picked.day, time.hour, time.minute)
                            : picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: _kBorder, width: 1.5),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: _kMuted),
                      const SizedBox(width: 8),
                      Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}  '
                        '${selectedDate.hour.toString().padLeft(2,"0")}:'
                        '${selectedDate.minute.toString().padLeft(2,"0")}',
                        style: GoogleFonts.dmSans(fontSize: 13, color: _kDark)),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12)),
                  style: GoogleFonts.dmSans(fontSize: 13),
                ),
              ]),
            ),
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
                final name       = nameCtrl.text.trim();
                final prog       = progCtrl.text.trim();
                final interviewer = interviewerCtrl.text.trim();
                if (name.isEmpty || prog.isEmpty || interviewer.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await SupabaseService.scheduleInterview(
                    applicationId: '',
                    applicantUserId: '',
                    applicantName: name,
                    programme: prog,
                    applicantType: '',
                    scheduledDate: selectedDate,
                    format: selectedFormat,
                    location: locationCtrl.text.trim(),
                    interviewerName: interviewer,
                    notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                  );
                  final user = SupabaseService.currentUser;
                  await SupabaseService.insertAuditLog(
                    adminName: user?.email ?? 'Admin',
                    adminRole: 'Admin',
                    actionType: 'Interview Scheduled',
                    description: 'Interview scheduled for $name — $prog',
                    targetId: name,
                    targetType: 'Interview',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Interview scheduled for $name'),
                      backgroundColor: _kGreen));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'), backgroundColor: _kRed));
                  }
                }
              },
              child: Text('Schedule', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    progCtrl.dispose();
    locationCtrl.dispose();
    interviewerCtrl.dispose();
    notesCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kRed));
    final items = _filtered;
    final cards = _interviews.where((i) => i.cardType != null).take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 64),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildHeader(),
        const SizedBox(height: 14),
        _buildStatStrip(),
        const SizedBox(height: 14),
        _buildToolbar(),
        const SizedBox(height: 10),
        _buildTabs(),
        const SizedBox(height: 12),
        _buildCardGrid(cards),
        const SizedBox(height: 4),
        _buildTable(items),
      ]),
    );
  }

  // ── header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RichText(text: TextSpan(
          style: GoogleFonts.dmSerifDisplay(fontSize: 22, fontWeight: FontWeight.w900,
            color: _kDark, letterSpacing: -0.4),
          children: const [
            TextSpan(text: 'Interviews', style: TextStyle(color: _kRed, fontStyle: FontStyle.italic)),
          ],
        )),
        const SizedBox(height: 3),
        Text('Schedule and manage applicant interviews for 2026 intake.',
          style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w300)),
      ])),
      const SizedBox(width: 12),
      _OutlineBtn(icon: Icons.download_outlined, label: 'Export Schedule'),
      const SizedBox(width: 8),
      _PrimaryBtn(icon: Icons.add, label: 'Schedule Interview', onTap: _showScheduleDialog),
    ]);
  }

  // ── stat strip ──────────────────────────────────────────────────────────────
  Widget _buildStatStrip() {
    return Row(children: [
      _StatChip(icon: Icons.event_outlined,
        iconBg: _kRedSoft, iconBorder: _kRedMid, iconColor: _kRed,
        value: '${_interviews.length}', label: 'Total Scheduled'),
      const SizedBox(width: 10),
      _StatChip(icon: Icons.timer_outlined,
        iconBg: const Color(0xFFFFF3E0), iconBorder: const Color(0xFFFFCC80), iconColor: _kAmber,
        value: '${_interviews.where((i) => i.cardType == _IvCardType.today).length}', label: 'Today'),
      const SizedBox(width: 10),
      _StatChip(icon: Icons.calendar_month_outlined,
        iconBg: const Color(0xFFEAF0FF), iconBorder: const Color(0xFFC0CCFF), iconColor: _kBlue,
        value: '${_interviews.where((i) => i.cardType == _IvCardType.upcoming).length}', label: 'Upcoming'),
      const SizedBox(width: 10),
      _StatChip(icon: Icons.check_circle_outline_rounded,
        iconBg: const Color(0xFFE8F5EE), iconBorder: const Color(0xFFAADDBB), iconColor: _kGreen,
        value: '${_interviews.where((i) => i.status == _IvStatus.completed).length}', label: 'Completed'),
    ]);
  }

  // ── toolbar ─────────────────────────────────────────────────────────────────
  Widget _buildToolbar() {
    return Row(children: [
      Expanded(child: Container(
        height: 40,
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _kBorder, width: 1.5)),
        child: Row(children: [
          const SizedBox(width: 10),
          const Icon(Icons.search, size: 16, color: _kMuted),
          const SizedBox(width: 6),
          Expanded(child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w300, color: _kDark),
            decoration: InputDecoration(
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
              hintText: 'Search by applicant name or programme…',
              hintStyle: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFFC8B8BB), fontWeight: FontWeight.w300),
            ),
          )),
        ]),
      )),
      const SizedBox(width: 8),
      _FilterDrop(value: _typeFilter,
        items: const ['All Types','In-Person','Virtual','Phone'],
        onChanged: (v) => setState(() => _typeFilter = v)),
      const SizedBox(width: 8),
      _FilterDrop(value: _statusFilter,
        items: const ['All Status','Scheduled','Upcoming','Completed','Cancelled','Rescheduled'],
        onChanged: (v) => setState(() => _statusFilter = v)),
      const SizedBox(width: 8),
      _FilterDrop(value: _progFilter,
        items: const ['All Programmes','BSc Computer Science','MBA Business','LLB Law','MSc Public Health'],
        onChanged: (v) => setState(() => _progFilter = v)),
    ]);
  }

  // ── tabs ────────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    const labels = ['All','Today','This Week','Completed','Cancelled'];
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kBorder))),
      child: Row(children: List.generate(labels.length, (i) {
        final active = _tabIdx == i;
        final count = _tabCount(i);
        return GestureDetector(
          onTap: () => setState(() => _tabIdx = i),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(
              color: active ? _kRed : Colors.transparent, width: 2))),
            child: Row(children: [
              Text(labels[i], style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                color: active ? _kRed : _kMuted)),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? _kRed : _kRedSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? _kRedDeep : _kRedMid)),
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

  // ── card grid ───────────────────────────────────────────────────────────────
  Widget _buildCardGrid(List<_Interview> cards) {
    return LayoutBuilder(builder: (ctx, bc) {
      final cols = bc.maxWidth > 900 ? 3 : bc.maxWidth > 600 ? 2 : 1;
      return Wrap(spacing: 14, runSpacing: 14, children: cards.map((iv) =>
        SizedBox(
          width: (bc.maxWidth - (cols - 1) * 14) / cols,
          child: _IvCard(interview: iv),
        ),
      ).toList());
    });
  }

  // ── table ───────────────────────────────────────────────────────────────────
  Widget _buildTable(List<_Interview> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(children: [
        // head
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0x08C41E3A), Colors.transparent]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            border: Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(children: const [
            Expanded(flex: 20, child: _TH(label: 'Applicant')),
            Expanded(flex: 12, child: _TH(label: 'Programme')),
            Expanded(flex: 10, child: _TH(label: 'Date & Time')),
            Expanded(flex: 10, child: _TH(label: 'Format')),
            Expanded(flex: 9,  child: _TH(label: 'Status')),
            SizedBox(width: 140, child: _TH(label: 'Actions')),
          ]),
        ),
        // rows
        ...items.map((iv) => _TableRow(interview: iv)),
        // pagination
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: _kBorder))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            RichText(text: TextSpan(
              style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300),
              children: [
                const TextSpan(text: 'Showing '),
                TextSpan(text: '1–${items.length}',
                  style: const TextStyle(color: _kDark, fontWeight: FontWeight.w500)),
                const TextSpan(text: ' of '),
                TextSpan(text: '${_interviews.length}',
                  style: const TextStyle(color: _kDark, fontWeight: FontWeight.w500)),
                const TextSpan(text: ' interviews'),
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
          ]),
        ),
      ]),
    );
  }
}

// ── interview card ─────────────────────────────────────────────────────────────
class _IvCard extends StatefulWidget {
  final _Interview interview;
  const _IvCard({required this.interview});
  @override State<_IvCard> createState() => _IvCardState();
}
class _IvCardState extends State<_IvCard> {
  bool _hover = false;

  Color get _topBarColor => switch (widget.interview.cardType) {
    _IvCardType.today    => _kRed,
    _IvCardType.upcoming => _kBlue,
    _IvCardType.done     => _kGreen,
    null                 => _kMuted,
  };

  (Color, Color, Color) get _iconColors => switch (widget.interview.cardType) {
    _IvCardType.today    => (_kRedSoft, _kRedMid, _kRed),
    _IvCardType.upcoming => (const Color(0xFFEAF0FF), const Color(0xFFC0CCFF), _kBlue),
    _IvCardType.done     => (const Color(0xFFE8F5EE), const Color(0xFFAADDBB), _kGreen),
    null                 => (_kRedSoft, _kRedMid, _kMuted),
  };

  IconData get _cardIcon => widget.interview.status == _IvStatus.completed
      ? Icons.check_rounded
      : Icons.person_outline_rounded;

  @override
  Widget build(BuildContext context) {
    final iv = widget.interview;
    final ic = _iconColors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover ? const Color(0x47C41E3A) : _kBorder, width: 1.5),
          boxShadow: [BoxShadow(
            color: _hover ? const Color(0x1AC41E3A) : const Color(0x0AC41E3A),
            blurRadius: _hover ? 28 : 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // coloured top bar
          Container(height: 3,
            decoration: BoxDecoration(
              color: _topBarColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // icon + actions row
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  transform: Matrix4.rotationZ(_hover ? -0.087 : 0)
                    ..scaleByDouble(_hover ? 1.08 : 1.0, _hover ? 1.08 : 1.0, _hover ? 1.08 : 1.0, 1.0),
                  transformAlignment: Alignment.center,
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: ic.$1,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: ic.$2)),
                  child: Icon(_cardIcon, size: 17, color: ic.$3),
                ),
                const Spacer(),
                AnimatedOpacity(
                  opacity: _hover ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Row(children: iv.status == _IvStatus.completed
                    ? [
                        _QBtn(icon: Icons.visibility_outlined, tip: 'View Notes'),
                        const SizedBox(width: 4),
                        _QBtn(icon: Icons.download_outlined, tip: 'Download Report'),
                      ]
                    : [
                        _QBtn(icon: Icons.refresh_rounded, tip: 'Reschedule'),
                        const SizedBox(width: 4),
                        _QBtn(icon: Icons.close_rounded, tip: 'Cancel', red: true),
                      ],
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Text(iv.applicant, style: GoogleFonts.dmSerifDisplay(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: _hover ? _kRedDeep : _kDark)),
              const SizedBox(height: 2),
              Text('${iv.programme} · ${iv.applicantType}',
                style: GoogleFonts.dmSans(
                  fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
              const SizedBox(height: 10),
              // details
              _IvDetail(icon: Icons.access_time_rounded, text: iv.time),
              const SizedBox(height: 5),
              _IvDetail(icon: Icons.calendar_today_outlined, text: iv.date),
              const SizedBox(height: 5),
              _IvDetail(
                icon: iv.format == _IvFormat.inPerson
                    ? Icons.home_outlined
                    : Icons.videocam_outlined,
                text: '${iv.location} · ${_formatLabel(iv.format)}'),
              const SizedBox(height: 12),
              // footer
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF5E8EB)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatusPill(status: iv.status),
                    _MiniAvatar(initials: iv.interviewerInitials, color: iv.interviewerColor),
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

String _formatLabel(_IvFormat f) => switch (f) {
  _IvFormat.inPerson => 'In-Person',
  _IvFormat.virtual  => 'Virtual',
  _IvFormat.phone    => 'Phone',
};

// ── table row ─────────────────────────────────────────────────────────────────
class _TableRow extends StatefulWidget {
  final _Interview interview;
  const _TableRow({required this.interview});
  @override State<_TableRow> createState() => _TableRowState();
}
class _TableRowState extends State<_TableRow> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final iv = widget.interview;
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
          // applicant
          Expanded(flex: 20, child: Row(children: [
            _Avatar(initials: iv.initials, color: iv.avatarColor, size: 30),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(iv.applicant, style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w500, color: _kDark)),
              Text(iv.applicantId, style: GoogleFonts.dmSans(
                fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
            ]),
          ])),
          // programme
          Expanded(flex: 12, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(iv.programme, style: GoogleFonts.dmSans(fontSize: 12, color: _kDark)),
            Text(iv.applicantType, style: GoogleFonts.dmSans(
              fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
          ])),
          // date
          Expanded(flex: 10, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(iv.date, style: GoogleFonts.dmSans(fontSize: 12, color: _kDark)),
            Text(iv.time, style: GoogleFonts.dmSans(
              fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
          ])),
          // format
          Expanded(flex: 10, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_formatLabel(iv.format), style: GoogleFonts.dmSans(fontSize: 12, color: _kDark)),
            Text(iv.location, style: GoogleFonts.dmSans(
              fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
          ])),
          // status
          Expanded(flex: 9, child: _StatusPill(status: iv.status)),
          // actions
          SizedBox(width: 140, child: Row(children: [
            _QBtn(icon: Icons.visibility_outlined, tip: 'View'),
            const SizedBox(width: 4),
            _QBtn(icon: Icons.refresh_rounded, tip: 'Reschedule'),
            const SizedBox(width: 4),
            _QBtn(icon: Icons.chat_bubble_outline_rounded, tip: 'Add Notes'),
            const SizedBox(width: 4),
            _QBtn(icon: Icons.close_rounded, tip: 'Cancel', red: true),
          ])),
        ]),
      ),
    );
  }
}

// ── small widgets ─────────────────────────────────────────────────────────────

class _IvDetail extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IvDetail({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 12, color: _kMuted),
    const SizedBox(width: 6),
    Expanded(child: Text(text, style: GoogleFonts.dmSans(
      fontSize: 11, color: _kDark, fontWeight: FontWeight.w300),
      overflow: TextOverflow.ellipsis)),
  ]);
}

class _StatusPill extends StatelessWidget {
  final _IvStatus status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, label) = switch (status) {
      _IvStatus.scheduled   => (const Color(0xFFFFF3E0), _kAmber, const Color(0xFFFFCC80), 'Scheduled'),
      _IvStatus.upcoming    => (const Color(0xFFEAF0FF), _kBlue,  const Color(0xFFC0CCFF), 'Upcoming'),
      _IvStatus.completed   => (const Color(0xFFE8F5EE), _kGreen, const Color(0xFFAADDBB), 'Completed'),
      _IvStatus.cancelled   => (_kRedSoft, _kRed, _kRedMid, 'Cancelled'),
      _IvStatus.rescheduled => (const Color(0xFFEFE8F5), const Color(0xFF7040BB), const Color(0xFFCCBBEE), 'Rescheduled'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 4, height: 4, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.08, color: fg)),
      ]),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  const _MiniAvatar({required this.initials, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 24, height: 24,
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [color, Color.lerp(color, Colors.black, 0.3)!]),
      shape: BoxShape.circle),
    child: Center(child: Text(initials, style: GoogleFonts.dmSans(
      fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
  );
}

class _Avatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;
  const _Avatar({required this.initials, required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [color, Color.lerp(color, Colors.black, 0.3)!]),
      shape: BoxShape.circle,
      boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 2))]),
    child: Center(child: Text(initials, style: GoogleFonts.dmSans(
      fontSize: size * 0.33, fontWeight: FontWeight.w700, color: Colors.white))),
  );
}

class _QBtn extends StatefulWidget {
  final IconData icon;
  final String tip;
  final bool red;
  const _QBtn({required this.icon, required this.tip, this.red = false});
  @override State<_QBtn> createState() => _QBtnState();
}
class _QBtnState extends State<_QBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
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
            color: _hover ? (widget.red ? _kRedSoft : const Color(0xFFE8F5EE)) : Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: _hover ? (widget.red ? _kRed : _kGreen) : _kBorder, width: 1.5)),
          child: Icon(widget.icon, size: 13,
            color: _hover ? (widget.red ? _kRed : _kGreen) : _kMuted),
        ),
      ),
    );
  }
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
              fontSize: 18, fontWeight: FontWeight.w900, color: _kDark,
              letterSpacing: -0.3, height: 1)),
            const SizedBox(height: 2),
            Text(widget.label, style: GoogleFonts.dmSans(
              fontSize: 11, color: _kMuted, fontWeight: FontWeight.w300)),
          ]),
        ]),
      ),
    ),
  );
}

class _TH extends StatelessWidget {
  final String label;
  const _TH({required this.label});
  @override
  Widget build(BuildContext context) => Text(label, style: GoogleFonts.dmSans(
    fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: _kMuted));
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
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit:  (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hover ? -1 : 0, 0),
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
  );
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
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit:  (_) => setState(() => _hover = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _hover ? _kRed : _kBorder, width: 1.5)),
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

class _FilterDrop extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _FilterDrop({required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: _kBorder, width: 1.5)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e,
          child: Text(e, style: GoogleFonts.dmSans(fontSize: 12, color: _kDark)))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _kMuted),
        style: GoogleFonts.dmSans(fontSize: 12, color: _kDark),
        isDense: true,
      ),
    ),
  );
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
          border: Border.all(color: on ? _kRed : _kBorder, width: 1.5)),
        child: Center(child: widget.child != null
          ? IconTheme(data: IconThemeData(color: on ? Colors.white : _kMuted, size: 14),
              child: widget.child!)
          : Text(widget.label ?? '', style: GoogleFonts.dmSans(
              fontSize: 12, color: on ? Colors.white : _kMuted))),
      ),
    );
  }
}
