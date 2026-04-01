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

// ── data models ───────────────────────────────────────────────────────────────
enum _RptStatus { generated, pending, scheduled }
enum _RptIconColor { red, blue, green, amber, purple }

class _ReportTemplate {
  final String title;
  final String desc;
  final _RptStatus status;
  final String lastGen;
  final _RptIconColor iconColor;
  final IconData icon;
  const _ReportTemplate({
    required this.title, required this.desc, required this.status,
    required this.lastGen, required this.iconColor, required this.icon,
  });
}

const _kTemplates = <_ReportTemplate>[
  _ReportTemplate(
    title: 'Application Summary Report',
    desc: 'Full overview of all applications — counts by status, type, faculty and intake period.',
    status: _RptStatus.generated, lastGen: 'Today',
    iconColor: _RptIconColor.red, icon: Icons.description_outlined,
  ),
  _ReportTemplate(
    title: 'Applicant Demographics',
    desc: 'Breakdown by nationality, age, gender and applicant type with geographic distribution.',
    status: _RptStatus.generated, lastGen: 'Mar 13',
    iconColor: _RptIconColor.blue, icon: Icons.people_outline_rounded,
  ),
  _ReportTemplate(
    title: 'Document Verification Status',
    desc: 'Tracks all submitted documents — verified, pending, rejected — per applicant and type.',
    status: _RptStatus.pending, lastGen: 'Mar 10',
    iconColor: _RptIconColor.green, icon: Icons.fact_check_outlined,
  ),
  _ReportTemplate(
    title: 'Interview Schedule Report',
    desc: 'Complete interview schedule with applicant details, dates, formats and assigned reviewers.',
    status: _RptStatus.scheduled, lastGen: 'Auto: Weekly',
    iconColor: _RptIconColor.purple, icon: Icons.calendar_today_outlined,
  ),
  _ReportTemplate(
    title: 'Admission Trends Analysis',
    desc: 'Weekly and monthly application trends compared against previous intake years with projections.',
    status: _RptStatus.generated, lastGen: 'Mar 14',
    iconColor: _RptIconColor.amber, icon: Icons.bar_chart_rounded,
  ),
  _ReportTemplate(
    title: 'Admin Activity Audit Report',
    desc: 'Full log of admin actions — approvals, rejections, notes and document verifications by staff member.',
    status: _RptStatus.generated, lastGen: 'Today',
    iconColor: _RptIconColor.red, icon: Icons.shield_outlined,
  ),
];

// ── bar chart data ─────────────────────────────────────────────────────────────
const _kBarLabels = ['W1','W2','W3','W4','W5','W6','W7','W8'];

// ── app type config ───────────────────────────────────────────────────────────
class _AppType {
  final String label;
  final int count;
  final double frac;
  final Color color;
  final Color bgColor;
  const _AppType(this.label, this.count, this.frac, this.color, this.bgColor);
}

const _kTypeConfig = [
  ('undergraduate', 'Undergraduate', _kRed,    _kRedSoft),
  ('international', 'International', _kBlue,   Color(0xFFEAF0FF)),
  ('masters',       'Masters / PG',  _kPurple, Color(0xFFEFE8F5)),
  ('returning',     'Re-admission',  _kAmber,  Color(0xFFFFF3E0)),
  ('transfer',      'Transfer',      _kGreen,  Color(0xFFE8F5EE)),
];

