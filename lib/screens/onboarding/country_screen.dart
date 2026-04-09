import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:au_connect/main.dart';
import 'package:au_connect/widgets/country_chip.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

// ── Country → suggested locale codes ─────────────────────────────────────────
// Keys are the internal country codes stored in OnboardingState.country.
// For freetext ("Other") entries the lookup falls back to _displayNameLangMap.
// Languages are ordered by priority (first = pre-selected default).
// Only locales supported by the app are listed: ar, en, fr, pt, sw.
// Amharic (Ethiopia) is not yet supported so Ethiopia defaults to English.
const Map<String, List<String>> _codeLangMap = {
  'Zimbabwe':    ['en'],
  'Zambia':      ['en'],
  'DRCongo':     ['fr', 'en'],
  'Kenya':       ['sw', 'en'],
  'Nigeria':     ['en'],
  'SouthAfrica': ['en'],
  'Tanzania':    ['sw', 'en'],
  'Ghana':       ['en'],
  'Ethiopia':    ['en'],
  'Mozambique':  ['pt', 'en'],
};

// Fallback map for freetext country names entered via the "Other" dialog.
const Map<String, List<String>> _displayNameLangMap = {
  'Democratic Republic of Congo': ['fr', 'en'],
  'DR Congo':                     ['fr', 'en'],
  'Republic of Congo':            ['fr', 'en'],
  'Angola':                       ['pt', 'en'],
  'Uganda':                       ['en', 'sw'],
  'Rwanda':                       ['fr', 'en', 'sw'],
  'Burundi':                      ['fr', 'sw', 'en'],
  'Cameroon':                     ['fr', 'en'],
  'Senegal':                      ['fr', 'en'],
  'Ivory Coast':                  ['fr', 'en'],
  "Côte d'Ivoire":                ['fr', 'en'],
  'Egypt':                        ['ar', 'en'],
  'Morocco':                      ['ar', 'fr', 'en'],
  'Tunisia':                      ['ar', 'fr', 'en'],
  'Malawi':                       ['en'],
  'South Africa':                 ['en'],
  'Botswana':                     ['en'],
  'Namibia':                      ['en'],
  'Madagascar':                   ['fr', 'en'],
};

List<String> _langsForCountry(String countryCode) =>
    _codeLangMap[countryCode] ??
    _displayNameLangMap[countryCode] ??
    ['en'];

// ── Language display metadata ─────────────────────────────────────────────────
const _langMeta = <String, (String flag, String label)>{
  'ar': ('🇸🇦', 'العربية'),
  'en': ('🇬🇧', 'English'),
  'fr': ('🇫🇷', 'Français'),
  'pt': ('🇵🇹', 'Português'),
  'sw': ('🇹🇿', 'Kiswahili'),
};

// ── Screen ────────────────────────────────────────────────────────────────────
class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  static const _countries = [
    ('🇿🇼', 'Zimbabwe',     'Zimbabwe'),
    ('🇿🇲', 'Zambia',       'Zambia'),
    ('🇨🇩', 'DR Congo',     'DRCongo'),
    ('🇰🇪', 'Kenya',        'Kenya'),
    ('🇳🇬', 'Nigeria',      'Nigeria'),
    ('🇿🇦', 'South Africa', 'SouthAfrica'),
    ('🇹🇿', 'Tanzania',     'Tanzania'),
    ('🇬🇭', 'Ghana',        'Ghana'),
    ('🇪🇹', 'Ethiopia',     'Ethiopia'),
    ('🇲🇿', 'Mozambique',   'Mozambique'),
  ];

  List<String> _suggestedLangs = [];
  String? _selectedLang;

  void _onCountryPicked(String countryCode) {
    final langs = _langsForCountry(countryCode);
    setState(() {
      _suggestedLangs = langs;
      _selectedLang = langs.first;
    });
    if (langs.length == 1) {
      // Single language — apply silently, no UI shown
      _applyLocale(langs.first);
    }
  }

  Future<void> _applyLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
    if (!mounted) return;
    AuConnectApp.of(context)?.setLocale(Locale(code));
  }

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
          CrimsonHeader(
            icon: '🌍',
            tag: 'About You',
            title: 'Which country are you from?',
            subtitle: 'Tap your country below',
            onBack: c.back,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      itemCount: _countries.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (_, i) {
                        final item = _countries[i];
                        return CountryChip(
                          flag: item.$1,
                          name: item.$2,
                          isSelected: c.state.country == item.$3,
                          onTap: () {
                            c.state.country = item.$3;
                            c.refresh();
                            _onCountryPicked(item.$3);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // "Other African country" entry
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
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, ctrl.text.trim()),
                                child: const Text('Save'),
                              ),
                            ],
                          );
                        },
                      );
                      if (val != null && val.isNotEmpty) {
                        c.state.country = val;
                        c.refresh();
                        _onCountryPicked(val);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorder, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '🌐  Other African country...',
                        style: TextStyle(color: kTextLight),
                      ),
                    ),
                  ),
                  // Language suggestion chips — shown only for 2+ languages
                  if (_suggestedLangs.length > 1) ...[
                    const SizedBox(height: 20),
                    _LanguageSuggestion(
                      languages: _suggestedLangs,
                      selected: _selectedLang,
                      onSelect: (code) {
                        setState(() => _selectedLang = code);
                        _applyLocale(code);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language suggestion widget ────────────────────────────────────────────────

class _LanguageSuggestion extends StatelessWidget {
  final List<String> languages;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _LanguageSuggestion({
    required this.languages,
    required this.selected,
    required this.onSelect,
  });

  static const _crimson = Color(0xFFB22234);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select your preferred language:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: kTextLight,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: languages.map((code) {
            final meta = _langMeta[code] ?? ('🌐', code);
            final isSelected = selected == code;
            return _LangChip(
              flag: meta.$1,
              label: meta.$2,
              isSelected: isSelected,
              onTap: () => onSelect(code),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangChip({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  static const _crimson = Color(0xFFB22234);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? _crimson : Colors.white,
          border: Border.all(
            color: isSelected ? _crimson : const Color(0xFFCCCCCC),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _crimson.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
