import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'アカウント作成',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 説明テキスト
              const Text(
                'ログインに使用するユーザー名とパスワードを設定してください',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // ユーザー名
              _buildLabel('ユーザー名'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _usernameController,
                hint: 'ユーザー名を入力',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 8),
              Text(
                '※ 英数字と記号（_ - .）が使用できます（4文字以上）',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 24),

              // パスワード
              _buildLabel('パスワード'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _passwordController,
                hint: 'パスワードを入力',
                isVisible: _isPasswordVisible,
                onToggleVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                '※ 8文字以上で設定してください',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 24),

              // パスワード確認
              _buildLabel('パスワード（確認）'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _passwordConfirmController,
                hint: 'もう一度パスワードを入力',
                isVisible: _isPasswordConfirmVisible,
                onToggleVisibility: () {
                  setState(() {
                    _isPasswordConfirmVisible = !_isPasswordConfirmVisible;
                  });
                },
              ),

              const SizedBox(height: 40),

              // 作成ボタン
              _buildCreateButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: !isVisible,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: onToggleVisibility,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCreateAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          disabledBackgroundColor: AppColors.buttonDisabled,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'アカウントを作成',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  bool _isValidUsername(String username) {
    // 英数字と _ - . のみ許可、4文字以上
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_\-.]{4,}$');
    return usernameRegex.hasMatch(username);
  }

  Future<void> _handleCreateAccount() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;

    // バリデーション
    if (username.isEmpty) {
      _showError('ユーザー名を入力してください');
      return;
    }

    if (!_isValidUsername(username)) {
      _showError('ユーザー名は4文字以上の英数字と記号（_ - .）で入力してください');
      return;
    }

    if (AuthService.userExists(username)) {
      _showError('このユーザー名は既に使用されています');
      return;
    }

    if (password.isEmpty) {
      _showError('パスワードを入力してください');
      return;
    }

    if (password.length < 8) {
      _showError('パスワードは8文字以上で設定してください');
      return;
    }

    if (password != passwordConfirm) {
      _showError('パスワードが一致しません');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // アカウント作成
    final result = await AuthService.createAccount(username, password);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      // 自動ログイン成功 - プロフィール登録画面へ
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/profile-registration',
        );
      }
    } else {
      _showError(result['error'] ?? 'アカウント作成に失敗しました');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
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
}
