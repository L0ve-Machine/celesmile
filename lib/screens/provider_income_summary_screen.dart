import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/provider_database_service.dart';

class ProviderIncomeSummaryScreen extends StatefulWidget {
  const ProviderIncomeSummaryScreen({super.key});

  @override
  State<ProviderIncomeSummaryScreen> createState() => _ProviderIncomeSummaryScreenState();
}

class _ProviderIncomeSummaryScreenState extends State<ProviderIncomeSummaryScreen> {
  String? _providerId;
  final providerDb = ProviderDatabaseService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerId = ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  Widget build(BuildContext context) {
    final summary = _providerId != null
        ? providerDb.getRevenueSummary(_providerId!)
        : {'thisMonthTotal': 0, 'pendingTotal': 0, 'paidTotal': 0, 'totalRevenue': 0};

    final revenues = _providerId != null
        ? providerDb.getRevenuesByProvider(_providerId!)
        : [];

    // Sort by date (newest first)
    revenues.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '収益サマリー',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryOrange, AppColors.secondaryOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '総売上',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¥${summary['totalRevenue'].toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: '今月の売上',
                          amount: summary['thisMonthTotal'],
                          icon: Icons.calendar_today,
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: '未入金額',
                          amount: summary['pendingTotal'],
                          icon: Icons.pending,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    title: '入金済み',
                    amount: summary['paidTotal'],
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 32),

                  // Revenue records list
                  const Text(
                    '収益履歴',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (revenues.isEmpty)
                    _buildEmptyState()
                  else
                    ...revenues.map((revenue) => _buildRevenueCard(revenue)).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¥${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_money,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '収益履歴がありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(RevenueRecord revenue) {
    final booking = _providerId != null
        ? providerDb.getBookingsByProvider(_providerId!).firstWhere(
            (b) => b.id == revenue.bookingId,
            orElse: () => Booking(
              id: '',
              providerId: '',
              salonId: '',
              serviceId: '',
              customerName: '不明',
              customerPhone: '',
              customerEmail: '',
              serviceName: '不明なサービス',
              bookingDate: revenue.date,
              timeSlot: '',
              price: revenue.amount,
              status: 'completed',
              createdAt: revenue.date,
            ),
          )
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking?.serviceName ?? '不明なサービス',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking?.customerName ?? '不明',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '¥${revenue.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(revenue.date),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.payment,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                revenue.paymentMethod,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: revenue.status == 'paid'
                      ? Colors.green.withOpacity(0.1)
                      : AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  revenue.status == 'paid' ? '入金済み' : '未入金',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: revenue.status == 'paid' ? Colors.green : AppColors.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
