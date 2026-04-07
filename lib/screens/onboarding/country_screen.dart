import 'package:flutter/material.dart';
import 'package:au_connect/widgets/country_chip.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  final countries = const [
    ('🇿🇼', 'Zimbabwe', 'Zimbabwe'),
    ('🇿🇲', 'Zambia', 'Zambia'),
    ('🇨🇩', 'DR Congo', 'DRCongo'),
    ('🇰🇪', 'Kenya', 'Kenya'),
    ('🇳🇬', 'Nigeria', 'Nigeria'),
    ('🇿🇦', 'South Africa', 'SouthAfrica'),
    ('🇹🇿', 'Tanzania', 'Tanzania'),
    ('🇬🇭', 'Ghana', 'Ghana'),
    ('🇪🇹', 'Ethiopia', 'Ethiopia'),
    ('🇲🇿', 'Mozambique', 'Mozambique'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      footer: PrimaryButton(
        label: 'Continue →',
        isDisabled: c.state.country.isEmpty,
        onTap: c.state.country.isEmpty ? null : c.goFromCountry,
      ),
      child: Column(
        children: [
          CrimsonHeader(icon: '🌍', tag: 'About You', title: 'Which country are you from?', subtitle: 'Tap your country below', onBack: c.back),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      itemCount: countries.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                      itemBuilder: (_, i) {
                        final item = countries[i];
                        return CountryChip(
                          flag: item.$1,
                          name: item.$2,
                          isSelected: c.state.country == item.$3,
                          onTap: () {
                            c.state.country = item.$3;
                            c.refresh();
                          },
                        );
                      },
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final val = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          final ctrl = TextEditingController();
                          return AlertDialog(
                            title: const Text('Enter your country name'),
                            content: TextField(controller: ctrl),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
                            ],
                          );
                        },
                      );
                      if (val != null && val.isNotEmpty) {
                        c.state.country = val;
                        c.refresh();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorder, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('🌐  Other African country...', style: TextStyle(color: kTextLight)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
