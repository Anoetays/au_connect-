import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/models/returning_student_data.dart';

/// Mock service to simulate fetching returning student profile data from a backend.
class ReturningStudentService {
  /// Simulates an asynchronous API call to fetch the student's complete profile.
  Future<ReturningStudentProfile> fetchStudentProfile() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    return ReturningStudentProfile(
      studentId: 'STU-2024-001',
      fullName: 'Sarah Johnson',
      email: 'sarah.johnson@university.edu',
      phoneNumber: '+1 (555) 123-4567',
      profileImageUrl: '',
      academicActivity: PreviousAcademicActivity(
        lastSemester: 'Fall 2022',
        program: 'Computer Science (BSc)',
        status: 'Good Standing',
        yearsAway: 2,
        gpa: 3.5,
      ),
      reinstatement: ReinstatementApplication(
        status: ReinstatementStatus.pending,
        appliedOn: DateTime.now().subtract(const Duration(days: 5)),
        deadline: DateTime.now().add(const Duration(days: 10)),
        requiredDocuments: [
          'Proof of Graduation (if applicable)',
          'Academic Transcript',
          'Personal Statement',
          'Letter of Recommendation',
        ],
        uploadedDocuments: [
          'Proof of Graduation (if applicable)',
          'Academic Transcript',
        ],
      ),
      outstandingFees: [
        OutstandingFee(
          type: 'Tuition',
          amount: 5000.00,
          status: PaymentStatus.pending,
          dueDate: DateTime.now().add(const Duration(days: 20)),
          description: 'Spring 2024 Semester Tuition',
        ),
        OutstandingFee(
          type: 'Library Fine',
          amount: 150.00,
          status: PaymentStatus.overdue,
          dueDate: DateTime.now().subtract(const Duration(days: 30)),
          description: 'Outstanding library fees from previous enrollment',
        ),
      ],
      availableCourses: [
        CourseOption(
          courseCode: 'CS301',
          courseName: 'Data Structures',
          credits: 3,
          instructor: 'Dr. Michael Smith',
          schedule: 'MWF 10:00 - 11:00 AM',
          isRecommended: true,
        ),
        CourseOption(
          courseCode: 'CS302',
          courseName: 'Algorithms',
          credits: 3,
          instructor: 'Prof. Emily White',
          schedule: 'TTh 2:00 - 3:30 PM',
          isRecommended: true,
        ),
        CourseOption(
          courseCode: 'CS303',
          courseName: 'Database Systems',
          credits: 4,
          instructor: 'Dr. James Brown',
          schedule: 'MWF 1:00 - 2:30 PM',
          isPreviouslyCourse: true,
        ),
        CourseOption(
          courseCode: 'MATH301',
          courseName: 'Linear Algebra',
          credits: 3,
          instructor: 'Prof. Robert Davis',
          schedule: 'TTh 10:00 - 11:30 AM',
        ),
      ],
      selectedCourses: [],
      catchUpPlan: CatchUpPlan(
        missedSemesters: 4,
        originalGraduationDate: DateTime(2023, 5, 15),
        revisedGraduationDate: DateTime(2025, 5, 15),
        suggestedCourses: [
          'CS301 - Data Structures',
          'CS302 - Algorithms',
          'ENG201 - Advanced Writing',
        ],
        academicAdvisorName: 'Dr. Patricia Lee',
        academicAdvisorEmail: 'patricia.lee@university.edu',
      ),
      housingHistory: [
        HousingRecord(
          semester: 'Fall 2022',
          hostelName: 'North Campus Residence',
          roomNumber: '405',
          costPerSemester: 2500.00,
          status: 'Completed',
        ),
        HousingRecord(
          semester: 'Spring 2022',
          hostelName: 'Central Campus Hostel',
          roomNumber: '207',
          costPerSemester: 2300.00,
          status: 'Completed',
        ),
      ],
      housingOptions: [
        HousingOption(
          hostelName: 'North Campus Residence',
          type: 'On-Campus',
          costPerSemester: 2500.00,
          availability: 'Available',
          amenities: ['WiFi', 'Dining Hall', 'Gym', 'Study Lounge'],
          distance: 0.5,
          rating: 4.5,
        ),
        HousingOption(
          hostelName: 'Central Park Apartments',
          type: 'Off-Campus',
          costPerSemester: 1800.00,
          availability: 'Limited',
          amenities: ['WiFi', 'Laundry', 'Parking', 'Kitchen'],
          distance: 2.0,
          rating: 4.2,
        ),
        HousingOption(
          hostelName: 'Student Commons',
          type: 'On-Campus',
          costPerSemester: 2200.00,
          availability: 'Available',
          amenities: ['WiFi', 'Gym', 'Cafeteria', 'Recreation Room'],
          distance: 0.8,
          rating: 4.7,
        ),
      ],
      notifications: [
        NotificationItem(
          id: '1',
          title: 'Reinstatement Deadline',
          message: 'Complete your reinstatement application by March 25, 2026',
          dateTime: DateTime.now(),
          type: 'deadline',
        ),
        NotificationItem(
          id: '2',
          title: 'Outstanding Fees',
          message: 'You have outstanding fees that must be paid before registration',
          dateTime: DateTime.now().subtract(const Duration(days: 1)),
          type: 'payment',
        ),
        NotificationItem(
          id: '3',
          title: 'Course Registration Open',
          message: 'Course registration for Spring 2024 is now open',
          dateTime: DateTime.now().subtract(const Duration(days: 2)),
          type: 'registration',
        ),
      ],
      totalOutstandingBalance: 5150.00,
    );
  }
}

