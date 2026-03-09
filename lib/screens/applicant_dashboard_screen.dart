import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

class ApplicantDashboardScreen extends StatelessWidget {
  const ApplicantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF9FAFB), // Very light gray background
      appBar: AppBar(
         backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF9FAFB),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Symbols.menu, color: AppTheme.primary),
              onPressed: () {},
            ),
          ),
        ),
        title: Text(
          'Africa University App',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textLight : AppTheme.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
             child: CircleAvatar(
               backgroundColor: Colors.grey[300],
               radius: 18,
               child: const Icon(Symbols.person, color: Colors.grey),
               // In a real app this would be an image
             ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
               Text(
                "Let's start your application.",
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : const Color(0xFF475569), // slate-600
                ),
              ),
              const SizedBox(height: 24),
              
              // Info Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF0F0), // Very light red/pink hue
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Your Application Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select the application category that best describes your academic situation to ensure you get the right requirements.',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

               // Application Types List
              _ApplicationTypeCard(
                icon: Symbols.school,
                title: 'First-Year Application',
                description: 'High school seniors applying to university for the first time following the traditional path.',
                onTap: () {},
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              
              _ApplicationTypeCard(
                icon: Symbols.public,
                title: 'International Applicants',
                description: 'First-year students with citizenship outside Zimbabwe applying to study at Africa University.',
                onTap: () {},
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              
              _ApplicationTypeCard(
                icon: Symbols.transfer_within_a_station,
                title: 'Transfer Applicants',
                description: 'Students who are currently enrolled at another college or university and want to transfer to Africa University.',
                onTap: () {},
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              
              _ApplicationTypeCard(
                icon: Symbols.history_edu,
                title: 'Resumed Undergraduate Students',
                description: 'Students returning to higher education after an interruption or delay in their studies.',
                onTap: () {},
                isDark: isDark,
              ),

              const SizedBox(height: 32),

               // Help Support Banner
              Container(
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   color: isDark ? const Color(0xFF1E293B) : Colors.white,
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(
                       color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), 
                       style: BorderStyle.solid,
                   ),
                 ),
                 // Custom dashed border effect
                 child: Stack(
                   children: [
                      // Dashed border overlay could go here, for now solid is fine or we use a custom painter. 
                      // Using a simple row for content
                      Row(
                         children: [
                            Icon(Symbols.help, color: Colors.grey[400], size: 28),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Need help with your selection?',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Contact\nSupport', 
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.primary, 
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                )
                              ),
                            )
                         ],
                      )
                   ]
                 ),
              ),
              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
         color: isDark ? const Color(0xFF0F172A) : Colors.white,
         border: Border(
           top: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
         ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: isDark ? Colors.grey[500] : const Color(0xFF94A3B8), // slate-400
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Symbols.home),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.description),
            label: 'APPLICATIONS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.school),
            label: 'PROGRAMS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.person),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}

class _ApplicationTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isDark;

  const _ApplicationTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
         padding: const EdgeInsets.all(20),
         decoration: BoxDecoration(
           color: isDark ? const Color(0xFF1E293B) : Colors.white,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), // slate-100
           ),
           boxShadow: [
             if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
           ],
         ),
         child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                 width: 48,
                 height: 48,
                 decoration: BoxDecoration(
                   color: AppTheme.primary,
                   borderRadius: BorderRadius.circular(12),
                   boxShadow: [
                     BoxShadow(
                       color: AppTheme.primary.withOpacity(0.3),
                       blurRadius: 12,
                       offset: const Offset(0, 4),
                     )
                   ]
                 ),
                 child: Icon(icon, color: Colors.white, size: 24, fill: 1),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.textLight : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B), // slate-500
                        height: 1.4,
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Symbols.chevron_right, 
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ],
         ),
      ),
    );
  }
}
