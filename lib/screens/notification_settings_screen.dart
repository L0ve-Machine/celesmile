import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // 通知設定の状態
  bool _bookingNotifications = true;
  bool _messageNotifications = true;
  bool _promotionNotifications = false;
  bool _systemNotifications = true;
  bool _emailNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bookingNotifications = prefs.getBool('booking_notifications') ?? true;
      _messageNotifications = prefs.getBool('message_notifications') ?? true;
      _promotionNotifications = prefs.getBool('promotion_notifications') ?? false;
      _systemNotifications = prefs.getBool('system_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('booking_notifications', _bookingNotifications);
    await prefs.setBool('message_notifications', _messageNotifications);
    await prefs.setBool('promotion_notifications', _promotionNotifications);
    await prefs.setBool('system_notifications', _systemNotifications);
    await prefs.setBool('email_notifications', _emailNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('プッシュ通知'),
          _buildNotificationTile(
            '予約通知',
            '予約の確認、リマインダー、変更通知',
            _bookingNotifications,
            (value) {
              setState(() {
                _bookingNotifications = value;
              });
              _saveSettings();
            },
          ),
          _buildNotificationTile(
            'メッセージ通知',
            'チャットメッセージの通知',
            _messageNotifications,
            (value) {
              setState(() {
                _messageNotifications = value;
              });
              _saveSettings();
            },
          ),
          _buildNotificationTile(
            'プロモーション通知',
            'キャンペーンやお得な情報の通知',
            _promotionNotifications,
            (value) {
              setState(() {
                _promotionNotifications = value;
              });
              _saveSettings();
            },
          ),
          _buildNotificationTile(
            'システム通知',
            'アプリのアップデートや重要なお知らせ',
            _systemNotifications,
            (value) {
              setState(() {
                _systemNotifications = value;
              });
              _saveSettings();
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('その他の通知設定'),
          _buildNotificationTile(
            'メール通知',
            '重要な通知をメールでも受け取る',
            _emailNotifications,
            (value) {
              setState(() {
                _emailNotifications = value;
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBeige,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primaryOrange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '通知設定はいつでも変更できます。\n重要な通知を見逃さないよう、適切に設定してください。',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryOrange,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}