class AppNavigationService {
  static String dashboardRouteForApplicantType(String applicantType) {
    final normalized = applicantType.trim().toLowerCase();
    if (normalized.contains('international')) return '/international_dashboard';
    if (normalized.contains('master') || normalized.contains('postgrad')) return '/masters_dashboard';
    if (normalized.contains('return') || normalized.contains('transfer')) return '/returning_dashboard';
    if (normalized.contains('admin')) return '/admin_dashboard';
    return '/onboarding_dashboard';
  }

  static String dashboardRouteForApplicantProfile(String applicantType) {
    return dashboardRouteForApplicantType(applicantType);
  }
}
