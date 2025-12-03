import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/mysql_service.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  String? _myInviteCode;
  bool _isLoadingInviteCode = false;

  @override
  void initState() {
    super.initState();
    _loadMyInviteCode();
  }

  Future<void> _loadMyInviteCode() async {
    final providerId = AuthService.currentUserProviderId;
    if (providerId == null) return;

    setState(() => _isLoadingInviteCode = true);

    try {
      final code = await MySQLService.instance.getInviteCode(providerId);
      if (mounted) {
        setState(() {
          _myInviteCode = code;
          _isLoadingInviteCode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInviteCode = false);
      }
    }
  }

  void _shareInviteCode() {
    if (_myInviteCode == null) return;

    final message = '''
セレスマイルに招待します！

招待コード: $_myInviteCode

このコードを使って登録すると、あなたと私に500円オフクーポンがもらえます！

アプリをダウンロード:
https://celesmile-demo.duckdns.org
''';

    Share.share(message);
  }

  void _copyInviteCode() {
    if (_myInviteCode == null) return;

    Clipboard.setData(ClipboardData(text: _myInviteCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('招待コードをコピーしました'),
        backgroundColor: AppColors.primaryOrange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'マイページ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('お客様向けガイド'),
          _buildMenuItem(
            context,
            '利用規約・ガイドライン',
            () {
              Navigator.pushNamed(context, '/terms-of-service');
            },
          ),
          _buildSectionHeader('マイページ'),
          _buildMenuItem(
            context,
            'チャット',
            () {
              Navigator.pushNamed(context, '/chat-list');
            },
            icon: Icons.chat_bubble_outline,
          ),
          _buildMenuItem(
            context,
            '予約履歴',
            () {
              Navigator.pushNamed(context, '/booking-history');
            },
          ),
          _buildMenuItem(
            context,
            'プロフィール編集',
            () {
              Navigator.pushNamed(context, '/profile-registration', arguments: {'isEditMode': true});
            },
          ),
          _buildSectionHeader('アカウントの切り替え', trailing: _buildInfoButton(context)),
          _buildMenuItem(
            context,
            '掲載者として新規登録',
            () {
              Navigator.pushNamed(context, '/poster-registration-intro');
            },
          ),
          _buildSectionHeader('友達招待'),
          _buildInviteCodeCard(),
          _buildSectionHeader('その他'),
          _buildMenuItem(
            context,
            '通知設定',
            () {
              Navigator.pushNamed(context, '/notification-settings');
            },
          ),
          _buildSectionHeader('アカウント'),
          _buildMenuItem(
            context,
            'ログアウト',
            () {
              // Clear auth state
              AuthService.logout();
              // Navigate to the first page (WelcomeScreen)
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, VoidCallback onTap, {IconData? icon}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: AppColors.primaryOrange,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCodeCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryOrange.withOpacity(0.1),
            AppColors.secondaryOrange.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard, color: AppColors.primaryOrange, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '友達を招待して500円GET！',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'あなたの招待コードで友達が登録すると、\nあなたと友達に500円オフクーポンがもらえます！',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Row(
              children: [
                const Text(
                  'あなたの招待コード:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _isLoadingInviteCode
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryOrange,
                          ),
                        )
                      : Text(
                          _myInviteCode ?? '---',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                            letterSpacing: 2,
                          ),
                        ),
                ),
                IconButton(
                  onPressed: _myInviteCode != null ? _copyInviteCode : null,
                  icon: const Icon(Icons.copy, size: 20),
                  color: AppColors.primaryOrange,
                  tooltip: 'コピー',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _myInviteCode != null ? _shareInviteCode : null,
              icon: const Icon(Icons.share, size: 18),
              label: const Text('友達に共有する'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('掲載者とは'),
            content: const Text(
              'サービスを提供するスタッフとして登録することができます。\n'
              'プロフィールや提供サービスを掲載し、お客様からの予約を受け付けることができます。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accentBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.help_outline,
              color: Colors.white,
              size: 14,
            ),
            SizedBox(width: 4),
            Text(
              '掲載者とは',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
