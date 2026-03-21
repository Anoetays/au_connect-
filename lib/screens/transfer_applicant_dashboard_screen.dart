import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/screens/transfer_credit_evaluation_screen.dart';
import 'package:au_connect/screens/transfer_program_eligibility_screen.dart';
import 'package:au_connect/screens/transfer_course_planner_screen.dart';
import 'package:au_connect/screens/transfer_documents_screen.dart';
import 'package:au_connect/screens/transfer_advisor_support_screen.dart';
import 'package:au_connect/screens/transfer_notifications_screen.dart';
import 'package:au_connect/screens/transfer_fees_summary_screen.dart';
import 'package:au_connect/models/transfer_data.dart';

class TransferApplicantDashboardScreen extends StatefulWidget {
  const TransferApplicantDashboardScreen({super.key});

  @override
  State<TransferApplicantDashboardScreen> createState() => _TransferApplicantDashboardScreenState();
}

class _TransferApplicantDashboardScreenState extends State<TransferApplicantDashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  late TransferData _transferData;

  String get _userName => 'Student';
  String get _applicationStatus {
    switch (_transferData.currentStage) {
      case TransferStage.submitted:
        return 'Submitted';
      case TransferStage.underReview:
        return 'Under Review';
      case TransferStage.creditEvaluation:
        return 'Credit Evaluation';
      case TransferStage.approved:
        return 'Approved';
      case TransferStage.admitted:
        return 'Admitted';
    }
  }

  String get _statusMessage {
    switch (_transferData.currentStage) {
      case TransferStage.submitted:
        return 'Your application has been submitted.';
      case TransferStage.underReview:
        return 'Your application is currently being reviewed.';
      case TransferStage.creditEvaluation:
        return 'Your transcripts are being evaluated for credit transfer.';
      case TransferStage.approved:
        return 'Your transfer credits have been approved.';
      case TransferStage.admitted:
        return 'Congratulations! You have been admitted.';
    }
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();

    _loadTransferData();
  }

  Future<void> _loadTransferData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('transferData');
    if (dataString != null) {
      try {
        final dataJson = jsonDecode(dataString);
        setState(() {
          _transferData = TransferData.fromJson(dataJson);
        });
      } catch (e) {
        // If parsing fails, use default data
        setState(() {
          _transferData = TransferData();
        });
      }
    } else {
      setState(() {
        _transferData = TransferData();
      });
    }
  }

  Future<void> _saveTransferData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = jsonEncode(_transferData.toJson());
    await prefs.setString('transferData', dataString);
  }

  void _updateTransferData(TransferData newData) {
    setState(() {
      _transferData = newData;
    });
    _saveTransferData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      drawer: _buildDrawer(context, isDark),
      appBar: AppBar(
        title: Text('Welcome back, $_userName'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              radius: 18,
              child: Icon(Symbols.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transfer Applicant Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Type: Transfer',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTransferStatusCard(context, isDark),
                  const SizedBox(height: 20),
                  _buildQuickStats(context),
                  const SizedBox(height: 20),
                  _buildNextActions(context),
                  const SizedBox(height: 20),
                  _buildCreditEvaluationSummary(context),
                  const SizedBox(height: 20),
                  _buildSmartInsights(context),
                  const SizedBox(height: 20),
                  _buildRecentNotifications(context),
                  const SizedBox(height: 20),
                  _buildAdvisorSupport(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransferStatusCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Application Status',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _applicationStatus,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _statusMessage,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            _buildStageIndicator(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStageIndicator(bool isDark) {
    final stages = [
      'Submitted',
      'Under Review',
      'Credit Evaluation',
      'Approved',
      'Admitted',
    ];

    final currentIndex = TransferStage.values.indexOf(_transferData.currentStage);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(stages.length, (index) {
        final isActive = index <= currentIndex;
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : Theme.of(context).cardColor,
                  border: Border.all(
                    color: isActive ? AppTheme.primary : Theme.of(context).dividerColor,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    isActive ? Symbols.check : Symbols.circle,
                    size: 14,
                    color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stages[index],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isActive ? AppTheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard(
          title: 'Credits Transferred',
          value: '${_transferData.creditsTransferred}',
          icon: Symbols.school,
          onTap: () async {
            final result = await Navigator.push<TransferStage?>(
              context,
              MaterialPageRoute(
                builder: (_) => TransferCreditEvaluationScreen(currentStage: _transferData.currentStage),
              ),
            );
            if (result != null && result != _transferData.currentStage) {
              _updateTransferData(_transferData.copyWith(currentStage: result));
            }
          },
        ),
        _buildStatCard(
          title: 'Credits Remaining',
          value: '${_transferData.creditsRemaining}',
          icon: Symbols.auto_stories,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransferCoursePlannerScreen()),
            );
          },
        ),
        _buildStatCard(
          title: 'Eligible Programs',
          value: '${_transferData.eligiblePrograms}',
          icon: Symbols.checklist_rtl,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransferProgramEligibilityScreen()),
            );
          },
        ),
        _buildStatCard(
          title: 'Documents',
          value: '${_transferData.uploadedDocuments}/${_transferData.totalDocuments}',
          icon: Symbols.upload_file,
          onTap: () async {
            final result = await Navigator.push<int?>(
              context,
              MaterialPageRoute(
                builder: (_) => TransferDocumentsScreen(
                  initialUploadedDocuments: _transferData.uploadedDocuments,
                  totalDocuments: _transferData.totalDocuments,
                ),
              ),
            );
            if (result != null && result != _transferData.uploadedDocuments) {
              _updateTransferData(_transferData.copyWith(uploadedDocuments: result));
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 170,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildActionCard(
              context,
              title: 'Upload Missing Documents',
              actionLabel: 'Upload',
              icon: Symbols.upload_file,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransferDocumentsScreen()),
                );
              },
            ),
            _buildActionCard(
              context,
              title: 'Submit Course Outlines',
              actionLabel: 'Submit',
              icon: Symbols.description,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransferCreditEvaluationScreen()),
                );
              },
            ),
            _buildActionCard(
              context,
              title: 'Book Advisor Session',
              actionLabel: 'Book',
              icon: Symbols.support_agent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransferAdvisorSupportScreen()),
                );
              },
            ),
            _buildActionCard(
              context,
              title: 'Review Eligible Programs',
              actionLabel: 'Review',
              icon: Symbols.school,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransferProgramEligibilityScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String actionLabel,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 220,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: onTap,
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditEvaluationSummary(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Credit Evaluation Summary',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEvaluationChip(context, 'Accepted', '18'),
                _buildEvaluationChip(context, 'Rejected', '6'),
                _buildEvaluationChip(context, 'Pending', '6'),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransferCreditEvaluationScreen()),
                  );
                },
                child: const Text('View Full Evaluation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationChip(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildSmartInsights(BuildContext context) {
    final theme = Theme.of(context);
    final insights = _transferData.smartInsights;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Insights',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            ...insights.map((text) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Symbols.info, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentNotifications(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Notifications',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.push<List<String>?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransferNotificationsScreen(initialNotifications: _transferData.notifications),
                      ),
                    );
                    if (result != null && result != _transferData.notifications) {
                      _updateTransferData(_transferData.copyWith(notifications: result));
                    }
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._transferData.notifications.map((notification) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Symbols.notifications, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        notification,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisorSupport(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Advisor Support',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push<String?>(
                      context,
                      MaterialPageRoute(builder: (_) => const TransferAdvisorSupportScreen()),
                    );
                    if (result != null) {
                      final updatedNotifications = List<String>.from(_transferData.notifications)..insert(0, result);
                      _updateTransferData(_transferData.copyWith(notifications: updatedNotifications));
                    }
                  },
                  child: const Text('Get Help'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Need assistance? Chat with an advisor or book a session to discuss credit transfer and program planning.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget drawerItem(String title, IconData icon, VoidCallback onTap) {
      return ListTile(
        leading: Icon(icon, color: colorScheme.onSurfaceVariant),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        onTap: onTap,
      );
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 26,
                    child: const Icon(Symbols.person, color: AppTheme.primary, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Transfer Dashboard',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  drawerItem('Dashboard Overview', Symbols.dashboard, () => Navigator.pop(context)),
                  drawerItem('Credit Evaluation', Symbols.school, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransferCreditEvaluationScreen()),
                    );
                  }),
                  drawerItem('Program Eligibility', Symbols.checklist_rtl, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransferProgramEligibilityScreen()),
                    );
                  }),
                  drawerItem('Course Planner', Symbols.calendar_month, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransferCoursePlannerScreen()),
                    );
                  }),
                  drawerItem('Documents', Symbols.upload_file, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransferDocumentsScreen()),
                    );
                  }),
                  drawerItem('Advisor Support', Symbols.support_agent, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransferAdvisorSupportScreen()),
                    );
                  }),
                  drawerItem('Notifications', Symbols.notifications, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransferNotificationsScreen(
                          initialNotifications: _transferData.notifications,
                        ),
                      ),
                    );
                  }),
                  drawerItem('Fees & Summary', Symbols.attach_money, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransferFeesSummaryScreen()),
                    );
                  }),
                  drawerItem('Settings', Symbols.settings, () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Symbols.logout, color: colorScheme.onSurfaceVariant),
              title: Text(
                'Sign Out',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
