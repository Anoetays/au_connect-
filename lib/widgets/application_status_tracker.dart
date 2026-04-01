import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/supabase_service.dart';

/// Real-time application status timeline for the applicant dashboard.
class ApplicationStatusTracker extends StatefulWidget {
  final String applicationId;
  final String currentStatus;

  const ApplicationStatusTracker({
    super.key,
    required this.applicationId,
    required this.currentStatus,
  });

  @override
  State<ApplicationStatusTracker> createState() =>
      _ApplicationStatusTrackerState();
}

class _ApplicationStatusTrackerState extends State<ApplicationStatusTracker> {
  List<Map<String, dynamic>> _history = [];
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  static const _steps = [
    ('Submitted', Icons.send_rounded),
    ('Under Review', Icons.manage_search_rounded),
    ('Decision Made', Icons.gavel_rounded),
    ('Approved', Icons.check_circle_rounded),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.applicationId.isNotEmpty) {
      _sub = SupabaseService.streamStatusHistory(widget.applicationId)
          .listen((h) {
        if (mounted) setState(() => _history = h);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  int get _currentStepIndex {
    switch (widget.currentStatus) {
      case 'Approved':
        return 3;
      case 'Rejected':
        return 2;
      case 'Under Review':
        return 1;
      default:
        return 0;
    }
  }

  bool get _isDenied => widget.currentStatus == 'Rejected';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryCrimson.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                border: Border.all(
                    color: AppTheme.primaryCrimson.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.timeline_rounded,
                  size: 14, color: AppTheme.primaryCrimson),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Application Status',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              Text('Live updates',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppTheme.textMuted)),
            ]),
            const Spacer(),
            _StatusBadge(status: widget.currentStatus),
          ]),
          const SizedBox(height: 20),

          // ── Timeline ────────────────────────────────────────────────────
          _buildTimeline(),

          // ── History log ─────────────────────────────────────────────────
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text('Activity Log',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            ..._history.reversed.take(4).map((h) => _HistoryItem(entry: h)),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return LayoutBuilder(builder: (_, cs) {
      final isNarrow = cs.maxWidth < 380;
      if (isNarrow) {
        return Column(
          children: _steps.asMap().entries.map((e) {
            return _VerticalStep(
              index: e.key,
              label: e.value.$1,
              icon: e.value.$2,
              stepCount: _steps.length,
              currentIndex: _currentStepIndex,
              isDenied: _isDenied,
            );
          }).toList(),
        );
      }
      return Row(
        children: _steps.asMap().entries.expand((e) {
          final isLast = e.key == _steps.length - 1;
          return [
            _HorizontalStep(
              index: e.key,
              label: e.value.$1,
              icon: e.value.$2,
              currentIndex: _currentStepIndex,
              isDenied: _isDenied,
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 22),
                  color: e.key < _currentStepIndex
                      ? AppTheme.primaryCrimson
                      : AppTheme.border,
                ),
              ),
          ];
        }).toList(),
      );
    });
  }
}

// ── _HorizontalStep ──────────────────────────────────────────────────────────

class _HorizontalStep extends StatelessWidget {
  final int index, currentIndex;
  final String label;
  final IconData icon;
  final bool isDenied;

  const _HorizontalStep({
    required this.index,
    required this.label,
    required this.icon,
    required this.currentIndex,
    required this.isDenied,
  });

  bool get _done => index < currentIndex;
  bool get _active => index == currentIndex;
  bool get _denied => isDenied && index == 2; // Decision Made step

  Color get _color {
    if (_denied) return AppTheme.statusDenied;
    if (_done || _active) return AppTheme.primaryCrimson;
    return AppTheme.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final bg = _denied
        ? AppTheme.statusDenied.withValues(alpha: 0.1)
        : (_done || _active)
            ? AppTheme.primaryLight
            : AppTheme.border.withValues(alpha: 0.4);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: _active
                ? _color
                : (_done ? _color.withValues(alpha: 0.5) : AppTheme.border),
            width: _active ? 2 : 1.5,
          ),
        ),
        child: _done && !_denied
            ? Icon(Icons.check_rounded, size: 15, color: _color)
            : Icon(icon, size: 14, color: _color),
      ),
      const SizedBox(height: 6),
      SizedBox(
        width: 68,
        child: Text(
          _denied && index == 2 ? 'Denied' : label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: _active ? FontWeight.w700 : FontWeight.w400,
            color: _active ? _color : AppTheme.textMuted,
          ),
        ),
      ),
    ]);
  }
}

// ── _VerticalStep ─────────────────────────────────────────────────────────────

class _VerticalStep extends StatelessWidget {
  final int index, currentIndex, stepCount;
  final String label;
  final IconData icon;
  final bool isDenied;

  const _VerticalStep({
    required this.index,
    required this.label,
    required this.icon,
    required this.currentIndex,
    required this.stepCount,
    required this.isDenied,
  });

  bool get _done => index < currentIndex;
  bool get _active => index == currentIndex;
  bool get _denied => isDenied && index == 2;

  Color get _color {
    if (_denied) return AppTheme.statusDenied;
    if (_done || _active) return AppTheme.primaryCrimson;
    return AppTheme.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: (_done || _active)
                ? AppTheme.primaryLight
                : AppTheme.border.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            border: Border.all(
              color: _active
                  ? _color
                  : (_done ? _color.withValues(alpha: 0.5) : AppTheme.border),
            ),
          ),
          child: _done && !_denied
              ? Icon(Icons.check_rounded, size: 13, color: _color)
              : Icon(icon, size: 12, color: _color),
        ),
        if (index < stepCount - 1)
          Container(
              width: 2,
              height: 24,
              color: _done ? AppTheme.primaryCrimson : AppTheme.border),
      ]),
      const SizedBox(width: 12),
      Padding(
        padding: EdgeInsets.only(
            top: 6, bottom: index < stepCount - 1 ? 0 : 0),
        child: Text(
          _denied && index == 2 ? 'Denied' : label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: _active ? FontWeight.w600 : FontWeight.w400,
            color: _active ? _color : AppTheme.textMuted,
          ),
        ),
      ),
    ]);
  }
}

// ── _StatusBadge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      'Approved' => (const Color(0xFFE8F5EE), AppTheme.statusApproved),
      'Rejected' => (AppTheme.primaryLight, AppTheme.statusDenied),
      'Under Review' => (const Color(0xFFEAF0FF), AppTheme.statusReview),
      _ => (const Color(0xFFFFF3E0), AppTheme.statusPending),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fg),
        ),
        const SizedBox(width: 5),
        Text(status.isEmpty ? 'Submitted' : status,
            style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      ]),
    );
  }
}

// ── _HistoryItem ──────────────────────────────────────────────────────────────

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _HistoryItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final status = entry['status'] as String? ?? '';
    final changedBy = entry['changed_by'] as String? ?? 'System';
    final changedAt = entry['changed_at'] as String? ?? '';
    final dt = DateTime.tryParse(changedAt)?.toLocal();
    final timeStr = dt != null
        ? '${dt.day}/${dt.month}/${dt.year} '
            '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: AppTheme.primaryCrimson),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Status set to "$status" by $changedBy',
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppTheme.textSecondary),
          ),
        ),
        Text(timeStr,
            style: GoogleFonts.dmSans(
                fontSize: 10, color: AppTheme.textMuted)),
      ]),
    );
  }
}
