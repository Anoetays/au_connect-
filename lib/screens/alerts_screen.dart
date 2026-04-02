import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:intl/intl.dart';

// ── colour tokens ─────────────────────────────────────────────────────────────
const _kRed     = AppTheme.primaryCrimson;
const _kRedSoft = AppTheme.primaryLight;
const _kRedMid  = Color(0xFFE8C0C8);
const _kDark    = AppTheme.textPrimary;
const _kMuted   = AppTheme.textMuted;
const _kBorder  = AppTheme.border;
const _kGreen   = AppTheme.statusApproved;
const _kBlue    = AppTheme.statusReview;
const _kAmber   = AppTheme.statusPending;

// ── helpers ───────────────────────────────────────────────────────────────────
String _timeAgo(String? iso) {
  if (iso == null) return '';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';
  final d = DateTime.now().difference(dt);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} hr${d.inHours > 1 ? "s" : ""} ago';
  if (d.inDays == 1) return 'Yesterday';
  if (d.inDays < 7) return '${d.inDays} days ago';
  return DateFormat('MMM d, yyyy').format(dt);
}

(IconData, Color) _iconForType(String? type) {
  switch (type) {
    case 'status_update':    return (Icons.check_circle_outline_rounded, _kGreen);
    case 'announcement':     return (Icons.campaign_outlined,            _kBlue);
    case 'new_application':  return (Icons.description_outlined,         _kRed);
    default:                 return (Icons.notifications_outlined,       _kAmber);
  }
}

// ── main widget ───────────────────────────────────────────────────────────────
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  String? _typeFilter; // null = all, 'status_update', 'announcement'

  @override
  void initState() {
    super.initState();
    _sub = SupabaseService.streamMyApplicantNotifications().listen(
      (rows) {
        if (mounted) setState(() { _notifs = rows; _loading = false; });
      },
      onError: (_) {
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_typeFilter == null) return _notifs;
    return _notifs.where((n) => n['type'] == _typeFilter).toList();
  }

  Future<void> _markRead(String id) async {
    await SupabaseService.markNotificationRead(id);
  }

  Future<void> _dismiss(String id) async {
    await SupabaseService.dismissNotification(id);
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear all notifications?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text('This action cannot be undone.',
          style: GoogleFonts.dmSans(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All')),
        ],
      ),
    );
    if (confirm == true) {
      for (final n in _notifs) {
        await SupabaseService.dismissNotification(n['id'] as String);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Notifications',
          style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _clearAll,
            tooltip: 'Clear all'),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kRed))
                : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = [
      (null,              'All'),
      ('status_update',   'Status Updates'),
      ('announcement',    'Announcements'),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips.map((c) {
            final selected = _typeFilter == c.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(c.$2,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : _kDark)),
                selected: selected,
                onSelected: (_) => setState(() => _typeFilter = c.$1),
                selectedColor: _kRed,
                backgroundColor: Colors.white,
                side: BorderSide(color: selected ? _kRed : _kBorder),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    final items = _filtered;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: _kRedSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kRedMid, width: 1.5)),
                child: const Icon(Icons.notifications_none_rounded, size: 32, color: _kMuted),
              ),
              const SizedBox(height: 16),
              Text('No notifications yet',
                style: GoogleFonts.dmSans(
                  fontSize: 17, fontWeight: FontWeight.w700, color: _kDark)),
              const SizedBox(height: 6),
              Text(
                'You\'ll receive updates here when your application status changes or when the admissions office sends an announcement.',
                style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted, height: 1.5),
                textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final n = items[i];
        return _NotifCard(
          notif: n,
          onTap: () => _markRead(n['id'] as String),
          onDismiss: () => _dismiss(n['id'] as String),
        );
      },
    );
  }
}

// ── _NotifCard ────────────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _NotifCard({required this.notif, required this.onTap, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isRead = notif['is_read'] == true;
    final type = notif['type'] as String? ?? '';
    final title = notif['title'] as String? ?? '';
    final body = notif['body'] as String? ?? (notif['message'] as String? ?? '');
    final timeStr = _timeAgo(notif['created_at'] as String?);
    final (icon, iconColor) = _iconForType(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead ? _kBorder : _kRed.withValues(alpha: 0.3),
            width: isRead ? 1 : 1.5),
          boxShadow: [BoxShadow(
            color: _kRed.withValues(alpha: isRead ? 0.03 : 0.07),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // left accent bar for unread
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: isRead ? Colors.transparent : _kRed,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14))),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withValues(alpha: 0.2))),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                        color: _kDark))),
                    if (!isRead)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: _kRed)),
                  ]),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(body,
                      style: GoogleFonts.dmSans(
                        fontSize: 12, color: _kMuted, height: 1.45),
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(timeStr, style: GoogleFonts.dmSans(
                      fontSize: 11, color: _kMuted.withValues(alpha: 0.7))),
                    const Spacer(),
                    GestureDetector(
                      onTap: onDismiss,
                      child: Text('Dismiss',
                        style: GoogleFonts.dmSans(
                          fontSize: 11, color: _kMuted,
                          decoration: TextDecoration.underline)),
                    ),
                  ]),
                ])),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
