import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  // NOTE: This is a stub for Safaricom Daraja (M-Pesa) STK Push integration.
  // For real integration, set the consumerKey/secret and implement OAuth token exchange.

  static const String _darajaBase = 'https://sandbox.safaricom.co.ke';
  // Provide your Daraja credentials via environment or secure storage
  static String consumerKey = '';
  static String consumerSecret = '';

  // Simulate obtaining OAuth token (in production, use real credentials)
  static Future<String?> getAccessToken() async {
    if (consumerKey.isEmpty || consumerSecret.isEmpty) return null;
    final credential = base64Encode(utf8.encode('\$consumerKey:\$consumerSecret'));
    final url = Uri.parse('\$_darajaBase/oauth/v1/generate?grant_type=client_credentials');
    final resp = await http.get(url, headers: {'Authorization': 'Basic '
      '\$credential'});
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body);
      return json['access_token'];
    }
    return null;
  }

  // Initiate STK Push - NOTE: this is a simulated call for demo/testing purposes
  static Future<Map<String, dynamic>> initiateMpesaStkPush({
    required String phone,
    required double amount,
    required String accountReference,
    String callbackUrl = 'https://example.com/mpesa/callback',
  }) async {
    // In production: use getAccessToken() and call /mpesa/stkpush/v1/processrequest
    await Future.delayed(const Duration(seconds: 1));
    // Return a simulated response
    return {
      'status': 'success',
      'merchantRequestId': DateTime.now().millisecondsSinceEpoch.toString(),
      'checkoutRequestId': 'CHK' + DateTime.now().millisecondsSinceEpoch.toString(),
      'amount': amount,
      'phone': phone,
    };
  }

  // Verify transaction - simulated
  static Future<bool> verifyTransaction(String checkoutRequestId) async {
    await Future.delayed(const Duration(seconds: 1));
    // In sandbox, assume success
    return true;
  }
}
