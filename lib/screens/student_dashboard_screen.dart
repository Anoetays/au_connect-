import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/services/anthropic_service.dart';
import 'chatbot_dashboard_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _academicRecords = [];
  Map<String, dynamic>? _feeRecord;
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        SupabaseService.getProfile(),
        SupabaseService.getAcademicRecords(),
        SupabaseService.getFeeRecord(),
        SupabaseService.getAnnouncements('student'),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Map<String, dynamic>?;
        _academicRecords = (results[1] as List<Map<String, dynamic>>?) ?? [];
        _feeRecord = results[2] as Map<String, dynamic>?;
        _announcements = (results[3] as List<Map<String, dynamic>>?) ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load your data.';
        _loading = false;
      });
    }
  }

  String get _displayName {
    final name = _profile?['full_name'] as String?;
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    return SupabaseService.currentUser?.email?.split('@').first ?? 'Student';
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(
        profile: _profile,
        academicRecords: _academicRecords,
        announcements: _announcements,
        onRefresh: _loadData,
        loading: _loading,
        error: _error,
        greeting: _greeting,
        displayName: _displayName,
      ),
      _CoursesTab(academicRecords: _academicRecords, loading: _loading),
      _PaymentsTab(feeRecord: _feeRecord, loading: _loading),
      _DocumentsTab(profile: _profile),
      const _ChatTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: pages),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFloatingNav()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.white,
      title: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(9)),
          child:
              const Icon(Icons.school_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        const Text('AU Connect',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
                fontSize: 17)),
      ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE5E7EB), height: 1),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.language_rounded,
              color: AppTheme.textMuted, size: 20),
          tooltip: 'Change Language',
          onPressed: () =>
              Navigator.pushNamed(context, '/language_change'),
        ),
        GestureDetector(
          onTap: () => setState(() => _selectedIndex = 3),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFD33131), Color(0xFF7A0000)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _displayName.isNotEmpty
                    ? _displayName[0].toUpperCase()
                    : 'S',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingNav() {
    final items = [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Courses'),
      (Icons.account_balance_wallet_outlined,
          Icons.account_balance_wallet_rounded, 'Pay'),
      (Icons.folder_outlined, Icons.folder_rounded, 'Docs'),
      (Icons.smart_toy_outlined, Icons.smart_toy_rounded, 'AI'),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF2F2F7).withValues(alpha: 0),
            const Color(0xFFF2F2F7)
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8)),
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final (icon, activeIcon, label) = items[i];
            final isSelected = _selectedIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 16 : 10, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    color:
                        isSelected ? Colors.white : AppTheme.outline,
                    size: 22,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: isSelected
                        ? Row(children: [
                            const SizedBox(width: 6),
                            Text(label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ])
                        : const SizedBox.shrink(),
                  ),
                ]),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── HOME TAB ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final List<Map<String, dynamic>> academicRecords;
  final List<Map<String, dynamic>> announcements;
  final Future<void> Function() onRefresh;
  final bool loading;
  final String? error;
  final String greeting;
  final String displayName;

  const _HomeTab({
    required this.profile,
    required this.academicRecords,
    required this.announcements,
    required this.onRefresh,
    required this.loading,
    required this.error,
    required this.greeting,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppTheme.primary, strokeWidth: 3));
    }

    final latest =
        academicRecords.isNotEmpty ? academicRecords.first : null;
    final semester = latest?['semester']?.toString() ?? '—';
    final gpa = latest?['gpa']?.toString() ?? '—';
    final courses = latest?['courses'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
              child: _buildWelcomeCard(context, semester, gpa, courses.length)),
          if (error != null)
            SliverToBoxAdapter(child: _buildError(context)),
          if (announcements.isNotEmpty)
            SliverToBoxAdapter(
                child: _buildAnnouncements(context)),
          if (courses.isNotEmpty)
            SliverToBoxAdapter(
                child: _buildCoursesSection(context, courses)),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(
      BuildContext context, String semester, String gpa, int courseCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD33131), Color(0xFF6B0000)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFD33131).withValues(alpha: 0.32),
              blurRadius: 26,
              offset: const Offset(0, 12))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('$greeting,',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text('Africa University Student',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13)),
              ])),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 28),
          ),
        ]),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            _miniStat(semester, 'Semester'),
            _vDivider(),
            _miniStat(gpa, 'GPA'),
            _vDivider(),
            _miniStat('$courseCount', 'Courses'),
          ]),
        ),
      ]),
    );
  }

  Widget _miniStat(String value, String label) {
    return Expanded(
        child: Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label,
          style:
              TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
    ]));
  }

  Widget _vDivider() {
    return Container(
        width: 1, height: 36, color: Colors.white.withValues(alpha: 0.2));
  }

  Widget _buildError(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200)),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded,
            color: Colors.orange.shade700, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(error!,
                style: TextStyle(
                    color: Colors.orange.shade800, fontSize: 12))),
        TextButton(
            onPressed: onRefresh,
            child: const Text('Retry', style: TextStyle(fontSize: 12))),
      ]),
    );
  }

  Widget _buildAnnouncements(BuildContext context) {
    final accentColors = [
      const Color(0xFF7C3AED),
      const Color(0xFF0EA5E9),
      const Color(0xFFD97706),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Row(children: [
          const Text('Announcements',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Text('${announcements.length}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      ...announcements.take(3).toList().asMap().entries.map((entry) {
        final a = entry.value;
        final color = accentColors[entry.key % accentColors.length];
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.campaign_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
                child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['title']?.toString() ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (a['body'] != null)
                Text(a['body']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ])),
          ]),
        );
      }),
    ]);
  }

  Widget _buildCoursesSection(BuildContext context, List<dynamic> courses) {
    final courseColors = [
      const Color(0xFF7C3AED),
      const Color(0xFFD33131),
      const Color(0xFF0EA5E9),
      const Color(0xFF16A34A),
      const Color(0xFFD97706),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Text('Current Courses',
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface)),
      ),
      ...courses.take(5).toList().asMap().entries.map((entry) {
        final i = entry.key;
        final c = entry.value;
        final course =
            c is Map ? c : {'name': c.toString(), 'code': '', 'grade': 'N/A'};
        final color = courseColors[i % courseColors.length];
        final grade = course['grade']?.toString() ?? 'N/A';
        Color gradeColor;
        if (grade.startsWith('A')) {
          gradeColor = const Color(0xFF16A34A);
        } else if (grade.startsWith('B')) {
          gradeColor = const Color(0xFF0EA5E9);
        } else if (grade.startsWith('C')) {
          gradeColor = const Color(0xFFD97706);
        } else {
          gradeColor = AppTheme.outline;
        }
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border(left: BorderSide(color: color, width: 4)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(children: [
            Expanded(
                child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(course['name']?.toString() ?? 'Course',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.onSurface)),
              if ((course['code']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(course['code']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.onSurfaceVariant)),
              ],
            ])),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(grade,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: gradeColor)),
            ),
          ]),
        );
      }),
    ]);
  }
}

