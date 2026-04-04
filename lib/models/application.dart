class Application {
  final String id;
  final String applicantId;
  final String applicantName;
  final String email;
  final String type;
  final String programme;
  final String faculty;
  final String nationality;
  final String phone;
  final String status;
  final String? notes;
  final bool applicationFeePaid;
  final DateTime? submittedAt;
  final DateTime? createdAt;

  const Application({
    this.id = '',
    this.applicantId = '',
    this.applicantName = '',
    this.email = '',
    this.type = '',
    this.programme = '',
    this.faculty = '',
    this.nationality = '',
    this.phone = '',
    this.status = 'draft',
    this.notes,
    this.applicationFeePaid = false,
    this.submittedAt,
    this.createdAt,
  });

 factory Application.fromJson(Map<String, dynamic> json) {
  final dynamic notesJson = json['notes'];

  return Application(
    id: json['id']?.toString() ?? '',
    applicantId: json['applicant_id']?.toString() ?? '',
    applicantName: json['applicant_name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
    programme: json['programme']?.toString() ?? '',
    faculty: json['faculty']?.toString() ?? '',
    nationality: json['nationality']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    status: json['status']?.toString() ?? 'draft',
    notes: notesJson == null ? null : notesJson.toString(),

    // handle bool that may come back as bool OR 0/1 int
    applicationFeePaid: (() {
      final v = json['application_fee_paid'];
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v.toLowerCase() == 'true' || v == '1';
      return false;
    })(),

    submittedAt: json['submitted_at'] != null
        ? DateTime.tryParse(json['submitted_at'].toString())
        : null,

    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
  );
}
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicant_id': applicantId,
      'applicant_name': applicantName,
      'email': email,
      'type': type,
      'programme': programme,
      'faculty': faculty,
      'nationality': nationality,
      'phone': phone,
      'status': status,
      'notes': notes,
      'application_fee_paid': applicationFeePaid,
      if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  bool get isSubmitted => status.toLowerCase() != 'draft';
}
