import 'package:flutter/material.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/progress_bar.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class ResidencyCheckScreen extends StatefulWidget {
  const ResidencyCheckScreen({super.key});

  @override
  State<ResidencyCheckScreen> createState() => _ResidencyCheckScreenState();
}

class _ResidencyCheckScreenState extends State<ResidencyCheckScreen> {
  bool _isSaving = false;

  Future<void> _onContinue(BuildContext context) async {
    final c = OnboardingScope.of(context);
    if (c.state.residesInZimbabwe == null) return;

    setState(() => _isSaving = true);
    try {
      await c.saveResidency();
    } catch (_) {
      // Non-fatal — continue regardless
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;
    // Both paths continue into AccommodationScreen (index 19)
    c.goTo(19);
  }

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    final selected = c.state.residesInZimbabwe;

    return OnboardingShell(
      footer: _isSaving
          ? const Center(child: CircularProgressIndicator(color: kCrimson))
          : PrimaryButton(
              label: 'Continue →',
              isDisabled: selected == null,
              onTap: selected == null ? null : () => _onContinue(context),
            ),
      child: Column(
        children: [
          // ── Crimson header ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 54, 24, 28),
            decoration: const BoxDecoration(
              color: kCrimson,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -6,
                  left: -4,
                  child: IconButton(
                    onPressed: c.back,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('🏠', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'APPLICATION • STEP 5B',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.4,
                          color: Color(0x99FFFFFF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Residency Check',
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'This helps us tailor your application experience and visa requirements.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xCCFFFFFF),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const ProgressBar(step: 5, total: 8, percent: 60),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── Question card ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: kCrimsonMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🏠', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Do you currently reside in Zimbabwe?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select the option that best describes your current place of residence.',
                        style: TextStyle(
                          fontSize: 13,
                          color: kTextMid,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Option A: Yes ──────────────────────────
                      _OptionTile(
                        emoji: '🇿🇼',
                        label: 'Yes, I live in Zimbabwe',
                        subtitle: 'I am a local or resident applicant',
                        isSelected: selected == true,
                        selectedColor: kCrimson,
                        selectedBg: kCrimsonMuted,
                        onTap: () {
                          c.state.residesInZimbabwe = true;
                          c.state.applicantType = 'local';
                          c.refresh();
                        },
                      ),
                      const SizedBox(height: 12),

                      // ── Option B: No ───────────────────────────
                      _OptionTile(
                        emoji: '✈️',
                        label: 'No, I reside outside Zimbabwe',
                        subtitle: 'I am an international applicant',
                        isSelected: selected == false,
                        selectedColor: const Color(0xFFC9952A),
                        selectedBg: const Color(0xFFFDF5E6),
                        onTap: () {
                          c.state.residesInZimbabwe = false;
                          c.state.applicantType = 'international';
                          c.refresh();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Info note ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E7),
                    border: Border.all(color: const Color(0xFFF0D080)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💡', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'International applicants not residing in Zimbabwe will receive visa and study permit guidance after completing their application. This is required for all non-residents.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A5C00),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable option tile ─────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final bool isSelected;
  final Color selectedColor;
  final Color selectedBg;
  final VoidCallback onTap;

  const _OptionTile({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.selectedColor,
    required this.selectedBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : kBorder,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Radio dot
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? selectedColor : kBorder,
                  width: 2,
                ),
                color: isSelected ? selectedColor : Colors.white,
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(Icons.circle, size: 9, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? selectedColor : kTextDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: kTextLight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
