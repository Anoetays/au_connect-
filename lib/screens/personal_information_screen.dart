import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'document_upload_screen.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/providers/application_form_provider.dart';
import 'package:au_connect/services/supabase_client_provider.dart';

// ─── color tokens ─────────────────────────────────────────────────────────────
const _kCrimson      = AppTheme.primaryDark;
const _kCrimsonLight = AppTheme.primaryCrimson;
const _kInk          = AppTheme.textPrimary;
const _kInkMid       = AppTheme.textSecondary;
const _kParchment    = AppTheme.background;
const _kParchDeep    = Color(0xFFF0EBE1);
const _kBorder       = AppTheme.border;
const _kMuted        = AppTheme.textMuted;
const _kTintBg       = Color(0xFFF4F2FA);
const _kTintBd       = Color(0xFFE0DBF0);
const _kTintInput    = Color(0xFFD5CFE8);
const _kPlaceholder  = Color(0xFFC4BAB0);

// ─── Comprehensive dial-code map ──────────────────────────────────────────────
const _kDialCodes = <String, String>{
  'Afghanistan': '+93',
  'Albania': '+355',
  'Algeria': '+213',
  'Angola': '+244',
  'Argentina': '+54',
  'Armenia': '+374',
  'Australia': '+61',
  'Austria': '+43',
  'Azerbaijan': '+994',
  'Bahrain': '+973',
  'Bangladesh': '+880',
  'Belarus': '+375',
  'Belgium': '+32',
  'Benin': '+229',
  'Bolivia': '+591',
  'Bosnia and Herzegovina': '+387',
  'Botswana': '+267',
  'Brazil': '+55',
  'Bulgaria': '+359',
  'Burkina Faso': '+226',
  'Burundi': '+257',
  'Cambodia': '+855',
  'Cameroon': '+237',
  'Canada': '+1',
  'Cape Verde': '+238',
  'Central African Republic': '+236',
  'Chad': '+235',
  'Chile': '+56',
  'China': '+86',
  'Colombia': '+57',
  'Comoros': '+269',
  'Congo (DRC)': '+243',
  'Congo (Republic)': '+242',
  'Costa Rica': '+506',
  'Croatia': '+385',
  'Cuba': '+53',
  'Cyprus': '+357',
  'Czech Republic': '+420',
  'Denmark': '+45',
  'Djibouti': '+253',
  'Ecuador': '+593',
  'Egypt': '+20',
  'El Salvador': '+503',
  'Eritrea': '+291',
  'Estonia': '+372',
  'Ethiopia': '+251',
  'Finland': '+358',
  'France': '+33',
  'Gabon': '+241',
  'Gambia': '+220',
  'Georgia': '+995',
  'Germany': '+49',
  'Ghana': '+233',
  'Greece': '+30',
  'Guatemala': '+502',
  'Guinea': '+224',
  'Guinea-Bissau': '+245',
  'Honduras': '+504',
  'Hungary': '+36',
  'India': '+91',
  'Indonesia': '+62',
  'Iran': '+98',
  'Iraq': '+964',
  'Ireland': '+353',
  'Israel': '+972',
  'Italy': '+39',
  'Ivory Coast': '+225',
  'Jamaica': '+1876',
  'Japan': '+81',
  'Jordan': '+962',
  'Kazakhstan': '+7',
  'Kenya': '+254',
  'Kuwait': '+965',
  'Kyrgyzstan': '+996',
  'Laos': '+856',
  'Latvia': '+371',
  'Lebanon': '+961',
  'Lesotho': '+266',
  'Liberia': '+231',
  'Libya': '+218',
  'Lithuania': '+370',
  'Luxembourg': '+352',
  'Madagascar': '+261',
  'Malawi': '+265',
  'Malaysia': '+60',
  'Maldives': '+960',
  'Mali': '+223',
  'Mauritania': '+222',
  'Mauritius': '+230',
  'Mexico': '+52',
  'Moldova': '+373',
  'Mongolia': '+976',
  'Morocco': '+212',
  'Mozambique': '+258',
  'Myanmar': '+95',
  'Namibia': '+264',
  'Nepal': '+977',
  'Netherlands': '+31',
  'New Zealand': '+64',
  'Niger': '+227',
  'Nigeria': '+234',
  'North Korea': '+850',
  'Norway': '+47',
  'Oman': '+968',
  'Pakistan': '+92',
  'Palestine': '+970',
  'Panama': '+507',
  'Paraguay': '+595',
  'Peru': '+51',
  'Philippines': '+63',
  'Poland': '+48',
  'Portugal': '+351',
  'Qatar': '+974',
  'Romania': '+40',
  'Russia': '+7',
  'Rwanda': '+250',
  'Saudi Arabia': '+966',
  'Senegal': '+221',
  'Serbia': '+381',
  'Sierra Leone': '+232',
  'Singapore': '+65',
  'Slovakia': '+421',
  'Slovenia': '+386',
  'Somalia': '+252',
  'South Africa': '+27',
  'South Korea': '+82',
  'South Sudan': '+211',
  'Spain': '+34',
  'Sri Lanka': '+94',
  'Sudan': '+249',
  'Swaziland': '+268',
  'Sweden': '+46',
  'Switzerland': '+41',
  'Syria': '+963',
  'Taiwan': '+886',
  'Tajikistan': '+992',
  'Tanzania': '+255',
  'Thailand': '+66',
  'Togo': '+228',
  'Tunisia': '+216',
  'Turkey': '+90',
  'Turkmenistan': '+993',
  'Uganda': '+256',
  'Ukraine': '+380',
  'United Arab Emirates': '+971',
  'United Kingdom': '+44',
  'United States': '+1',
  'Uruguay': '+598',
  'Uzbekistan': '+998',
  'Venezuela': '+58',
  'Vietnam': '+84',
  'Yemen': '+967',
  'Zambia': '+260',
  'Zimbabwe': '+263',
};