// ═══════════════════════════════════════════════════════════════════════════════
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Map<String, dynamic>> _apps = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = SupabaseService.streamApplications().listen((apps) {
      setState(() { _apps = apps; _loading = false; });
    }, onError: (_) => setState(() => _loading = false));
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  // ── computed chart data ───────────────────────────────────────────────────

  List<double> get _barHeights {
    final weeks = SupabaseService.groupByWeek(_apps);
    if (weeks.isEmpty) return List.filled(8, 0);
    final counts = weeks.map((e) => e.value.toDouble()).toList();
    final maxVal = counts.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return counts;
    return counts.map((c) => (c / maxVal) * 112).toList();
  }

  List<_AppType> get _appTypes {
    final byType = SupabaseService.groupByType(_apps);
    if (byType.isEmpty) return [];
    final maxCount = byType.values.isNotEmpty
        ? byType.values.reduce((a, b) => a > b ? a : b)
        : 1;
    return _kTypeConfig.map((t) {
      final count = byType.entries
          .where((e) => e.key.toLowerCase().contains(t.$1))
          .fold(0, (acc, e) => acc + e.value);
      return _AppType(
        t.$2, count, maxCount > 0 ? count / maxCount : 0, t.$3, t.$4);
    }).where((t) => t.count > 0).toList();
  }

  void _generateReport() {
    final lines = ['ID,Name,Type,Nationality,Programme,Status,Submitted'];
    for (final r in _apps) {
      final name  = r['applicant_name'] as String? ?? '';
      final id    = r['applicant_id']   as String? ?? '';
      final type  = r['type']           as String? ?? '';
      final nat   = r['nationality']    as String? ?? '';
      final prog  = r['programme']      as String? ?? '';
      final stat  = r['status']         as String? ?? '';
      final sub   = r['submitted_at']   as String? ?? '';
      lines.add('"$id","$name","$type","$nat","$prog","$stat","$sub"');
    }
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report CSV (${_apps.length} rows) copied to clipboard')));
  }

  Future<void> _showScheduleDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Schedule Report', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Scheduled reports are sent to the admin email every week on Monday at 08:00 UTC.'),
          SizedBox(height: 10),
          Text('Contact IT support to configure custom schedules.',
              style: TextStyle(fontSize: 12, color: _kMuted)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Weekly report schedule activated')));
            },
            child: const Text('Activate Weekly Schedule'),
          ),
        ],
      ),
    );
  }

  int get _statToday {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _apps.where((r) {
      final dt = DateTime.tryParse(r['submitted_at'] as String? ?? '')?.toLocal();
      return dt != null && !dt.isBefore(todayStart);
    }).length;
  }

  int get _statPending =>
      _apps.where((r) => r['status'] == 'Pending').length;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kRed));
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── page header ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Reports', style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24, fontWeight: FontWeight.w900, color: _kDark,
                    letterSpacing: -0.4,
                  ).copyWith(
                    shadows: [const Shadow(color: Colors.transparent)],
                  ).merge(TextStyle(
                    foreground: Paint()..shader = const LinearGradient(
                      colors: [_kRedDeep, _kRed],
                    ).createShader(const Rect.fromLTWH(0, 0, 160, 36)),
                  )),),
                  const SizedBox(height: 3),
                  Text('Generate, schedule and download data reports for 2024 intake.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w300)),
                ]),
              ),
              _OutlineBtn(
                icon: Icons.calendar_today_outlined,
                label: 'Schedule Report',
                onTap: _showScheduleDialog,
              ),
              const SizedBox(width: 8),
              _PrimaryBtn(
                icon: Icons.download_rounded,
                label: 'Generate Report',
                onTap: _generateReport,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── stat strip ────────────────────────────────────────────────────
          Row(children: [
            _StatChip(icon: Icons.description_outlined,    color: _RptIconColor.red,
              val: _apps.isEmpty ? '0' : '${_apps.length}', lbl: 'Total Applications'),
            const SizedBox(width: 10),
            _StatChip(icon: Icons.check_rounded,           color: _RptIconColor.green,
              val: '$_statToday', lbl: 'Submitted Today'),
            const SizedBox(width: 10),
            _StatChip(icon: Icons.calendar_today_outlined, color: _RptIconColor.blue,
              val: '$_statPending', lbl: 'Pending Review'),
            const SizedBox(width: 10),
            _StatChip(icon: Icons.download_rounded,        color: _RptIconColor.amber,
              val: '${_kTemplates.length}', lbl: 'Report Templates'),
          ]),
          const SizedBox(height: 16),

          // ── two-col charts ────────────────────────────────────────────────
          LayoutBuilder(builder: (context, bc) {
            final twoCol = bc.maxWidth > 640;
            final barChart = _BarChartCard(bars: _barHeights);
            final typeCard = _appTypes.isEmpty
                ? _AppTypeCard(types: const [])
                : _AppTypeCard(types: _appTypes);
            if (twoCol) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: barChart),
                const SizedBox(width: 12),
                Expanded(child: typeCard),
              ]);
            }
            return Column(children: [
              barChart,
              const SizedBox(height: 12),
              typeCard,
            ]);
          }),
          const SizedBox(height: 20),

          // ── section label ─────────────────────────────────────────────────
          Text('Available Report Templates',
            style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600,
              letterSpacing: 1.8, color: _kMuted,
            ).copyWith(fontSize: 10),
          ),
          const SizedBox(height: 12),

          // ── report grid ───────────────────────────────────────────────────
          LayoutBuilder(builder: (context, bc) {
            final cols = bc.maxWidth > 900 ? 3 : bc.maxWidth > 580 ? 2 : 1;
            final spacing = (cols - 1) * 10.0;
            final cardW = (bc.maxWidth - spacing) / cols;
            final rows = <Widget>[];
            for (var i = 0; i < _kTemplates.length; i += cols) {
              if (i > 0) rows.add(const SizedBox(height: 10));
              final rowCards = <Widget>[];
              for (var j = 0; j < cols && i + j < _kTemplates.length; j++) {
                if (j > 0) rowCards.add(const SizedBox(width: 10));
                rowCards.add(SizedBox(width: cardW,
                  child: _ReportCard(t: _kTemplates[i + j])));
              }
              rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowCards));
            }
            return Column(children: rows);
          }),
        ],
      ),
    );
  }
}

