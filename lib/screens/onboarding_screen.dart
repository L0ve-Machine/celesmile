import 'package:flutter/material.dart';
import '../constants/colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.touch_app_rounded,
      iconColor: AppColors.primaryOrange,
      stepNumber: '1',
      title: 'かんたん3ステップ',
      subtitle: 'サービスを簡単に予約',
      description: 'アプリから簡単にサービスプロバイダーを探して予約できます',
      features: ['豊富なカテゴリ', '詳細な検索', 'レビューで安心'],
    ),
    OnboardingPage(
      icon: Icons.schedule_rounded,
      iconColor: AppColors.accentBlue,
      stepNumber: '2',
      title: '日時を選んで予約',
      subtitle: 'あなたの都合に合わせて',
      description: 'カレンダーから希望日時を選択。料金も事前に確認できます',
      features: ['柔軟な日時選択', '透明な料金', '即時予約確定'],
    ),
    OnboardingPage(
      icon: Icons.verified_user_rounded,
      iconColor: Colors.green,
      stepNumber: '3',
      title: '安心・安全なサービス',
      subtitle: 'プロフェッショナルがお伺い',
      description: '認証済みのサービス提供者が、確実にサービスを提供します',
      features: ['身元確認済み', 'レビュー評価', 'サポート体制'],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/phone-verification');
            },
            child: Text(
              'スキップ',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          return _buildPage(_pages[index]);
        },
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Icon with animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    page.iconColor.withOpacity(0.2),
                    page.iconColor.withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(
                page.icon,
                size: 60,
                color: page.iconColor,
              ),
            ),

            const SizedBox(height: 48),

            // Title
            Text(
              page.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              page.subtitle,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary.withOpacity(0.8),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Description
            if (page.description != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  page.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 40),

            // Feature cards
            if (page.features != null) ...[
              ...page.features!.map((feature) => _buildFeatureCard(feature, page.iconColor)),
            ],

            const Spacer(),

            // Page indicator
            _buildPageIndicator(),

            const SizedBox(height: 32),

            // Buttons
            _buildButtons(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String feature, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            feature,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        bool isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? _pages[_currentPage].iconColor
                : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildButtons() {
    bool isLastPage = _currentPage == _pages.length - 1;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (isLastPage) {
                Navigator.pushNamed(context, '/phone-verification');
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _pages[_currentPage].iconColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              isLastPage ? '始める' : '次へ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),

        if (isLastPage) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/');
            },
            child: Text(
              'すでにアカウントをお持ちの方',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

}

class OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String stepNumber;
  final String title;
  final String subtitle;
  final String? description;
  final List<String>? features;

  OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    this.description,
    this.features,
  });
}