// Sorted list of all countries
final List<String> _kAllCountries = _kDialCodes.keys.toList()..sort();

// Map from ISO country codes to country names
const Map<String, String> _kCountryCodeToName = {
  'AF': 'Afghanistan',
  'AL': 'Albania',
  'DZ': 'Algeria',
  'AO': 'Angola',
  'AR': 'Argentina',
  'AM': 'Armenia',
  'AU': 'Australia',
  'AT': 'Austria',
  'AZ': 'Azerbaijan',
  'BH': 'Bahrain',
  'BD': 'Bangladesh',
  'BY': 'Belarus',
  'BE': 'Belgium',
  'BJ': 'Benin',
  'BO': 'Bolivia',
  'BA': 'Bosnia and Herzegovina',
  'BW': 'Botswana',
  'BR': 'Brazil',
  'BG': 'Bulgaria',
  'BF': 'Burkina Faso',
  'BI': 'Burundi',
  'KH': 'Cambodia',
  'CM': 'Cameroon',
  'CA': 'Canada',
  'CV': 'Cape Verde',
  'CF': 'Central African Republic',
  'TD': 'Chad',
  'CL': 'Chile',
  'CN': 'China',
  'CO': 'Colombia',
  'KM': 'Comoros',
  'CD': 'Congo (DRC)',
  'CG': 'Congo (Republic)',
  'CR': 'Costa Rica',
  'HR': 'Croatia',
  'CU': 'Cuba',
  'CY': 'Cyprus',
  'CZ': 'Czech Republic',
  'DK': 'Denmark',
  'DJ': 'Djibouti',
  'EC': 'Ecuador',
  'EG': 'Egypt',
  'SV': 'El Salvador',
  'ER': 'Eritrea',
  'EE': 'Estonia',
  'ET': 'Ethiopia',
  'FI': 'Finland',
  'FR': 'France',
  'GA': 'Gabon',
  'GM': 'Gambia',
  'GE': 'Georgia',
  'DE': 'Germany',
  'GH': 'Ghana',
  'GR': 'Greece',
  'GT': 'Guatemala',
  'GN': 'Guinea',
  'GW': 'Guinea-Bissau',
  'HN': 'Honduras',
  'HU': 'Hungary',
  'IN': 'India',
  'ID': 'Indonesia',
  'IR': 'Iran',
  'IQ': 'Iraq',
  'IE': 'Ireland',
  'IL': 'Israel',
  'IT': 'Italy',
  'CI': 'Ivory Coast',
  'JM': 'Jamaica',
  'JP': 'Japan',
  'JO': 'Jordan',
  'KZ': 'Kazakhstan',
  'KE': 'Kenya',
  'KW': 'Kuwait',
  'KG': 'Kyrgyzstan',
  'LA': 'Laos',
  'LV': 'Latvia',
  'LB': 'Lebanon',
  'LS': 'Lesotho',
  'LR': 'Liberia',
  'LY': 'Libya',
  'LT': 'Lithuania',
  'LU': 'Luxembourg',
  'MG': 'Madagascar',
  'MW': 'Malawi',
  'MY': 'Malaysia',
  'MV': 'Maldives',
  'ML': 'Mali',
  'MR': 'Mauritania',
  'MU': 'Mauritius',
  'MX': 'Mexico',
  'MD': 'Moldova',
  'MN': 'Mongolia',
  'MA': 'Morocco',
  'MZ': 'Mozambique',
  'MM': 'Myanmar',
  'NA': 'Namibia',
  'NP': 'Nepal',
  'NL': 'Netherlands',
  'NZ': 'New Zealand',
  'NE': 'Niger',
  'NG': 'Nigeria',
  'KP': 'North Korea',
  'NO': 'Norway',
  'OM': 'Oman',
  'PK': 'Pakistan',
  'PS': 'Palestine',
  'PA': 'Panama',
  'PY': 'Paraguay',
  'PE': 'Peru',
  'PH': 'Philippines',
  'PL': 'Poland',
  'PT': 'Portugal',
  'QA': 'Qatar',
  'RO': 'Romania',
  'RU': 'Russia',
  'RW': 'Rwanda',
  'SA': 'Saudi Arabia',
  'SN': 'Senegal',
  'RS': 'Serbia',
  'SL': 'Sierra Leone',
  'SG': 'Singapore',
  'SK': 'Slovakia',
  'SI': 'Slovenia',
  'SO': 'Somalia',
  'ZA': 'South Africa',
  'KR': 'South Korea',
  'SS': 'South Sudan',
  'ES': 'Spain',
  'LK': 'Sri Lanka',
  'SD': 'Sudan',
  'SZ': 'Swaziland',
  'SE': 'Sweden',
  'CH': 'Switzerland',
  'SY': 'Syria',
  'TW': 'Taiwan',
  'TJ': 'Tajikistan',
  'TZ': 'Tanzania',
  'TH': 'Thailand',
  'TG': 'Togo',
  'TN': 'Tunisia',
  'TR': 'Turkey',
  'TM': 'Turkmenistan',
  'UG': 'Uganda',
  'UA': 'Ukraine',
  'AE': 'United Arab Emirates',
  'GB': 'United Kingdom',
  'US': 'United States',
  'UY': 'Uruguay',
  'UZ': 'Uzbekistan',
  'VE': 'Venezuela',
  'VN': 'Vietnam',
  'YE': 'Yemen',
  'ZM': 'Zambia',
  'ZW': 'Zimbabwe',
};

