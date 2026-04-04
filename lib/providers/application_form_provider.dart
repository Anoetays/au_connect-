import 'package:flutter_riverpod/flutter_riverpod.dart';

// Models for application form data
class SelectedProgram {
  final String name;
  final String faculty;
  final int durationYears;

  const SelectedProgram({
    this.name = '',
    this.faculty = '',
    this.durationYears = 0,
  });

  SelectedProgram copyWith({
    String? name,
    String? faculty,
    int? durationYears,
  }) {
    return SelectedProgram(
      name: name ?? this.name,
      faculty: faculty ?? this.faculty,
      durationYears: durationYears ?? this.durationYears,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'faculty': faculty,
    'durationYears': durationYears,
  };

  factory SelectedProgram.fromJson(Map<String, dynamic> json) {
    return SelectedProgram(
      name: json['name'] ?? '',
      faculty: json['faculty'] ?? '',
      durationYears: json['durationYears'] ?? 0,
    );
  }
}

class UploadedDocument {
  final String type;
  final String fileName;
  final String url;
  final DateTime uploadedAt;

  const UploadedDocument({
    required this.type,
    required this.fileName,
    required this.url,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'fileName': fileName,
    'url': url,
    'uploadedAt': uploadedAt.toIso8601String(),
  };

  factory UploadedDocument.fromJson(Map<String, dynamic> json) {
    return UploadedDocument(
      type: json['type'],
      fileName: json['fileName'],
      url: json['url'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
    );
  }
}

class PaymentInfo {
  final bool isPaid;
  final double amount;
  final String? reference;
  final String? method;
  final DateTime? paidAt;

  const PaymentInfo({
    this.isPaid = false,
    this.amount = 0.0,
    this.reference,
    this.method,
    this.paidAt,
  });

  PaymentInfo copyWith({
    bool? isPaid,
    double? amount,
    String? reference,
    String? method,
    DateTime? paidAt,
  }) {
    return PaymentInfo(
      isPaid: isPaid ?? this.isPaid,
      amount: amount ?? this.amount,
      reference: reference ?? this.reference,
      method: method ?? this.method,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'isPaid': isPaid,
    'amount': amount,
    'reference': reference,
    'method': method,
    'paidAt': paidAt?.toIso8601String(),
  };

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      isPaid: json['isPaid'] ?? false,
      amount: (json['amount'] ?? 0.0).toDouble(),
      reference: json['reference'],
      method: json['method'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }
}

class ApplicationFormState {
  final String ownerUserId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String dob;
  final String country;
  final String nationalId;
  final String kinName;
  final String kinPhone;
  final String hobbies;
  final List<Map<String, String>> academicHistory;
  final SelectedProgram selectedProgram;
  final List<UploadedDocument> documents;
  final PaymentInfo paymentInfo;

  const ApplicationFormState({
    this.ownerUserId = '',
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.dob = '',
    this.country = 'Zimbabwe',
    this.nationalId = '',
    this.kinName = '',
    this.kinPhone = '',
    this.hobbies = '',
    this.academicHistory = const [],
    this.selectedProgram = const SelectedProgram(),
    this.documents = const [],
    this.paymentInfo = const PaymentInfo(),
  });

  String get fullName {
    final parts = [firstName, middleName, lastName].where((s) => s.isNotEmpty);
    return parts.isEmpty ? '' : parts.join(' ');
  }

  ApplicationFormState copyWith({
    String? ownerUserId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phone,
    String? dob,
    String? country,
    String? nationalId,
    String? kinName,
    String? kinPhone,
    String? hobbies,
    List<Map<String, String>>? academicHistory,
    SelectedProgram? selectedProgram,
    List<UploadedDocument>? documents,
    PaymentInfo? paymentInfo,
  }) {
    return ApplicationFormState(
      ownerUserId: ownerUserId ?? this.ownerUserId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      country: country ?? this.country,
      nationalId: nationalId ?? this.nationalId,
      kinName: kinName ?? this.kinName,
      kinPhone: kinPhone ?? this.kinPhone,
      hobbies: hobbies ?? this.hobbies,
      academicHistory: academicHistory ?? this.academicHistory,
      selectedProgram: selectedProgram ?? this.selectedProgram,
      documents: documents ?? this.documents,
      paymentInfo: paymentInfo ?? this.paymentInfo,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUserId': ownerUserId,
    'firstName': firstName,
    'middleName': middleName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'dob': dob,
    'country': country,
    'nationalId': nationalId,
    'kinName': kinName,
    'kinPhone': kinPhone,
    'hobbies': hobbies,
    'academicHistory': academicHistory,
    'selectedProgram': selectedProgram.toJson(),
    'documents': documents.map((d) => d.toJson()).toList(),
    'paymentInfo': paymentInfo.toJson(),
  };

  factory ApplicationFormState.fromJson(Map<String, dynamic> json) {
    return ApplicationFormState(
      ownerUserId: json['ownerUserId'] ?? '',
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      dob: json['dob'] ?? '',
      country: json['country'] ?? 'Zimbabwe',
      nationalId: json['nationalId'] ?? '',
      kinName: json['kinName'] ?? '',
      kinPhone: json['kinPhone'] ?? '',
      hobbies: json['hobbies'] ?? '',
      academicHistory: List<Map<String, String>>.from(
        (json['academicHistory'] ?? []).map((e) => Map<String, String>.from(e)),
      ),
      selectedProgram: json['selectedProgram'] != null
          ? SelectedProgram.fromJson(json['selectedProgram'])
          : const SelectedProgram(),
      documents: (json['documents'] ?? [])
          .map<UploadedDocument>((d) => UploadedDocument.fromJson(d))
          .toList(),
      paymentInfo: json['paymentInfo'] != null
          ? PaymentInfo.fromJson(json['paymentInfo'])
          : const PaymentInfo(),
    );
  }
}

// StateNotifier for managing the application form state
class ApplicationFormNotifier extends StateNotifier<ApplicationFormState> {
  ApplicationFormNotifier() : super(const ApplicationFormState());

  void resetForUser(String userId) {
    state = ApplicationFormState(ownerUserId: userId);
  }

  // Personal info updates
  void updatePersonalInfo({
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phone,
    String? dob,
    String? country,
    String? nationalId,
    String? kinName,
    String? kinPhone,
    String? hobbies,
  }) {
    state = state.copyWith(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      phone: phone,
      dob: dob,
      country: country,
      nationalId: nationalId,
      kinName: kinName,
      kinPhone: kinPhone,
      hobbies: hobbies,
    );
  }

  void updateAcademicHistory(List<Map<String, String>> academicHistory) {
    state = state.copyWith(academicHistory: academicHistory);
  }

  // Program selection
  void updateSelectedProgram(SelectedProgram program) {
    state = state.copyWith(selectedProgram: program);
  }

  // Documents
  void addDocument(UploadedDocument document) {
    state = state.copyWith(
      documents: [...state.documents, document],
    );
  }

  void updateDocuments(List<UploadedDocument> documents) {
    state = state.copyWith(documents: documents);
  }

  void removeDocument(String type) {
    state = state.copyWith(
      documents: state.documents.where((d) => d.type != type).toList(),
    );
  }

  // Payment
  void updatePaymentInfo(PaymentInfo paymentInfo) {
    state = state.copyWith(paymentInfo: paymentInfo);
  }

  // Reset
  void reset() {
    state = const ApplicationFormState();
  }

  // Load from JSON (for persistence)
  void loadFromJson(Map<String, dynamic> json) {
    state = ApplicationFormState.fromJson(json);
  }
}

// Provider for the application form state
final applicationFormProvider = StateNotifierProvider<ApplicationFormNotifier, ApplicationFormState>(
  (ref) => ApplicationFormNotifier(),
);