// ── _StatChip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatefulWidget {
  final IconData icon;
  final _RptIconColor color;
  final String val, lbl;
  const _StatChip({required this.icon, required this.color, required this.val, required this.lbl});
  @override State<_StatChip> createState() => _StatChipState();
}
class _StatChipState extends State<_StatChip> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final (bg, border, stroke) = _iconColors(widget.color);
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
              decoration: BoxDecoration(color: bg,
                borderRadius: BorderRadius.circular(10), border: Border.all(color: border, width: 1)),
              child: Transform.rotate(
                angle: _hov ? -0.09 : 0,
                child: Icon(widget.icon, size: 15, color: stroke),
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

// ── _BarChartCard ─────────────────────────────────────────────────────────────
class _BarChartCard extends StatelessWidget {
  final List<double> bars;
  const _BarChartCard({required this.bars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [BoxShadow(color: _kRed.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _kRedSoft, borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _kRedMid, width: 1),
            ),
            child: const Icon(Icons.bar_chart_rounded, size: 14, color: _kRed),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Applications by Week', style: GoogleFonts.dmSerifDisplay(
              fontSize: 14, fontWeight: FontWeight.w700, color: _kDark)),
            Text('Submissions · Last 8 weeks', style: GoogleFonts.dmSans(
              fontSize: 10.5, color: _kMuted, fontWeight: FontWeight.w300)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: '8 weeks',
                isDense: true,
                style: GoogleFonts.dmSans(fontSize: 11, color: _kDark),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _kMuted),
                items: const [
                  DropdownMenuItem(value: '8 weeks', child: Text('8 weeks')),
                  DropdownMenuItem(value: '3 months', child: Text('3 months')),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        bars.every((h) => h == 0)
            ? SizedBox(
                height: 130,
                child: Center(child: Text('No data yet',
                  style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted))),
              )
            : SizedBox(
                height: 130,
                child: CustomPaint(painter: _BarChartPainter(bars: bars)),
              ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _kBarLabels.map((l) => Text(l, style: GoogleFonts.dmSans(
            fontSize: 9.5, color: _kMuted, fontWeight: FontWeight.w300))).toList(),
        ),
      ]),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> bars;
  const _BarChartPainter({required this.bars});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = _kRedSoft..strokeWidth = 1;
    for (final y in [size.height * 0.15, size.height * 0.42, size.height * 0.70]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final n = bars.length;
    if (n == 0) return;
    final barW = (size.width - 16) / n - 4;
    final maxH = bars.reduce((a, b) => a > b ? a : b);
    for (var i = 0; i < n; i++) {
      final barH = maxH > 0 ? (bars[i] / maxH) * size.height : 0.0;
      if (barH <= 0) continue;
      final x = 8 + i * ((size.width - 16) / n);
      final isRecent = i >= n - 3;
      final color = isRecent ? _kRedDeep : (i % 2 == 0 ? _kRed : _kRedMid);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - barH, barW, barH),
          const Radius.circular(4),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.bars != bars;
}

