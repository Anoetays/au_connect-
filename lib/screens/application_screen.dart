import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:au_connect/models/profile.dart';
import 'package:au_connect/services/app_navigation_service.dart';
import 'package:au_connect/services/application_service.dart';
import 'package:au_connect/services/profile_service.dart';
import 'package:au_connect/theme/app_theme.dart';

class ApplicationScreen extends StatefulWidget {
  const ApplicationScreen({super.key});

  @override
  State<ApplicationScreen> createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends State<ApplicationScreen> {
  final _programmeCtrl = TextEditingController();
  final _facultyCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _programmeCtrl.dispose();
    _facultyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(Profile profile) async {
    final programme = _programmeCtrl.text.trim();
    final faculty = _facultyCtrl.text.trim();
    if (programme.isEmpty || faculty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter programme and faculty.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApplicationService.submitApplication(
        profile: profile,
        type: profile.applicantType,
        programme: programme,
        faculty: faculty,
        nationality: profile.countryOfOrigin,
        phone: profile.phone,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully.')),
      );
      Navigator.of(context).pushReplacementNamed(
        AppNavigationService.dashboardRouteForApplicantProfile(profile.applicantType),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Application', style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<Profile?>(
        future: ProfileService.getMyProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('No profile found.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Profile validation', style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(profile.isComplete ? 'Profile is complete.' : 'Profile is incomplete. Please finish required fields.', style: GoogleFonts.dmSans()),
                      const SizedBox(height: 16),
                      TextField(controller: _programmeCtrl, decoration: const InputDecoration(labelText: 'Programme')),
                      const SizedBox(height: 12),
                      TextField(controller: _facultyCtrl, decoration: const InputDecoration(labelText: 'Faculty')),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : () => _submit(profile),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDark, foregroundColor: Colors.white),
                          child: _isSubmitting
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                              : const Text('Submit Application'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
