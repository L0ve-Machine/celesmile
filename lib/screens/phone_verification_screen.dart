import 'package:flutter/material.dart';
import '../constants/colors.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_updateButtonState);
    _phoneController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _phoneController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '電話番号の確認',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // Handle done action
              FocusScope.of(context).unfocus();
            },
            child: const Text(
              '完了',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description banner
                _buildDescriptionBanner(),

                const SizedBox(height: 30),

                // Phone number label
                _buildPhoneNumberLabel(),

                const SizedBox(height: 12),

                // Phone number input field
                _buildPhoneNumberField(),

                const SizedBox(height: 30),

                // Next button
                _buildNextButton(),

                const SizedBox(height: 30),

                // Notice text
                _buildNoticeText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '掲載ページを公開するには、携帯電話番号の登録が必要です。',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPhoneNumberLabel() {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: '携帯電話番号',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: ' ',
            style: TextStyle(fontSize: 16),
          ),
          TextSpan(
            text: '必須',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textRed,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.lightGray,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.phone_outlined,
            color: AppColors.lightGray,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: AppColors.lightGray,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtonEnabled
            ? () {
                // Handle next action
                // SMS verification would be implemented here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('SMS認証機能は未実装です'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isButtonEnabled ? AppColors.orange : AppColors.buttonDisabled,
          disabledBackgroundColor: AppColors.buttonDisabled,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          '次へ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• 電話番号は本人確認、不正利用防止のために利用します。他のユーザーに公開されることはありません。',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '• 本人確認のため、必ずご自身の携帯電話番号をご登録ください。',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