class _FormValidators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    if (value != value.trim()) {
      return 'Remove leading/trailing spaces';
    }
    return null;
  }

  static String? name(String? value) {
    final requiredMessage = required(value);
    if (requiredMessage != null) return requiredMessage;

    final nameRegex = RegExp(r"^[A-Za-z](?:[A-Za-z\s'-]*[A-Za-z])?");
    if (!nameRegex.hasMatch(value!)) {
      return 'Only letters, spaces, apostrophes and hyphens allowed';
    }
    return null;
  }

  static String? phone(String? value) {
    final requiredMessage = required(value);
    if (requiredMessage != null) return requiredMessage;

    final phoneRegex = RegExp(r"^\+?[0-9]{7,15}");
    if (!phoneRegex.hasMatch(value!.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}

class _InputFormatters {
  static final name = [FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s'-]"))];
  static final digits = [FilteringTextInputFormatter.digitsOnly];
}

class _InputDecorations {
  static InputDecoration textField(String placeholder) => InputDecoration(
        hintText: placeholder,
        hintStyle: GoogleFonts.dmSans(fontSize: 14, color: _kPlaceholder),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: InputBorder.none,
      );

  static InputDecoration dateField() => InputDecoration(
        hintText: 'DD / MM / YYYY',
        hintStyle: GoogleFonts.dmSans(fontSize: 14, color: _kPlaceholder),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kCrimson, width: 1.5),
        ),
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: _kMuted),
      );
}

class PersonalInformationScreen extends ConsumerStatefulWidget {
  const PersonalInformationScreen({super.key, this.nextRoute, this.initialCountry});
  final WidgetBuilder? nextRoute;
  /// Optional country to pre-populate (e.g. passed from Get Started / dashboard).
  final String? initialCountry;

