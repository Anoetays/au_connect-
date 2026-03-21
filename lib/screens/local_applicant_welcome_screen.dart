import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

class LocalApplicantWelcomeScreen extends StatefulWidget {
  const LocalApplicantWelcomeScreen({super.key});

  @override
  State<LocalApplicantWelcomeScreen> createState() =>
      _LocalApplicantWelcomeScreenState();
}

class _LocalApplicantWelcomeScreenState
    extends State<LocalApplicantWelcomeScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('AU Connect'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                // Welcome Header
                Text(
                  'Welcome to Africa University!',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Let's get you started on your academic journey.",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Main Content
                if (isMobile) ...[
                  // Mobile Layout
                  _buildHeroCard(context, theme, colorScheme),
                  const SizedBox(height: 32),
                  _buildInfoCardsGrid(context, theme, colorScheme),
                  const SizedBox(height: 32),
                  _buildOnboardingSteps(context, theme, colorScheme),
                  const SizedBox(height: 32),
                  _buildTipsSection(context, theme),
                ] else ...[
                  // Desktop Layout
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildHeroCard(context, theme, colorScheme),
                            const SizedBox(height: 32),
                            _buildInfoCardsGrid(context, theme, colorScheme),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          children: [
                            _buildOnboardingSteps(context, theme, colorScheme),
                            const SizedBox(height: 32),
                            _buildTipsSection(context, theme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFDC003),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'Priority Action',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start Your Application',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Begin your application process in a few simple steps. We\'ve streamlined the journey for your success.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/applicant_dashboard');
            },
            icon: const Icon(Symbols.arrow_forward),
            label: const Text('Get Started'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDC003),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardsGrid(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        _buildInfoCard(
          context,
          theme,
          colorScheme,
          icon: Symbols.school,
          title: 'Programs Offered',
          description: 'Explore available degrees and find what suits you best.',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Browse Programs')),
            );
          },
        ),
        _buildInfoCard(
          context,
          theme,
          colorScheme,
          icon: Symbols.verified,
          title: 'Admission Requirements',
          description: 'Understand exactly what you need before you start applying.',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('View Requirements')),
            );
          },
        ),
        _buildInfoCard(
          context,
          theme,
          colorScheme,
          icon: Symbols.support_agent,
          title: 'Support / Help',
          description: 'Need assistance? Our team is here to help you anytime.',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact Support')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Learn More',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF785900),
                  ),
                ),
                Icon(Symbols.chevron_right,
                    size: 16, color: const Color(0xFF785900)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingSteps(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final steps = [
      ('person_add', '1. Create Profile', 'Setup your secure account', 0),
      ('badge', '2. Add Personal Information', 'Identity and contact details', 1),
      ('upload_file', '3. Upload Required Documents', 'Transcripts and IDs', 2),
      ('list_alt', '4. Select Program', 'Choose your major', 3),
      ('send', '5. Submit Application', 'Final review and submission', 4),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Onboarding Steps',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${((_currentStep / steps.length) * 100).toStringAsFixed(0)}% COMPLETE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(steps.length, (index) {
            final isCompleted = index < _currentStep;
            final isCurrent = index == _currentStep;

            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                children: [
                  // Progress indicator
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent || isCompleted
                          ? AppTheme.primary
                          : Colors.white,
                      border: Border.all(
                        color: isCurrent || isCompleted
                            ? AppTheme.primary
                            : colorScheme.outline.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getIconData(steps[index].$1),
                      color: isCurrent || isCompleted ? Colors.white : colorScheme.outline,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[index].$2,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCurrent || isCompleted
                                ? AppTheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          steps[index].$3,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.lightbulb,
                color: const Color(0xFFFDC003),
              ),
              const SizedBox(width: 12),
              Text(
                'Before You Begin',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            'Prepare your scanned academic documents (PDF format preferred).',
            'Ensure you have a stable internet connection.',
            'Use a valid personal email address for all communications.',
          ].map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Symbols.check_circle,
                    color: const Color(0xFFFDC003),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getIconData(String symbol) {
    switch (symbol) {
      case 'person_add':
        return Symbols.person_add;
      case 'badge':
        return Symbols.badge;
      case 'upload_file':
        return Symbols.upload_file;
      case 'list_alt':
        return Symbols.list_alt;
      case 'send':
        return Symbols.send;
      default:
        return Symbols.done;
    }
  }
}
