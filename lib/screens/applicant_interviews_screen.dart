import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/theme/app_theme.dart';

// ── colour tokens ─────────────────────────────────────────────────────────────
const _kRed     = AppTheme.primaryCrimson;
const _kDark    = AppTheme.textPrimary;
const _kMuted   = AppTheme.textMuted;
const _kGreen   = AppTheme.statusApproved;
const _kBlue    = AppTheme.statusReview;
const _kAmber   = AppTheme.statusPending;

class ApplicantInterviewsScreen extends StatefulWidget {
  const ApplicantInterviewsScreen({super.key});

  @override
  State<ApplicantInterviewsScreen> createState() => _ApplicantInterviewsScreenState();
}

class _ApplicantInterviewsScreenState extends State<ApplicantInterviewsScreen> {
  List<Map<String, dynamic>> _interviews = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<List<Map<String, dynamic>>>? _intStreamSub;

  @override
  void initState() {
    super.initState();
    _loadInterviews();
    _setupInterviewsStreaming();
  }

  @override
  void dispose() {
    _intStreamSub?.cancel();
    super.dispose();
  }

  Future<void> _loadInterviews() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // For applicants, we'll use the streaming to get their interviews
      // The initial load will be handled by the stream
      setState(() {
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

  void _setupInterviewsStreaming() {
    _intStreamSub = SupabaseService.streamMyInterviews().listen(
      (interviews) {
        if (!mounted) return;
        setState(() {
          _interviews = interviews;
          _loading = false;
        });
      },
      onError: (error) {
        debugPrint('Interviews stream error: $error');
        if (!mounted) return;
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Interviews',
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
                        'Failed to load interviews',
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
                        onPressed: _loadInterviews,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kRed,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _interviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note_outlined, size: 64, color: _kMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No interviews scheduled yet',
                            style: GoogleFonts.dmSans(fontSize: 18, color: _kMuted),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You will be notified when an interview is scheduled for you.',
                            style: GoogleFonts.dmSans(fontSize: 14, color: _kMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _interviews.length,
                      itemBuilder: (context, index) {
                        final interview = _interviews[index];
                        return _InterviewCard(interview: interview);
                      },
                    ),
    );
  }
}

class _InterviewCard extends StatelessWidget {
  const _InterviewCard({required this.interview});

  final Map<String, dynamic> interview;

  @override
  Widget build(BuildContext context) {
    final programme = interview['programme'] as String? ?? 'Unknown Programme';
    final scheduledDate = interview['scheduled_date'] as String?;
    final scheduledTime = interview['scheduled_time'] as String?;
    final location = interview['location'] as String? ?? 'TBD';
    final format = interview['format'] as String? ?? 'in-person';
    final status = interview['status'] as String? ?? 'scheduled';
    final interviewer = interview['interviewer_name'] as String? ?? 'TBD';

    // Format date and time
    String dateTimeStr = 'Date TBD';
    if (scheduledDate != null) {
      try {
        final date = DateTime.parse(scheduledDate);
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        final year = date.year;
        dateTimeStr = '$day/$month/$year';
        if (scheduledTime != null) {
          dateTimeStr += ' at $scheduledTime';
        }
      } catch (_) {}
    }

    // Status color
    Color statusColor = _kBlue; // scheduled
    if (status == 'completed') {
      statusColor = _kGreen;
    } else if (status == 'cancelled') {
      statusColor = _kRed;
    } else if (status == 'rescheduled') {
      statusColor = _kAmber;
    }

    // Format icon
    IconData formatIcon = Icons.location_on;
    if (format == 'virtual') {
      formatIcon = Icons.videocam;
    } else if (format == 'phone') {
      formatIcon = Icons.phone;
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
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    programme,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: _kMuted),
                const SizedBox(width: 8),
                Text(
                  dateTimeStr,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: _kMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(formatIcon, size: 16, color: _kMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    format == 'virtual' ? 'Virtual Meeting' :
                    format == 'phone' ? 'Phone Call' : location,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: _kMuted,
                    ),
                  ),
                ),
              ],
            ),
            if (interviewer != 'TBD') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: _kMuted),
                  const SizedBox(width: 8),
                  Text(
                    'Interviewer: $interviewer',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}