  @override
  ConsumerState<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends ConsumerState<PersonalInformationScreen> {
  // ── form key ──────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── controllers ────────────────────────────────────────────────────────────
  final _firstNameCtrl    = TextEditingController();
  final _middleNameCtrl   = TextEditingController();
  final _lastNameCtrl     = TextEditingController();
  final _emailCtrl        = TextEditingController();
  final _phoneCtrl        = TextEditingController();
  final _dobCtrl          = TextEditingController();
  final _nationalIdCtrl   = TextEditingController();
  final _kinNameCtrl      = TextEditingController();
  final _kinPhoneCtrl     = TextEditingController();
  final List<TextEditingController> _schoolControllers = [];
  final List<TextEditingController> _gradesControllers = [];
  final _hobbiesCtrl      = TextEditingController();

  // ── validators ─────────────────────────────────────────────────────────────
  String? _requiredValidator(String? value) => _FormValidators.required(value);
  String? _nameValidator(String? value) => _FormValidators.name(value);
  String? _phoneValidator(String? value) => _FormValidators.phone(value);

  void _onCountryChanged(String? newCountry) {
    if (newCountry == null) return;
    ref.read(applicationFormProvider.notifier).updatePersonalInfo(country: newCountry);
    // Auto-populate the phone dial code when country changes
    final dialCode = _kDialCodes[newCountry] ?? '';
    if (dialCode.isNotEmpty) {
      // Replace only if phone field is empty or only contains a dial code
      final current = _phoneCtrl.text;
      final isDialCodeOnly = current.isEmpty || _kDialCodes.values.any((d) => current == d);
      if (isDialCodeOnly) {
        _phoneCtrl.text = dialCode;
        _phoneCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _phoneCtrl.text.length),
        );
      }
    }
  }

  void _trimAllTextFields() {
    final controllers = <TextEditingController>[
      _firstNameCtrl,
      _middleNameCtrl,
      _lastNameCtrl,
      _phoneCtrl,
      _dobCtrl,
      _nationalIdCtrl,
      _kinNameCtrl,
      _kinPhoneCtrl,
      _hobbiesCtrl,
      ..._schoolControllers,
      ..._gradesControllers,
    ];

    for (final controller in controllers) {
      final trimmed = controller.text.trim();
      if (controller.text != trimmed) {
        controller.text = trimmed;
        controller.selection = TextSelection.collapsed(offset: trimmed.length);
      }
    }

    ref.read(applicationFormProvider.notifier).updatePersonalInfo(
      firstName: _firstNameCtrl.text,
      middleName: _middleNameCtrl.text,
      lastName: _lastNameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
      dob: _dobCtrl.text,
      nationalId: _nationalIdCtrl.text,
      kinName: _kinNameCtrl.text,
      kinPhone: _kinPhoneCtrl.text,
      hobbies: _hobbiesCtrl.text,
    );

    final history = List<Map<String, String>>.generate(
      _schoolControllers.length,
      (i) => {
        'school': _schoolControllers[i].text,
        'grades': _gradesControllers[i].text,
      },
    );
    ref.read(applicationFormProvider.notifier).updateAcademicHistory(history);
  }

  void _syncAcademicControllersFromState() {
    final history = ref.read(applicationFormProvider).academicHistory;

    // Dispose existing controllers safely; keep list sizes aligned to state
    for (final c in _schoolControllers) {
      c.dispose();
    }
    for (final c in _gradesControllers) {
      c.dispose();
    }

    _schoolControllers.clear();
    _gradesControllers.clear();

    for (var i = 0; i < history.length; i++) {
      final entry = history[i];
      final schoolCtrl = TextEditingController(text: entry['school'] ?? '');
      final gradesCtrl = TextEditingController(text: entry['grades'] ?? '');

      schoolCtrl.addListener(() {
        final updatedHistory = List<Map<String, String>>.from(ref.read(applicationFormProvider).academicHistory);
        if (i < updatedHistory.length) {
          updatedHistory[i] = {
            'school': schoolCtrl.text,
            'grades': updatedHistory[i]['grades'] ?? '',
          };
          ref.read(applicationFormProvider.notifier).updateAcademicHistory(updatedHistory);
        }
      });

      gradesCtrl.addListener(() {
        final updatedHistory = List<Map<String, String>>.from(ref.read(applicationFormProvider).academicHistory);
        if (i < updatedHistory.length) {
          updatedHistory[i] = {
            'school': updatedHistory[i]['school'] ?? '',
            'grades': gradesCtrl.text,
          };
          ref.read(applicationFormProvider.notifier).updateAcademicHistory(updatedHistory);
        }
      });

      _schoolControllers.add(schoolCtrl);
      _gradesControllers.add(gradesCtrl);
    }
  }

  void _ensureAcademicControllers() {
    final history = ref.read(applicationFormProvider).academicHistory;
    if (history.length != _schoolControllers.length) {
      _syncAcademicControllersFromState();
    }
  }

  String _formatDateForDisplay(String rawDate) {
    if (rawDate.isEmpty) return '';

    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      // Fallback from dd/MM/yyyy legacy format
      try {
        final parts = rawDate.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateFormat('dd MMM yyyy').format(DateTime(year, month, day));
        }
      } catch (_) {}
    }

    return rawDate;
  }

  String _formatDateForStorage(String displayDate) {
    if (displayDate.isEmpty) return '';

    try {
      final parsed = DateFormat('dd MMM yyyy').parseStrict(displayDate);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      // Also support pass-through if already ISO
      try {
        final parsedIso = DateTime.parse(displayDate);
        return DateFormat('yyyy-MM-dd').format(parsedIso);
      } catch (_) {}

      // Fallback from dd/MM/yyyy legacy format
      try {
        final parts = displayDate.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateFormat('yyyy-MM-dd').format(DateTime(year, month, day));
        }
      } catch (_) {}
    }

    return '';
  }

  @override
  void initState() {
    super.initState();
    final currentUserId = SupabaseClientProvider.currentUser?.id ?? '';
    debugPrint('Current user ID: ${currentUserId.isEmpty ? 'none' : currentUserId}');

    final existingState = ref.read(applicationFormProvider);
    if (existingState.ownerUserId != currentUserId) {
      ref.read(applicationFormProvider.notifier).resetForUser(currentUserId);
    }

    // Get initial state from provider
    final initialState = ref.read(applicationFormProvider);
    final locale = ui.PlatformDispatcher.instance.locale;
    final detectedCountry = _kCountryCodeToName[locale.countryCode];

    // Initialize controllers with provider values
    _firstNameCtrl.text = initialState.firstName;
    _middleNameCtrl.text = initialState.middleName;
    _lastNameCtrl.text = initialState.lastName;
    _emailCtrl.text = initialState.email.isNotEmpty
      ? initialState.email
      : (SupabaseClientProvider.currentUser?.email ?? '');
    _phoneCtrl.text = initialState.phone.isNotEmpty ? initialState.phone : _kDialCodes[initialState.country] ?? '+263';
    _dobCtrl.text = _formatDateForDisplay(initialState.dob);
    _nationalIdCtrl.text = initialState.nationalId;
    _kinNameCtrl.text = initialState.kinName;
    _kinPhoneCtrl.text = initialState.kinPhone;
    _hobbiesCtrl.text = initialState.hobbies;

    _syncAcademicControllersFromState();

    // Add listeners to sync with provider
    _firstNameCtrl.addListener(() {
      ref.read(applicationFormProvider.notifier).updatePersonalInfo(firstName: _firstNameCtrl.text);
    });
    _middleNameCtrl.addListener(() {
      ref.read(applicationFormProvider.notifier).updatePersonalInfo(middleName: _middleNameCtrl.text);
    });
    _lastNameCtrl.addListener(() {
      ref.read(applicationFormProvider.notifier).updatePersonalInfo(lastName: _lastNameCtrl.text);
    });
    _emailCtrl.addListener(() {
      ref.read(applicationFormProvider.notifier).updatePersonalInfo(email: _emailCtrl.text);
    });
    _phoneCtrl.addListener(() {
      ref.read(applicationFormProvider.notifier).updatePersonalInfo(phone: _phoneCtrl.text);
    });
    _dobCtrl.addListener(() {
      final iso = _formatDateForStorage(_dobCtrl.text);
      ref.read(applicationFormProvider.notifier).updatePersonalInfo(dob: iso);
    });
    _nationalIdCtrl.addListener(() {
      ref.read(applicationFormProvider.notifier).updatePersonalInfo(nationalId: _nationalIdCtrl.text);
    });
    _kinNameCtrl.addListener(() {
      ref.read(applicationFormProvider.notifier).updatePersonalInfo(kinName: _kinNameCtrl.text);
    });
    _kinPhoneCtrl.addListener(() {
      ref.read(applicationFormProvider.notifier).updatePersonalInfo(kinPhone: _kinPhoneCtrl.text);
    });
    _hobbiesCtrl.addListener(() {
      ref.read(applicationFormProvider.notifier).updatePersonalInfo(hobbies: _hobbiesCtrl.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final currentState = ref.read(applicationFormProvider);

      if (initialState.country == 'Zimbabwe' && detectedCountry != null) {
        ref.read(applicationFormProvider.notifier).updatePersonalInfo(country: detectedCountry);
      }

      if (widget.initialCountry != null && widget.initialCountry != currentState.country) {
        ref.read(applicationFormProvider.notifier).updatePersonalInfo(country: widget.initialCountry!);
      }
    });
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _middleNameCtrl, _lastNameCtrl,
      _emailCtrl, _phoneCtrl, _dobCtrl, _nationalIdCtrl,
      _kinNameCtrl, _kinPhoneCtrl,
      _hobbiesCtrl,
    ]) {
      c.dispose();
    }

    for (final c in _schoolControllers) {
      c.dispose();
    }
    for (final c in _gradesControllers) {
      c.dispose();
    }

    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: _kParchment,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 36 : 16,
                vertical: isDesktop ? 48 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 210,
                              child: _buildSidebar(),
                            ),
                            const SizedBox(width: 48),
                            Expanded(child: _buildMain(context)),
                          ],
                        )
                      : _buildMain(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xF5FAF7F2),
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_rounded,
                    size: 18, color: _kCrimson),
                const SizedBox(width: 8),
                Text(
                  'Back',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kCrimson,
                  ),
                ),
              ],
            ),
          ),
          // Title
          Flexible(
            child: Text(
              'Personal Information',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _kCrimson,
                letterSpacing: 0.04 * 18,
              ),
            ),
          ),
          // Right controls
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kBorder, width: 1.5),
                ),
                child: Text(
                  'Onboarding',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.08 * 11,
                    color: _kMuted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kBorder, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '?',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SIDEBAR ───────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    final formState = ref.watch(applicationFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressSidebar(formState: formState, stepText: 'Step 2 of 5'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D1A1208),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Complete your personal information to unlock program recommendations tailored to your background.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: _kInkMid,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_kDialCodes.containsKey(formState.country))
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: _kMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${formState.country}: ${_kDialCodes[formState.country]}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      color: _kInkMid,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

// ── MAIN ──────────────────────────────────────────────────────────────────
  Widget _buildMain(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Milestone badge + heading
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _kParchDeep,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBorder),
            ),
            child: Text(
              'Application Milestone',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.06 * 11,
                color: _kMuted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Personal Information',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide your legal identity details and academic background to help us curate your student experience at Africa University.',
            style: GoogleFonts.dmSans(
              fontSize: 13.5,
              color: _kMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // Legal Identity
          _buildSection(
            title: 'Legal Identity',
            tinted: false,
            child: _buildLegalIdentity(),
          ),
          const SizedBox(height: 32),

          // Next of Kin
          _buildSection(
            title: 'Next of Kin',
            subtitle: 'Emergency contact information',
            tinted: true,
            child: _buildNextOfKin(),
          ),
          const SizedBox(height: 32),

          // Academic History (dynamic)
          _buildSection(
            title: 'Academic History',
            tinted: false,
            child: _buildAcademicHistory(),
          ),
          const SizedBox(height: 32),

          // Personal Interests
          _buildSection(
            title: 'Personal Interests',
            tinted: false,
            child: _buildPersonalInterests(),
          ),
          const SizedBox(height: 8),

          // Footer nav
          _buildFooterNav(context),
        ],
      ),
    );
  }

  // ── SECTION WRAPPER ───────────────────────────────────────────────────────
  Widget _buildSection({
    required String title,
    String? subtitle,
    required bool tinted,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      decoration: BoxDecoration(
        color: tinted ? _kTintBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tinted ? _kTintBd : _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1A1208),
            blurRadius: 16,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: subtitle != null ? 44 : 28,
                decoration: BoxDecoration(
                  color: _kCrimson,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _kCrimson,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        color: _kMuted,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: tinted ? _kTintBd : _kParchDeep,
              height: 1,
            ),
          ),
          child,
        ],
      ),
    );
  }

  // ── LEGAL IDENTITY ────────────────────────────────────────────────────────
  Widget _buildLegalIdentity() {
    return Column(
      children: [
        // Row 1: First, Middle, Last
        _threeCol([
          _FormField(
            label: 'First Name',
            placeholder: 'Enter first name',
            controller: _firstNameCtrl,
            validator: _nameValidator,
            inputFormatters: _InputFormatters.name,
          ),
          _FormField(
            label: 'Middle Name',
            placeholder: 'Enter middle name',
            controller: _middleNameCtrl,
            validator: _nameValidator,
            inputFormatters: _InputFormatters.name,
          ),
          _FormField(
            label: 'Last Name',
            placeholder: 'Enter last name',
            controller: _lastNameCtrl,
            validator: _nameValidator,
            inputFormatters: _InputFormatters.name,
          ),
        ]),
        const SizedBox(height: 16),
        _FormField(
          label: 'Email Address',
          placeholder: 'Enter email address',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 16),
        // Row 2: Phone, DOB, Country
        _threeCol([
          // Phone with separate dial code
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel('Phone Number'),
              const SizedBox(height: 7),
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _kParchment,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      border: Border.all(color: _kBorder, width: 1.5),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _kDialCodes[ref.watch(applicationFormProvider).country] ?? '',
                      style: GoogleFonts.dmSans(fontSize: 14, color: _kInk),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: _InputFormatters.digits,
                      style: GoogleFonts.dmSans(fontSize: 14, color: _kInk),
                      validator: _phoneValidator,
                      decoration: InputDecoration(
                        hintText: '...',
                        hintStyle: GoogleFonts.dmSans(fontSize: 14, color: _kPlaceholder),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          borderSide: BorderSide(color: _kBorder, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          borderSide: BorderSide(color: _kBorder, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          borderSide: BorderSide(color: _kCrimson, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          _DateField(
            label: 'Date of Birth',
            controller: _dobCtrl,
            validator: _requiredValidator,
          ),
          _CountryDropdown(
            label: 'Country of Residence',
            value: ref.watch(applicationFormProvider).country,
            items: _kAllCountries,
            onChanged: _onCountryChanged,
            validator: _requiredValidator,
          ),
        ]),
        const SizedBox(height: 16),
        // National ID
        _FormField(
          label: 'National ID Number',
          placeholder: 'ID Number / Passport Number',
          controller: _nationalIdCtrl,
          validator: _requiredValidator,
        ),
      ],
    );
  }

  // ── NEXT OF KIN ───────────────────────────────────────────────────────────
  Widget _buildNextOfKin() {
    return Row(
      children: [
        Expanded(
          child: _FormField(
            label: "Full Name",
            placeholder: "Kin's full name",
            controller: _kinNameCtrl,
            tinted: true,
            validator: _nameValidator,
            inputFormatters: _InputFormatters.name,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _FormField(
            label: "Kin's Phone Number",
            placeholder: 'Contact number',
            controller: _kinPhoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: _InputFormatters.digits,
            tinted: true,
            validator: _phoneValidator,
          ),
        ),
      ],
    );
  }

  // ── ACADEMIC HISTORY ──────────────────────────────────────────────────────
  Widget _buildAcademicHistory() {
    _ensureAcademicControllers();
    final entries = ref.watch(applicationFormProvider).academicHistory;

    return Column(
      children: [
        ...List.generate(entries.length, (index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FormField(
                label: 'Previous School Attended',
                placeholder: 'Name of High School or College',
                controller: _schoolControllers[index],
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),
              _TextareaField(
                label: 'Grades / Distinctions',
                placeholder:
                    'List your key results (e.g., A-Level: Mathematics A, Physics B...)',
                controller: _gradesControllers[index],
                validator: _requiredValidator,
              ),
              if (entries.length > 1) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    button: true,
                    label: 'Remove school entry',
                    child: TextButton.icon(
                      onPressed: () {
                        final updatedHistory = List<Map<String, String>>.from(ref.read(applicationFormProvider).academicHistory);
                        if (index >= 0 && index < updatedHistory.length) {
                          updatedHistory.removeAt(index);
                          ref.read(applicationFormProvider.notifier).updateAcademicHistory(updatedHistory);
                          _syncAcademicControllersFromState();
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: _kCrimson,
                        textStyle: const TextStyle(fontSize: 12),
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ),
              ],
              if (index != entries.length - 1) const SizedBox(height: 20),
            ],
          );
        }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final updatedHistory = List<Map<String, String>>.from(ref.read(applicationFormProvider).academicHistory);
              updatedHistory.add({'school': '', 'grades': ''});
              ref.read(applicationFormProvider.notifier).updateAcademicHistory(updatedHistory);
              _syncAcademicControllersFromState();
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('+ Add Another School'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kCrimson,
              side: const BorderSide(color: _kCrimson),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ── PERSONAL INTERESTS ────────────────────────────────────────────────────
  Widget _buildPersonalInterests() {
    return _TextareaField(
      label: 'Hobbies & Extracurricular Activities',
      placeholder: 'Tell us about what you enjoy outside the classroom...',
      controller: _hobbiesCtrl,
      validator: _requiredValidator,
    );
  }

  // ── FOOTER NAV ────────────────────────────────────────────────────────────
  Widget _buildFooterNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back step
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_rounded,
                    size: 15, color: _kMuted),
                const SizedBox(width: 8),
                Text(
                  'Back to step 1',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kMuted,
                  ),
                ),
              ],
            ),
          ),
          // Save & Continue
          _SaveButton(
            onTap: () {
              _trimAllTextFields();
              if (_formKey.currentState!.validate()) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: widget.nextRoute ?? (_) => const DocumentUploadScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _threeCol(List<Widget> children) {
    return LayoutBuilder(builder: (ctx, constraints) {
      if (constraints.maxWidth < 500) {
        return Column(
          children: children
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: c,
                  ))
              .toList(),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.asMap().entries.map((e) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: e.key < children.length - 1 ? 16 : 0),
              child: e.value,
            ),
          );
        }).toList(),
      );
    });
  }
}

