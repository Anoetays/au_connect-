import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:intl/intl.dart';

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

// ── helpers ────────────────────────────────────────────────────────────────────
String _timeAgo(String? isoString) {
  if (isoString == null) return '';
  final dt = DateTime.tryParse(isoString);
  if (dt == null) return '';
  final d = DateTime.now().difference(dt.toLocal());
  if (d.inMinutes < 1) return 'Just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} hr${d.inHours > 1 ? "s" : ""} ago';
  if (d.inDays == 1) return 'Yesterday';
  if (d.inDays < 7) return '${d.inDays} days ago';
  return DateFormat('MMM d, yyyy').format(dt.toLocal());
}

(IconData, Color, Color, Color) _notifStyle(String? type) {
  switch (type) {
    case 'new_application':
      return (Icons.description_outlined,
          const Color(0xFFF5E8EB), const Color(0xFFE8C0C8), _kRed);
    case 'status_update':
      return (Icons.check_circle_outline_rounded,
          const Color(0xFFE8F5EE), const Color(0xFFAADDBB), _kGreen);
    case 'announcement':
      return (Icons.campaign_outlined,
          const Color(0xFFEAF0FF), const Color(0xFFC0CCFF), _kBlue);
    case 'document':
      return (Icons.folder_outlined,
          const Color(0xFFEAF0FF), const Color(0xFFC0CCFF), _kBlue);
    case 'system':
      return (Icons.info_outline_rounded,
          const Color(0xFFFFF3E0), const Color(0xFFFFCC80), _kAmber);
    case 'user':
      return (Icons.person_add_outlined,
          const Color(0xFFEFE8F5), const Color(0xFFCCBBEE), _kPurple);
    default:
      return (Icons.notifications_outlined,
          _kRedSoft, _kRedMid, _kRed);
  }
}

// ── page widget ───────────────────────────────────────────────────────────────
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  String _search = '';
  String _typeFilter = 'All Types';
  String _statusFilter = 'All Status';
  int _tabIdx = 0;

  @override
  void initState() {
    super.initState();
    _sub = SupabaseService.streamAdminNotifications().listen(
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

  // ── derived lists ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    var list = _notifs.toList();

    // tab filter
    if (_tabIdx == 1) {
      list = list.where((n) => n['is_read'] == false).toList();
    } else if (_tabIdx == 2) {
      list = list.where((n) => (n['type'] as String? ?? '').contains('application') || n['type'] == 'new_application' || n['type'] == 'status_update').toList();
    } else if (_tabIdx == 3) {
      list = list.where((n) => n['type'] == 'document').toList();
    } else if (_tabIdx == 4) {
      list = list.where((n) => n['type'] == 'system' || n['type'] == 'announcement').toList();
    }

    // dropdown filters
    if (_typeFilter != 'All Types') {
      final map = {
        'Application': ['new_application', 'status_update'],
        'Document': ['document'],
        'System': ['system'],
        'Announcement': ['announcement'],
        'User': ['user'],
      };
      final types = map[_typeFilter];
      if (types != null) list = list.where((n) => types.contains(n['type'])).toList();
    }

    if (_statusFilter == 'Unread') {
      list = list.where((n) => n['is_read'] == false).toList();
    } else if (_statusFilter == 'Read') {
      list = list.where((n) => n['is_read'] == true).toList();
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((n) =>
        (n['title'] as String? ?? '').toLowerCase().contains(q) ||
        (n['body'] as String? ?? '').toLowerCase().contains(q)).toList();
    }

    return list;
  }

  int get _unreadCount => _notifs.where((n) => n['is_read'] == false).length;

  int _tabCount(int idx) {
    if (idx == 0) return _notifs.length;
    if (idx == 1) return _unreadCount;
    if (idx == 2) return _notifs.where((n) => n['type'] == 'new_application' || n['type'] == 'status_update').length;
    if (idx == 3) return _notifs.where((n) => n['type'] == 'document').length;
    return _notifs.where((n) => n['type'] == 'system' || n['type'] == 'announcement').length;
  }

  Future<void> _markRead(String id) async {
    await SupabaseService.markNotificationRead(id);
  }

  Future<void> _dismiss(String id) async {
    await SupabaseService.dismissNotification(id);
  }

  Future<void> _markAllRead() async {
    await SupabaseService.markAllAdminNotificationsRead();
  }

  Future<void> _clearAll() async {
    for (final n in _notifs) {
      await SupabaseService.dismissNotification(n['id'] as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kRed));
    }
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
    final apps = _notifs.where((n) => n['type'] == 'new_application' || n['type'] == 'status_update').length;
    final docs = _notifs.where((n) => n['type'] == 'document').length;
    return Row(children: [
      _StatChip(icon: Icons.notifications_outlined, iconBg: _kRedSoft, iconBorder: _kRedMid,
        iconColor: _kRed, value: '${_notifs.length}', label: 'Total'),
      const SizedBox(width: 10),
      _StatChip(icon: Icons.info_outline_rounded, iconBg: const Color(0xFFFFF3E0),
        iconBorder: const Color(0xFFFFCC80), iconColor: _kAmber, value: '$_unreadCount', label: 'Unread'),
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
        items: const ['All Types','Application','Document','System','Announcement','User'],
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
  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder, width: 1.5),
        ),
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _kRedSoft,
              border: Border.all(color: _kRedMid, width: 1.5),
              borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.notifications_off_outlined, size: 28, color: _kMuted),
          ),
          const SizedBox(height: 14),
          Text('No notifications yet',
            style: GoogleFonts.dmSerifDisplay(fontSize: 17, fontWeight: FontWeight.w700, color: _kDark)),
          const SizedBox(height: 5),
          Text('Notifications will appear here when applicants submit applications or documents.',
            style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w300),
            textAlign: TextAlign.center),
        ]),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0AC41E3A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final n = e.value;
          final isLast = e.key == items.length - 1;
          return _NotifTile(
            notif: n,
            isLast: isLast,
            onTap: () => _markRead(n['id'] as String),
            onDismiss: () => _dismiss(n['id'] as String),
          );
        }).toList(),
      ),
    );
  }
}

