import 'package:flutter/material.dart';

enum ApplicationStatus {
  draft,
  submitted,
  inReview,
  approved,
  rejected,
}

extension ApplicationStatusExtension on ApplicationStatus {
  String get displayName {
    switch (this) {
      case ApplicationStatus.draft:
        return 'Draft';
      case ApplicationStatus.submitted:
        return 'Submitted';
      case ApplicationStatus.inReview:
        return 'In Review';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  String get description {
    switch (this) {
      case ApplicationStatus.draft:
        return 'Your application is being prepared';
      case ApplicationStatus.submitted:
        return 'Application submitted successfully';
      case ApplicationStatus.inReview:
        return 'Application under review';
      case ApplicationStatus.approved:
        return 'Your application has been approved.';
      case ApplicationStatus.rejected:
        return 'Your application was not successful.';
    }
  }

  IconData get icon {
    switch (this) {
      case ApplicationStatus.draft:
        return Icons.edit;
      case ApplicationStatus.submitted:
        return Icons.check_circle;
      case ApplicationStatus.inReview:
        return Icons.hourglass_top;
      case ApplicationStatus.approved:
        return Icons.check_circle_outline;
      case ApplicationStatus.rejected:
        return Icons.cancel;
    }
  }

  Color get color {
    switch (this) {
      case ApplicationStatus.draft:
        return Colors.orange;
      case ApplicationStatus.submitted:
        return Colors.blue;
      case ApplicationStatus.inReview:
        return Colors.yellow;
      case ApplicationStatus.approved:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
    }
  }

  int get progressValue {
    switch (this) {
      case ApplicationStatus.draft:
        return 20;
      case ApplicationStatus.submitted:
        return 40;
      case ApplicationStatus.inReview:
        return 70;
      case ApplicationStatus.approved:
        return 100;
      case ApplicationStatus.rejected:
        return 0;
    }
  }
}

class ApplicationData {
  static ApplicationStatus currentStatus = ApplicationStatus.submitted; // This would come from backend

  static void updateStatus(ApplicationStatus newStatus) {
    currentStatus = newStatus;
    // In a real app, this would update the backend
    // Also trigger notification logic here
  }
}