// ── COURSES TAB ───────────────────────────────────────────────────────────────

class _CoursesTab extends StatelessWidget {
  final List<Map<String, dynamic>> academicRecords;
  final bool loading;

  const _CoursesTab({required this.academicRecords, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppTheme.primary, strokeWidth: 3));
    }
    if (academicRecords.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.school_outlined,
                size: 40, color: AppTheme.primary)),
        const SizedBox(height: 20),
        const Text('No Academic Records',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface)),
        const SizedBox(height: 8),
        const Text('Your records will appear here',
            style: TextStyle(color: AppTheme.onSurfaceVariant)),
      ]));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Academic Records',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface)),
        const SizedBox(height: 4),
        Text(
            '${academicRecords.length} semester${academicRecords.length == 1 ? '' : 's'} recorded',
            style: const TextStyle(
                color: AppTheme.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 20),
        ...academicRecords.map((record) {
          final courses = record['courses'] as List<dynamic>? ?? [];
          final gpa = record['gpa']?.toString() ?? 'N/A';
          final gpaVal = double.tryParse(gpa) ?? 0;
          final gpaColor = gpaVal >= 3.5
              ? const Color(0xFF16A34A)
              : gpaVal >= 2.5
                  ? const Color(0xFF0EA5E9)
                  : const Color(0xFFD97706);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF334155)]),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(record['semester']?.toString() ?? 'Semester',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('${courses.length} courses',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 13)),
                      ])),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: gpaColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      Text(gpa,
                          style: TextStyle(
                              color: gpaColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 20)),
                      Text('GPA',
                          style: TextStyle(
                              color: gpaColor.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
              ),
              if (courses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      children: courses.asMap().entries.map((entry) {
                    final c = entry.value;
                    final course = c is Map
                        ? c
                        : {'name': c.toString(), 'code': '', 'grade': 'N/A'};
                    final isLast = entry.key == courses.length - 1;
                    final grade = course['grade']?.toString() ?? 'N/A';
                    Color gc;
                    if (grade.startsWith('A')) {
                      gc = const Color(0xFF16A34A);
                    } else if (grade.startsWith('B')) {
                      gc = const Color(0xFF0EA5E9);
                    } else if (grade.startsWith('C')) {
                      gc = const Color(0xFFD97706);
                    } else {
                      gc = AppTheme.outline;
                    }
                    return Column(children: [
                      Row(children: [
                        Expanded(
                            child: Text(
                                course['name']?.toString() ?? 'Course',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13))),
                        Text(grade,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: gc)),
                      ]),
                      if (!isLast)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1)),
                    ]);
                  }).toList()),
                ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ── PAYMENTS TAB ──────────────────────────────────────────────────────────────