// ── _AppTypeCard ──────────────────────────────────────────────────────────────
class _AppTypeCard extends StatelessWidget {
  final List<_AppType> types;
  const _AppTypeCard({required this.types});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [BoxShadow(color: _kRed.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF), borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFC0CCFF), width: 1),
            ),
            child: const Icon(Icons.format_list_bulleted_rounded, size: 14, color: _kBlue),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Applications by Type', style: GoogleFonts.dmSerifDisplay(
              fontSize: 14, fontWeight: FontWeight.w700, color: _kDark)),
            Text('Breakdown 2024', style: GoogleFonts.dmSans(
              fontSize: 10.5, color: _kMuted, fontWeight: FontWeight.w300)),
          ]),
        ]),
        const SizedBox(height: 18),
        if (types.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No data yet',
              style: TextStyle(fontSize: 13, color: _kMuted))),
          )
        else
        ...types.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(t.label, style: GoogleFonts.dmSans(fontSize: 12, color: _kDark)),
              Text('${t.count}', style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w600, color: t.color)),
            ]),
            const SizedBox(height: 5),
            Stack(children: [
              Container(height: 8,
                decoration: BoxDecoration(color: t.bgColor, borderRadius: BorderRadius.circular(20))),
              FractionallySizedBox(
                widthFactor: t.frac,
                child: Container(height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [t.color, _darken(t.color)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ]),
          ]),
        )),
      ]),
    );
  }

  Color _darken(Color c) => Color.fromARGB(
    c.a.round(), (c.r * 0.65).round(), (c.g * 0.65).round(), (c.b * 0.65).round());
}

