import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/auth_service.dart';
import '../../services/mpesa_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/balance_card_widget.dart';
import './widgets/booking_management_widget.dart';
import './widgets/promo_offer_card.dart';
import './widgets/quick_action_button.dart';
import './widgets/transaction_item_widget.dart';

class MyWalletScreen extends StatefulWidget {
  const MyWalletScreen({super.key});

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen> {
  bool _isRefreshing = false;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Rides', 'Top-ups', 'Refunds'];
  double _walletBalance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _bookings = [];
  final _supabase = SupabaseService.client;
  final _authService = AuthService(); // Add this line

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _loadBookings();
  }

  Future<void> _loadWalletData() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    setState(() => _isRefreshing = true);

    try {
      // Load wallet balance
      final balance = await MpesaService.getWalletBalance(currentUser.id);

      // Load wallet transactions
      final transactions = await MpesaService.getWalletTransactions(
        currentUser.id,
      );

      setState(() {
        _walletBalance = balance;
        _transactions = transactions.map((txn) {
          return {
            'id': txn['id'],
            'type': txn['transaction_type'] == 'credit'
                ? 'topup'
                : txn['transaction_type'] == 'refund'
                ? 'refund'
                : 'ride',
            'description': txn['description'] ?? 'Transaction',
            'amount': txn['transaction_type'] == 'debit'
                ? -(txn['amount'] as num).toDouble()
                : (txn['amount'] as num).toDouble(),
            'date': txn['created_at'],
            'status': 'completed',
            'icon': txn['transaction_type'] == 'credit'
                ? Icons.add_circle
                : txn['transaction_type'] == 'refund'
                ? Icons.refresh
                : Icons.directions_car,
            'color': txn['transaction_type'] == 'credit'
                ? const Color(0xFF4CAF50)
                : txn['transaction_type'] == 'refund'
                ? const Color(0xFF2196F3)
                : const Color(0xFFFF9800),
          };
        }).toList();
        _isRefreshing = false;
      });
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _loadBookings() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      final bookings = await _supabase
          .from('Bookings')
          .select('*, Vehicle(*)')
          .eq('passenger_id', currentUser.id)
          .eq('status', 'Confirmed')
          .order('created_at', ascending: false);

      setState(() {
        _bookings = List<Map<String, dynamic>>.from(bookings);
      });
    } catch (e) {
      debugPrint('Error loading bookings: $e');
    }
  }

  Future<void> _refreshBalance() async {
    await _loadWalletData();
    await _loadBookings();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Balance updated')));
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await MpesaService.cancelBooking(bookingId: bookingId);

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      _loadWalletData();
      _loadBookings();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == 'All') return _transactions;
    return _transactions.where((txn) {
      switch (_selectedFilter) {
        case 'Rides':
          return txn['type'] == 'ride';
        case 'Top-ups':
          return txn['type'] == 'topup';
        case 'Refunds':
          return txn['type'] == 'refund';
        default:
          return true;
      }
    }).toList();
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Transaction Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              _buildDetailRow(theme, 'Description', transaction['description']),
              _buildDetailRow(
                theme,
                'Amount',
                'Ksh ${transaction['amount'].abs().toStringAsFixed(2)}',
              ),
              _buildDetailRow(theme, 'Date', transaction['date']),
              _buildDetailRow(theme, 'Status', transaction['status']),
              _buildDetailRow(theme, 'Transaction ID', transaction['id']),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Receipt downloaded')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download),
                    SizedBox(width: 2.w),
                    const Text('Download Receipt'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
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
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'My Wallet',
        variant: CustomAppBarVariant.withBack,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBalance,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          children: [
            // Balance Card
            BalanceCardWidget(
              balance: _walletBalance,
              isRefreshing: _isRefreshing,
            ),
            SizedBox(height: 3.h),

            // Active Bookings Section
            BookingManagementWidget(
              bookings: _bookings,
              onCancelBooking: _cancelBooking,
              onRefresh: _loadBookings,
            ),
            SizedBox(height: 3.h),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.add,
                    label: 'Add Money',
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add money feature coming soon'),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.send,
                    label: 'Send Money',
                    color: const Color(0xFF2196F3),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Send money feature coming soon'),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.request_page,
                    label: 'Request',
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request money feature coming soon'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Promotional Offers
            PromoOfferCard(),
            SizedBox(height: 3.h),

            // Transaction History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Search feature coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 1.h),

            // Filter Chips
            SizedBox(
              height: 5.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: theme.cardColor,
                      selectedColor: theme.colorScheme.primary.withValues(
                        alpha: 0.2,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 2.h),

            // Transaction List
            if (_filteredTransactions.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 15.w,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No transactions found',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredTransactions.map(
                (transaction) => TransactionItemWidget(
                  transaction: transaction,
                  onTap: () => _showTransactionDetails(transaction),
                ),
              ),

            SizedBox(height: 2.h),

            // Security Features Section
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
                  Text(
                    'Security & Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _buildSecurityItem(
                    theme,
                    Icons.lock,
                    'Transaction PIN',
                    'Set up for secure payments',
                    true,
                  ),
                  _buildSecurityItem(
                    theme,
                    Icons.account_balance,
                    'Spending Limit',
                    'Ksh 500 per day',
                    false,
                  ),
                  _buildSecurityItem(
                    theme,
                    Icons.verified_user,
                    'Account Verified',
                    'Full access enabled',
                    false,
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    bool showAction,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 5.w),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: showAction
          ? TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Setup PIN feature coming soon'),
                  ),
                );
              },
              child: const Text('Setup'),
            )
          : Icon(Icons.check_circle, color: const Color(0xFF4CAF50), size: 5.w),
    );
  }
}
