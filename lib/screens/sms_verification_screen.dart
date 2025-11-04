import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../services/didit_service.dart';
import '../services/auth_service.dart';

class SmsVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const SmsVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // 最初のフィールドにフォーカスを設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getVerificationCode() {
    return _controllers.map((c) => c.text).join('');
  }

  bool _isCodeComplete() {
    return _controllers.every((c) => c.text.isNotEmpty);
  }

  Future<void> _verifyCode() async {
    if (!_isCodeComplete()) {
      setState(() {
        _errorMessage = '認証コードを6桁入力してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final code = _getVerificationCode();
    final result = await DiditService.verifyPhoneCode(code);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      // 認証成功 - 電話番号を保存してアカウント作成画面へ
      AuthService.currentUserPhone = result['phone_number'];

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/account-setup',
        (route) => false,
      );
    } else {
      setState(() {
        _errorMessage = result['error'] ?? '認証に失敗しました';
      });
      // エラー時は入力をクリア
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await DiditService.sendPhoneCode(widget.phoneNumber);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('認証コードを再送信しました'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _errorMessage = result['error'] ?? '再送信に失敗しました';
      });
    }
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'SMS認証',
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 説明テキスト
              _buildDescriptionSection(),

              const SizedBox(height: 40),

              // 認証コード入力フィールド
              _buildCodeInputFields(),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // 確認ボタン
              _buildVerifyButton(),

              const SizedBox(height: 24),

              // 再送信リンク
              _buildResendSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    // 電話番号の表示形式を整形
    String displayPhone = widget.phoneNumber;
    if (displayPhone.startsWith('+81')) {
      displayPhone = '0${displayPhone.substring(3)}';
    }

    return Column(
      children: [
        const Icon(
          Icons.phone_android,
          size: 60,
          color: AppColors.primaryOrange,
        ),
        const SizedBox(height: 24),
        Text(
          displayPhone,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '上記の電話番号にSMSで\n6桁の認証コードを送信しました',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeInputFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 45,
          height: 55,
          margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _errorMessage.isNotEmpty
                      ? Colors.red
                      : AppColors.lightGray,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _errorMessage.isNotEmpty
                      ? Colors.red
                      : AppColors.primaryOrange,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              // エラーメッセージをクリア
              if (_errorMessage.isNotEmpty) {
                setState(() {
                  _errorMessage = '';
                });
              }

              if (value.isNotEmpty) {
                // 次のフィールドに自動フォーカス
                if (index < 5) {
                  _focusNodes[index + 1].requestFocus();
                } else {
                  // 最後のフィールドの場合、キーボードを閉じる
                  FocusScope.of(context).unfocus();
                  // 自動で認証を試みる
                  if (_isCodeComplete()) {
                    _verifyCode();
                  }
                }
              }
            },
            onSubmitted: (_) {
              if (index < 5) {
                _focusNodes[index + 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyCode,
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
                '確認',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        const Text(
          'SMSが届かない場合',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isLoading ? null : _resendCode,
          child: const Text(
            '認証コードを再送信',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}