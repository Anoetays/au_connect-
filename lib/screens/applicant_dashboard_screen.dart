import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/screens/activities_achievements_screen.dart';
import 'package:au_connect/screens/document_upload_screen.dart';
import 'package:au_connect/screens/education_history_screen.dart';
import 'package:au_connect/screens/profile_information_screen.dart';
import 'package:au_connect/screens/my_application_status_screen.dart';
import 'package:au_connect/screens/colleges_faculties_screen.dart';
import 'package:au_connect/screens/college_search_screen.dart';
import 'package:au_connect/screens/degree_search_screen.dart';
import 'package:au_connect/screens/payments_screen.dart';
import 'package:au_connect/screens/on_the_spot_admission_screen.dart';
import 'package:au_connect/screens/financial_assistance_screen.dart';
import 'package:au_connect/screens/payment_history_screen.dart';
import 'package:au_connect/screens/visa_immigration_screen.dart';
import 'package:au_connect/screens/travel_arrival_screen.dart';
import 'package:au_connect/screens/fees_currency_screen.dart';
import 'package:au_connect/screens/english_proficiency_screen.dart';
import 'package:au_connect/screens/accommodation_screen.dart';
import 'package:au_connect/screens/orientation_support_screen.dart';
import 'package:au_connect/screens/international_tips_screen.dart';
import 'package:au_connect/models/applicant_data.dart';
import 'package:au_connect/models/school_record.dart';

class ApplicantDashboardScreen extends StatefulWidget {
  final String applicantType;

  const ApplicantDashboardScreen({super.key, required this.applicantType});

  @override
  State<ApplicantDashboardScreen> createState() => _ApplicantDashboardScreenState();
}

