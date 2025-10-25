import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/provider_database_service.dart';
import '../services/auth_service.dart';
import '../services/profile_image_service.dart';

class ProviderHomeDashboardScreen extends StatefulWidget {
  const ProviderHomeDashboardScreen({super.key});

  @override
  State<ProviderHomeDashboardScreen> createState() => _ProviderHomeDashboardScreenState();
}

class _ProviderHomeDashboardScreenState extends State<ProviderHomeDashboardScreen> {
  final providerDb = ProviderDatabaseService();
  String? _currentProviderId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get provider ID from arguments or from logged in user
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      _currentProviderId = args;
    } else {
      // Try to get from logged in user
      _currentProviderId = AuthService.currentUserProviderId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _currentProviderId != null
        ? providerDb.getProvider(_currentProviderId!)
        : null;
    final verification = _currentProviderId != null
        ? providerDb.getVerification(_currentProviderId!)
        : null;

    // Check if provider has registered (has verification submitted)
    final hasRegistered = provider != null && verification != null;

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
      body: hasRegistered ? _buildRegisteredView(provider, verification) : _buildUnregisteredView(),
    );
  }

  Widget _buildRegisteredView(ProviderProfile? provider, IdentityVerification? verification) {
    final salons = _currentProviderId != null
        ? providerDb.getSalonsByProvider(_currentProviderId!)
        : [];

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
                            provider?.name ?? 'ゲストユーザー',
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
                  iconColor: verification?.verificationStatus == 'approved'
                      ? Colors.green
                      : AppColors.primaryOrange,
                  title: '審査状況',
                  subtitle: verification?.verificationStatus == 'approved'
                      ? '承認済み'
                      : '審査中',
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
                if (verification?.verificationStatus == 'approved')
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
                if (verification?.verificationStatus == 'approved')
                  const SizedBox(height: 12),

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

                // My salons
                _buildDashboardCard(
                  icon: Icons.store,
                  iconColor: AppColors.primaryOrange,
                  title: 'マイサロン',
                  subtitle: '${salons.length}件登録済み',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/provider-my-salons',
                      arguments: _currentProviderId,
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