// ── _NotifTile ─────────────────────────────────────────────────────────────────
class _NotifTile extends StatefulWidget {
  final Map<String, dynamic> notif;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _NotifTile({
    required this.notif,
    required this.isLast,
    required this.onTap,
    required this.onDismiss,
  });
  @override
  State<_NotifTile> createState() => _NotifTileState();
}

class _NotifTileState extends State<_NotifTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.notif;
    final isRead = n['is_read'] == true;
    final type = n['type'] as String? ?? '';
    final title = n['title'] as String? ?? '';
    final body = n['body'] as String? ?? (n['message'] as String? ?? '');
    final timeStr = _timeAgo(n['created_at'] as String?);
    final (icon, iconBg, iconBorder, iconColor) = _notifStyle(type);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () {
          if (!isRead) widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: _hover
                ? _kRedSoft
                : isRead
                    ? Colors.transparent
                    : const Color(0xFFFFF8F9),
            border: Border(
              bottom: BorderSide(
                color: widget.isLast ? Colors.transparent : _kBorder.withValues(alpha: 0.5)),
              left: BorderSide(
                color: isRead ? Colors.transparent : _kRed,
                width: 3),
            ),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Icon
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                border: Border.all(color: iconBorder, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(title,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                    color: _kDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
                if (!isRead)
                  Container(
                    width: 7, height: 7,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: _kRed),
                  ),
              ]),
              const SizedBox(height: 3),
              Text(body,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: _kMuted,
                  fontWeight: FontWeight.w300,
                  height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text(timeStr, style: GoogleFonts.dmSans(
                fontSize: 11, color: _kMuted.withValues(alpha: 0.7))),
            ])),
            const SizedBox(width: 8),
            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 15, color: _kMuted),
              onSelected: (action) {
                if (action == 'read') widget.onTap();
                if (action == 'dismiss') widget.onDismiss();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'read',
                  child: Text('Mark as read',
                    style: GoogleFonts.dmSans(fontSize: 13))),
                PopupMenuItem(value: 'dismiss',
                  child: Text('Dismiss',
                    style: GoogleFonts.dmSans(fontSize: 13))),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ── small widgets ─────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final Color iconBg, iconBorder, iconColor;
  final IconData icon;
  final String value, label;
  const _StatChip({
    required this.icon, required this.iconBg, required this.iconBorder,
    required this.iconColor, required this.value, required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: _kRed.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: iconBg, border: Border.all(color: iconBorder),
            borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.dmSerifDisplay(
            fontSize: 17, fontWeight: FontWeight.w900, color: _kDark)),
          Text(label, style: GoogleFonts.dmSans(
            fontSize: 10, color: _kMuted, fontWeight: FontWeight.w300)),
        ]),
      ]),
    ));
  }
}

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

class _FilterDrop extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _FilterDrop({required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(11)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: GoogleFonts.dmSans(fontSize: 12, color: _kDark),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _kMuted),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}
