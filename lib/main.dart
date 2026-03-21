import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:au_connect/config/supabase_config.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/screens/welcome_screen.dart';
import 'package:au_connect/screens/admin_sign_in_screen.dart';
import 'package:au_connect/screens/applicant_sign_in_screen.dart';
import 'package:au_connect/screens/student_sign_in_screen.dart';
import 'package:au_connect/screens/applicant_dashboard_screen.dart';
import 'package:au_connect/screens/transfer_applicant_dashboard_screen.dart';
import 'package:au_connect/screens/applicant_sign_up_screen.dart';
import 'package:au_connect/screens/applicant_type_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  debugPrint('Supabase initialized successfully');
  runApp(const AuConnectApp());
}

class AuConnectApp extends StatelessWidget {
  const AuConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AU Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Force light theme for white appearance
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/student_sign_in': (context) => const StudentSignInScreen(),
        '/applicant_sign_in': (context) => const ApplicantSignInScreen(),
        '/admin_sign_in': (context) => const AdminSignInScreen(),
        '/applicant_dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final type = args is String ? args : 'First-Year';
          if (type.toLowerCase() == 'transfer') {
            return const TransferApplicantDashboardScreen();
          }
          return ApplicantDashboardScreen(applicantType: type);
        },
        '/applicant_sign_up': (context) => const ApplicantSignUpScreen(),
        '/applicant_type_selection': (context) => const ApplicantTypeSelectionScreen(),
      },
    );
  }
}