class _ProgressSidebar extends StatelessWidget {
  final ApplicationFormState formState;
  final String stepText;

  const _ProgressSidebar({
    Key? key,
    required this.formState,
    required this.stepText,
  }) : super(key: key);

  double get _progress {
    final basicFields = [
      formState.firstName,
      formState.middleName,
      formState.lastName,
      formState.phone,
      formState.dob,
      formState.country,
      formState.nationalId,
      formState.kinName,
      formState.kinPhone,
      formState.hobbies,
    ];

    final filledBasic = basicFields.where((value) => value.trim().isNotEmpty).length;
    final academicFields = formState.academicHistory.fold<int>(0, (count, entry) {
      var filled = 0;
      if ((entry['school'] ?? '').trim().isNotEmpty) filled++;
      if ((entry['grades'] ?? '').trim().isNotEmpty) filled++;
      return count + filled;
    });

    final totalFields = basicFields.length + formState.academicHistory.length * 2;
    if (totalFields == 0) return 0.0;

    return (filledBasic + academicFields) / totalFields;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress.clamp(0.0, 1.0);
    final percentage = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR PROGRESS',
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.16 * 10,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$percentage%',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: _kCrimson,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: _kBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(_kCrimson),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stepText,
          style: GoogleFonts.dmSans(fontSize: 11.5, color: _kMuted),
        ),
      ],
    );
  }
}

