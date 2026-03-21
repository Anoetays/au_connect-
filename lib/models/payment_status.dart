import 'package:flutter/material.dart';

enum PaymentStatus {
  unpaid,
  paid,
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.paid:
        return 'Paid';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.unpaid:
        return Colors.red;
      case PaymentStatus.paid:
        return Colors.green;
    }
  }
}

enum PaymentMethodType {
  ecoCash,
  visaCard,
  flutterwave,
}

class PaymentRecord {
  final String txRef;
  final PaymentMethodType method;
  final double amount;
  PaymentStatus status;
  final DateTime createdAt;
  String? note;

  PaymentRecord({
    required this.txRef,
    required this.method,
    required this.amount,
    this.status = PaymentStatus.unpaid,
    DateTime? createdAt,
    this.note,
  }) : createdAt = createdAt ?? DateTime.now();
}

class PaymentData {
  static const double applicationFeeAmount = 25.0;
  static PaymentStatus applicationFeeStatus = PaymentStatus.unpaid; // This would come from backend
  static final List<PaymentRecord> paymentHistory = [];

  static void updatePaymentStatus(PaymentStatus newStatus) {
    applicationFeeStatus = newStatus;
    // In a real app, this would update the backend
    // Also trigger notification logic here
  }

  static void addPaymentRecord(PaymentRecord record) {
    paymentHistory.insert(0, record);
  }

  static void updatePaymentRecordStatus(String txRef, PaymentStatus status, {String? note}) {
    final index = paymentHistory.indexWhere((r) => r.txRef == txRef);
    if (index == -1) return;

    paymentHistory[index].status = status;
    if (note != null) {
      paymentHistory[index].note = note;
    }
  }
}