class Document {
  final String id;
  final String applicationId;
  final String userId;
  final String documentType;
  final String fileName;
  final String? fileUrl;
  final String verificationStatus;
  final bool verified;
  final DateTime? uploadedAt;

  const Document({
    this.id = '',
    this.applicationId = '',
    this.userId = '',
    this.documentType = '',
    this.fileName = '',
    this.fileUrl,
    this.verificationStatus = 'pending_review',
    this.verified = false,
    this.uploadedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String? ?? '',
      applicationId: json['application_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      documentType: json['document_type'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      fileUrl: json['file_url'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'pending_review',
      verified: json['verified'] as bool? ?? false,
      uploadedAt: json['uploaded_at'] != null ? DateTime.tryParse(json['uploaded_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'application_id': applicationId,
      'user_id': userId,
      'document_type': documentType,
      'file_name': fileName,
      'file_url': fileUrl,
      'verification_status': verificationStatus,
      'verified': verified,
      if (uploadedAt != null) 'uploaded_at': uploadedAt!.toIso8601String(),
    };
  }
}
