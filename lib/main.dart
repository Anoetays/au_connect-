import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:au_connect/firebase_options.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/screens/welcome_screen.dart';
import 'package:au_connect/screens/admin_sign_in_screen.dart';
import 'package:au_connect/screens/applicant_sign_in_screen.dart';
import 'package:au_connect/screens/student_sign_in_screen.dart';
import 'package:au_connect/screens/applicant_dashboard_screen.dart';
import 'package:au_connect/screens/applicant_sign_up_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Firebase initialized: ${Firebase.app().name}');
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
      // Default theme mode can be controlled, here we let system dictate
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/student_sign_in': (context) => const StudentSignInScreen(),
        '/applicant_sign_in': (context) => const ApplicantSignInScreen(),
        '/admin_sign_in': (context) => const AdminSignInScreen(),
        '/applicant_dashboard': (context) => const ApplicantDashboardScreen(),
        '/applicant_sign_up': (context) => const ApplicantSignUpScreen(),
      },
    );
  }
}
