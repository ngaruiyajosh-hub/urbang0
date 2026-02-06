import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TransactionItemWidget extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onTap;

  const TransactionItemWidget({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = transaction['amount'] as double;
    final isPositive = amount > 0;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: (transaction['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            transaction['icon'] as IconData,
            color: transaction['color'] as Color,
            size: 6.w,
          ),
        ),
        title: Text(
          transaction['description'],
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          transaction['date'],
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isPositive ? '+' : ''}Ksh ${amount.abs().toStringAsFixed(2)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isPositive
                    ? const Color(0xFF4CAF50)
                    : theme.textTheme.bodyLarge?.color,
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 0.5.h),
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                transaction['status'],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                  fontSize: 9.sp,
                ),
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