class _ApplicantDashboardScreenState extends State<ApplicantDashboardScreen> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Applicant data model
  late ApplicantData _applicantData;

  bool _internationalPreview = false;

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

    // Load applicant data and dashboard preference
    _loadApplicantData();
    _loadDashboardPreference();
  }

  Future<void> _loadApplicantData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString('applicant_data');
    if (dataJson != null) {
      try {
        final dataMap = jsonDecode(dataJson) as Map<String, dynamic>;
        _applicantData = ApplicantData.fromJson(dataMap);
      } catch (e) {
        // If parsing fails, create default data
        _applicantData = ApplicantData();
      }
    } else {
      _applicantData = ApplicantData();
    }
    setState(() {});
  }

  Future<void> _saveApplicantData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('applicant_data', jsonEncode(_applicantData.toJson()));
  }

  Future<void> _updateApplicantData(void Function() update) async {
    setState(update);
    await _saveApplicantData();
  }

  Future<void> _loadDashboardPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPreview = prefs.getBool('internationalPreview') ?? false;
    setState(() {
      _internationalPreview = savedPreview;
    });
  }

  Future<void> _saveDashboardPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('internationalPreview', value);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  bool get _isInternational {
    if (_internationalPreview) return true;
    return widget.applicantType.toLowerCase() == 'international';
  }

  bool get _hasUploadedTranscript =>
      _applicantData.hasUploadedTranscript ||
      _applicantData.educationHistoryRecords.any((record) => record?.hasTranscript ?? false);

  String get _userName => 'Student';
  String get _applicationStatus => 'In Progress';
  double get _applicationProgress {
    if (!_isInternational) {
      return ([_hasUploadedTranscript, _applicantData.hasSubmittedEnglishScores, _applicantData.hasSubmittedPersonalStatement]
              .where((complete) => complete)
              .length /
          3);
    }

    final items = [
      _applicantData.hasSubmittedPersonalStatement,
      _applicantData.educationHistoryRecords.isNotEmpty,
      _hasUploadedTranscript,
      _applicantData.hasSubmittedEnglishScores,
      _applicantData.hasUploadedPassport,
      _applicantData.hasUploadedVisaDocuments,
      _applicantData.visaStatus == VisaStatus.approved,
      (_applicantData.arrivalDate != null && _applicantData.airportPickupRequested),
    ];

    return items.where((complete) => complete).length / items.length;
  }

  String get _nextDeadline => 'June 30, 2026';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildMainDashboardView(context, isDark);
  }

  Future<void> _navigateToNextTask(BuildContext context) async {
    if (_applicantData.educationHistoryRecords.isNotEmpty &&
        _applicantData.educationHistoryRecords.any((record) => !(record?.hasTranscript ?? false))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload a transcript (or mark it uploaded) for every school you listed before continuing.',
          ),
        ),
      );
      return;
    }

    // Routes the user to the next incomplete task/section and marks it complete.
    if (!_hasUploadedTranscript) {
      await _navigateToDocumentTask(context, DocumentUploadTask.transcript);
      return;
    }

    if (!_applicantData.hasSubmittedEnglishScores) {
      await _navigateToDocumentTask(context, DocumentUploadTask.english);
      return;
    }

    if (_isInternational && !_applicantData.hasUploadedPassport) {
      await _navigateToDocumentTask(context, DocumentUploadTask.passport);
      return;
    }

    if (_isInternational && !_applicantData.hasUploadedVisaDocuments) {
      await _navigateToDocumentTask(context, DocumentUploadTask.visa);
      return;
    }

    if (_isInternational && _applicantData.visaStatus != VisaStatus.approved) {
      final result = await Navigator.push<VisaImmigrationScreenResult?>(
        context,
        MaterialPageRoute(builder: (_) => VisaImmigrationScreen(initialStatus: _applicantData.visaStatus)),
      );
      if (result != null) {
        await _updateApplicantData(() {
          _applicantData.visaStatus = VisaStatus.values[result.status.index];
          _applicantData.hasUploadedPassport = result.checklist['Passport Copy'] == DocumentStatus.uploaded ||
              result.checklist['Passport Copy'] == DocumentStatus.verified;
          _applicantData.hasUploadedVisaDocuments = result.checklist['Proof of Funds'] == DocumentStatus.uploaded ||
              result.checklist['Proof of Funds'] == DocumentStatus.verified;
        });
      }
      return;
    }

    if (_isInternational && (_applicantData.arrivalDate == null || !_applicantData.airportPickupRequested)) {
      final result = await Navigator.push<TravelArrivalScreenResult?>(
        context,
        MaterialPageRoute(builder: (_) => TravelArrivalScreen(
          initialArrivalDate: _applicantData.arrivalDate,
          initialAirportPickupRequested: _applicantData.airportPickupRequested,
        )),
      );
      if (result != null) {
        await _updateApplicantData(() {
          _applicantData.arrivalDate = result.arrivalDate;
          _applicantData.airportPickupRequested = result.airportPickupRequested;
        });
      }
      return;
    }

    if (!_applicantData.hasSubmittedPersonalStatement) {
      final completed = await Navigator.push<bool?>(
        context,
        MaterialPageRoute(builder: (_) => const ProfileInformationScreen()),
      );
      if (completed == true) {
        await _updateApplicantData(() => _applicantData.hasSubmittedPersonalStatement = true);
      }
      return;
    }

    // Fallback: go to profile details if everything is complete.
    await Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (_) => const ProfileInformationScreen()),
    );
  }

  Future<void> _navigateToDocumentTask(BuildContext context, DocumentUploadTask task) async {
    final currentResult = DocumentUploadResult(
      transcriptUploaded: _hasUploadedTranscript,
      englishUploaded: _applicantData.hasSubmittedEnglishScores,
      passportUploaded: _applicantData.hasUploadedPassport,
      visaUploaded: _applicantData.hasUploadedVisaDocuments,
    );

    final result = await Navigator.push<DocumentUploadResult?>(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentUploadScreen(
          task: task,
          initialResult: currentResult,
        ),
      ),
    );

    if (result != null) {
      await _updateApplicantData(() {
        _applicantData.hasUploadedTranscript = result.transcriptUploaded;
        _applicantData.hasSubmittedEnglishScores = result.englishUploaded;
        _applicantData.hasUploadedPassport = result.passportUploaded;
        _applicantData.hasUploadedVisaDocuments = result.visaUploaded;
      });
    }
  }

  Widget _buildMainDashboardView(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      drawer: _buildDrawer(context, isDark),
      appBar: AppBar(
        title: Text('Welcome back, $_userName'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: colorScheme.onSurface.withOpacity(0.1),
              radius: 18,
              child: Icon(Symbols.person, color: colorScheme.onSurfaceVariant),
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
                    'Applicant Dashboard',
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Type: ${_internationalPreview ? 'International (Preview)' : widget.applicantType}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'View as:',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(12),
                        isSelected: [_internationalPreview == false, _internationalPreview == true],
                        onPressed: (index) async {
                          final newValue = index == 1;
                          setState(() {
                            _internationalPreview = newValue;
                          });
                          await _saveDashboardPreference(newValue);
                        },
                        borderColor: theme.dividerColor,
                        selectedBorderColor: AppTheme.primary,
                        selectedColor: Colors.white,
                        fillColor: AppTheme.primary,
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Local'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('International'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Application progress card
                  _buildAnimatedCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Application progress',
                                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            value: _applicationProgress,
                            backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                            color: colorScheme.primary,
                            minHeight: 8,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(_applicationProgress * 100).round()}% complete',
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                              _buildAnimatedButton(
                                onPressed: () => _navigateToNextTask(context),
                                child: const Text('Continue Application'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildProgressBreakdown(isDark),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

              // Deadline reminder card
              _buildAnimatedCard(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Symbols.event, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Next application deadline',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _nextDeadline,
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Application sections
              _buildAnimatedSectionCard(
                context,
                icon: Symbols.person,
                title: 'Profile Information',
                subtitle: 'Update your personal details',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileInformationScreen(),
                    ),
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildAnimatedSectionCard(
                context,
                icon: Symbols.school,
                title: 'Education History',
                subtitle: 'Add previous schools and transcripts',
                onTap: () async {
                  final updatedRecords = await Navigator.push<List<SchoolRecord>?>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EducationHistoryScreen(initialRecords: _applicantData.educationHistoryRecords),
                    ),
                  );
                  if (updatedRecords != null) {
                    await _updateApplicantData(() {
                      _applicantData.educationHistoryRecords
                        ..clear()
                        ..addAll(updatedRecords);
                    });
                  }
                },
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildAnimatedSectionCard(
                context,
                icon: Symbols.emoji_events,
                title: 'Activities & Achievements',
                subtitle: 'Share your extracurriculars',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActivitiesAchievementsScreen(),
                    ),
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildAnimatedSectionCard(
                context,
                icon: Symbols.upload_file,
                title: 'Document Upload',
                subtitle: _isInternational
                    ? 'Upload transcripts, passport & visa documents, and test scores'
                    : 'Upload transcripts and ID documents',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentUploadScreen(
                        task: _isInternational ? DocumentUploadTask.overview : DocumentUploadTask.transcript,
                      ),
                    ),
                  );
                },
                isDark: isDark,
              ),

              if (_isInternational) ...[
                const SizedBox(height: 16),
                _buildAnimatedSectionCard(
                  context,
                  icon: Symbols.flight_takeoff,
                  title: 'Visa & Immigration',
                  subtitle: 'Track your visa status and required documents',
                  onTap: () async {
                    final result = await Navigator.push<VisaImmigrationScreenResult?>(
                      context,
                      MaterialPageRoute(builder: (_) => VisaImmigrationScreen(initialStatus: _applicantData.visaStatus)),
                    );
                    if (result != null) {
                      await _updateApplicantData(() {
                        _applicantData.visaStatus = VisaStatus.values[result.status.index];
                        _applicantData.hasUploadedPassport =
                            result.checklist['Passport Copy'] == DocumentStatus.uploaded ||
                                result.checklist['Passport Copy'] == DocumentStatus.verified;
                        _applicantData.hasUploadedVisaDocuments =
                            result.checklist['Proof of Funds'] == DocumentStatus.uploaded ||
                                result.checklist['Proof of Funds'] == DocumentStatus.verified;
                      });
                    }
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildAnimatedSectionCard(
                  context,
                  icon: Symbols.flight,
                  title: 'Travel & Arrival',
                  subtitle: 'Plan your arrival and request airport pickup',
                  onTap: () async {
                    final result = await Navigator.push<TravelArrivalScreenResult?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TravelArrivalScreen(
                          initialArrivalDate: _applicantData.arrivalDate,
                          initialAirportPickupRequested: _applicantData.airportPickupRequested,
                        ),
                      ),
                    );
                    if (result != null) {
                      await _updateApplicantData(() {
                        _applicantData.arrivalDate = result.arrivalDate;
                        _applicantData.airportPickupRequested = result.airportPickupRequested;
                      });
                    }
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildAnimatedSectionCard(
                  context,
                  icon: Symbols.attach_money,
                  title: 'Fees & Payments',
                  subtitle: 'View tuition fees and payment options',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeesCurrencyScreen()),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildAnimatedSectionCard(
                  context,
                  icon: Symbols.language,
                  title: 'English Proficiency',
                  subtitle: 'Submit IELTS/TOEFL scores or request a waiver',
                  onTap: () async {
                    final result = await Navigator.push<EnglishProficiencyScreenResult?>(
                      context,
                      MaterialPageRoute(builder: (_) => const EnglishProficiencyScreen()),
                    );
                    if (result != null) {
                      await _updateApplicantData(() {
                        _applicantData.hasSubmittedEnglishScores = result.status == ProficiencyStatus.submitted ||
                            result.status == ProficiencyStatus.verified ||
                            result.status == ProficiencyStatus.waived;
                      });
                    }
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildAnimatedSectionCard(
                  context,
                  icon: Symbols.home,
                  title: 'Accommodation',
                  subtitle: 'Find on-campus and off-campus housing options',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccommodationScreen()),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildAnimatedSectionCard(
                  context,
                  icon: Symbols.support_agent,
                  title: 'Orientation & Support',
                  subtitle: 'Get orientation details and support contacts',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrientationSupportScreen()),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildAnimatedSectionCard(
                  context,
                  icon: Symbols.lightbulb,
                  title: 'Tips for International Students',
                  subtitle: 'Quick tips to help you get started overseas',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InternationalTipsScreen()),
                    );
                  },
                  isDark: isDark,
                ),
              ],

              const SizedBox(height: 24),

              // Remaining tasks
              Text(
                'Remaining tasks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTaskItem(
                'Upload High School Transcript',
                _hasUploadedTranscript,
                isDark,
                () => _navigateToDocumentTask(context, DocumentUploadTask.transcript),
              ),
              _buildTaskItem(
                'English Proficiency Test Scores',
                _applicantData.hasSubmittedEnglishScores,
                isDark,
                () => _navigateToDocumentTask(context, DocumentUploadTask.english),
              ),
              _buildTaskItem(
                'Submit Personal Statement',
                _applicantData.hasSubmittedPersonalStatement,
                isDark,
                () async {
                  final completed = await Navigator.push<bool?>(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileInformationScreen()),
                  );
                  if (completed == true) {
                    await _updateApplicantData(() => _applicantData.hasSubmittedPersonalStatement = true);
                  }
                },
              ),

              if (_isInternational) ...[
                const SizedBox(height: 12),
                _buildTaskItem(
                  'Upload Passport Copy',
                  _applicantData.hasUploadedPassport,
                  isDark,
                  () => _navigateToDocumentTask(context, DocumentUploadTask.passport),
                ),
                _buildTaskItem(
                  'Upload Visa Documents',
                  _applicantData.hasUploadedVisaDocuments,
                  isDark,
                  () => _navigateToDocumentTask(context, DocumentUploadTask.visa),
                ),
                _buildTaskItem(
                  'Complete Visa Application',
                  _applicantData.visaStatus == VisaStatus.approved,
                  isDark,
                  () async {
                    final result = await Navigator.push<VisaImmigrationScreenResult?>(
                      context,
                      MaterialPageRoute(builder: (_) => VisaImmigrationScreen(initialStatus: _applicantData.visaStatus)),
                    );
                    if (result != null) {
                      await _updateApplicantData(() {
                        _applicantData.visaStatus = VisaStatus.values[result.status.index];
                      });
                    }
                  },
                ),
                _buildTaskItem(
                  'Plan Travel & Pickup',
                  _applicantData.arrivalDate != null && _applicantData.airportPickupRequested,
                  isDark,
                  () async {
                    final result = await Navigator.push<TravelArrivalScreenResult?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TravelArrivalScreen(
                          initialArrivalDate: _applicantData.arrivalDate,
                          initialAirportPickupRequested: _applicantData.airportPickupRequested,
                        ),
                      ),
                    );
                    if (result != null) {
                      await _updateApplicantData(() {
                        _applicantData.arrivalDate = result.arrivalDate;
                        _applicantData.airportPickupRequested = result.airportPickupRequested;
                      });
                    }
                  },
                ),
              ],

              const SizedBox(height: 32), // Bottom spacing
            ],
          ),
        ),
      ),
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
                  Text(
                    'Applicant Dashboard',
                    style: const TextStyle(
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
                  drawerItem('Application Dashboard', Symbols.dashboard, () => Navigator.pop(context)),
                  drawerItem('My Application', Symbols.description, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyApplicationStatusScreen()),
                    );
                  }),
                  drawerItem('Colleges & Faculties', Symbols.account_balance, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CollegesFacultiesScreen()),
                    );
                  }),
                  drawerItem('College Search', Symbols.search, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CollegeSearchScreen()),
                    );
                  }),
                  drawerItem('Degree Search', Symbols.school, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DegreeSearchScreen()),
                    );
                  }),
                  drawerItem('On-the-Spot Admission', Symbols.flash_on, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OnTheSpotAdmissionScreen()),
                    );
                  }),
                  drawerItem('Financial Assistance', Symbols.attach_money, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FinancialAssistanceScreen()),
                    );
                  }),
                  drawerItem('Payments', Symbols.payment, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                    );
                  }),
                  drawerItem('Payment History', Symbols.receipt_long, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
                    );
                  }),
                  if (_isInternational) ...[
                    drawerItem('Visa & Immigration', Symbols.flight_takeoff, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VisaImmigrationScreen()),
                      );
                    }),
                    drawerItem('Travel & Arrival', Symbols.flight, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TravelArrivalScreen()),
                      );
                    }),
                    drawerItem('Fees & Payments', Symbols.attach_money, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeesCurrencyScreen()),
                      );
                    }),
                    drawerItem('English Proficiency', Symbols.language, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EnglishProficiencyScreen()),
                      );
                    }),
                    drawerItem('Accommodation', Symbols.home, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AccommodationScreen()),
                      );
                    }),
                    drawerItem('Orientation & Support', Symbols.support_agent, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrientationSupportScreen()),
                      );
                    }),
                    drawerItem('Tips', Symbols.lightbulb, () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InternationalTipsScreen()),
                      );
                    }),
                  ],
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

  Widget _buildAnimatedCard({required Widget child}) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: theme.cardColor,
      child: child,
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return _AnimatedButtonWrapper(
      onPressed: onPressed,
      child: child,
    );
  }

  Widget _buildAnimatedSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return _AnimatedSectionCardWrapper(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      isDark: isDark,
    );
  }

  Widget _buildProgressBreakdown(bool isDark) {
    final theme = Theme.of(context);
    final items = [
      {'label': 'Profile', 'done': _applicantData.hasSubmittedPersonalStatement},
      {'label': 'Academic History', 'done': _applicantData.educationHistoryRecords.isNotEmpty},
      {'label': 'Documents', 'done': _hasUploadedTranscript && _applicantData.hasSubmittedEnglishScores},
      if (_isInternational) ...[
        {'label': 'Visa', 'done': _applicantData.visaStatus == VisaStatus.approved},
        {
          'label': 'Travel readiness',
          'done': _applicantData.arrivalDate != null && _applicantData.airportPickupRequested,
        },
      ],
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final done = item['done'] as bool;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: done ? AppTheme.primary.withOpacity(0.15) : theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: done ? AppTheme.primary : theme.dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                done ? Symbols.check_circle : Symbols.radio_button_unchecked,
                size: 16,
                color: done ? AppTheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                item['label'] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: done ? AppTheme.primary : theme.colorScheme.onSurfaceVariant,
                  fontWeight: done ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskItem(String title, bool completed, bool isDark, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              completed ? Symbols.check_circle : Symbols.radio_button_unchecked,
              color: completed ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              ),
            ),
            if (!completed)
              TextButton(
                onPressed: onTap,
                child: const Text('Do now'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedButtonWrapper extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _AnimatedButtonWrapper({
    required this.onPressed,
    required this.child,
  });

  @override
  State<_AnimatedButtonWrapper> createState() => _AnimatedButtonWrapperState();
}

class _AnimatedButtonWrapperState extends State<_AnimatedButtonWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton(
        onPressed: _handlePress,
        child: widget.child,
      ),
    );
  }
}

class _AnimatedSectionCardWrapper extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _AnimatedSectionCardWrapper({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_AnimatedSectionCardWrapper> createState() =>
      _AnimatedSectionCardWrapperState();
}

class _AnimatedSectionCardWrapperState extends State<_AnimatedSectionCardWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _elevationAnimation,
        builder: (context, child) {
          return InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(_elevationAnimation.value * 0.1),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Symbols.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