/// Main Returning Student Dashboard Screen
/// Displays comprehensive information and features for students resuming studies.
class ReturningStudentDashboardScreen extends StatefulWidget {
  const ReturningStudentDashboardScreen({super.key});

  @override
  State<ReturningStudentDashboardScreen> createState() =>
      _ReturningStudentDashboardScreenState();
}

class _ReturningStudentDashboardScreenState
    extends State<ReturningStudentDashboardScreen> {
  final ReturningStudentService _service = ReturningStudentService();
  ReturningStudentProfile? _profile;
  bool _isLoading = true;
  bool _sidebarExpanded = true;
  String _currentPage = 'overview'; // Tracks which page to display

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _service.fetchStudentProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Sidebar Navigation
                if (!isMobile || _sidebarExpanded)
                  _buildSidebar(context, isMobile),
                // Main Content
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: _buildMainContent(),
                  ),
                ),
              ],
            ),
    );
  }

  /// Builds the top AppBar with profile and notifications
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'AU Connect',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        if (_profile != null) ...[
          // Notifications icon with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Symbols.notifications, color: Colors.black),
                onPressed: () {
                  debugPrint('Notifications tapped');
                  setState(() => _currentPage = 'notifications');
                },
              ),
              if (_profile!.notifications.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_profile!.notifications.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Profile menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                setState(() => _currentPage = 'profile');
              } else if (value == 'logout') {
                debugPrint('Logout tapped');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Symbols.person, size: 20),
                    SizedBox(width: 10),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Symbols.logout, size: 20),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Symbols.person, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  /// Builds the left sidebar navigation
  Widget _buildSidebar(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    final navigationItems = [
      ('overview', 'Dashboard Overview', Symbols.dashboard),
      ('resume', 'Resume Studies', Symbols.school),
      ('reinstatement', 'Reinstatement', Symbols.approval),
      ('fees', 'Fees & Payments', Symbols.receipt_long),
      ('courses', 'Course Registration', Symbols.menu_book),
      ('catchup', 'Catch-Up Plan', Symbols.timeline),
      ('housing', 'Housing', Symbols.home),
      ('notifications', 'Notifications', Symbols.notifications),
      ('profile', 'Profile', Symbols.person),
    ];

    return Container(
      width: _sidebarExpanded ? 280 : 80,
      color: Colors.white,
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: _sidebarExpanded
                ? Text(
                    'Menu',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  )
                : Icon(Symbols.menu, color: Colors.grey[600]),
          ),
          // Navigation Items
          Expanded(
            child: ListView.builder(
              itemCount: navigationItems.length,
              itemBuilder: (context, index) {
                final (page, label, icon) = navigationItems[index];
                final isSelected = _currentPage == page;

                return _buildNavItem(
                  page: page,
                  label: label,
                  icon: icon,
                  isSelected: isSelected,
                  isExpanded: _sidebarExpanded,
                );
              },
            ),
          ),
          // Sidebar Footer Toggle
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: IconButton(
              icon: Icon(
                _sidebarExpanded ? Symbols.chevron_left : Symbols.chevron_right,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() => _sidebarExpanded = !_sidebarExpanded);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single navigation item
  Widget _buildNavItem({
    required String page,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isExpanded,
  }) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.grey[100],
      onTap: () {
        setState(() => _currentPage = page);
      },
      leading: Icon(
        icon,
        color: isSelected ? Colors.red[800] : Colors.grey[600],
        size: 24,
      ),
      title: isExpanded
          ? Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.red[800] : Colors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            )
          : null,
      trailing: isExpanded && isSelected
          ? Icon(Symbols.chevron_right, color: Colors.red[800], size: 20)
          : null,
    );
  }

  /// Main content area - delegates to different pages based on _currentPage
  Widget _buildMainContent() {
    if (_profile == null) {
      return const Center(child: Text('Failed to load profile'));
    }

    switch (_currentPage) {
      case 'overview':
        return _buildOverviewPage();
      case 'resume':
        return _buildResumePage();
      case 'reinstatement':
        return _buildReinstatementPage();
      case 'fees':
        return _buildFeesPage();
      case 'courses':
        return _buildCoursesPage();
      case 'catchup':
        return _buildCatchUpPage();
      case 'housing':
        return _buildHousingPage();
      case 'notifications':
        return _buildNotificationsPage();
      case 'profile':
        return _buildProfilePage();
      default:
        return _buildOverviewPage();
    }
  }

  // ==================== Page Builders ====================

  /// Dashboard Overview Page
  Widget _buildOverviewPage() {
    final profile = _profile!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'Welcome Back, ${profile.fullName}!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve been away for ${profile.academicActivity.yearsAway} year(s). Let\'s get you back on track!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Key Stats Cards
            _buildStatCards(profile),
            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActionsGrid(profile),
            const SizedBox(height: 32),

            // Recent Notifications
            Text(
              'Recent Notifications',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentNotifications(profile.notifications.take(3).toList()),
          ],
        ),
      ),
    );
  }

  /// Builds stat cards for the overview
  Widget _buildStatCards(ReturningStudentProfile profile) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard('Last Semester', profile.academicActivity.lastSemester,
            Symbols.calendar_month),
        _buildStatCard('Current GPA', '${profile.academicActivity.gpa}',
            Symbols.trending_up),
        _buildStatCard(
            'Outstanding Balance',
            '\$${profile.totalOutstandingBalance.toStringAsFixed(2)}',
            Symbols.attach_money),
        _buildStatCard('Missed Semesters',
            '${profile.catchUpPlan.missedSemesters}', Symbols.event_busy),
      ],
    );
  }

  /// Builds a single stat card
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.red[800], size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds quick action buttons grid
  Widget _buildQuickActionsGrid(ReturningStudentProfile profile) {
    final actions = [
      ('Resume Journey', Symbols.arrow_forward, 'resume'),
      ('Pay Fees', Symbols.payment, 'fees'),
      ('Register Courses', Symbols.menu_book, 'courses'),
      ('Apply Housing', Symbols.home, 'housing'),
    ];

    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: actions
          .map(
            (action) => _buildActionButton(action.$1, action.$2, action.$3),
          )
          .toList(),
    );
  }

  /// Builds a quick action button
  Widget _buildActionButton(String label, IconData icon, String page) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: () => setState(() => _currentPage = page),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.red[800], size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the resume journey page
  Widget _buildResumePage() {
    final activity = _profile!.academicActivity;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resume Your Journey',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // Previous Academic Activity Card
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Last Academic Activity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Last Semester:', activity.lastSemester),
                    _buildInfoRow('Program:', activity.program),
                    _buildInfoRow('Status:', activity.status),
                    _buildInfoRow('Years Away:', '${activity.yearsAway} years'),
                    _buildInfoRow('GPA:', activity.gpa.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.elevated(
                onPressed: () {
                  debugPrint('Continue where you left off tapped');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continue Where You Left Off',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Reinstatement application page
  Widget _buildReinstatementPage() {
    final reinstatement = _profile!.reinstatement;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reinstatement / Readmission',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // Status Card
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      reinstatement.status == ReinstatementStatus.pending
                          ? Symbols.hourglass_empty
                          : reinstatement.status == ReinstatementStatus.approved
                              ? Symbols.check_circle
                              : Symbols.cancel,
                      color: reinstatement.status == ReinstatementStatus.pending
                          ? Colors.amber[700]
                          : reinstatement.status == ReinstatementStatus.approved
                              ? Colors.green[700]
                              : Colors.red[800],
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reinstatement.status == ReinstatementStatus.pending
                                ? 'Application Pending'
                                : reinstatement.status ==
                                        ReinstatementStatus.approved
                                    ? 'Application Approved'
                                    : 'Application Not Started',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (reinstatement.deadline != null)
                            Text(
                              'Deadline: ${reinstatement.deadline?.toString().split(' ')[0]}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Document Upload Section
            Text(
              'Required Documents',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: reinstatement.completionPercentage,
              color: Colors.green[700],
              backgroundColor: Colors.grey[300],
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${reinstatement.uploadedDocuments.length} of ${reinstatement.requiredDocuments.length} documents uploaded',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              itemCount: reinstatement.requiredDocuments.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final doc = reinstatement.requiredDocuments[index];
                final isUploaded =
                    reinstatement.uploadedDocuments.contains(doc);

                return ListTile(
                  leading: Icon(
                    isUploaded ? Symbols.check_circle : Symbols.upload_file,
                    color: isUploaded ? Colors.green[700] : Colors.grey[400],
                  ),
                  title: Text(doc),
                  trailing: isUploaded
                      ? null
                      : ElevatedButton(
                          onPressed: () =>
                              debugPrint('Upload $doc tapped'),
                          child: const Text('Upload'),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Fees and payments page
  Widget _buildFeesPage() {
    final fees = _profile!.outstandingFees;
    final totalBalance = _profile!.totalOutstandingBalance;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fees & Payments',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // Total Balance Card
            Card(
              color: Colors.red[50],
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Outstanding Balance',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\$${totalBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            debugPrint('Pay Now tapped'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                        ),
                        child: const Text(
                          'Pay Now',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Fees List
            Text(
              'Fee Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              itemCount: fees.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final fee = fees[index];
                return _buildFeeItem(fee);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single fee item
  Widget _buildFeeItem(OutstandingFee fee) {
    final statusColor = fee.status == PaymentStatus.paid
        ? Colors.green[700]
        : fee.status == PaymentStatus.pending
            ? Colors.amber[700]
            : Colors.red[800];

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fee.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor?.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fee.status == PaymentStatus.paid
                        ? 'Paid'
                        : fee.status == PaymentStatus.pending
                            ? 'Pending'
                            : 'Overdue',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              fee.description,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${fee.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Due: ${fee.dueDate.toString().split(' ')[0]}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Course registration page
  Widget _buildCoursesPage() {
    final courses = _profile!.availableCourses;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Registration',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select courses for the upcoming semester',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Recommended Courses
            Text(
              'Recommended For You',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              itemCount: courses.where((c) => c.isRecommended).length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final course = courses.where((c) => c.isRecommended).toList()[index];
                return _buildCourseCard(course);
              },
            ),
            const SizedBox(height: 24),

            // Other Available Courses
            Text(
              'Other Available Courses',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              itemCount: courses.where((c) => !c.isRecommended).length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final course = courses.where((c) => !c.isRecommended).toList()[index];
                return _buildCourseCard(course);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a course card
  Widget _buildCourseCard(CourseOption course) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${course.courseCode} - ${course.courseName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Instructor: ${course.instructor}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (course.isRecommended)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Recommended',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${course.credits} Credits • ${course.schedule}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => debugPrint('Register ${course.courseCode} tapped'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Catch-up plan page
  Widget _buildCatchUpPage() {
    final plan = _profile!.catchUpPlan;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Academic Catch-Up Plan',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // Timeline Card
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Graduation Timeline',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Original Expected Graduation:',
                      plan.originalGraduationDate?.toString().split(' ')[0] ?? 'N/A',
                    ),
                    _buildInfoRow(
                      'Revised Graduation Date:',
                      plan.revisedGraduationDate?.toString().split(' ')[0] ?? 'N/A',
                    ),
                    _buildInfoRow(
                      'Semesters Missed:',
                      '${plan.missedSemesters}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Suggested Courses
            Text(
              'Suggested Courses',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              itemCount: plan.suggestedCourses.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.white,
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Symbols.check, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        Text(plan.suggestedCourses[index]),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Academic Advisor Info
            Card(
              color: Colors.blue[50],
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Academic Advisor',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      plan.academicAdvisorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.academicAdvisorEmail,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => debugPrint('Contact advisor tapped'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                        ),
                        child: const Text(
                          'Schedule Meeting',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Housing page
  Widget _buildHousingPage() {
    final profile = _profile!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Housing',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // Previous Housing History
            Text(
              'Previous Housing',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              itemCount: profile.housingHistory.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final record = profile.housingHistory[index];
                return Card(
                  color: Colors.white,
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              record.hostelName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                record.status,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Semester:',
                          record.semester,
                        ),
                        _buildInfoRow(
                          'Room:',
                          record.roomNumber,
                        ),
                        _buildInfoRow(
                          'Cost:',
                          '\$${record.costPerSemester}',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Available Housing Options
            Text(
              'Available Housing Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              itemCount: profile.housingOptions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final option = profile.housingOptions[index];
                return _buildHousingOptionCard(option);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a housing option card
  Widget _buildHousingOptionCard(HousingOption option) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.hostelName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${option.type} • ${option.distance} km from campus',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(Symbols.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${option.rating}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: option.availability == 'Available'
                            ? Colors.green[100]
                            : Colors.amber[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        option.availability,
                        style: TextStyle(
                          color: option.availability == 'Available'
                              ? Colors.green[800]
                              : Colors.amber[800],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: option.amenities
                  .map((amenity) => Chip(
                        label: Text(
                          amenity,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.grey[100],
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${option.costPerSemester}/semester',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      debugPrint('Apply for ${option.hostelName}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Notifications page
  Widget _buildNotificationsPage() {
    final notifications = _profile!.notifications;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              itemCount: notifications.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _buildNotificationItem(notif);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a notification item
  Widget _buildNotificationItem(NotificationItem notif) {
    final typeIcon = notif.type == 'deadline'
        ? Symbols.schedule
        : notif.type == 'payment'
            ? Symbols.payment
            : Symbols.assignment;

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(typeIcon, color: Colors.red[800], size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notif.dateTime.toString().split('.')[0],
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red[800],
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a list of recent notifications
  Widget _buildRecentNotifications(List<NotificationItem> notifications) {
    return Column(
      children: notifications
          .map((notif) => _buildNotificationItem(notif))
          .toList(),
    );
  }

  /// Profile page
  Widget _buildProfilePage() {
    final profile = _profile!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Profile',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // Profile Header
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Symbols.person, size: 40),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.fullName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${profile.studentId}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => debugPrint('Edit Profile tapped'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Contact Information
            Text(
              'Contact Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Email:', profile.email),
                    const Divider(),
                    _buildInfoRow('Phone:', profile.phoneNumber),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Academic Information
            Text(
              'Academic Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'Program:',
                      profile.academicActivity.program,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Last Semester:',
                      profile.academicActivity.lastSemester,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'GPA:',
                      profile.academicActivity.gpa.toString(),
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Status:',
                      profile.academicActivity.status,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
