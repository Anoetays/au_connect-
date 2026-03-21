/// Represents a single academic record (school/college/university) in a student's history.
///
/// This is shared across multiple screens and stored as part of the persistent
/// applicant dashboard state.

enum InstitutionType {
  highSchool,
  collegeUniversity,
  technicalVocational,
}

extension InstitutionTypeLabel on InstitutionType {
  String get label {
    switch (this) {
      case InstitutionType.highSchool:
        return 'High School / Secondary School';
      case InstitutionType.collegeUniversity:
        return 'College or University';
      case InstitutionType.technicalVocational:
        return 'Technical or Vocational School';
    }
  }
}

class SchoolRecord {
  final String schoolName;
  final String country;
  final InstitutionType institutionType;
  final String qualification;
  final String? fieldOfStudy;
  final DateTime startDate;
  final DateTime? endDate;
  final bool currentlyStudying;
  final String transcriptFilePath;

  SchoolRecord({
    required this.schoolName,
    required this.country,
    required this.institutionType,
    required this.qualification,
    this.fieldOfStudy,
    required this.startDate,
    this.endDate,
    required this.currentlyStudying,
    required this.transcriptFilePath,
  });

  bool get hasTranscript => transcriptFilePath.isNotEmpty;

  String get transcriptFileName {
    if (transcriptFilePath.isEmpty) return '';
    return Uri.file(transcriptFilePath).pathSegments.last;
  }

  Map<String, dynamic> toJson() => {
        'schoolName': schoolName,
        'country': country,
        'institutionType': institutionType.index,
        'qualification': qualification,
        'fieldOfStudy': fieldOfStudy,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'currentlyStudying': currentlyStudying,
        'transcriptFilePath': transcriptFilePath,
      };

  factory SchoolRecord.fromJson(Map<String, dynamic> json) => SchoolRecord(
        schoolName: json['schoolName'],
        country: json['country'],
        institutionType: InstitutionType.values[json['institutionType']],
        qualification: json['qualification'],
        fieldOfStudy: json['fieldOfStudy'],
        startDate: DateTime.parse(json['startDate']),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        currentlyStudying: json['currentlyStudying'],
        transcriptFilePath: json['transcriptFilePath'],
      );
}
