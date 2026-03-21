class TransferData {
  int creditsTransferred;
  int creditsRemaining;
  int eligiblePrograms;
  int uploadedDocuments;
  int totalDocuments;
  TransferStage currentStage;
  List<String> notifications;
  List<String> smartInsights;

  TransferData({
    this.creditsTransferred = 24,
    this.creditsRemaining = 36,
    this.eligiblePrograms = 3,
    this.uploadedDocuments = 2,
    this.totalDocuments = 4,
    this.currentStage = TransferStage.creditEvaluation,
    List<String>? notifications,
    List<String>? smartInsights,
  }) : 
    notifications = notifications ?? [
      'Your transcript evaluation is in progress.',
      'New message from your transfer advisor.',
      'Additional documents required for credit evaluation.',
    ],
    smartInsights = smartInsights ?? [
      'You qualify for Year 2 entry',
      'Estimated graduation time: 2.5 years',
      'Missing requirement: Calculus I',
    ];

  Map<String, dynamic> toJson() => {
    'creditsTransferred': creditsTransferred,
    'creditsRemaining': creditsRemaining,
    'eligiblePrograms': eligiblePrograms,
    'uploadedDocuments': uploadedDocuments,
    'totalDocuments': totalDocuments,
    'currentStage': currentStage.index,
    'notifications': notifications,
    'smartInsights': smartInsights,
  };

  factory TransferData.fromJson(Map<String, dynamic> json) => TransferData(
    creditsTransferred: json['creditsTransferred'] ?? 24,
    creditsRemaining: json['creditsRemaining'] ?? 36,
    eligiblePrograms: json['eligiblePrograms'] ?? 3,
    uploadedDocuments: json['uploadedDocuments'] ?? 2,
    totalDocuments: json['totalDocuments'] ?? 4,
    currentStage: TransferStage.values[json['currentStage'] ?? 2],
    notifications: List<String>.from(json['notifications'] ?? []),
    smartInsights: List<String>.from(json['smartInsights'] ?? []),
  );

  TransferData copyWith({
    int? creditsTransferred,
    int? creditsRemaining,
    int? eligiblePrograms,
    int? uploadedDocuments,
    int? totalDocuments,
    TransferStage? currentStage,
    List<String>? notifications,
    List<String>? smartInsights,
  }) {
    return TransferData(
      creditsTransferred: creditsTransferred ?? this.creditsTransferred,
      creditsRemaining: creditsRemaining ?? this.creditsRemaining,
      eligiblePrograms: eligiblePrograms ?? this.eligiblePrograms,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      currentStage: currentStage ?? this.currentStage,
      notifications: notifications ?? this.notifications,
      smartInsights: smartInsights ?? this.smartInsights,
    );
  }
}

enum TransferStage {
  submitted,
  underReview,
  creditEvaluation,
  approved,
  admitted,
}