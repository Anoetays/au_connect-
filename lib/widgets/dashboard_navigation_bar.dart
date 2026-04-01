import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';

class DashboardNavigationBar extends StatefulWidget {
  final String currentPage;
  final void Function(String menuKey) onItemSelected;

  const DashboardNavigationBar({super.key, required this.currentPage, required this.onItemSelected});

  @override
  State<DashboardNavigationBar> createState() => _DashboardNavigationBarState();
}

class _DashboardNavigationBarState extends State<DashboardNavigationBar> {
  String selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo/Title on the left
                Text(
                  'AU Connect',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                ),
                // Navigation items on the right
                if (isMobile)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLanguageButton(context),
                      const SizedBox(width: 12),
                      _buildMobileMenu(context),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildLanguageButton(context),
                      const SizedBox(width: 20),
                      ..._buildNavItems(context),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: selectedLanguage,
        icon: const Icon(Icons.language, size: 18),
        iconSize: 20,
        underline: const SizedBox(),
        items: ['English', 'French', 'Portuguese', 'Swahili'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              selectedLanguage = newValue;
            });
          }
        },
      ),
    );
  }

  Widget _buildMobileMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu),
      onSelected: widget.onItemSelected,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Dashboard', child: Text('Dashboard')),
        const PopupMenuItem(value: 'Application Progress', child: Text('Application Progress')),
        const PopupMenuItem(value: 'Payments', child: Text('Payments')),
        const PopupMenuItem(value: 'Financial Assistance', child: Text('Financial Assistance')),
      ],
    );
  }

  List<Widget> _buildNavItems(BuildContext context) {
    final items = [
      {'label': 'Dashboard', 'icon': Icons.dashboard},
      {'label': 'Application Progress', 'icon': Icons.timeline},
      {'label': 'Payments', 'icon': Icons.payment},
      {'label': 'Financial Assistance', 'icon': Icons.account_balance_wallet},
    ];

    return items.map((item) {
      final isActive = item['label'] == widget.currentPage;

      return InkWell(
        onTap: () => widget.onItemSelected(item['label'] as String),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item['icon'] as IconData,
                color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                item['label'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
