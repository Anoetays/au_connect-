import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class PaynowConfig {
  /// https://www.paynow.co.zw/ for production
  /// https://www.paynow.co.zw/ for sandbox (same endpoint - use test credentials)
  static const baseUrl = 'https://www.paynow.co.zw/';

  /// Your Paynow integration details. Replace with real values.
  static const paynowId = 'YOUR_PAYNOW_ID';
  static const integrationKey = 'YOUR_INTEGRATION_KEY';
}

class PaynowResponse {
  final String status;
  final String? pollUrl;
  final String? browserUrl;
  final String? error;

  PaynowResponse({
    required this.status,
    this.pollUrl,
    this.browserUrl,
    this.error,
  });

  factory PaynowResponse.fromMap(Map<String, dynamic> map) {
    return PaynowResponse(
      status: map['status'] as String? ?? '',
      pollUrl: map['pollUrl'] as String?,
      browserUrl: map['browserUrl'] as String?,
      error: map['error'] as String?,
    );
  }
}

class PaynowService {
  /// Initiates an EcoCash payment via Paynow.
  ///
  /// Returns a [PaynowResponse] containing the pollUrl and browserUrl that can be used to
  /// check or redirect to the payment status.
  Future<PaynowResponse> initiateEcoCashPayment({
    required String reference,
    required double amount,
    required String phoneNumber,
  }) async {
    // Paynow expects amount as a string with 2 decimal places.
    final amountStr = amount.toStringAsFixed(2);

    final hashInput = '${PaynowConfig.paynowId}$reference$amountStr${PaynowConfig.integrationKey}';
    final hash = md5.convert(utf8.encode(hashInput)).toString();

    final uri = Uri.parse('${PaynowConfig.baseUrl}Interface/InitiateTransaction');
    final payload = {
      'paynowId': PaynowConfig.paynowId,
      'reference': reference,
      'amount': amountStr,
      'id': reference,
      'additionalInfo': 'ecocash',
      'returnUrl': 'https://example.com/return',
      'resultUrl': 'https://example.com/result',
      'transactionDate': DateTime.now().toIso8601String(),
      'mobile': phoneNumber,
      'hash': hash,
    };

    final response = await http.post(uri, body: payload);

    if (response.statusCode != 200) {
      return PaynowResponse(status: 'ERROR', error: 'HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return PaynowResponse.fromMap(json);
  }
}