// ─── _FormField ──────────────────────────────────────────────────────────────
class _FormField extends StatefulWidget {
  final String label, placeholder;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool tinted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _FormField({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.tinted = false,
    this.validator,
    this.inputFormatters,
  });

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  final _focus = FocusNode();
  final ValueNotifier<bool> _focused = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      _focused.value = _focus.hasFocus;
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _focused.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(widget.label),
          const SizedBox(height: 7),
          ValueListenableBuilder<bool>(
            valueListenable: _focused,
            builder: (context, focused, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 50,
                decoration: BoxDecoration(
                  color: focused
                      ? Colors.white
                      : (widget.tinted ? Colors.white : _kParchment),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: focused
                        ? _kCrimson
                        : (widget.tinted ? _kTintInput : _kBorder),
                    width: 1.5,
                  ),
                  boxShadow: focused
                      ? const [
                          BoxShadow(
                            color: Color(0x149B1B30),
                            blurRadius: 0,
                            spreadRadius: 3,
                          ),
                        ]
                      : [],
                ),
                child: child,
              );
            },
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              style: GoogleFonts.dmSans(fontSize: 14, color: _kInk),
              validator: widget.validator,
              decoration: _InputDecorations.textField(widget.placeholder),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _TextareaField ───────────────────────────────────────────────────────────
