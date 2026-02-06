import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import './widgets/booking_info_widget.dart';
import './widgets/payment_method_card.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;
  bool _showFareBreakdown = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'card_1',
      'type': 'Credit Card',
      'name': 'Visa •••• 4242',
      'icon': Icons.credit_card,
      'isDefault': true,
    },
    {
      'id': 'card_2',
      'type': 'Debit Card',
      'name': 'Mastercard •••• 8888',
      'icon': Icons.credit_card,
      'isDefault': false,
    },
    {
      'id': 'wallet',
      'type': 'Digital Wallet',
      'name': 'My Wallet (Ksh 125.50)',
      'icon': Icons.account_balance_wallet,
      'isDefault': false,
    },
    {
      'id': 'cash',
      'type': 'Cash',
      'name': 'Pay with Cash',
      'icon': Icons.money,
      'isDefault': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Set default payment method
    _selectedPaymentMethod = _paymentMethods.firstWhere(
      (method) => method['isDefault'] == true,
      orElse: () => _paymentMethods.first,
    )['id'];
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isProcessing = false);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: Icon(
            Icons.check_circle,
            color: const Color(0xFF4CAF50),
            size: 15.w,
          ),
          title: const Text('Payment Successful'),
          content: const Text(
            'Your booking has been confirmed. You will receive a confirmation shortly.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Payment',
        variant: CustomAppBarVariant.withBack,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                children: [
                  // Booking Info Section
                  BookingInfoWidget(),
                  SizedBox(height: 2.h),

                  // Fare Summary Card
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fare Summary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showFareBreakdown = !_showFareBreakdown;
                                });
                              },
                              icon: Icon(
                                _showFareBreakdown
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 5.w,
                              ),
                              label: Text(
                                _showFareBreakdown ? 'Hide' : 'Details',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: theme.textTheme.bodyLarge,
                            ),
                            Text(
                              r'Ksh 24.50',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (_showFareBreakdown) ...[
                          SizedBox(height: 2.h),
                          _buildFareBreakdown(theme),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Payment Methods Section
                  Text(
                    'Select Payment Method',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.5.h),

                  ..._paymentMethods.map(
                    (method) => PaymentMethodCard(
                      id: method['id'],
                      type: method['type'],
                      name: method['name'],
                      icon: method['icon'],
                      isSelected: _selectedPaymentMethod == method['id'],
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = method['id'];
                        });
                      },
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Add Payment Method Button
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Add payment method feature coming soon',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Payment Method'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // View Past Rides Link
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Viewing past rides...'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View Past Rides'),
                    ),
                  ),

                  SizedBox(height: 2.h),
                ],
              ),
            ),

            // Confirm Payment Button (Fixed at bottom)
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    backgroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor: theme.colorScheme.primary
                        .withValues(alpha: 0.5),
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'Confirm Payment - Ksh 24.50',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method
  Widget _buildFareBreakdown(ThemeData theme) {
    return Column(
      children: [
        _buildFareRow('Base Fare', 'Ksh 15.00', theme),
        SizedBox(height: 1.h),
        _buildFareRow('Distance', 'Ksh 6.50', theme),
        SizedBox(height: 1.h),
        _buildFareRow('Service Fee', 'Ksh 3.00', theme),
        SizedBox(height: 1.h),
        Divider(color: theme.dividerColor),
        SizedBox(height: 1.h),
        _buildFareRow('Total', 'Ksh 24.50', theme, isBold: true),
      ],
    );
  }

  Widget _buildFareRow(
    String label,
    String amount,
    ThemeData theme, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