// ── _ReportCard ───────────────────────────────────────────────────────────────
class _ReportCard extends StatefulWidget {
  final _ReportTemplate t;
  const _ReportCard({required this.t});
  @override State<_ReportCard> createState() => _ReportCardState();
}
class _ReportCardState extends State<_ReportCard> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final (bg, border, stroke) = _iconColors(widget.t.iconColor);
    final topColor = stroke;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit:  (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hov ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hov ? _kRed.withValues(alpha: 0.28) : _kBorder, width: 1.5),
          boxShadow: [BoxShadow(
            color: _kRed.withValues(alpha: _hov ? 0.10 : 0.04),
            blurRadius: _hov ? 28 : 8, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.5),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 3px top bar
            Container(height: 3, color: topColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: bg,
                      borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 1)),
                    child: Transform.rotate(
                      angle: _hov ? -0.09 : 0,
                      child: Transform.scale(scale: _hov ? 1.08 : 1.0,
                        child: Icon(widget.t.icon, size: 18, color: stroke)),
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: _hov ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Row(children: [
                      _QaBtn(tip: 'Download', icon: Icons.download_rounded),
                      const SizedBox(width: 5),
                      _QaBtn(tip: 'Schedule', icon: Icons.calendar_today_outlined),
                    ]),
                  ),
                ]),
                const SizedBox(height: 10),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 14.5, fontWeight: FontWeight.w700,
                    color: _hov ? _kRedDeep : _kDark),
                  child: Text(widget.t.title),
                ),
                const SizedBox(height: 5),
                Text(widget.t.desc, style: GoogleFonts.dmSans(
                  fontSize: 11.5, color: _kMuted, fontWeight: FontWeight.w300, height: 1.55)),
                const SizedBox(height: 12),
                Container(height: 1, color: _kRedSoft),
                const SizedBox(height: 10),
                Row(children: [
                  _StatusPill(status: widget.t.status),
                  const Spacer(),
                  Text('Last: ${widget.t.lastGen}', style: GoogleFonts.dmSans(
                    fontSize: 10, color: _kMuted, fontWeight: FontWeight.w300)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── _StatusPill ───────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final _RptStatus status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final (bg, border, text, label) = switch (status) {
      _RptStatus.generated => (const Color(0xFFE8F5EE), const Color(0xFFAADDBB), _kGreen, 'Generated'),
      _RptStatus.pending   => (const Color(0xFFFFF3E0), const Color(0xFFFFCC80), _kAmber, 'Pending'),
      _RptStatus.scheduled => (const Color(0xFFEAF0FF), const Color(0xFFC0CCFF), _kBlue,  'Scheduled'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(
          color: text, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 9.5, fontWeight: FontWeight.w600,
          color: text, letterSpacing: 0.7,
        ).copyWith(fontSize: 9.5)),
      ]),
    );
  }
}

// ── _QaBtn ────────────────────────────────────────────────────────────────────
class _QaBtn extends StatefulWidget {
  final String tip;
  final IconData icon;
  const _QaBtn({required this.tip, required this.icon});
  @override State<_QaBtn> createState() => _QaBtnState();
}
class _QaBtnState extends State<_QaBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tip,
      textStyle: const TextStyle(fontSize: 10, color: Colors.white),
      decoration: BoxDecoration(color: _kDark, borderRadius: BorderRadius.circular(5)),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hov = true),
        onExit:  (_) => setState(() => _hov = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: _hov ? _kRedSoft : Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _hov ? _kRed : _kBorder, width: 1.5),
          ),
          child: Icon(widget.icon, size: 13, color: _hov ? _kRed : _kMuted),
        ),
      ),
    );
  }
}

// ── _PrimaryBtn ───────────────────────────────────────────────────────────────
class _PrimaryBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.icon, required this.label, required this.onTap});
  @override State<_PrimaryBtn> createState() => _PrimaryBtnState();
}
class _PrimaryBtnState extends State<_PrimaryBtn> {
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
          duration: const Duration(milliseconds: 220),
          transform: Matrix4.translationValues(0, _hov ? -1 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kRed, _kRedDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(
              color: _kRed.withValues(alpha: _hov ? 0.38 : 0.28),
              blurRadius: _hov ? 20 : 14, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 13, color: Colors.white),
            const SizedBox(width: 6),
            Text(widget.label, style: GoogleFonts.dmSans(
              fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.white)),
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
(Color bg, Color border, Color stroke) _iconColors(_RptIconColor c) => switch (c) {
  _RptIconColor.red    => (_kRedSoft,                const Color(0xFFE8C0C8), _kRed),
  _RptIconColor.blue   => (const Color(0xFFEAF0FF),  const Color(0xFFC0CCFF), _kBlue),
  _RptIconColor.green  => (const Color(0xFFE8F5EE),  const Color(0xFFAADDBB), _kGreen),
  _RptIconColor.amber  => (const Color(0xFFFFF3E0),  const Color(0xFFFFCC80), _kAmber),
  _RptIconColor.purple => (const Color(0xFFEFE8F5),  const Color(0xFFCCBBEE), _kPurple),
};
