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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBeige,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            _buildWelcomePage(),
            _buildThreeStepsPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Stack(
      children: [
        Column(
          children: [
            // Top navigation bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _goToLogin,
                    icon: Icon(
                      Icons.close,
                      color: Colors.black54,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Welcome Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryOrange.withOpacity(0.2),
                    AppColors.lightBeige.withOpacity(0.2),
                  ],
                ),
              ),
              child: Icon(
                Icons.celebration_rounded,
                size: 60,
                color: AppColors.primaryOrange,
              ),
            ),

            const SizedBox(height: 48),

            // Welcome Text
            Text(
              '新規登録！',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryOrange,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            Text(
              'Celesmileへようこそ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              '暮らしの出張ケアアプリ\nあなたの生活をもっと豊かに',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Features
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildWelcomeFeature(Icons.home_rounded, '自宅でプロのサービス'),
                  _buildWelcomeFeature(Icons.schedule_rounded, '好きな時間に予約'),
                  _buildWelcomeFeature(Icons.verified_rounded, '安心・安全な認証システム'),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Page indicator
            _buildPageIndicator(),

            const SizedBox(height: 32),

            // Next Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[400]!, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    '次へ進む',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeFeature(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightGray,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightBeige.withOpacity(0.3),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 簡単3ステップページ
  Widget _buildThreeStepsPage() {
    return Stack(
      children: [
        Column(
          children: [
            // Top navigation bar with separator line
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      IconButton(
                        onPressed: _goBack,
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.black54,
                          size: 28,
                        ),
                      ),
                      // Close button
                      IconButton(
                        onPressed: _goToLogin,
                        icon: Icon(
                          Icons.close,
                          color: Colors.black54,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                // Separator line
                Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Title
            Text(
              '簡単3ステップ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryOrange,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'すぐに始められます',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 40),

            // 3 Steps
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildStepItem(
                      stepNumber: 1,
                      icon: Icons.touch_app_rounded,
                      title: '希望のサービスを選択',
                      subtitle: '依頼内容の詳細を入力',
                      imagePath: 'assets/images/2.png',
                    ),
                    const SizedBox(height: 16),
                    _buildStepItem(
                      stepNumber: 2,
                      icon: Icons.calendar_today_rounded,
                      title: '希望の日時を選択',
                      subtitle: '金額を確認して依頼完了！',
                      imagePath: 'assets/images/3.png',
                    ),
                    const SizedBox(height: 16),
                    _buildStepItem(
                      stepNumber: 3,
                      icon: Icons.home_rounded,
                      title: 'サービス実施',
                      subtitle: '指定日に家事キャストを待つだけ！',
                      imagePath: 'assets/images/4.png',
                    ),
                  ],
                ),
              ),
            ),

            // Page indicator
            _buildPageIndicator(),

            const SizedBox(height: 32),

            // Register Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/phone-verification');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '新規登録へ',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required IconData icon,
    required String title,
    required String subtitle,
    required String imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Step number circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryOrange,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
          // Icon
          Icon(
            icon,
            size: 32,
            color: AppColors.primaryOrange.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        bool isActive = _currentPage == index;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? (_currentPage == 0 ? AppColors.primaryOrange : Color(0xFF8B7355))
                : Colors.grey[400],
          ),
        );
      }),
    );
  }
}
