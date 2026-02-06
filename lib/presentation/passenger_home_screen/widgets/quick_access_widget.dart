import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Quick access toolbar for recent destinations and favorite locations
class QuickAccessWidget extends StatelessWidget {
  const QuickAccessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.5.h),
        SizedBox(
          height: 12.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildQuickAccessCard(
                theme,
                'Home',
                Icons.home,
                '123 Main St, Nairobi',
              ),
              SizedBox(width: 3.w),
              _buildQuickAccessCard(
                theme,
                'Work',
                Icons.work,
                '456 Business Ave',
              ),
              SizedBox(width: 3.w),
              _buildQuickAccessCard(
                theme,
                'Airport',
                Icons.flight,
                'JKIA Terminal 1',
              ),
              SizedBox(width: 3.w),
              _buildQuickAccessCard(
                theme,
                'Mall',
                Icons.shopping_bag,
                'Westgate Shopping',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
    ThemeData theme,
    String title,
    IconData icon,
    String address,
  ) {
    return Container(
      width: 40.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 5.w, color: theme.colorScheme.primary),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            address,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
