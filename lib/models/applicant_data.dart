import 'package:au_connect/models/school_record.dart';
import 'package:au_connect/models/visa_status.dart';

export 'package:au_connect/models/visa_status.dart';

class ApplicantData {
  bool hasUploadedTranscript;
  bool hasSubmittedEnglishScores;
  bool hasSubmittedPersonalStatement;
  bool hasUploadedPassport;
  bool hasUploadedVisaDocuments;
  VisaStatus visaStatus;
  DateTime? arrivalDate;
  bool airportPickupRequested;
  List<SchoolRecord> educationHistoryRecords;

  ApplicantData({
    this.hasUploadedTranscript = false,
    this.hasSubmittedEnglishScores = false,
    this.hasSubmittedPersonalStatement = true,
    this.hasUploadedPassport = false,
    this.hasUploadedVisaDocuments = false,
    this.visaStatus = VisaStatus.notStarted,
    this.arrivalDate,
    this.airportPickupRequested = false,
    List<SchoolRecord>? educationHistoryRecords,
  }) : educationHistoryRecords = educationHistoryRecords ?? [];

  Map<String, dynamic> toJson() => {
    'hasUploadedTranscript': hasUploadedTranscript,
    'hasSubmittedEnglishScores': hasSubmittedEnglishScores,
    'hasSubmittedPersonalStatement': hasSubmittedPersonalStatement,
    'hasUploadedPassport': hasUploadedPassport,
    'hasUploadedVisaDocuments': hasUploadedVisaDocuments,
    'visaStatus': visaStatus.index,
    'arrivalDate': arrivalDate?.toIso8601String(),
    'airportPickupRequested': airportPickupRequested,
    'educationHistoryRecords': educationHistoryRecords.map((r) => r.toJson()).toList(),
  };

  factory ApplicantData.fromJson(Map<String, dynamic> json) => ApplicantData(
    hasUploadedTranscript: json['hasUploadedTranscript'] ?? false,
    hasSubmittedEnglishScores: json['hasSubmittedEnglishScores'] ?? false,
    hasSubmittedPersonalStatement: json['hasSubmittedPersonalStatement'] ?? true,
    hasUploadedPassport: json['hasUploadedPassport'] ?? false,
    hasUploadedVisaDocuments: json['hasUploadedVisaDocuments'] ?? false,
    visaStatus: VisaStatus.values[json['visaStatus'] ?? 0],
    arrivalDate: json['arrivalDate'] != null ? DateTime.parse(json['arrivalDate']) : null,
    airportPickupRequested: json['airportPickupRequested'] ?? false,
    educationHistoryRecords: (json['educationHistoryRecords'] as List<dynamic>?)
        ?.map((r) => SchoolRecord.fromJson(r))
        .toList() ?? [],
  );

  ApplicantData copyWith({
    bool? hasUploadedTranscript,
    bool? hasSubmittedEnglishScores,
    bool? hasSubmittedPersonalStatement,
    bool? hasUploadedPassport,
    bool? hasUploadedVisaDocuments,
    VisaStatus? visaStatus,
    DateTime? arrivalDate,
    bool? airportPickupRequested,
    List<SchoolRecord>? educationHistoryRecords,
  }) {
    return ApplicantData(
      hasUploadedTranscript: hasUploadedTranscript ?? this.hasUploadedTranscript,
      hasSubmittedEnglishScores: hasSubmittedEnglishScores ?? this.hasSubmittedEnglishScores,
      hasSubmittedPersonalStatement: hasSubmittedPersonalStatement ?? this.hasSubmittedPersonalStatement,
      hasUploadedPassport: hasUploadedPassport ?? this.hasUploadedPassport,
      hasUploadedVisaDocuments: hasUploadedVisaDocuments ?? this.hasUploadedVisaDocuments,
      visaStatus: visaStatus ?? this.visaStatus,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      airportPickupRequested: airportPickupRequested ?? this.airportPickupRequested,
      educationHistoryRecords: educationHistoryRecords ?? this.educationHistoryRecords,
    );
  }
}
