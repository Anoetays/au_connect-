import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:au_connect/services/onboarding_application_service.dart';
import 'package:au_connect/services/document_service.dart';

import 'onboarding_constants.dart';
import 'onboarding_data.dart';

class OnboardingController extends ChangeNotifier {
  final OnboardingData state = OnboardingData();

  int index = 0;
  bool isLoading = false;

  final List<String> screenIds = const [
    's-splash',
    's-welcome',
    's-register',
    's-country',
    's-language',
    's-name-lang',
    's-bonjour',
    's-role',
    's-letsgo',
    's-gender',
    's-dob',
    's-level',
    's-field',
    's-programme',
    's-alevel',
    's-disqualified',
    's-academic',
    's-finance',
    's-residency',
    's-accommodation',
    's-disability',
    's-almost',
    's-nextofkin',
    's-payment',
    's-review',
    's-success',
    's-tracker',
  ];

  void goTo(int newIndex) {
    if (newIndex < 0 || newIndex >= screenIds.length) return;
    index = newIndex;
    notifyListeners();
  }

  void next() => goTo(index + 1);
  void back() => goTo(index - 1);
  void refresh() => notifyListeners();

  void showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> autoAdvanceSplash() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (index == 0) {
      goTo(1);
    }
  }

  Future<void> pickCertificate() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (picked != null && picked.files.isNotEmpty) {
      final file = picked.files.first;
      state.certificateFileName = file.name;
      notifyListeners();

      try {
        // Upload bytes to Supabase Storage and record in documents table
        await DocumentService.uploadDocument(
          fileName: file.name,
          documentType: 'certificate',
          fileBytes: file.bytes,
        );
        // Also record filename on the application row
        await OnboardingApplicationService.saveField(
          'certificate_file_name',
          file.name,
        );
        debugPrint('Certificate uploaded: ${file.name}');
      } catch (e) {
        debugPrint('Error uploading certificate: $e');
      }
    }
  }

  void goFromCountry() {
    if (state.country == 'DRCongo' || state.country == 'Mozambique') {
      goTo(4);
    } else {
      state.language = 'English';
      goTo(5);
    }
  }

  String greetingHello() =>
      (kGreetings[state.language] ?? kGreetings['English']!)['hello']!;

  String greetingWelcome() =>
      (kGreetings[state.language] ?? kGreetings['English']!)['welcome']!;

  Map<String, String> nameLabels() =>
      kNameLabels[state.language] ?? kNameLabels['English']!;

  List<String> currentProgrammes() =>
      List<String>.from(kProgrammes[state.field]!['programmes'] as List);

  String currentRequirement() => kProgrammes[state.field]!['requirement'] as String;
  String currentALevelMsg() => kProgrammes[state.field]!['aLevelMsg'] as String;

  // Save personal info (step 2: register)
  Future<void> savePersonalInfo() async {
    try {
      await OnboardingApplicationService.saveFields({
        'first_name': state.firstName,
        'last_name': state.lastName,
        'email': state.email,
        'phone': state.phone,
      });
      debugPrint('Personal info saved');
    } catch (e) {
      debugPrint('Error saving personal info: $e');
    }
  }

  // Save country (step 3)
  Future<void> saveCountry() async {
    try {
      await OnboardingApplicationService.saveField('country', state.country);
      debugPrint('Country saved: ${state.country}');
    } catch (e) {
      debugPrint('Error saving country: $e');
    }
  }

  // Save language (step 4)
  Future<void> saveLanguage() async {
    try {
      await OnboardingApplicationService.saveField('language', state.language);
      debugPrint('Language saved: ${state.language}');
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  // Save name preferences (step 5)
  Future<void> saveName() async {
    try {
      await OnboardingApplicationService.saveField('preferred_name', state.preferredName);
      debugPrint('Name saved: ${state.preferredName}');
    } catch (e) {
      debugPrint('Error saving name: $e');
    }
  }

  // Save gender (step 9)
  Future<void> saveGender() async {
    try {
      await OnboardingApplicationService.saveField('gender', state.gender);
      debugPrint('Gender saved: ${state.gender}');
    } catch (e) {
      debugPrint('Error saving gender: $e');
    }
  }

  // Save DOB (step 10)
  Future<void> saveDOB() async {
    try {
      await OnboardingApplicationService.saveField('date_of_birth', state.dob);
      debugPrint('DOB saved: ${state.dob}');
    } catch (e) {
      debugPrint('Error saving DOB: $e');
    }
  }

  // Save study level (step 11)
  Future<void> saveStudyLevel() async {
    try {
      await OnboardingApplicationService.saveField('study_level', state.studyLevel);
      debugPrint('Study level saved: ${state.studyLevel}');
    } catch (e) {
      debugPrint('Error saving study level: $e');
    }
  }

  // Save field of study (step 12)
  Future<void> saveFieldOfStudy() async {
    try {
      await OnboardingApplicationService.saveField('field_of_study', state.field);
      debugPrint('Field of study saved: ${state.field}');
    } catch (e) {
      debugPrint('Error saving field of study: $e');
    }
  }

  // Save programme (step 13)
  Future<void> saveProgramme() async {
    try {
      await OnboardingApplicationService.saveField('programme', state.programme);
      debugPrint('Programme saved: ${state.programme}');
    } catch (e) {
      debugPrint('Error saving programme: $e');
    }
  }

  // Save A-level qualification (step 14)
  Future<void> saveALevelQualified() async {
    try {
      await OnboardingApplicationService.saveField(
        'a_level_qualified',
        state.aLevelQualified == 'yes',
      );
      debugPrint('A-level qualified saved: ${state.aLevelQualified}');
    } catch (e) {
      debugPrint('Error saving A-level qualified: $e');
    }
  }

  // Save academic info (step 16)
  Future<void> saveAcademicInfo() async {
    try {
      await OnboardingApplicationService.saveFields({
        'school_attended': state.school,
        'grades': state.grades,
      });
      debugPrint('Academic info saved');
    } catch (e) {
      debugPrint('Error saving academic info: $e');
    }
  }

  // Save financing (step 17)
  Future<void> saveFinancing() async {
    try {
      await OnboardingApplicationService.saveField('financing', state.financing);
      debugPrint('Financing saved: ${state.financing}');
    } catch (e) {
      debugPrint('Error saving financing: $e');
    }
  }

  // Save accommodation (step 18)
  Future<void> saveAccommodation() async {
    try {
      await OnboardingApplicationService.saveField('accommodation', state.accommodation);
      debugPrint('Accommodation saved: ${state.accommodation}');
    } catch (e) {
      debugPrint('Error saving accommodation: $e');
    }
  }

  // Save disability info (step 19)
  Future<void> saveDisability() async {
    try {
      await OnboardingApplicationService.saveFields({
        'disability': state.disability,
        'disability_detail': state.disabilityDetail,
      });
      debugPrint('Disability info saved');
    } catch (e) {
      debugPrint('Error saving disability info: $e');
    }
  }

  // Save next of kin (step 21)
  Future<void> saveNextOfKin() async {
    try {
      await OnboardingApplicationService.saveFields({
        'kin_name': state.kinName,
        'kin_relationship': state.kinRel,
        'kin_phone': state.kinPhone,
      });
      debugPrint('Next of kin info saved');
    } catch (e) {
      debugPrint('Error saving next of kin: $e');
    }
  }

  // Save residency info (residency check step)
  Future<void> saveResidency() async {
    try {
      await OnboardingApplicationService.saveFields({
        'resides_in_zimbabwe': state.residesInZimbabwe,
        'applicant_type': state.applicantType,
      });
      debugPrint('Residency saved: ${state.residesInZimbabwe}, type: ${state.applicantType}');
    } catch (e) {
      debugPrint('Error saving residency: $e');
    }
  }

  // Save payment method (step 22)
  Future<void> savePaymentMethod() async {
    try {
      await OnboardingApplicationService.saveField('payment_method', state.paymentMethod);
      debugPrint('Payment method saved: ${state.paymentMethod}');
    } catch (e) {
      debugPrint('Error saving payment method: $e');
    }
  }

  // Load saved data from Supabase for review
  Future<void> loadSavedData() async {
    try {
      isLoading = true;
      notifyListeners();

      final data = await OnboardingApplicationService.getApplication();
      
      // Populate state with saved data
      state.firstName = data['first_name'] ?? '';
      state.lastName = data['last_name'] ?? '';
      state.email = data['email'] ?? '';
      state.phone = data['phone'] ?? '';
      state.country = data['country'] ?? '';
      state.language = data['language'] ?? '';
      state.preferredName = data['preferred_name'] ?? '';
      state.gender = data['gender'] ?? '';
      state.dob = data['date_of_birth'] ?? '';
      state.studyLevel = data['study_level'] ?? '';
      state.field = data['field_of_study'] ?? '';
      state.programme = data['programme'] ?? '';
      state.aLevelQualified = data['a_level_qualified'] ? 'yes' : 'no';
      state.school = data['school_attended'] ?? '';
      state.grades = data['grades'] ?? '';
      state.financing = data['financing'] ?? '';
      state.accommodation = data['accommodation'] ?? '';
      state.disability = data['disability'] ?? '';
      state.disabilityDetail = data['disability_detail'] ?? '';
      state.kinName = data['kin_name'] ?? '';
      state.kinRel = data['kin_relationship'] ?? '';
      state.kinPhone = data['kin_phone'] ?? '';
      state.paymentMethod = data['payment_method'] ?? '';
      state.certificateFileName = data['certificate_file_name'];

      isLoading = false;
      notifyListeners();
      debugPrint('Loaded saved application data');
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('Error loading saved data: $e');
      rethrow;
    }
  }

  Future<void> doRegister(BuildContext context) async {
    final fname = state.firstName.trim();
    final lname = state.lastName.trim();
    final email = state.email.trim();
    final password = state.password;

    if (fname.isEmpty || lname.isEmpty || email.isEmpty || password.isEmpty) {
      showToast(context, 'Please fill in all fields');
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final authService = Supabase.instance.client.auth;
      
      // Create auth account
      final response = await authService.signUp(
        email: email,
        password: password,
        data: {
          'full_name': '$fname $lname',
        },
      );
      
      if (response.user == null) {
        throw Exception('Sign-up failed: no user returned');
      }

      state.userId = response.user!.id;
      
      // Save initial personal info to applications table
      await savePersonalInfo();

      isLoading = false;
      notifyListeners();
      
      showToast(context, 'Account created! Check your email to verify.');
      goTo(3);
    } on AuthException catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('Auth error: ${e.message}');
      showToast(context, 'Sign-up failed: ${e.message}');
    } catch (err) {
      isLoading = false;
      notifyListeners();
      debugPrint('Unexpected error: $err');
      showToast(context, 'Error: $err');
    }
  }

  Future<void> doSubmit(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      // Update application status to submitted
      await OnboardingApplicationService.submitApplication();
      
      isLoading = false;
      notifyListeners();
      
      showToast(context, 'Application submitted successfully!');
      goTo(25); // Success screen
    } catch (err) {
      isLoading = false;
      notifyListeners();
      debugPrint('Submit error: $err');
      showToast(context, 'Failed to submit application: $err');
    }
  }
}
