import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

class AdminSignInScreen extends StatefulWidget {
  const AdminSignInScreen({super.key});

  @override
  State<AdminSignInScreen> createState() => _AdminSignInScreenState();
}

class _AdminSignInScreenState extends State<AdminSignInScreen> {
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context, isDark),
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTitle(isDark),
                              const SizedBox(height: 32),
                              _buildForm(isDark),
                              const SizedBox(height: 32),
                              _buildFooter(isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildBottomLinks(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
           bottom: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
         ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
               Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Symbols.admin_panel_settings,
                    color: Colors.white,
                    size: 24,
                    fill: 0,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AU Connect',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                  ),
                ),
            ],
          ),
          IconButton(
             onPressed: () => Navigator.pop(context), // Let's use as back button since no help action
             tooltip: 'Back',
             icon: Icon(
                Symbols.help_outline,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
             )
          )
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Sign-In',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            height: 1.1,
            color: isDark ? AppTheme.textLight : AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
         Text(
          'Access the AU Connect administration dashboard',
          style: TextStyle(
            fontSize: 16,
             color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Admin Number or Email
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Admin Number or Email',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        TextField(
           decoration: InputDecoration(
              hintText: 'e.g. admin@auconnect.com',
              prefixIcon: const Icon(Symbols.person, size: 20),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                   color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                   color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
        ),
        
        const SizedBox(height: 24),

        // Password
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Password',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {},
                 style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Forgot?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        TextField(
          obscureText: _obscurePassword,
           decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Symbols.lock, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Symbols.visibility : Symbols.visibility_off, size: 20),
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
               filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                   color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                   color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
        ),

        const SizedBox(height: 24),
        
        // Remember me
         Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: AppTheme.primary,
                 side: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[400]!),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Keep me signed in for 30 days',
              style: TextStyle(
                fontSize: 14,
                 color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8, 
              shadowColor: AppTheme.primary.withOpacity(0.25),
            ),
             child: const Text('Sign In to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
  
  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 32),
      decoration: BoxDecoration(
         border: Border(
           top: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
         ),
      ),
      child: Text.rich(
        TextSpan(
          text: 'Need technical support? ',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[500]
          ),
          children: const [
            TextSpan(
              text: 'Contact IT Helpdesk',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomLinks(bool isDark) {
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.2,
      color: Colors.grey[400],
    );
    final dot = Container(
      width: 4, height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        shape: BoxShape.circle,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('SECURITY POLICY', style: style),
        dot,
        Text('PRIVACY NOTICE', style: style),
         dot,
        Text('TERMS OF USE', style: style),
      ],
    );
  }
}
