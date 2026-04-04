import 'package:flutter_riverpod/flutter_riverpod.dart';

// Data class for personal info form state
class AcademicHistoryEntry {
  final String school;
  final String grades;

  const AcademicHistoryEntry({this.school = '', this.grades = ''});

  AcademicHistoryEntry copyWith({String? school, String? grades}) {
    return AcademicHistoryEntry(
      school: school ?? this.school,
      grades: grades ?? this.grades,
    );
  }
}

class PersonalInfoFormState {
  final String firstName;
  final String middleName;
  final String lastName;
  final String phone;
  final String dob;
  final String country;
  final String nationalId;
  final String kinName;
  final String kinPhone;
  final String hobbies;
  final List<AcademicHistoryEntry> academicHistory;

  const PersonalInfoFormState({
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.phone = '',
    this.dob = '',
    this.country = 'Zimbabwe',
    this.nationalId = '',
    this.kinName = '',
    this.kinPhone = '',
    this.hobbies = '',
    this.academicHistory = const [
      AcademicHistoryEntry(),
      AcademicHistoryEntry(),
    ],
  });

  PersonalInfoFormState copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    String? phone,
    String? dob,
    String? country,
    String? nationalId,
    String? kinName,
    String? kinPhone,
    String? hobbies,
    List<AcademicHistoryEntry>? academicHistory,
  }) {
    return PersonalInfoFormState(
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      country: country ?? this.country,
      nationalId: nationalId ?? this.nationalId,
      kinName: kinName ?? this.kinName,
      kinPhone: kinPhone ?? this.kinPhone,
      hobbies: hobbies ?? this.hobbies,
      academicHistory: academicHistory ?? this.academicHistory,
    );
  }
}

// StateNotifier for managing the form state
class PersonalInfoFormNotifier extends StateNotifier<PersonalInfoFormState> {
  PersonalInfoFormNotifier() : super(const PersonalInfoFormState());

  void updateFirstName(String value) {
    state = state.copyWith(firstName: value);
  }

  void updateMiddleName(String value) {
    state = state.copyWith(middleName: value);
  }

  void updateLastName(String value) {
    state = state.copyWith(lastName: value);
  }

  void updatePhone(String value) {
    state = state.copyWith(phone: value);
  }

  void updateDob(String value) {
    state = state.copyWith(dob: value);
  }

  void updateCountry(String value) {
    state = state.copyWith(country: value);
  }

  void updateNationalId(String value) {
    state = state.copyWith(nationalId: value);
  }

  void updateKinName(String value) {
    state = state.copyWith(kinName: value);
  }

  void updateKinPhone(String value) {
    state = state.copyWith(kinPhone: value);
  }

  void updateAcademicHistoryEntry(int index, {String? school, String? grades}) {
    final history = List<AcademicHistoryEntry>.from(state.academicHistory);
    if (index < 0 || index >= history.length) return;
    history[index] = history[index].copyWith(school: school, grades: grades);
    state = state.copyWith(academicHistory: history);
  }

  void addAcademicHistoryEntry() {
    final history = List<AcademicHistoryEntry>.from(state.academicHistory)
      ..add(const AcademicHistoryEntry());
    state = state.copyWith(academicHistory: history);
  }

  void removeAcademicHistoryEntry(int index) {
    final history = List<AcademicHistoryEntry>.from(state.academicHistory);
    if (history.length <= 1) return;
    if (index < 0 || index >= history.length) return;
    history.removeAt(index);
    state = state.copyWith(academicHistory: history);
  }

  void updateHobbies(String value) {
    state = state.copyWith(hobbies: value);
  }

  void reset() {
    state = const PersonalInfoFormState();
  }
}

// Provider for the form state
final personalInfoFormProvider = StateNotifierProvider<PersonalInfoFormNotifier, PersonalInfoFormState>((ref) {
  return PersonalInfoFormNotifier();
});