import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildTopNavigation(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildWelcomeHeader(context, isDark),
                        _buildRoleCards(context, isDark),
                        const SizedBox(height: 120), // Space for footer
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Footer Visual pinned to bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 128, // h-32
            child: _buildFooterVisual(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavigation(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          Text(
            'AU Connect',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.015,
              color: isDark ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          SizedBox(
            width: 40,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Symbols.info,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Symbols.school,
              color: AppTheme.primary,
              size: 36,
              fill: 0, // Outlined
            ),
          ),
          Text(
            'Welcome to AU Connect',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1,
              letterSpacing: -0.5,
              color: isDark ? AppTheme.textLight : AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'The central hub for your university journey. Please select your role to continue.',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCards(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0),
      child: Column(
        children: [
          _RoleCard(
            title: 'Student',
            description: 'Access courses, view grades, and get the latest campus updates.',
            icon: Symbols.person,
            isPrimaryStyle: true,
            onTap: () => Navigator.pushNamed(context, '/student_sign_in'),
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _RoleCard(
            title: 'Applicant',
            description: 'Track your application, submit documents, and check requirements.',
            icon: Symbols.description,
            isPrimaryStyle: false,
            onTap: () => Navigator.pushNamed(context, '/applicant_sign_in'),
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _RoleCard(
            title: 'Admin',
            description: 'Manage campus systems, verify records, and oversee operations.',
            icon: Symbols.admin_panel_settings,
            isPrimaryStyle: false,
            onTap: () => Navigator.pushNamed(context, '/admin_sign_in'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterVisual(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          // Abstract shapes
          Positioned(
            bottom: -50,
            left: -50,
            right: -50,
             child: Transform.rotate(
               angle: 0.2, // ~12 degrees
               child: Container(
                 height: 200,
                 decoration: BoxDecoration(
                   color: AppTheme.primary.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(100),
                 ),
               ),
             ),
          ),
           Positioned(
            bottom: -80,
            left: -100,
            right: -100,
             child: Transform.rotate(
               angle: -0.2, // ~-12 degrees
               child: Container(
                 height: 250,
                 decoration: BoxDecoration(
                   color: AppTheme.primary.withOpacity(0.05),
                   borderRadius: BorderRadius.circular(100),
                 ),
               ),
             ),
          ),
          // Footer Text
          Align(
            alignment: Alignment.center,
            child: Text(
              '© 2024 AU Connect. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isPrimaryStyle;
  final VoidCallback onTap;
  final bool isDark;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isPrimaryStyle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white, // slate-800 or white
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), // slate-700 or slate-100
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPrimaryStyle ? AppTheme.primary : AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Symbols.chevron_right,
                color: isPrimaryStyle ? Colors.white : AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}