import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/provider_database_service.dart';
import '../services/auth_service.dart';
import '../services/profile_image_service.dart';

class ProviderSettingsScreen extends StatefulWidget {
  const ProviderSettingsScreen({super.key});

  @override
  State<ProviderSettingsScreen> createState() => _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState extends State<ProviderSettingsScreen> {
  String? _providerId;
  final providerDb = ProviderDatabaseService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      _providerId = args;
    } else {
      _providerId = AuthService.currentUserProviderId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _providerId != null ? providerDb.getProvider(_providerId!) : null;

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
          '設定',
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
            // Profile header
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
                children: [
                  ProfileImageService().buildProfileAvatar(
                    userId: _providerId ?? 'test_provider_001',
                    isProvider: true,
                    radius: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider?.name ?? 'ゲストユーザー',
                    style: const TextStyle(
                      fontSize: 20,
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
                  if (provider?.isVerified ?? false) ...[
                    const SizedBox(height: 8),
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
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Account settings section
            _buildSectionHeader('アカウント設定'),
            _buildSettingItem(
              icon: Icons.person_outline,
              title: 'プロフィール編集',
              subtitle: '写真、名前、連絡先などを編集',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/provider-profile-edit',
                  arguments: _providerId,
                ).then((_) => setState(() {})); // Refresh after edit
              },
            ),
            _buildSettingItem(
              icon: Icons.email_outlined,
              title: 'メールアドレス',
              subtitle: provider?.email ?? '未設定',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/provider-profile-edit',
                  arguments: _providerId,
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.phone_outlined,
              title: '電話番号',
              subtitle: provider?.phone ?? '未設定',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/provider-profile-edit',
                  arguments: _providerId,
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.lock_outline,
              title: 'パスワード変更',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/provider-profile-edit',
                  arguments: _providerId,
                );
              },
            ),

            const SizedBox(height: 8),

            // Business settings section
            _buildSectionHeader('ビジネス設定'),
            _buildSettingItem(
              icon: Icons.store_outlined,
              title: 'マイサロン管理',
              subtitle: 'サロン情報の編集・追加',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/provider-my-salons',
                  arguments: _providerId,
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.account_balance_outlined,
              title: '銀行口座情報',
              subtitle: '報酬振込先の管理',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/bank-registration',
                  arguments: _providerId,
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.verified_user_outlined,
              title: '本人確認書類',
              subtitle: '審査ステータスの確認',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/provider-verification-status',
                  arguments: _providerId,
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.calendar_month_outlined,
              title: '空き状況カレンダー',
              subtitle: '予約可能な時間を設定',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/provider-availability-calendar',
                  arguments: _providerId,
                );
              },
            ),

            const SizedBox(height: 8),

            // Notification settings section
            _buildSectionHeader('通知設定'),
            _buildSettingItem(
              icon: Icons.notifications_outlined,
              title: 'プッシュ通知',
              subtitle: '新規予約、メッセージなど',
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  _showComingSoonDialog('通知設定');
                },
                activeColor: AppColors.primaryOrange,
              ),
            ),
            _buildSettingItem(
              icon: Icons.mail_outline,
              title: 'メール通知',
              subtitle: '予約確認、売上レポートなど',
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  _showComingSoonDialog('メール通知設定');
                },
                activeColor: AppColors.primaryOrange,
              ),
            ),

            const SizedBox(height: 8),

            // Support section
            _buildSectionHeader('サポート'),
            _buildSettingItem(
              icon: Icons.help_outline,
              title: 'ヘルプセンター',
              onTap: () {
                _showComingSoonDialog('ヘルプセンター');
              },
            ),
            _buildSettingItem(
              icon: Icons.description_outlined,
              title: '利用規約',
              onTap: () {
                _showComingSoonDialog('利用規約');
              },
            ),
            _buildSettingItem(
              icon: Icons.privacy_tip_outlined,
              title: 'プライバシーポリシー',
              onTap: () {
                _showComingSoonDialog('プライバシーポリシー');
              },
            ),
            _buildSettingItem(
              icon: Icons.info_outline,
              title: 'アプリについて',
              subtitle: 'バージョン 1.0.0',
              onTap: () {
                _showAboutDialog();
              },
            ),

            const SizedBox(height: 24),

            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('ログアウト'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryOrange,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('準備中'),
        content: Text('$feature機能は現在準備中です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Celesmileについて'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'バージョン: 1.0.0',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              '自宅に呼べる、暮らしの出張ケアアプリ',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '© 2025 Celesmile Inc.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              AuthService.logout();
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
            child: const Text(
              'ログアウト',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
