import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../widgets/orange_wave_painter.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBeige,
      resizeToAvoidBottomInset: false, // キーボード表示時の自動リサイズを無効化
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Bottom left orange decoration (placed first, at absolute bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: null,
            child: Image.asset(
              'assets/images/orange_bottom.png',
              width: MediaQuery.of(context).size.width * 0.6,
              fit: BoxFit.contain,
              alignment: Alignment.bottomLeft,
            ),
          ),
          // Main content - completely fixed, no scrolling
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                const SizedBox(height: 10),

                // Logo
                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/images/logoForLogin.png',
                      height: 68,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 75),

                // Illustration
                Image.asset(
                  'assets/images/front.png',
                  width: double.infinity,
                  height: 210,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 8),

                // Subtitle
                _buildSubtitle(),

                const SizedBox(height: 12),

                // Welcome title
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontFamily: 'Qilka',
                    fontSize: 35,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5C4033),
                    letterSpacing: 1.0,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                // Username field
                _buildCompactField('ユーザーネーム', _usernameController, false),

                const SizedBox(height: 8),

                // Password field
                _buildCompactField('パスワード', _passwordController, true),

                const SizedBox(height: 10),

                // Login link
                _buildLoginLink(),

                const SizedBox(height: 10),

                // Terms and conditions text
                _buildTermsText(),

                const SizedBox(height: 40),
                ],
              ),
            ),
            ),
          ),
        // Top right orange decoration
        Positioned(
          top: 0,
          right: 0,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/orange_top.png',
              width: MediaQuery.of(context).size.width * 0.6,
              fit: BoxFit.contain,
            ),
          ),
        ),
        // Bottom right registration section - fixed position
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32, right: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/onboarding');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '新規登録',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "パスワードがわかりませんか？",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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

  Widget _buildLogo() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/images/logo.png',
        height: 70,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildIllustration() {
    return Image.asset(
      'assets/images/front.png',
      width: double.infinity,
      height: 220,
      fit: BoxFit.contain,
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      '自宅に呼べる、暮らしの出張ケアアプリ',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCompactField(String label, TextEditingController controller, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '',
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return TextButton(
      onPressed: _handleLogin,
      child: const Text(
        'ログイン',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryOrange,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // 入力チェック
    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog('ユーザーネームとパスワードを入力してください');
      return;
    }

    // 認証
    if (await AuthService.login(username, password)) {
      // Check if user is a provider
      if (AuthService.isProvider) {
        // Provider user - go to provider dashboard
        Navigator.pushReplacementNamed(
          context,
          '/provider-home-dashboard',
          arguments: AuthService.currentUserProviderId,
        );
        return;
      }

      // Regular user - check profile
      final profile = AuthService.currentUserProfile;

      // プロフィールがnullでない場合のみチェック
      // nullの場合は新規ユーザーとして扱う
      if (profile != null && profile.isComplete) {
        // プロフィール完了済み - ダッシュボードへ
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // プロフィールが未完了
        Navigator.pushReplacementNamed(context, '/profile-registration');
      }
    } else {
      // ログイン失敗 - AuthServiceから詳細なエラーメッセージを取得
      final errorMessage = AuthService.lastLoginError ?? 'ログインに失敗しました';
      _showErrorDialog(errorMessage);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログインエラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsText() {
    return const Text(
      '登録することでCelestcareの利用規約・\nおよびプライバシーポリシーに同意するものとします',
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

}
