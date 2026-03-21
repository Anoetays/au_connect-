import 'dart:convert';

import 'package:http/http.dart' as http;

/// A simple helper for creating Flutterwave checkout sessions.
///
/// NOTE: You must configure your Flutterwave secret key below before using.
/// For the best security, do not hard-code secrets in source; use a secure
/// secrets store or environment configuration in production.
class FlutterwaveService {
  /// Replace this with your Flutterwave Secret Key (sk_live_... or sk_test_...)
  ///
  /// Important: Do not commit real secrets to source control.
  static const secretKey = 'YOUR_FLUTTERWAVE_SECRET_KEY';

  /// The URL that Flutterwave will redirect the user to after payment.
  /// Update this to a page that can handle the callback in your app/server.
  static const redirectUrl = 'https://example.com/flutterwave-callback';

  /// Initiates a Flutterwave checkout and returns the payment link.
  ///
  /// Returns a [FlutterwaveResponse] with details required to redirect the user.
  Future<FlutterwaveResponse> createCheckout({
    required String txRef,
    required double amount,
    required String currency,
    required String customerEmail,
    required String customerName,
  }) async {
    final uri = Uri.parse('https://api.flutterwave.com/v3/payments');

    final payload = {
      'tx_ref': txRef,
      'amount': amount.toStringAsFixed(2),
      'currency': currency,
      'redirect_url': redirectUrl,
      'customer': {
        'email': customerEmail,
        'name': customerName,
      },
      'customizations': {
        'title': 'Application Fee',
        'description': 'Application fee payment',
      },
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $secretKey',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      return FlutterwaveResponse(
        success: false,
        message: 'Unexpected HTTP status: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final status = decoded['status'] as String?;
    final data = decoded['data'] as Map<String, dynamic>?;

    if (status == 'success' && data != null) {
      return FlutterwaveResponse(
        success: true,
        message: decoded['message'] as String? ?? 'Success',
        checkoutUrl: data['link'] as String?,
      );
    }

    return FlutterwaveResponse(
      success: false,
      message: decoded['message'] as String? ?? 'Unknown error',
    );
  }

  /// Verifies the status of a Flutterwave transaction by reference.
  ///
  /// Returns a [FlutterwaveVerificationResponse] where `success` indicates
  /// whether the payment completed successfully.
  Future<FlutterwaveVerificationResponse> verifyTransaction({
    required String txRef,
  }) async {
    final uri = Uri.parse('https://api.flutterwave.com/v3/transactions/verify_by_reference?tx_ref=$txRef');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $secretKey',
      },
    );

    if (response.statusCode != 200) {
      return FlutterwaveVerificationResponse(
        success: false,
        status: 'unknown',
        message: 'Unexpected HTTP status: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final status = decoded['status'] as String?;
    final data = decoded['data'] as Map<String, dynamic>?;

    final transactionStatus = data?['status'] as String?;

    return FlutterwaveVerificationResponse(
      success: transactionStatus == 'successful',
      status: transactionStatus,
      message: decoded['message'] as String? ?? status,
    );
  }
}

class FlutterwaveResponse {
  final bool success;
  final String? message;
  final String? checkoutUrl;

  FlutterwaveResponse({
    required this.success,
    this.message,
    this.checkoutUrl,
  });
}

class FlutterwaveVerificationResponse {
  final bool success;
  final String? status;
  final String? message;

  FlutterwaveVerificationResponse({
    required this.success,
    this.status,
    this.message,
  });
}