class _TextareaField extends StatefulWidget {
  final String label, placeholder;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const _TextareaField({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.validator,
  });

  @override
  State<_TextareaField> createState() => _TextareaFieldState();
}

class _TextareaFieldState extends State<_TextareaField> {
  final _focus = FocusNode();
  final ValueNotifier<bool> _focused = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      _focused.value = _focus.hasFocus;
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _focused.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(widget.label),
          const SizedBox(height: 7),
          ValueListenableBuilder<bool>(
            valueListenable: _focused,
            builder: (context, focused, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: focused ? Colors.white : _kParchment,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: focused ? _kCrimson : _kBorder,
                    width: 1.5,
                  ),
                  boxShadow: focused
                      ? const [
                          BoxShadow(
                            color: Color(0x149B1B30),
                            blurRadius: 0,
                            spreadRadius: 3,
                          ),
                        ]
                      : [],
                ),
                child: child,
              );
            },
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focus,
              minLines: 3,
              maxLines: 6,
              style: GoogleFonts.dmSans(fontSize: 14, color: _kInk),
              validator: widget.validator,
              decoration: _InputDecorations.textField(widget.placeholder),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _DateField ───────────────────────────────────────────────────────────────
class _DateField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const _DateField({required this.label, required this.controller, this.validator});

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _kCrimson),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      widget.controller.text = DateFormat('dd MMM yyyy').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.label}, date picker',
      button: true,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(widget.label),
          const SizedBox(height: 7),
          TextFormField(
            controller: widget.controller,
            readOnly: true,
            onTap: () => _pick(context),
            validator: widget.validator,
            style: GoogleFonts.dmSans(fontSize: 14, color: _kInk),
            decoration: _InputDecorations.dateField(),
          ),
        ],
      ),
    );
  }
}

