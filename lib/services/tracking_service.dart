import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

enum ApplicationStatus {
  submitted,
  underReview,
  documentVerification,
  approved,
  rejected,
  pending
}

enum DocumentStatus { pending, verified, rejected, resubmitRequired }

class TrackingUpdate {
  final String id;
  final String status;
  final String description;
  final DateTime timestamp;
  final String? staffMember;

  TrackingUpdate({
    required this.id,
    required this.status,
    required this.description,
    required this.timestamp,
    this.staffMember,
  });

  factory TrackingUpdate.fromJson(Map<String, dynamic> json) {
    return TrackingUpdate(
      id: json['id'],
      status: json['status'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      staffMember: json['staff_member'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'staff_member': staffMember,
    };
  }
}

class DocumentVerification {
  final String documentId;
  final String documentName;
  final DocumentStatus status;
  final DateTime uploadedDate;
  final DateTime? verifiedDate;
  final String? rejectionReason;

  DocumentVerification({
    required this.documentId,
    required this.documentName,
    required this.status,
    required this.uploadedDate,
    this.verifiedDate,
    this.rejectionReason,
  });

  factory DocumentVerification.fromJson(Map<String, dynamic> json) {
    return DocumentVerification(
      documentId: json['document_id'],
      documentName: json['document_name'],
      status: DocumentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      uploadedDate: DateTime.parse(json['uploaded_date']),
      verifiedDate: json['verified_date'] != null
          ? DateTime.parse(json['verified_date'])
          : null,
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document_id': documentId,
      'document_name': documentName,
      'status': status.toString().split('.').last,
      'uploaded_date': uploadedDate.toIso8601String(),
      'verified_date': verifiedDate?.toIso8601String(),
      'rejection_reason': rejectionReason,
    };
  }
}

class ApplicationTrackingData {
  final String applicationId;
  final String applicationName;
  final ApplicationStatus status;
  final double progressPercentage;
  final DateTime submittedDate;
  final DateTime? estimatedDecisionDate;
  final List<TrackingUpdate> updates;
  final List<DocumentVerification> documents;

  ApplicationTrackingData({
    required this.applicationId,
    required this.applicationName,
    required this.status,
    required this.progressPercentage,
    required this.submittedDate,
    this.estimatedDecisionDate,
    required this.updates,
    required this.documents,
  });

  factory ApplicationTrackingData.fromJson(Map<String, dynamic> json) {
    return ApplicationTrackingData(
      applicationId: json['application_id'],
      applicationName: json['application_name'],
      status: ApplicationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      progressPercentage: json['progress_percentage'].toDouble(),
      submittedDate: DateTime.parse(json['submitted_date']),
      estimatedDecisionDate: json['estimated_decision_date'] != null
          ? DateTime.parse(json['estimated_decision_date'])
          : null,
      updates: (json['updates'] as List)
          .map((u) => TrackingUpdate.fromJson(u))
          .toList(),
      documents: (json['documents'] as List)
          .map((d) => DocumentVerification.fromJson(d))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'application_id': applicationId,
      'application_name': applicationName,
      'status': status.toString().split('.').last,
      'progress_percentage': progressPercentage,
      'submitted_date': submittedDate.toIso8601String(),
      'estimated_decision_date': estimatedDecisionDate?.toIso8601String(),
      'updates': updates.map((u) => u.toJson()).toList(),
      'documents': documents.map((d) => d.toJson()).toList(),
    };
  }
}

class TrackingService {
  static const String _baseUrl = 'https://your-api.com';
  static final TrackingService _instance = TrackingService._internal();

  Timer? _refreshTimer;
  final Duration _refreshInterval = const Duration(seconds: 30);

  final Map<String, ApplicationTrackingData> _trackingCache = {};
  final Map<String, StreamController<ApplicationTrackingData>>
      _trackingStreamControllers = {};

  TrackingService._internal();

  factory TrackingService() {
    return _instance;
  }

  /// Get stream for real-time tracking updates
  Stream<ApplicationTrackingData> getTrackingStream(String applicationId) {
    if (!_trackingStreamControllers.containsKey(applicationId)) {
      _trackingStreamControllers[applicationId] =
          StreamController<ApplicationTrackingData>.broadcast();
      _startAutoRefresh(applicationId);
    }
    return _trackingStreamControllers[applicationId]!.stream;
  }

  /// Fetch application tracking data
  Future<ApplicationTrackingData?> fetchApplicationStatus(
      String applicationId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/applications/$applicationId/tracking'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = ApplicationTrackingData.fromJson(
          jsonDecode(response.body),
        );
        _trackingCache[applicationId] = data;
        _updateStream(applicationId, data);
        return data;
      }
    } catch (e) {
      debugPrint('Error fetching application status: $e');
    }
    return null;
  }

  /// Get cached tracking data
  ApplicationTrackingData? getCachedTrackingData(String applicationId) {
    return _trackingCache[applicationId];
  }

  /// Start auto-refresh for application tracking
  void _startAutoRefresh(String applicationId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) async {
      await fetchApplicationStatus(applicationId);
    });
  }

  /// Update tracking stream
  void _updateStream(String applicationId, ApplicationTrackingData data) {
    if (_trackingStreamControllers.containsKey(applicationId)) {
      if (!_trackingStreamControllers[applicationId]!.isClosed) {
        _trackingStreamControllers[applicationId]?.add(data);
      }
    }
  }

  /// Get status color for UI display
  static Color getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.submitted:
        return Colors.blue;
      case ApplicationStatus.underReview:
        return Colors.orange;
      case ApplicationStatus.documentVerification:
        return Colors.amber;
      case ApplicationStatus.approved:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
      case ApplicationStatus.pending:
        return Colors.grey;
    }
  }

  /// Get status label
  static String getStatusLabel(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.submitted:
        return 'Submitted';
      case ApplicationStatus.underReview:
        return 'Under Review';
      case ApplicationStatus.documentVerification:
        return 'Verifying Documents';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.pending:
        return 'Pending';
    }
  }

  /// Get estimated days until decision
  int? getDaysUntilDecision(ApplicationTrackingData data) {
    if (data.estimatedDecisionDate == null) return null;
    return data.estimatedDecisionDate!.difference(DateTime.now()).inDays;
  }

  /// Dispose streams
  void dispose() {
    _refreshTimer?.cancel();
    for (var controller in _trackingStreamControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _trackingStreamControllers.clear();
  }
}
