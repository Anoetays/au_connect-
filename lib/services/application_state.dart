import 'package:flutter/material.dart';

/// Tracks which application steps are complete.
/// Singleton — shared across all three applicant dashboards.
class ApplicationState extends ChangeNotifier {
  static final ApplicationState _instance = ApplicationState._();
  static ApplicationState get instance => _instance;
  ApplicationState._();

  bool personalInfoComplete = false;
  bool documentsUploaded = false;
  bool programmeSelected = false;
  bool feePaid = false;
  bool applicationSubmitted = false;

  int get completedSteps {
    int n = 0;
    if (personalInfoComplete) n++;
    if (documentsUploaded) n++;
    if (programmeSelected) n++;
    if (feePaid) n++;
    if (applicationSubmitted) n++;
    return n;
  }

  double get progress => completedSteps / 5.0;

  // ── Individual setters ────────────────────────────────────────────────────

  void setPersonalInfo(bool v) {
    if (personalInfoComplete == v) return;
    personalInfoComplete = v;
    notifyListeners();
  }

  void setDocumentsUploaded(bool v) {
    if (documentsUploaded == v) return;
    documentsUploaded = v;
    notifyListeners();
  }

  void setProgrammeSelected(bool v) {
    if (programmeSelected == v) return;
    programmeSelected = v;
    notifyListeners();
  }

  void setFeePaid(bool v) {
    if (feePaid == v) return;
    feePaid = v;
    notifyListeners();
  }

  void setApplicationSubmitted(bool v) {
    if (applicationSubmitted == v) return;
    applicationSubmitted = v;
    notifyListeners();
  }

  // ── Sync from Supabase data ───────────────────────────────────────────────

  void syncFromData({
    required Map<String, dynamic>? profile,
    required Map<String, dynamic>? application,
    required List<Map<String, dynamic>> documents,
  }) {
    personalInfoComplete = profile != null &&
        (profile['full_name'] as String? ?? '').isNotEmpty &&
        (profile['phone'] as String? ?? '').isNotEmpty;

    documentsUploaded = documents.isNotEmpty;

    programmeSelected = application != null &&
        (application['program'] as String? ??
                application['programme'] as String? ??
                '')
            .isNotEmpty;

    feePaid = application?['application_fee_paid'] as bool? ?? false;

    final status =
        (application?['status'] as String? ?? '').toLowerCase();
    applicationSubmitted =
        status.isNotEmpty && status != 'draft';

    notifyListeners();
  }

  /// Guard: check if a step is reachable, show SnackBar and return false if not.
  bool canNavigateTo(int step, BuildContext context) {
    // step indices match the 5 steps (0-based):
    // 0=personal, 1=documents, 2=programme, 3=payment, 4=submit
    String? message;
    switch (step) {
      case 1: // documents requires personal info
        if (!personalInfoComplete) {
          message =
              'Please complete your Personal Information before uploading documents.';
        }
        break;
      case 2: // programme requires documents
        if (!documentsUploaded) {
          message =
              'Please upload your documents before selecting a programme.';
        }
        break;
      case 3: // payment requires programme
        if (!programmeSelected) {
          message =
              'Please select a programme before proceeding to payment.';
        }
        break;
      case 4: // submit requires fee paid
        if (!feePaid) {
          message =
              'Please pay the application fee before submitting your application.';
        }
        break;
    }
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF7F1D1D),
        ),
      );
      return false;
    }
    return true;
  }

  void reset() {
    personalInfoComplete = false;
    documentsUploaded = false;
    programmeSelected = false;
    feePaid = false;
    applicationSubmitted = false;
    notifyListeners();
  }
}
