import 'dart:async';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';

/// M-Pesa Payment Service - Simulates Safaricom M-Pesa payment flow
class MpesaService {
  static final _supabase = SupabaseService.client;
  static final Map<String, Timer> _paymentTimers = {};
  static final Map<String, String> _pendingPayments = {};
  static const int _simulationDelaySeconds = 6;

  /// Initiate M-Pesa payment (simulated)
  static Future<Map<String, dynamic>> initiatePayment({
    required String bookingId,
    required String phoneNumber,
    required double amount,
  }) async {
    try {
      // Validate phone number format (Kenyan format)
      if (!_isValidKenyanPhone(phoneNumber)) {
        throw Exception('Invalid phone number. Use format: 254XXXXXXXXX');
      }

      // Generate local transaction ID (will be replaced by STK response if present)
      final localTransactionId = 'MPX${DateTime.now().millisecondsSinceEpoch}';

      // Create payment record
      final paymentData = {
        'booking_id': bookingId,
        'amount': amount,
        'payment_method': 'M-Pesa',
        'payment_status': 'Pending',
        'mpesa_transaction_id': localTransactionId,
        'mpesa_phone_number': phoneNumber,
        'payment_timeout_at': DateTime.now()
            .add(const Duration(minutes: 5))
            .toIso8601String(),
      };

      final response = await _supabase
          .from('Payments')
          .insert(paymentData)
          .select()
          .single();

      // Update booking with payment initiation time and timeout
      await _supabase
          .from('Bookings')
          .update({
            'payment_initiated_at': DateTime.now().toIso8601String(),
            'payment_timeout_at': DateTime.now()
                .add(const Duration(minutes: 5))
                .toIso8601String(),
          })
          .eq('id', bookingId);

      // Call Supabase Edge Function to initiate real STK Push (sandbox)
      final functionResponse = await _supabase.functions.invoke(
        'mpesa-stk-push',
        body: {
          'amount': amount,
          'phoneNumber': phoneNumber,
          'accountReference': bookingId,
          'transactionDesc': 'Urban Go ride payment',
        },
      );

      if (functionResponse.status != 200) {
        throw Exception(functionResponse.data?['error'] ?? 'STK push failed');
      }

      final checkoutRequestId = functionResponse.data?['CheckoutRequestID'];
      final transactionId = (checkoutRequestId ?? localTransactionId).toString();

      // Update payment record with actual transaction ID from STK response
      await _supabase
          .from('Payments')
          .update({'mpesa_transaction_id': transactionId})
          .eq('id', response['id']);

      // Store pending payment
      _pendingPayments[transactionId] = bookingId;

      // Start 5-minute timeout timer
      _startPaymentTimeout(transactionId, bookingId, response['id']);

      // Simulate callback after a short delay (sandbox)
      _scheduleSimulatedCallback(
        transactionId: transactionId,
        bookingId: bookingId,
        phoneNumber: phoneNumber,
        amount: amount,
      );

      return {
        'success': true,
        'transaction_id': transactionId,
        'payment_id': response['id'],
        'message':
            'Payment request sent to $phoneNumber. Please enter your M-Pesa PIN to complete.',
        'timeout_minutes': 5,
      };
    } catch (e) {
      debugPrint('M-Pesa initiation error: $e');
      return {
        'success': false,
        'message': 'Failed to initiate payment: ${e.toString()}',
      };
    }
  }

