import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/provider_database_service.dart';
import '../services/auth_service.dart';
import '../services/profile_image_service.dart';
import '../services/mysql_service.dart';

class ProviderHomeDashboardScreen extends StatefulWidget {
  final String? providerId;

  const ProviderHomeDashboardScreen({super.key, this.providerId});

  @override
  State<ProviderHomeDashboardScreen> createState() => _ProviderHomeDashboardScreenState();
}

class _ProviderHomeDashboardScreenState extends State<ProviderHomeDashboardScreen> {
  final providerDb = ProviderDatabaseService();
  String? _currentProviderId;
  Map<String, dynamic>? _providerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentProviderId = widget.providerId ?? AuthService.currentUserProviderId;
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    if (_currentProviderId != null) {
      try {
        print('🔍 Loading provider data for ID: $_currentProviderId');
        final data = await MySQLService.instance.getProviderById(_currentProviderId!);
        print('📦 Provider data received: $data');
        if (mounted) {
          setState(() {
            _providerData = data;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('❌ Error loading provider data: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryOrange,
          ),
        ),
      );
    }

    final provider = _currentProviderId != null
        ? providerDb.getProvider(_currentProviderId!)
        : null;

    // Use DB verified field instead of verification status
    print('🔍 Checking verification: _providerData=${_providerData != null}, verified=${_providerData?['verified']}, type=${_providerData?['verified']?.runtimeType}');
    final isVerified = _providerData?['verified'] == 1;
    print('✅ isVerified result: $isVerified');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.lightBeige,
        elevation: 0,
        title: Image.asset(
          'assets/images/logo.png',
          height: 45,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/provider-settings',
                arguments: _currentProviderId,
              );
            },
          ),
        ],
      ),
      body: _buildRegisteredView(provider, verification),
    );
  }

  Widget _buildRegisteredView(ProviderProfile? provider, IdentityVerification? verification) {

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with provider info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightBeige,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProfileImageService().buildProfileAvatar(
                      userId: _currentProviderId ?? 'test_provider_001',
                      isProvider: true,
                      radius: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _providerData?['name'] ?? 'ゲストユーザー',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            provider?.title ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (provider?.isVerified ?? false)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.verified, color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '認証済み',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'マイページ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Verification status card
                _buildDashboardCard(
                  icon: Icons.verified_user,
                  iconColor: isVerified
                      ? Colors.green
                      : AppColors.primaryOrange,
                  title: '審査状況',
                  subtitle: isVerified
                      ? '承認済み (DEBUG: verified=${_providerData?['verified']})'
                      : '審査中 (DEBUG: verified=${_providerData?['verified']})',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/provider-verification-status',
                      arguments: _currentProviderId,
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Availability calendar (only if approved)
                if (isVerified) ...[
                  // Debug
                  Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.green.withOpacity(0.1),
                    child: Text('DEBUG: isVerified=$isVerified, カレンダーを表示すべき'),
                  ),
                  _buildDashboardCard(
                    icon: Icons.calendar_month,
                    iconColor: AppColors.accentBlue,
                    title: '空き状況カレンダー',
                    subtitle: '予約可能な時間を設定',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/provider-availability-calendar',
                        arguments: _currentProviderId,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  // Debug
                  Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.red.withOpacity(0.1),
                    child: Text('DEBUG: isVerified=$isVerified, カレンダー非表示'),
                  ),
                ],

                // Chat
                _buildDashboardCard(
                  icon: Icons.chat_bubble_outline,
                  iconColor: AppColors.primaryOrange,
                  title: 'チャット',
                  subtitle: 'お客様とのメッセージ',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/provider-chat-list',
                      arguments: _currentProviderId,
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Upcoming bookings
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: MySQLService.instance.getBookingsByProvider(_currentProviderId!),
                  builder: (context, snapshot) {
                    final upcomingCount = snapshot.hasData
                        ? snapshot.data!.where((b) => b['status'] != 'cancelled' && b['status'] != 'completed').length
                        : 0;
                    return _buildDashboardCard(
                      icon: Icons.calendar_today,
                      iconColor: AppColors.accentBlue,
                      title: '直近の予約一覧',
                      subtitle: '${upcomingCount}件の予約',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/provider-bookings',
                          arguments: _currentProviderId,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Revenue summary
                FutureBuilder<Map<String, dynamic>>(
                  future: MySQLService.instance.getRevenueSummary(_currentProviderId!),
                  builder: (context, snapshot) {
                    final summary = snapshot.data ?? {'thisMonthTotal': 0, 'pendingTotal': 0};
                    return _buildDashboardCard(
                      icon: Icons.attach_money,
                      iconColor: Colors.green,
                      title: '収益サマリー',
                      subtitle: '今月: ¥${summary['thisMonthTotal']}, 未入金: ¥${summary['pendingTotal']}',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/provider-income-summary',
                          arguments: _currentProviderId,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),

                // My salons
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: MySQLService.instance.getSalonsByProvider(_currentProviderId!),
                  builder: (context, snapshot) {
                    final salonCount = snapshot.hasData ? snapshot.data!.length : 0;
                    return _buildDashboardCard(
                      icon: Icons.store,
                      iconColor: AppColors.primaryOrange,
                      title: 'マイサロン',
                      subtitle: '${salonCount}件登録済み',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/provider-my-salons',
                          arguments: _currentProviderId,
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnregisteredView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with provider info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightBeige,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.secondaryOrange.withOpacity(0.3),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primaryOrange,
                        size: 35,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ゲストユーザー',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Home Dashboard Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ホームダッシュボード',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Chat
                _buildDashboardCard(
                  icon: Icons.chat_bubble_outline,
                  iconColor: AppColors.primaryOrange,
                  title: 'チャット',
                  subtitle: 'お客様とのメッセージ',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/provider-chat-list',
                      arguments: _currentProviderId,
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Upcoming bookings
                _buildDashboardCard(
                  icon: Icons.calendar_today,
                  iconColor: AppColors.accentBlue,
                  title: '直近の予約一覧',
                  subtitle: '（承認／未対応／完了）',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/provider-bookings',
                      arguments: _currentProviderId,
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Revenue summary
                _buildDashboardCard(
                  icon: Icons.attach_money,
                  iconColor: Colors.green,
                  title: '収益サマリー',
                  subtitle: '（今月の売上、未入金額）',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/provider-income-summary',
                      arguments: _currentProviderId,
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Notifications
                _buildDashboardCard(
                  icon: Icons.notifications,
                  iconColor: AppColors.primaryOrange,
                  title: '運営からのお知らせ',
                  subtitle: '（ポリシー変更など）',
                  onTap: () {},
                ),

                const SizedBox(height: 32),

                const Text(
                  '新規掲載 & 本人確認フロー',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '電話番号認証して登録',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Registration steps
                _buildRegistrationStep(
                  step: 1,
                  title: 'メール／SNSログイン',
                  isCompleted: false,
                  onTap: () {},
                ),
                _buildRegistrationStep(
                  step: 2,
                  title: '本人確認書類アップロード',
                  subtitle: '（免許証など）',
                  isCompleted: false,
                  onTap: () {
                    Navigator.pushNamed(context, '/identity-verification', arguments: _currentProviderId);
                  },
                ),
                _buildRegistrationStep(
                  step: 3,
                  title: 'スタッフ側銀行口座登録',
                  subtitle: '（報酬振込用）',
                  isCompleted: false,
                  onTap: () {
                    Navigator.pushNamed(context, '/bank-registration', arguments: _currentProviderId);
                  },
                ),
                _buildRegistrationStep(
                  step: 4,
                  title: '同意画面',
                  subtitle: '（利用規約、個人情報保護）',
                  isCompleted: false,
                  onTap: () {},
                ),
                _buildRegistrationStep(
                  step: 5,
                  title: '「審査中／承認済」ステータス表示',
                  isCompleted: false,
                  onTap: () {
                    Navigator.pushNamed(context, '/provider-verification-status', arguments: _currentProviderId);
                  },
                ),
                _buildRegistrationStep(
                  step: 6,
                  title: 'プッシュ通知',
                  isCompleted: false,
                  onTap: () {},
                ),

                const SizedBox(height: 32),

                // Start registration button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/poster-registration-form');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '掲載者として新規登録を開始',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationStep({
    required int step,
    required String title,
    String? subtitle,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : AppColors.accentBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          step.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
