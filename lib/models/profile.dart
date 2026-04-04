class Profile {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String applicantType;
  final String countryOfOrigin;
  final String countryOfResidence;
  final String nationalId;
  final String kinName;
  final String kinPhone;
  final String hobbies;
  final String firstName;
  final String middleName;
  final String lastName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Profile({
    this.userId = '',
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.applicantType = 'Local',
    this.countryOfOrigin = '',
    this.countryOfResidence = '',
    this.nationalId = '',
    this.kinName = '',
    this.kinPhone = '',
    this.hobbies = '',
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.createdAt,
    this.updatedAt,
  });

  Profile copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    String? applicantType,
    String? countryOfOrigin,
    String? countryOfResidence,
    String? nationalId,
    String? kinName,
    String? kinPhone,
    String? hobbies,
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      applicantType: applicantType ?? this.applicantType,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      countryOfResidence: countryOfResidence ?? this.countryOfResidence,
      nationalId: nationalId ?? this.nationalId,
      kinName: kinName ?? this.kinName,
      kinPhone: kinPhone ?? this.kinPhone,
      hobbies: hobbies ?? this.hobbies,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] as String? ?? json['firstName'] as String? ?? '';
    final middleName = json['middle_name'] as String? ?? json['middleName'] as String? ?? '';
    final lastName = json['last_name'] as String? ?? json['lastName'] as String? ?? '';
    final fullName = json['full_name'] as String? ?? json['fullName'] as String? ?? [firstName, middleName, lastName].where((v) => v.trim().isNotEmpty).join(' ');

    return Profile(
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      fullName: fullName,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      applicantType: json['applicant_type'] as String? ?? json['applicantType'] as String? ?? 'Local',
      countryOfOrigin: json['country_of_origin'] as String? ?? json['countryOfOrigin'] as String? ?? '',
      countryOfResidence: json['country_of_residence'] as String? ?? json['countryOfResidence'] as String? ?? '',
      nationalId: json['national_id'] as String? ?? json['nationalId'] as String? ?? '',
      kinName: json['kin_name'] as String? ?? json['kinName'] as String? ?? '',
      kinPhone: json['kin_phone'] as String? ?? json['kinPhone'] as String? ?? '',
      hobbies: json['hobbies'] as String? ?? '',
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'applicant_type': applicantType,
      'country_of_origin': countryOfOrigin,
      'country_of_residence': countryOfResidence,
      'national_id': nationalId,
      'kin_name': kinName,
      'kin_phone': kinPhone,
      'hobbies': hobbies,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  bool get isComplete =>
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      applicantType.trim().isNotEmpty &&
      countryOfOrigin.trim().isNotEmpty &&
      countryOfResidence.trim().isNotEmpty &&
      nationalId.trim().isNotEmpty &&
      kinName.trim().isNotEmpty &&
      kinPhone.trim().isNotEmpty &&
      hobbies.trim().isNotEmpty;
}
