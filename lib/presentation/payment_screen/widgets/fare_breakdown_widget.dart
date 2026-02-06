import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FareBreakdownWidget extends StatelessWidget {
  const FareBreakdownWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Divider(color: theme.dividerColor),
        SizedBox(height: 1.h),
        _buildFareRow(theme, 'Base Fare', r'Ksh 5.00'),
        _buildFareRow(theme, 'Distance (8.5 km)', r'Ksh 12.75'),
        _buildFareRow(theme, 'Time (15 min)', r'Ksh 4.50'),
        _buildFareRow(theme, 'Service Fee', r'Ksh 2.25'),
        _buildFareRow(theme, 'Promo Discount', r'-Ksh 2.00', isDiscount: true),
        _buildFareRow(theme, 'Tax (8%)', r'Ksh 2.00'),
        SizedBox(height: 1.h),
        Divider(color: theme.dividerColor),
        SizedBox(height: 1.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              r'Ksh 24.50',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFareRow(
    ThemeData theme,
    String label,
    String amount, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDiscount
                  ? const Color(0xFF4CAF50)
                  : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
