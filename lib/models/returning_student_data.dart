/// Models for Returning Student Dashboard data structures

library;

// ==================== Enums ====================

enum ReinstatementStatus {
  notApplied,
  pending,
  approved,
  rejected,
}

enum PaymentStatus {
  paid,
  pending,
  overdue,
}

enum CourseLevel { firstYear, secondYear, thirdYear, fourthYear }

// ==================== Models ====================

/// Represents the previous academic activity of the returning student
class PreviousAcademicActivity {
  final String lastSemester; // e.g., "Fall 2023"
  final String program; // e.g., "Computer Science (BSc)"
  final String status; // e.g., "Good Standing", "Academic Probation"
  final int yearsAway; // Number of years since last enrollment
  final double gpa; // Last recorded GPA

  PreviousAcademicActivity({
    required this.lastSemester,
    required this.program,
    required this.status,
    required this.yearsAway,
    required this.gpa,
  });
}

/// Represents reinstatement/readmission application data
class ReinstatementApplication {
  final ReinstatementStatus status;
  final DateTime? appliedOn;
  final DateTime? deadline;
  final List<String> requiredDocuments;
  final List<String> uploadedDocuments;

  ReinstatementApplication({
    required this.status,
    this.appliedOn,
    this.deadline,
    required this.requiredDocuments,
    required this.uploadedDocuments,
  });

  bool get isPendingDocuments =>
      requiredDocuments.length > uploadedDocuments.length;

  double get completionPercentage =>
      uploadedDocuments.length / requiredDocuments.length;
}

/// Represents an outstanding fee/balance
class OutstandingFee {
  final String type; // e.g., "Tuition", "Accommodation", "Library"
  final double amount;
  final PaymentStatus status;
  final DateTime dueDate;
  final String description;

  OutstandingFee({
    required this.type,
    required this.amount,
    required this.status,
    required this.dueDate,
    required this.description,
  });
}

/// Represents a course the student is selecting
class CourseOption {
  final String courseCode;
  final String courseName;
  final int credits;
  final String instructor;
  final String schedule;
  final bool isPreviouslyCourse; // If student took this before
  final bool isRecommended; // If recommended for them

  CourseOption({
    required this.courseCode,
    required this.courseName,
    required this.credits,
    required this.instructor,
    required this.schedule,
    this.isPreviouslyCourse = false,
    this.isRecommended = false,
  });
}

/// Represents the academic catch-up plan
class CatchUpPlan {
  final int missedSemesters;
  final DateTime? originalGraduationDate;
  final DateTime? revisedGraduationDate;
  final List<String> suggestedCourses;
  final String academicAdvisorName;
  final String academicAdvisorEmail;

  CatchUpPlan({
    required this.missedSemesters,
    this.originalGraduationDate,
    this.revisedGraduationDate,
    required this.suggestedCourses,
    required this.academicAdvisorName,
    required this.academicAdvisorEmail,
  });
}

/// Represents previous housing record
class HousingRecord {
  final String semester; // e.g., "Fall 2023"
  final String hostelName;
  final String roomNumber;
  final double costPerSemester;
  final String status; // e.g., "Completed", "Cancelled"

  HousingRecord({
    required this.semester,
    required this.hostelName,
    required this.roomNumber,
    required this.costPerSemester,
    required this.status,
  });
}

/// Represents a housing option available
class HousingOption {
  final String hostelName;
  final String type; // e.g., "On-Campus", "Off-Campus"
  final double costPerSemester;
  final String availability; // e.g., "Available", "Limited"
  final List<String> amenities;
  final double distance; // Distance from campus in km
  final double rating; // 1-5 star rating

  HousingOption({
    required this.hostelName,
    required this.type,
    required this.costPerSemester,
    required this.availability,
    required this.amenities,
    required this.distance,
    required this.rating,
  });
}

/// Represents a notification/alert
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime dateTime;
  final String type; // e.g., "deadline", "payment", "registration"
  final bool isRead;
  final String? actionUrl; // Optional URL for action

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.dateTime,
    required this.type,
    this.isRead = false,
    this.actionUrl,
  });
}

/// Represents the complete returning student profile
class ReturningStudentProfile {
  final String studentId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String profileImageUrl;
  final PreviousAcademicActivity academicActivity;
  final ReinstatementApplication reinstatement;
  final List<OutstandingFee> outstandingFees;
  final List<CourseOption> availableCourses;
  final List<CourseOption> selectedCourses;
  final CatchUpPlan catchUpPlan;
  final List<HousingRecord> housingHistory;
  final List<HousingOption> housingOptions;
  final List<NotificationItem> notifications;
  final double totalOutstandingBalance;

  ReturningStudentProfile({
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.profileImageUrl,
    required this.academicActivity,
    required this.reinstatement,
    required this.outstandingFees,
    required this.availableCourses,
    required this.selectedCourses,
    required this.catchUpPlan,
    required this.housingHistory,
    required this.housingOptions,
    required this.notifications,
    required this.totalOutstandingBalance,
  });
}