// ─── _CountryDropdown — searchable dropdown ──────────────────────────────────
class _CountryDropdown extends FormField<String> {
  _CountryDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    FormFieldValidator<String>? validator,
  }) : super(
          initialValue: value,
          validator: validator,
          builder: (FormFieldState<String> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(label),
                const SizedBox(height: 7),
                GestureDetector(
                  onTap: () async {
                    final result = await showDialog<String>(
                      context: state.context,
                      builder: (_) => _CountrySearchDialog(
                        items: items,
                        selected: state.value ?? value,
                      ),
                    );
                    if (result != null) {
                      state.didChange(result);
                      onChanged(result);
                    }
                  },
                  child: Semantics(
                    label: '$label, country selection',
                    button: true,
                    value: state.value ?? value,
                    onTapHint: 'Choose country',
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 50),
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _kParchment,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kBorder, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              state.value ?? value,
                              style: GoogleFonts.dmSans(fontSize: 14, color: _kInk),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _kDialCodes[state.value ?? value] ?? '',
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: _kMuted,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: _kMuted),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          });
}

class _CountrySearchDialog extends StatefulWidget {
  final List<String> items;
  final String selected;
  const _CountrySearchDialog({required this.items, required this.selected});

  @override
  State<_CountrySearchDialog> createState() => _CountrySearchDialogState();
}

class _CountrySearchDialogState extends State<_CountrySearchDialog> {
  final _searchCtrl = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.items);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? List.from(widget.items)
            : widget.items
                .where((c) => c.toLowerCase().contains(q))
                .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: _kParchment,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kCrimson, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text('No countries found',
                          style: GoogleFonts.dmSans(color: _kMuted)))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final country = _filtered[i];
                        final dial = _kDialCodes[country] ?? '';
                        final selected = country == widget.selected;
                        return ListTile(
                          dense: true,
                          selected: selected,
                          selectedColor: _kCrimson,
                          selectedTileColor: AppTheme.primaryLight,
                          title: Text(
                            country,
                            style: GoogleFonts.dmSans(
                              fontSize: 13.5,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: Text(
                            dial,
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: _kMuted),
                          ),
                          onTap: () => Navigator.pop(context, country),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _FieldLabel ─────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1 * 11,
        color: _kInkMid,
      ),
    );
  }
}

// ─── _SaveButton ─────────────────────────────────────────────────────────────
class _SaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SaveButton({required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  final ValueNotifier<bool> _hover = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Save and continue',
      child: MouseRegion(
        onEnter: (_) => _hover.value = true,
        onExit: (_) => _hover.value = false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onTap,
          child: ValueListenableBuilder<bool>(
            valueListenable: _hover,
            builder: (context, hover, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                transform: hover
                    ? Matrix4.translationValues(0, -1, 0)
                    : Matrix4.identity(),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kCrimsonLight, _kCrimson],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _kCrimson.withValues(alpha: hover ? 0.38 : 0.28),
                      blurRadius: hover ? 20 : 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Save & Continue',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.04 * 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
