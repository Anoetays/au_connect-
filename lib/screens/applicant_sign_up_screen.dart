import 'package:flutter/material.dart';
import 'package:au_connect/l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/auth_service.dart';
import 'package:au_connect/services/supabase_service.dart';

class ApplicantSignUpScreen extends StatefulWidget {
  const ApplicantSignUpScreen({super.key});

  @override
  State<ApplicantSignUpScreen> createState() => _ApplicantSignUpScreenState();
}

class _ApplicantSignUpScreenState extends State<ApplicantSignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  double _passwordStrength = 0.0;
  String _strengthLabel = 'Weak';
  Color _strengthColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  static final _usernameRe = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  Future<void> _signUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final confirmEmail = _confirmEmailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || confirmEmail.isEmpty ||
        password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (!_usernameRe.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Username must be 3–20 characters and contain only letters, numbers, or underscores.'),
        ),
      );
      return;
    }

    if (email != confirmEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emails do not match')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password should be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUpWithEmailAndPassword(email, password);
      // Save username to the profiles table
      try {
        await SupabaseService.upsertProfile({
          'username': username,
          'email': email,
        });
      } catch (_) {
        // Non-fatal — profile can be set later
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created! Welcome, $username.')),
        );
        Navigator.pushReplacementNamed(context, '/applicant_type_selection');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _checkPasswordStrength() {
    // Simple mock strength checker for UI
    final password = _passwordController.text;
    double strength = 0;
    String label = 'Weak';
    Color color = AppTheme.primary; // Start red
    
    if (password.isNotEmpty) {
      strength = 0.25;
      if (password.length >= 8) {
        strength = 0.5;
        label = 'Fair';
        color = Colors.orange;
        if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[0-9]'))) {
          strength = 0.75;
          label = 'Strong';
          color = AppTheme.statusApproved; // green-500
          if (password.contains(RegExp(r'[!@#\$&*~]'))) {
            strength = 1.0;
             label = 'Very Strong';
          }
        }
      }
    } else {
      color = Colors.grey[300]!;
    }

    setState(() {
      _passwordStrength = strength;
      _strengthLabel = label;
      _strengthColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: Icon(Symbols.arrow_back, color: isDark ? AppTheme.textLight : AppTheme.textSecondary), // slate-600
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AU Connect',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textLight.withValues(alpha: 0.5) : AppTheme.border, // Very faint in the design
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 32),
                _buildFormCard(isDark, l10n),
                const SizedBox(height: 32),
                _buildFooterLinks(isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Your Applicant Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: isDark ? AppTheme.textLight : AppTheme.textPrimary, // slate-900
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Create an account to start your Africa University Application',
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: isDark ? Colors.grey[400] : AppTheme.textMuted, // slate-500
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.textPrimary : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'e.g. tendai_m  (3\u201320 chars, letters/numbers/_)',
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _emailController,
            label: l10n.email,
            hint: 'e.g. name@example.com',
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _confirmEmailController,
            label: l10n.confirmEmail,
            hint: 'Repeat your email',
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
             label: l10n.password,
             hint: 'At least 8 characters',
             isDark: isDark,
             isPassword: true,
             controller: _passwordController,
          ),
          const SizedBox(height: 12),
          _buildPasswordStrength(),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _confirmPasswordController,
            label: l10n.confirmPassword,
            hint: 'Repeat your password',
            isDark: isDark,
            isPassword: true,
          ),
          const SizedBox(height: 32),
          
          ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCrimson, // Muted red like design
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Less rounded than sign in
              ),
              elevation: 0,
            ),
            child: _isLoading 
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label, 
    required String hint, 
    required bool isDark,
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.border : AppTheme.textSecondary, // slate-700
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white : AppTheme.textSecondary),
          decoration: InputDecoration(
             hintText: hint,
             hintStyle: TextStyle(color: isDark ? Colors.grey[600] : AppTheme.textMuted), // slate-400
             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             filled: true,
             fillColor: isDark ? AppTheme.textPrimary : AppTheme.surface,
             border: OutlineInputBorder(
               borderRadius: BorderRadius.circular(8),
               borderSide: BorderSide(color: isDark ? AppTheme.textSecondary : AppTheme.border),
             ),
             enabledBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(8),
               borderSide: BorderSide(color: isDark ? AppTheme.textSecondary : AppTheme.border), // slate-100
             ),
             focusedBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(8),
               borderSide: const BorderSide(color: AppTheme.primary),
             ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrength() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final active = index < (_passwordStrength * 4).round();
            final color = active ? _strengthColor : Colors.grey[200]!;
            
            return Expanded(
              child: Container(
                 margin: EdgeInsets.only(right: index < 3 ? 4.0 : 0),
                 height: 4,
                 decoration: BoxDecoration(
                   color: color,
                   borderRadius: BorderRadius.circular(2),
                 ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Text(
              'Strength: ',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            Text(
               _passwordStrength == 0 ? '' : _strengthLabel,
               style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _strengthColor),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildFooterLinks(bool isDark) {
    return Column(
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : AppTheme.textMuted,
                  fontSize: 14,
                ),
              ),
              InkWell(
                onTap: () {
                   Navigator.pop(context); // Go back to sign in
                },
                 child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
           ],
        ),
        const SizedBox(height: 32),
        Text(
          '© 2026 AU Connect Applicant Portal',
          style: TextStyle(
             color: isDark ? Colors.grey[500] : AppTheme.textMuted,
             fontSize: 12,
          ),
        ),
      ],
    );
  }
}
