import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/profile_image_service.dart';
import '../services/mysql_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedLocation = '東京都';
  String? _selectedCategory;
  String? _selectedSubcategory;
  DateTime? _selectedDate;
  String? _selectedTimeRange;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _timeRanges = [
    {'label': '午前（6:00-12:00）', 'value': 'morning'},
    {'label': '午後（12:00-18:00）', 'value': 'afternoon'},
    {'label': '夕方〜夜（18:00-24:00）', 'value': 'evening'},
    {'label': '深夜（0:00-6:00）', 'value': 'latenight'},
  ];

  final List<String> _locations = [
    '東京都',
    '神奈川県',
    '千葉県',
    '埼玉県',
    '茨城県',
    '栃木県',
    '群馬県',
  ];

  final List<Map<String, dynamic>> _categories = [
    {
      'icon': '🧡',
      'svgIcon': 'assets/images/手鏡アイコン3.svg',
      'label': '美容・リラクゼーション',
      'emoji': '💆',
      'subcategories': [
        'まつげ',
        'ネイル',
        'マッサージ',
        '出張リラクゼーション（鍼灸・整体）',
        '出張パーソナルスタイリスト／ファッションコーディネート',
        'スタイリスト',
        '着付け',
        'タトゥー',
        'メイク',
      ]
    },
    {
      'icon': '👶',
      'svgIcon': 'assets/images/赤ちゃんのフリーアイコン25.svg',
      'label': '子育て・家事サポート',
      'emoji': '👶',
      'subcategories': [
        '保育',
        '家事',
        '整理収納アドバイザー',
        '出張料理・作り置きシェフ',
        '旅行同行',
      ]
    },
    {
      'icon': '📸',
      'svgIcon': 'assets/images/カメラアイコン10.svg',
      'label': '記念・ライフスタイル',
      'emoji': '📸',
      'subcategories': [
        'ベビーフォト',
        'イベントヘルパー',
        '出張カメラマン（家族写真・プロフィール写真など）',
      ]
    },
    {
      'icon': '🏋️',
      'svgIcon': 'assets/images/ランニングアイコン1.svg',
      'label': '健康・学び',
      'emoji': '🏋️',
      'subcategories': [
        'フィットネス／ヨガ／ピラティスのインストラクター派遣',
        '語学・音楽・習い事レッスン（ピアノ・英会話など）',
      ]
    },
    {
      'icon': '🐾',
      'svgIcon': 'assets/images/三毛猫のイラスト素材.svg',
      'label': 'ペット・生活環境',
      'emoji': '🐾',
      'subcategories': [
        'ペットケア・散歩代行',
        '出張ハウスクリーニング（エアコン・水回り専門）',
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkAndShowNotificationDialog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAndShowNotificationDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownNotificationDialog = prefs.getBool('has_shown_notification_dialog') ?? false;

    if (!hasShownNotificationDialog && mounted) {
      // Wait for the screen to be built
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _showNotificationPermissionDialog();
        await prefs.setBool('has_shown_notification_dialog', true);
      }
    }
  }

  void _showNotificationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                color: AppColors.primaryOrange,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '通知を受け取りますか？',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '予約の確認やメッセージなど\n大切なお知らせをお届けします',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '後で',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AppSettings.openAppSettings(type: AppSettingsType.notification);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('通知をオンにする'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildCampaignBanner(),
              // Only show notifications if there are active ones
              if (NotificationService().hasActiveNotifications()) ...[
                _buildNotifications(),
                const SizedBox(height: 8),
              ],
              _buildLocationSelector(),
              const SizedBox(height: 8),
              _buildCategorySection(),
              const SizedBox(height: 12),
              _buildDateTimeSection(),
              const SizedBox(height: 12),
              _buildSearchSection(),
              const SizedBox(height: 20),
              _buildPopularServices(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.lightBeige,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 45,
            fit: BoxFit.contain,
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/user-settings');
            },
            child: CircleAvatar(
              backgroundColor: AppColors.secondaryOrange.withOpacity(0.3),
              radius: 20,
              child: const Icon(
                Icons.person,
                color: AppColors.primaryOrange,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // 広告バナー設定（ここを編集して広告を変更）
  // ============================================
  static const String _bannerImageUrl = 'https://anagrams.jp/wp-content/uploads/how-to-make-a-banner-with-canva_header.png';
  static const String _bannerLinkUrl = ''; // タップ時に開くURL（空の場合はタップ無効）
  // ============================================

  Widget _buildCampaignBanner() {
    return GestureDetector(
      onTap: _bannerLinkUrl.isNotEmpty
          ? () async {
              final uri = Uri.parse(_bannerLinkUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          : null,
      child: Container(
        color: Colors.white,
        height: 150,
        width: double.infinity,
        child: Image.network(
          _bannerImageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withOpacity(0.3),
                    AppColors.secondaryOrange.withOpacity(0.3),
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryOrange,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryOrange.withOpacity(0.8),
                    AppColors.secondaryOrange,
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  'キャンペーン・広告エリア',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotifications() {
    final notifications = NotificationService().getActiveNotifications();

    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show the most recent notification
    final notification = notifications.first;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.campaign,
            color: AppColors.accentBlue,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notification.message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'サロンスタッフを探す',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentBlue, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.accentBlue,
                  size: 13,
                ),
                const SizedBox(width: 3),
                DropdownButton<String>(
                  value: _selectedLocation,
                  underline: const SizedBox(),
                  isDense: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.accentBlue,
                    size: 16,
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  items: _locations.map((String location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLocation = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final selectedCategoryData = _selectedCategory != null
        ? _categories.firstWhere((cat) => cat['label'] == _selectedCategory)
        : null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Horizontal scrollable main categories - smaller to show all 5
          SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['label'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedCategory == category['label']) {
                        _selectedCategory = null;
                        _selectedSubcategory = null;
                      } else {
                        _selectedCategory = category['label'];
                        _selectedSubcategory = null;
                      }
                    });
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accentBlue
                                  : AppColors.lightGray,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              category['svgIcon'],
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Center(
                            child: Text(
                              category['label'],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.accentBlue
                                    : AppColors.textSecondary,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Animated expandable subcategories
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: selectedCategoryData != null
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.lightGray.withOpacity(0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withOpacity(0.05),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    selectedCategoryData['emoji'],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'カテゴリを選択',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Subcategories as chips
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (selectedCategoryData['subcategories']
                                        as List<String>)
                                    .map((subcategory) {
                                  final isSelected =
                                      _selectedSubcategory == subcategory;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (_selectedSubcategory == subcategory) {
                                          _selectedSubcategory = null;
                                        } else {
                                          _selectedSubcategory = subcategory;
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.accentBlue
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.accentBlue
                                              : Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        subcategory,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    final now = DateTime.now();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '直前割がおトク',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
              if (_selectedDate != null || _selectedTimeRange != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentBlue, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 14,
                        color: AppColors.accentBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '日時で絞り込み中',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '日時',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  if (_selectedDate == null) {
                    setState(() {
                      _selectedDate = now;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedDate != null ? AppColors.accentBlue : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedDate != null ? AppColors.accentBlue : Colors.grey[400]!,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '指定する',
                    style: TextStyle(
                      fontSize: 13,
                      color: _selectedDate != null ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = null;
                    _selectedTimeRange = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedDate == null ? Colors.grey[200] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedDate == null ? Colors.grey[400]! : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '指定しない',
                    style: TextStyle(
                      fontSize: 13,
                      color: _selectedDate == null ? AppColors.textPrimary : Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 14,
              itemBuilder: (context, index) {
                final date = now.add(Duration(days: index));
                final isSelected = _selectedDate != null &&
                    _selectedDate!.year == date.year &&
                    _selectedDate!.month == date.month &&
                    _selectedDate!.day == date.day;
                final isToday = index == 0;
                final isTomorrow = index == 1;

                final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
                final weekday = weekdays[date.weekday - 1];

                Color dateColor = AppColors.textPrimary;
                if (isToday) dateColor = AppColors.accentBlue;
                if (isTomorrow) dateColor = Colors.red;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    width: 55,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentBlue : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.accentBlue : AppColors.lightGray,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (index <= 1)
                          Text(
                            isToday ? '今日' : '明日',
                            style: TextStyle(
                              fontSize: 8,
                              color: isSelected ? Colors.white : (isTomorrow ? Colors.red : AppColors.accentBlue),
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                            ),
                          ),
                        if (index <= 1) const SizedBox(height: 1),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : dateColor,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          weekday,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Time range filter chips
          if (_selectedDate != null) ...[
            const SizedBox(height: 12),
            Text(
              '時間帯',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeRanges.map((timeRange) {
                final isSelected = _selectedTimeRange == timeRange['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedTimeRange == timeRange['value']) {
                        _selectedTimeRange = null;
                      } else {
                        _selectedTimeRange = timeRange['value'];
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentBlue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.accentBlue : AppColors.lightGray,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      timeRange['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit,
                color: Colors.green[700],
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'フリーワード',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'メニュー名・サロン名など',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to search results page with current filters
                Navigator.pushNamed(
                  context,
                  '/search-results',
                  arguments: {
                    'category': _selectedCategory,
                    'subcategory': _selectedSubcategory,
                    'location': _selectedLocation,
                    'selectedDate': _selectedDate,
                    'selectedTimeRange': _selectedTimeRange,
                    'searchQuery': _searchQuery,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
                shadowColor: AppColors.primaryOrange.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.search, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'この条件で検索',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  // Helper method to parse Japanese date format
  bool _matchesDate(String serviceDate, DateTime selectedDate) {
    // Service date format: "2025年10月17日（金）"
    // Extract year, month, day from Japanese format
    final yearMatch = RegExp(r'(\d{4})年').firstMatch(serviceDate);
    final monthMatch = RegExp(r'(\d{1,2})月').firstMatch(serviceDate);
    final dayMatch = RegExp(r'(\d{1,2})日').firstMatch(serviceDate);

    if (yearMatch == null || monthMatch == null || dayMatch == null) {
      return false;
    }

    final year = int.parse(yearMatch.group(1)!);
    final month = int.parse(monthMatch.group(1)!);
    final day = int.parse(dayMatch.group(1)!);

    return year == selectedDate.year &&
        month == selectedDate.month &&
        day == selectedDate.day;
  }

  // Helper method to check if service time matches selected time range
  bool _matchesTimeRange(String serviceTime, String timeRange) {
    // Service time format: "10:00 - 11:30" or "18:00 - 19:30"
    // Extract start hour from time string
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(serviceTime);
    if (timeMatch == null) return false;

    final startHour = int.parse(timeMatch.group(1)!);

    // Time ranges:
    // morning: 6-12
    // afternoon: 12-18
    // evening: 18-24
    // latenight: 0-6
    switch (timeRange) {
      case 'morning':
        return startHour >= 6 && startHour < 12;
      case 'afternoon':
        return startHour >= 12 && startHour < 18;
      case 'evening':
        return startHour >= 18 && startHour < 24;
      case 'latenight':
        return startHour >= 0 && startHour < 6;
      default:
        return true;
    }
  }

  Widget _buildPopularServices() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: MySQLService.instance.getServices(
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        location: _selectedLocation,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        limit: 3,
        date: _selectedDate,
        timeRange: _selectedTimeRange,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 50),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final servicesData = snapshot.data!;

        // Convert MySQL data directly to ServiceModel
        List<ServiceModel> filteredServices = servicesData.map((data) {
          return ServiceModel(
            id: data['id'] ?? '',
            title: data['title'] ?? '',
            provider: data['provider_name'] ?? 'サロン',
            providerTitle: data['provider_title'] ?? data['category'] ?? '',
            price: data['price'] ?? '¥0',
            rating: data['rating']?.toString() ?? '5.0',
            reviews: data['reviews_count']?.toString() ?? '0',
            category: data['category'] ?? '',
            subcategory: data['subcategory'] ?? '',
            location: data['location'] ?? '東京都',
            address: data['address'] ?? '',
            date: '',
            time: '',
            menuItems: [],
            totalPrice: data['price'] ?? '¥0',
            reviewsList: [],
            description: data['description'] ?? '',
            providerId: data['provider_id'],
            salonId: data['salon_id'],
            serviceAreas: data['location'] ?? '東京都',
            transportationFee: 0,
          );
        }).toList();
    // Don't show section if no services match
    if (filteredServices.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                '該当するサービスが見つかりませんでした',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '条件を変更して再度お試しください',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    String sectionTitle = '人気のサービス';
    if (_searchQuery.isNotEmpty) {
      sectionTitle = '"$_searchQuery" の検索結果';
    } else if (_selectedDate != null && _selectedTimeRange != null) {
      final month = _selectedDate!.month;
      final day = _selectedDate!.day;
      final timeLabel = _timeRanges.firstWhere((t) => t['value'] == _selectedTimeRange)['label']!;
      sectionTitle = '$month月$day日 $timeLabel 対応可能なサービス';
    } else if (_selectedDate != null) {
      final month = _selectedDate!.month;
      final day = _selectedDate!.day;
      sectionTitle = '$month月$day日 対応可能なサービス';
    } else if (_selectedSubcategory != null) {
      sectionTitle = '$_selectedSubcategoryのサービス';
    } else if (_selectedCategory != null) {
      sectionTitle = '$_selectedCategoryのサービス';
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${filteredServices.length}件',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...filteredServices.map((service) => _buildServiceCard(service)).toList(),
        ],
      ),
    );
      },
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/service-detail',
          arguments: service.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Provider profile image
            ProfileImageService().buildProfileImage(
              userId: service.providerId ?? 'test_provider_001',
              isProvider: true,
              size: 80,
              defaultIcon: Icons.person,
            ),
            const SizedBox(width: 12),
            // Service details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.provider,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          service.category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (service.serviceAreas.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 10,
                                  color: AppColors.primaryOrange,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    service.serviceAreas.length > 20
                                        ? '${service.serviceAreas.substring(0, 20)}...'
                                        : service.serviceAreas,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primaryOrange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${service.rating} (${service.reviews})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            service.price,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (service.transportationFee > 0)
                            Text(
                              '+交通費¥${service.transportationFee}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
