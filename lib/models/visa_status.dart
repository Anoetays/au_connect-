/// Shared enum for visa status across the application.
///
/// This is used by both the applicant dashboard state model and the
/// visa/immigration screens.

library;

enum VisaStatus {
  notStarted,
  inProgress,
  approved,
}
