import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:au_connect/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:au_connect/config/supabase_config.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/screens/welcome_screen.dart';
import 'package:au_connect/screens/admin_sign_in_screen.dart';
import 'package:au_connect/screens/applicant_sign_in_screen.dart';
import 'package:au_connect/screens/student_sign_in_screen.dart';
import 'package:au_connect/screens/applicant_sign_up_screen.dart';
import 'package:au_connect/screens/applicant_type_selection_screen.dart';
import 'package:au_connect/screens/chatbot_dashboard_screen.dart';
import 'package:au_connect/screens/onboarding_dashboard_screen.dart';
import 'package:au_connect/screens/masters_dashboard_screen.dart';
import 'package:au_connect/screens/international_dashboard_screen.dart';
import 'package:au_connect/screens/returning_student_dashboard_screen.dart';
import 'package:au_connect/screens/student_dashboard_screen.dart';
import 'package:au_connect/screens/admin_dashboard_screen.dart';
import 'package:au_connect/screens/payments_screen.dart';
import 'package:au_connect/screens/language_selection_screen.dart';
import 'package:au_connect/screens/application_progress_screen.dart';
import 'package:au_connect/screens/payment_history_screen.dart';
import 'package:au_connect/screens/profile_settings_screen.dart';
import 'package:au_connect/screens/visa_application_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale');

  debugPrint('Supabase initialized successfully');
  runApp(AuConnectApp(
    initialLocale: savedLocale != null ? Locale(savedLocale) : null,
    showLanguageSelection: savedLocale == null,
  ));
}

/// Public interface so [LanguageSelectionScreen] can call [setLocale]
/// without referencing the private state class.
abstract class AppLocaleController {
  void setLocale(Locale locale);
}

class AuConnectApp extends StatefulWidget {
  final Locale? initialLocale;
  final bool showLanguageSelection;

  const AuConnectApp({
    super.key,
    this.initialLocale,
    this.showLanguageSelection = false,
  });

  /// Access the app locale controller from any widget to call [setLocale].
  static AppLocaleController? of(BuildContext context) =>
      context.findAncestorStateOfType<_AuConnectAppState>();

  @override
  State<AuConnectApp> createState() => _AuConnectAppState();
}

class _AuConnectAppState extends State<AuConnectApp>
    implements AppLocaleController {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale ?? const Locale('en');
  }

  @override
  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AU Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('pt'),
        Locale('sw'),
      ],
      initialRoute: widget.showLanguageSelection ? '/language' : '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/language': (context) => const LanguageSelectionScreen(),
        '/student_sign_in': (context) => const StudentSignInScreen(),
        '/applicant_sign_in': (context) => const ApplicantSignInScreen(),
        '/admin_sign_in': (context) => const AdminSignInScreen(),
        '/applicant_sign_up': (context) => const ApplicantSignUpScreen(),
        '/applicant_type_selection': (context) =>
            const ApplicantTypeSelectionScreen(),
        // Applicant dashboards
        '/chatbot_dashboard': (context) => const ChatbotDashboardScreen(),
        '/onboarding_dashboard': (context) =>
            const OnboardingDashboardScreen(),
        '/masters_dashboard': (context) => const MastersDashboardScreen(),
        '/international_dashboard': (context) =>
            const InternationalDashboardScreen(),
        '/returning_dashboard': (context) =>
            const ReturningStudentDashboardScreen(),
        // Application progress, payments & settings
        '/application_progress': (context) => const ApplicationProgressScreen(),
        '/payments': (context) => const PaymentsScreen(),
        '/payment_history': (context) => const PaymentHistoryScreen(),
        '/profile_settings': (context) => const ProfileSettingsScreen(),
        // Student & Admin dashboards
        '/student_dashboard': (context) => const StudentDashboardScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        // Settings
        '/language_change': (context) =>
            const LanguageSelectionScreen(isChange: true),
        '/visa_application': (context) => const VisaApplicationScreen(),
      },
    );
  }
}
