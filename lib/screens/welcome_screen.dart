import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';

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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 15),

                // Logo
                _buildLogo(),

                const SizedBox(height: 15),

                // Illustration
                _buildIllustration(),

                const SizedBox(height: 10),

                // Subtitle
                _buildSubtitle(),

                const SizedBox(height: 15),

                // Welcome title
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 15),

                // Username field
                _buildCompactField('ユーザーネーム', _usernameController, false),

                const SizedBox(height: 10),

                // Password field
                _buildCompactField('パスワード', _passwordController, true),

                const SizedBox(height: 12),

                // Login link
                _buildLoginLink(),

                const SizedBox(height: 15),

                // Terms and conditions text
                _buildTermsText(),

                const SizedBox(height: 12),

                // New registration section
                _buildNewRegistrationSection(),

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
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
      height: 240,
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
          decoration: TextDecoration.underline,
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

      // Regular user - check profile and payment info
      final profile = AuthService.currentUserProfile;
      final paymentInfo = AuthService.currentUserPaymentInfo;

      // プロフィールと決済情報がnullでない場合のみチェック
      // nullの場合は新規ユーザーとして扱う
      if (profile != null && profile.isComplete) {
        if (paymentInfo != null && paymentInfo.isComplete) {
          // すべて完了済み - ダッシュボードへ
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          // プロフィールは完了、決済情報が未完了
          Navigator.pushReplacementNamed(context, '/payment-registration');
        }
      } else {
        // プロフィールが未完了
        Navigator.pushReplacementNamed(context, '/profile-registration');
      }
    } else {
      // ログイン失敗
      if (AuthService.userExists(username)) {
        _showErrorDialog('パスワードが間違っています');
      } else {
        _showErrorDialog('ユーザーが見つかりません');
      }
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

  Widget _buildNewRegistrationSection() {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            // Navigate to onboarding for new registration
            Navigator.pushNamed(context, '/onboarding');
          },
          child: const Text(
            '新規登録',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.orange,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Don't Have an Account?",
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