class _PaymentsTab extends StatelessWidget {
  final Map<String, dynamic>? feeRecord;
  final bool loading;

  const _PaymentsTab({required this.feeRecord, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppTheme.primary, strokeWidth: 3));
    }

    if (feeRecord == null) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.account_balance_wallet_outlined,
                size: 40, color: AppTheme.primary)),
        const SizedBox(height: 20),
        const Text('No Fee Record Found',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface)),
        const SizedBox(height: 8),
        const Text('Contact the finance office for your fee statement',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            textAlign: TextAlign.center),
      ]));
    }

    final totalFees = (feeRecord!['total_fees'] as num?)?.toDouble() ?? 0.0;
    final paidAmount = (feeRecord!['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final balance = (totalFees - paidAmount).clamp(0.0, double.infinity);
    final progress =
        totalFees > 0 ? (paidAmount / totalFees).clamp(0.0, 1.0) : 0.0;
    final currency = feeRecord!['currency'] as String? ?? 'USD';
    final isPaid = balance <= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Fee Statement',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPaid
                  ? [const Color(0xFF16A34A), const Color(0xFF052e16)]
                  : [const Color(0xFFD33131), const Color(0xFF6B0000)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: (isPaid
                          ? const Color(0xFF16A34A)
                          : AppTheme.primary)
                      .withValues(alpha: 0.32),
                  blurRadius: 24,
                  offset: const Offset(0, 12))
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isPaid ? 'Fully Paid' : 'Outstanding Balance',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text('$currency ${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5)),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Flexible(
                child: Text('$currency ${paidAmount.toStringAsFixed(2)} paid',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              Flexible(
                child: Text('of $currency ${totalFees.toStringAsFixed(2)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13)),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        if (!isPaid)
          ElevatedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Online payment coming soon'))),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            icon: const Icon(Icons.payment_rounded),
            label: const Text('Pay Now',
                style:
                    TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
      ]),
    );
  }
}

// ── DOCUMENTS TAB ─────────────────────────────────────────────────────────────

class _DocumentsTab extends StatelessWidget {
  final Map<String, dynamic>? profile;

  const _DocumentsTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    final docs = [
      (Icons.description_rounded, 'Official Transcript', 'Full academic record',
          const Color(0xFF7C3AED)),
      (Icons.badge_rounded, 'Registration Letter', 'Proof of enrolment',
          const Color(0xFF0EA5E9)),
      (Icons.school_rounded, 'Student ID Card', 'Digital or physical ID',
          const Color(0xFF16A34A)),
      (Icons.receipt_long_rounded, 'Fee Receipt', 'Payment confirmation',
          const Color(0xFFD97706)),
      (Icons.workspace_premium_rounded, 'Recommendation Letter',
          'For scholarships & transfers', AppTheme.primary),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Documents',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface)),
        const SizedBox(height: 4),
        const Text('Request official university documents',
            style: TextStyle(
                color: AppTheme.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 20),
        ...docs.map((doc) {
          final (icon, title, subtitle, color) = doc;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.onSurface)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.onSurfaceVariant)),
              ])),
              ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(
                        content: Text('Requesting $title...'))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.1),
                  foregroundColor: color,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Request',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ── CHAT TAB ──────────────────────────────────────────────────────────────────

class _ChatTab extends StatelessWidget {
  const _ChatTab();

  @override
  Widget build(BuildContext context) {
    return const ChatbotDashboardScreen(
      systemPrompt: AUSystemPrompts.student,
      title: 'Student Assistant',
    );
  }
}