  /// Simulate M-Pesa payment confirmation (fallback PIN flow)
  static Future<Map<String, dynamic>> confirmPayment({
    required String transactionId,
    required String pin,
  }) async {
    try {
      // Validate PIN (simulated - just check length)
      if (pin.length != 4) {
        throw Exception('Invalid M-Pesa PIN');
      }

      // Check if payment exists and is pending
      final bookingId = _pendingPayments[transactionId];
      if (bookingId == null) {
        throw Exception('Payment not found or already processed');
      }

      // Get payment record
      final payment = await _supabase
          .from('Payments')
          .select()
          .eq('mpesa_transaction_id', transactionId)
          .single();

      if (payment['payment_status'] != 'Pending') {
        throw Exception('Payment already processed');
      }

      // Update payment status to completed
      await _supabase
          .from('Payments')
          .update({
            'payment_status': 'Completed',
            'transaction_date': DateTime.now().toIso8601String(),
          })
          .eq('id', payment['id']);

      // Update booking status to confirmed
      await _supabase
          .from('Bookings')
          .update({
            'status': 'Confirmed',
            'payment_completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);

      // Cancel timeout timer
      _cancelPaymentTimeout(transactionId);

      // Remove from pending
      _pendingPayments.remove(transactionId);

      return {
        'success': true,
        'message': 'Payment successful! Your booking is confirmed.',
        'booking_id': bookingId,
      };
    } catch (e) {
      debugPrint('M-Pesa confirmation error: $e');
      return {'success': false, 'message': 'Payment failed: ${e.toString()}'};
    }
  }

  /// Simulate M-Pesa callback via Edge Function
  static Future<void> simulatePaymentCallback({
    required String transactionId,
    required String bookingId,
    required String phoneNumber,
    required double amount,
  }) async {
    await _supabase.functions.invoke(
      'mpesa-stk-callback',
      body: {
        'transactionId': transactionId,
        'bookingId': bookingId,
        'phoneNumber': phoneNumber,
        'amount': amount,
      },
    );
  }

  /// Cancel booking and handle refund
  static Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
  }) async {
    try {
      // Get booking details
      final booking = await _supabase
          .from('Bookings')
          .select('*, Payments(*)')
          .eq('id', bookingId)
          .single();

      if (booking['status'] != 'Confirmed') {
        throw Exception('Only confirmed bookings can be cancelled');
      }

      // Update booking status to cancelled (triggers refund via database trigger)
      await _supabase
          .from('Bookings')
          .update({
            'status': 'Cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);

      return {
        'success': true,
        'message':
            'Booking cancelled successfully. Refund of Ksh ${booking['fare_amount']} has been added to your wallet.',
        'refund_amount': booking['fare_amount'],
      };
    } catch (e) {
      debugPrint('Booking cancellation error: $e');
      return {
        'success': false,
        'message': 'Failed to cancel booking: ${e.toString()}',
      };
    }
  }

  /// Get wallet balance
  static Future<double> getWalletBalance(String userId) async {
    try {
      final user = await _supabase
          .from('User')
          .select('wallet_balance')
          .eq('id', userId)
          .single();

      return (user['wallet_balance'] ?? 0.0).toDouble();
    } catch (e) {
      debugPrint('Error fetching wallet balance: $e');
      return 0.0;
    }
  }

  /// Get wallet transactions
  static Future<List<Map<String, dynamic>>> getWalletTransactions(
    String userId,
  ) async {
    try {
      final transactions = await _supabase
          .from('WalletTransactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(transactions);
    } catch (e) {
      debugPrint('Error fetching wallet transactions: $e');
      return [];
    }
  }

  /// Check payment status
  static Future<String> getPaymentStatus(String transactionId) async {
    try {
      final payment = await _supabase
          .from('Payments')
          .select('payment_status')
          .eq('mpesa_transaction_id', transactionId)
          .single();

      return payment['payment_status'] ?? 'Unknown';
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      return 'Unknown';
    }
  }

  /// Private: Start payment timeout timer
  static void _startPaymentTimeout(
    String transactionId,
    String bookingId,
    String paymentId,
  ) {
    _paymentTimers[transactionId] = Timer(const Duration(minutes: 5), () async {
      try {
        // Check if payment is still pending
        final status = await getPaymentStatus(transactionId);
        if (status == 'Pending') {
          // Update payment status to expired
          await _supabase
              .from('Payments')
              .update({'payment_status': 'Expired'})
              .eq('id', paymentId);

          // Update booking status to expired
          await _supabase
              .from('Bookings')
              .update({'status': 'Expired'})
              .eq('id', bookingId);

          // Remove from pending
          _pendingPayments.remove(transactionId);

          debugPrint('Payment timeout: $transactionId');
        }
      } catch (e) {
        debugPrint('Error handling payment timeout: $e');
      }
    });
  }

  static void _scheduleSimulatedCallback({
    required String transactionId,
    required String bookingId,
    required String phoneNumber,
    required double amount,
  }) {
    Timer(const Duration(seconds: _simulationDelaySeconds), () async {
      try {
        await simulatePaymentCallback(
          transactionId: transactionId,
          bookingId: bookingId,
          phoneNumber: phoneNumber,
          amount: amount,
        );
      } catch (e) {
        debugPrint('Simulated callback failed: $e');
      }
    });
  }

  /// Private: Cancel payment timeout timer
  static void _cancelPaymentTimeout(String transactionId) {
    _paymentTimers[transactionId]?.cancel();
    _paymentTimers.remove(transactionId);
  }

  /// Private: Validate Kenyan phone number format
  static bool _isValidKenyanPhone(String phone) {
    // Remove spaces and special characters
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Check if it matches Kenyan format: 254XXXXXXXXX (12 digits)
    if (cleaned.length == 12 && cleaned.startsWith('254')) {
      return true;
    }

    // Check if it matches local format: 07XXXXXXXX or 01XXXXXXXX (10 digits)
    if (cleaned.length == 10 &&
        (cleaned.startsWith('07') || cleaned.startsWith('01'))) {
      return true;
    }

    return false;
  }

  /// Format phone number to international format
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.length == 12 && cleaned.startsWith('254')) {
      return cleaned;
    }

    if (cleaned.length == 10 &&
        (cleaned.startsWith('07') || cleaned.startsWith('01'))) {
      return '254${cleaned.substring(1)}';
    }

    return cleaned;
  }

  /// Cleanup timers on app dispose
  static void dispose() {
    for (var timer in _paymentTimers.values) {
      timer.cancel();
    }
    _paymentTimers.clear();
    _pendingPayments.clear();
  }
}
