import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/l10n/app_localizations.dart';

// ── colour tokens ─────────────────────────────────────────────────────────────
const _kRed     = AppTheme.primaryCrimson;
const _kRedDeep = AppTheme.primaryDark;
const _kRedSoft = AppTheme.primaryLight;
const _kDark    = AppTheme.textPrimary;
const _kMuted   = AppTheme.textMuted;
const _kBlue    = AppTheme.statusReview;
const _kAmber   = AppTheme.statusPending;

class ApplicantAnnouncementsScreen extends StatefulWidget {
  const ApplicantAnnouncementsScreen({super.key});

  @override
  State<ApplicantAnnouncementsScreen> createState() => _ApplicantAnnouncementsScreenState();
}

class _ApplicantAnnouncementsScreenState extends State<ApplicantAnnouncementsScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<List<Map<String, dynamic>>>? _annStreamSub;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _setupStreaming();
  }

  @override
  void dispose() {
    _annStreamSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Get user role from profile
      final profile = await SupabaseService.getProfile();
      final role = profile?['role'] as String? ?? 'applicant';
      final announcements = await SupabaseService.getAnnouncements(role);
      if (!mounted) return;
      setState(() {
        _announcements = announcements;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _setupStreaming() {
    // Get user role for streaming
    SupabaseService.getProfile().then((profile) {
      final role = profile?['role'] as String? ?? 'applicant';
      _annStreamSub = SupabaseService.streamAnnouncements(role).listen(
        (announcements) {
          if (!mounted) return;
          setState(() {
            _announcements = announcements;
          });
        },
        onError: (error) {
          debugPrint('Announcements stream error: $error');
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.announcements,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 24,
            color: _kDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kRed))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: _kRed),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load announcements',
                        style: GoogleFonts.dmSans(fontSize: 16, color: _kMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: GoogleFonts.dmSans(fontSize: 14, color: _kMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadAnnouncements,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kRed,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _announcements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign_outlined, size: 64, color: _kMuted),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noAnnouncements,
                            style: GoogleFonts.dmSans(fontSize: 18, color: _kMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) {
                        final ann = _announcements[index];
                        return _AnnouncementCard(announcement: ann);
                      },
                    ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final Map<String, dynamic> announcement;

  @override
  Widget build(BuildContext context) {
    final title = announcement['title'] as String? ?? 'Untitled';
    final body = announcement['body'] as String? ?? '';
    final createdAt = announcement['created_at'] as String?;
    final targetRole = announcement['target_role'] as String? ?? 'all';

    // Format date
    String timeStr = 'Just now';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        final now = DateTime.now();
        final diff = now.difference(date);

        if (diff.inDays > 0) {
          timeStr = '${diff.inDays}d ago';
        } else if (diff.inHours > 0) {
          timeStr = '${diff.inHours}h ago';
        } else if (diff.inMinutes > 0) {
          timeStr = '${diff.inMinutes}m ago';
        }
      } catch (_) {}
    }

    // Priority color
    Color priorityColor = _kBlue; // normal
    final priority = announcement['priority'] as String?;
    if (priority == 'urgent') {
      priorityColor = _kAmber;
    } else if (priority == 'critical') {
      priorityColor = _kRed;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kDark,
                    ),
                  ),
                ),
                Text(
                  timeStr,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: _kMuted,
                  ),
                ),
              ],
            ),
            if (targetRole != 'all') ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kRedSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  targetRole.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _kRedDeep,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              body,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: _kMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}