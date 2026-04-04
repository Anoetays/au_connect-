import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:au_connect/models/profile.dart';
import 'package:au_connect/providers/application_form_provider.dart';
import 'package:au_connect/services/application_state.dart';
import 'package:au_connect/services/application_service.dart';
import 'package:au_connect/services/supabase_client_provider.dart';
import 'package:au_connect/services/profile_service.dart';
import 'package:au_connect/theme/app_theme.dart';

const _kCrimson = AppTheme.primaryDark;
const _kInk = AppTheme.textPrimary;
const _kMuted = AppTheme.textMuted;
const _kBorder = AppTheme.border;
// TODO: Set to false before production release.
const _allowUnpaidSubmissionForTesting = true;

class SubmitApplicationScreen extends ConsumerStatefulWidget {
  const SubmitApplicationScreen({super.key});

  @override
  ConsumerState<SubmitApplicationScreen> createState() =>
      _SubmitApplicationScreenState();
}

class _SubmitApplicationScreenState
    extends ConsumerState<SubmitApplicationScreen> {
  bool _declared = false;
  bool _submitting = false;

  List<String> _missingProfileFields(Profile profile) {
    final missing = <String>[];
    if (profile.firstName.trim().isEmpty) missing.add('First name');
    if (profile.lastName.trim().isEmpty) missing.add('Last name');
    if (profile.email.trim().isEmpty) missing.add('Email');
    if (profile.phone.trim().isEmpty) missing.add('Phone');
    if (profile.applicantType.trim().isEmpty) missing.add('Applicant type');
    if (profile.countryOfOrigin.trim().isEmpty) missing.add('Country of origin');
    if (profile.countryOfResidence.trim().isEmpty) missing.add('Country of residence');
    if (profile.nationalId.trim().isEmpty) missing.add('National ID');
    if (profile.kinName.trim().isEmpty) missing.add('Next of kin name');
    if (profile.kinPhone.trim().isEmpty) missing.add('Next of kin phone');
    if (profile.hobbies.trim().isEmpty) missing.add('Hobbies');
    return missing;
  }

  Future<void> _showMissingProfileDialog(List<String> missingFields) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Profile incomplete'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('These profile fields are still missing:'),
              const SizedBox(height: 12),
              ...missingFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(field)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final formState = ref.read(applicationFormProvider);

    if (!formState.paymentInfo.isPaid && !_allowUnpaidSubmissionForTesting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete payment before submitting.'),
          backgroundColor: _kCrimson,
        ),
      );
      return;
    }

    if (!_declared) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the declaration before submitting.'),
          backgroundColor: _kCrimson,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final existingProfile = await ProfileService.getMyProfile();
      final signedInEmail = SupabaseClientProvider.currentUser?.email ?? '';
      final mergedProfile = (existingProfile ?? const Profile()).copyWith(
        firstName: formState.firstName,
        middleName: formState.middleName,
        lastName: formState.lastName,
        email: formState.email.trim().isNotEmpty
            ? formState.email.trim()
            : (existingProfile?.email.trim().isNotEmpty == true
                ? existingProfile!.email.trim()
                : signedInEmail),
        phone: formState.phone.trim().isNotEmpty
            ? formState.phone.trim()
            : existingProfile?.phone,
        countryOfOrigin: formState.country,
        countryOfResidence: formState.country,
        nationalId: formState.nationalId,
        kinName: formState.kinName,
        kinPhone: formState.kinPhone,
        hobbies: formState.hobbies,
      );

      final missingFields = _missingProfileFields(mergedProfile);
      if (missingFields.isNotEmpty) {
        await _showMissingProfileDialog(missingFields);
        return;
      }

      await ProfileService.upsertProfile(
        mergedProfile,
      );

      await ApplicationService.finalizeSubmission();

      final app = await ApplicationService.getMyApplication();
      final appId = app?.id;
      if (appId != null) {
        await ApplicationService.updateApplicationProgramme(
          appId,
          programme: formState.selectedProgram.name,
          faculty: formState.selectedProgram.faculty,
        );
        await ApplicationService.updateApplicationFeePaid(
          appId,
          formState.paymentInfo.isPaid,
        );
      }

      ApplicationState.instance.setApplicationSubmitted(true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e'),
          backgroundColor: _kCrimson,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(applicationFormProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kInk,
        elevation: 0,
        title: Text(
          'Final Review & Submission',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: _kInk,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoCard(
              title: 'Personal Information',
              rows: [
                _row('Full Name', state.fullName),
                _row('Email', state.email),
                _row('Phone', state.phone),
                _row('Date of Birth', state.dob),
                _row('Country', state.country),
              ],
            ),
            const SizedBox(height: 14),
            _InfoCard(
              title: 'Selected Programme',
              rows: [
                _row('Programme', state.selectedProgram.name),
                _row('Faculty', state.selectedProgram.faculty),
                _row('Duration', '${state.selectedProgram.durationYears} year(s)'),
              ],
            ),
            const SizedBox(height: 14),
            _InfoCard(
              title: 'Documents',
              rows: state.documents.isEmpty
                  ? [_row('Status', 'No documents uploaded')]
                  : state.documents
                      .map((d) => _row(d.type, d.fileName))
                      .toList(),
            ),
            const SizedBox(height: 14),
            _InfoCard(
              title: 'Payment',
              rows: [
                _row('Paid', state.paymentInfo.isPaid ? 'Yes' : 'No'),
                _row('Amount', '\$${state.paymentInfo.amount.toStringAsFixed(2)}'),
                _row('Reference', state.paymentInfo.reference ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _declared,
              onChanged: (value) => setState(() => _declared = value ?? false),
              title: Text(
                'I declare that all information provided is true and correct.',
                style: GoogleFonts.dmSans(fontSize: 13.5, color: _kInk),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kCrimson,
                  foregroundColor: Colors.white,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Submit Application',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  MapEntry<String, String> _row(String label, String value) =>
      MapEntry(label, value.trim().isEmpty ? 'N/A' : value);
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${row.key}:',
                      style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: GoogleFonts.dmSans(fontSize: 13.5, color: _kInk),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
