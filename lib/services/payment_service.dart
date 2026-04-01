import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Change this to your production URL when deploying.
// Android emulators route 10.0.2.2 → the host machine's localhost.
String get _kBaseUrl {
  if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

class PaymentService {
  static String get baseUrl => _kBaseUrl;

  /// Initiates an EcoCash mobile payment.
  /// Returns `{success: true, pollUrl: "..."}` or `{success: false, error: "..."}`.
  static Future<Map<String, dynamic>> initiateEcoCash({
    required String phone,
    required double amount,
    required String email,
    required String reference,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/pay'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': phone,
              'amount': amount,
              'email': email,
              'reference': reference,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'pollUrl': body['pollUrl'] as String};
      }
      return {
        'success': false,
        'error': body['error'] as String? ?? 'Payment initiation failed',
      };
    } catch (_) {
      return {
        'success': false,
        'error': 'Could not reach the payment server. Check your connection.',
      };
    }
  }

  /// Polls Paynow for transaction status.
  /// Returns `{success: true, paid: bool, status: "..."}` or `{success: false, error: "..."}`.
  static Future<Map<String, dynamic>> pollTransaction(String pollUrl) async {
    try {
      final uri = Uri.parse('$baseUrl/api/poll')
          .replace(queryParameters: {'url': pollUrl});
      final res =
          await http.get(uri).timeout(const Duration(seconds: 15));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        return {
          'success': true,
          'paid': body['paid'] ?? false,
          'status': body['status'] ?? '',
        };
      }
      return {
        'success': false,
        'error': body['error'] as String? ?? 'Poll failed',
      };
    } catch (_) {
      return {'success': false, 'error': 'Poll request failed'};
    }
  }
}
