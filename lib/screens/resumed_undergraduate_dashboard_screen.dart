import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart'; // Assuming this exists for consistency

/// Enum representing the overall clearance status of the resumed student.
enum ClearanceStatus {
  pending,
  inProgress,
  cleared,
}

/// Represents a single item in the resumption checklist.
class ChecklistItem {
  final String title;
  final String subtitle;
  final bool isCompleted;

  ChecklistItem({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
  });
}

/// Represents the profile data for a resumed undergraduate student.
class StudentProfile {
  final String name;
  final ClearanceStatus clearanceStatus;
  final List<ChecklistItem> checklistItems;

  StudentProfile({
    required this.name,
    required this.clearanceStatus,
    required this.checklistItems,
  });
}

/// Mock service to simulate fetching student profile data from a backend.
class ResumedStudentService {
  /// Simulates an asynchronous API call to fetch the student's profile.
  /// Uses Future.delayed to mimic network latency.
  Future<StudentProfile> fetchStudentProfile() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate 2-second delay

    // Mock data - in a real app, this would come from an API
    return StudentProfile(
      name: 'John Doe',
      clearanceStatus: ClearanceStatus.inProgress,
      checklistItems: [
        ChecklistItem(
          title: 'Update Personal Information',
          subtitle: 'Ensure your contact details and personal info are up to date.',
          isCompleted: true,
        ),
        ChecklistItem(
          title: 'Academic Clearance',
          subtitle: 'Obtain clearance from your academic department.',
          isCompleted: false,
        ),
        ChecklistItem(
          title: 'Financial Clearance',
          subtitle: 'Settle any outstanding fees or financial obligations.',
          isCompleted: false,
        ),
        ChecklistItem(
          title: 'Course Registration',
          subtitle: 'Register for your upcoming semester courses.',
          isCompleted: false,
        ),
      ],
    );
  }
}

/// Screen for the Resumed Undergraduate Students Dashboard.
/// Displays a dynamic UI based on fetched student data, including
/// a welcome header, overall status card, and resumption checklist.
class ResumedUndergraduateDashboardScreen extends StatefulWidget {
  const ResumedUndergraduateDashboardScreen({super.key});

  @override
  State<ResumedUndergraduateDashboardScreen> createState() =>
      _ResumedUndergraduateDashboardScreenState();
}

class _ResumedUndergraduateDashboardScreenState
    extends State<ResumedUndergraduateDashboardScreen> {
  final ResumedStudentService _service = ResumedStudentService();
  StudentProfile? _studentProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  /// Fetches the student profile from the mock service.
  Future<void> _loadStudentProfile() async {
    try {
      final profile = await _service.fetchStudentProfile();
      setState(() {
        _studentProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      // In a real app, handle errors appropriately (e.g., show error message)
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AU Connect',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[50],
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildDashboardContent(),
          ),
        ),
      ),
    );
  }

  /// Builds the main dashboard content once data is loaded.
  Widget _buildDashboardContent() {
    if (_studentProfile == null) {
      return const Center(child: Text('Failed to load profile.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Text(
            'Welcome Back, ${_studentProfile!.name}!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete the resumption checklist below to get back on track with your studies.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          // Overall Status Card
          _buildStatusCard(),
          const SizedBox(height: 24),

          // Resumption Checklist
          Text(
            'Resumption Checklist',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _studentProfile!.checklistItems.length,
              itemBuilder: (context, index) {
                final item = _studentProfile!.checklistItems[index];
                return _buildChecklistItem(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the overall status card displaying the clearance status.
  Widget _buildStatusCard() {
    final status = _studentProfile!.clearanceStatus;
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    String statusText;
    String description;

    switch (status) {
      case ClearanceStatus.pending:
        icon = Symbols.warning;
        color = Colors.red[800]!;
        statusText = 'Pending Clearance';
        description = 'Your resumption process has not started yet.';
        break;
      case ClearanceStatus.inProgress:
        icon = Symbols.hourglass_empty;
        color = Colors.amber[700]!;
        statusText = 'Clearance In Progress';
        description = 'You are working through the resumption requirements.';
        break;
      case ClearanceStatus.cleared:
        icon = Symbols.check_circle;
        color = Colors.green[700]!;
        statusText = 'Cleared';
        description = 'You are ready to resume your studies!';
        break;
    }

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single checklist item.
  Widget _buildChecklistItem(ChecklistItem item) {
    final theme = Theme.of(context);

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: InkWell(
        onTap: () {
          // Simulate navigation - in a real app, this would navigate to the form
          debugPrint('Navigating to: ${item.title}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                item.isCompleted ? Symbols.check_circle : Symbols.arrow_forward,
                color: item.isCompleted ? Colors.green[700] : Colors.grey[500],
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Symbols.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}