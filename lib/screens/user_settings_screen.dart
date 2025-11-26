import 'package:flutter/material.dart';
import '../constants/colors.dart';

class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({super.key});

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
          _buildMenuItem(
            context,
            '友達を招待する',
            () {},
          ),
          _buildMenuItem(
            context,
            '招待コードを入力',
            () {},
          ),
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
