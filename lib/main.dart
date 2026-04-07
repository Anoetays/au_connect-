import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:au_connect/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:au_connect/config/supabase_config.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/screens/welcome_screen.dart';
import 'package:au_connect/screens/admin_sign_in_screen.dart';
import 'package:au_connect/screens/applicant_sign_in_screen.dart';
import 'package:au_connect/screens/student_sign_in_screen.dart';
import 'package:au_connect/screens/onboarding/onboarding_flow_screen.dart';
import 'package:au_connect/screens/applicant_type_selection_screen.dart';
import 'package:au_connect/screens/login_screen.dart';
import 'package:au_connect/screens/dashboard_screen.dart';
import 'package:au_connect/screens/application_screen.dart';
import 'package:au_connect/screens/admin_health_check_screen.dart';
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
import 'package:au_connect/screens/visa/visa_guidance_screen.dart';
import 'package:au_connect/screens/postgrad_masters_flows.dart';
import 'package:google_fonts/google_fonts.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Catch all Flutter framework errors so a crash shows a red error screen
  // instead of a silent white screen.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    debugPrint('Supabase initialized successfully');
  } catch (e, st) {
    debugPrint('Supabase init failed: $e\n$st');
  }

  String? savedLocale;
  try {
    final prefs = await SharedPreferences.getInstance();
    savedLocale = prefs.getString('locale');
  } catch (e) {
    debugPrint('SharedPreferences failed: $e');
  }

  runZonedGuarded(
    () => runApp(AuConnectApp(
      initialLocale: savedLocale != null ? Locale(savedLocale) : null,
      showLanguageSelection: savedLocale == null,
    )),
    (error, stack) => debugPrint('Unhandled error: $error\n$stack'),
  );
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
  late String _sessionUserId;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale ?? const Locale('en');
    _sessionUserId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
    debugPrint('Current user ID: $_sessionUserId');
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
      final nextUserId = authState.session?.user.id ?? 'anon';
      debugPrint('Current user ID: $nextUserId');
      if (!mounted) return;
      if (_sessionUserId != nextUserId) {
        setState(() => _sessionUserId = nextUserId);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
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
      initialRoute: '/applicant_sign_up',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/application': (context) => const ApplicationScreen(),
        '/admin_health_check': (context) => const AdminHealthCheckScreen(),
        '/language': (context) => const LanguageSelectionScreen(),
        '/student_sign_in': (context) => const StudentSignInScreen(),
        '/applicant_sign_in': (context) => const ApplicantSignInScreen(),
        '/admin_sign_in': (context) => const AdminSignInScreen(),
        '/applicant_sign_up': (context) => const OnboardingFlowScreen(),
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
        '/visa_guidance': (context) => const VisaGuidanceScreen(),
        '/postgrad_welcome': (context) => const PostgradWelcomeScreen(),
        '/masters_welcome': (context) => const MastersWelcomeScreen(),
      },
    ),
  );
  }
}
