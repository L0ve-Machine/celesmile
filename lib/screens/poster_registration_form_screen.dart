import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/provider_database_service.dart';

class PosterRegistrationFormScreen extends StatefulWidget {
  const PosterRegistrationFormScreen({super.key});

  @override
  State<PosterRegistrationFormScreen> createState() =>
      _PosterRegistrationFormScreenState();
}

class _PosterRegistrationFormScreenState
    extends State<PosterRegistrationFormScreen> {
  bool _step1Complete = false;
  bool _step2Complete = false;
  bool _step3Complete = false;
  bool _step4Complete = false;

  String? _providerId;
  String? _salonId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.accentBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '新規掲載手続き',
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
              const Text(
                '下記の項目を記入してください',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildStepItem(
                stepNumber: 1,
                title: '掲載者プロフィール',
                isComplete: _step1Complete,
                isActive: true,
                onTap: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/provider-profile-form',
                  );
                  if (result != null && result is Map) {
                    setState(() {
                      _step1Complete = result['completed'] ?? false;
                      _providerId = result['providerId'];
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              _buildStepItem(
                stepNumber: 2,
                title: 'サロン情報',
                isComplete: _step2Complete,
                isActive: _step1Complete,
                onTap: !_step1Complete
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('先にステップ1を完了してください'),
                          ),
                        );
                      }
                    : () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/salon-info-form',
                          arguments: _providerId,
                        );
                        if (result != null && result is Map) {
                          setState(() {
                            _step2Complete = result['completed'] ?? false;
                            _salonId = result['salonId'];
                          });
                        }
                      },
              ),
              const SizedBox(height: 20),
              _buildStepItem(
                stepNumber: 3,
                title: '掲載情報',
                isComplete: _step3Complete,
                isActive: _step2Complete,
                onTap: !_step2Complete
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('先にステップ2を完了してください'),
                          ),
                        );
                      }
                    : () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/listing-information',
                          arguments: {
                            'providerId': _providerId,
                            'salonId': _salonId,
                          },
                        );
                        if (result != null && result is Map) {
                          setState(() {
                            _step3Complete = result['completed'] ?? false;
                          });
                        }
                      },
              ),
              const SizedBox(height: 20),
              _buildStepItem(
                stepNumber: 4,
                title: 'メニュー登録',
                isComplete: _step4Complete,
                isActive: _step3Complete,
                onTap: !_step3Complete
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('先にステップ3を完了してください'),
                          ),
                        );
                      }
                    : () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/menu-registration',
                          arguments: {
                            'providerId': _providerId,
                            'salonId': _salonId,
                          },
                        );
                        if (result != null && result is Map) {
                          setState(() {
                            _step4Complete = result['completed'] ?? false;
                          });
                        }
                      },
              ),
              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '審査提出前にご確認ください',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(
                            text: 'ミニモ運営事務局では',
                          ),
                          TextSpan(
                            text: '利用規約・ガイドライン',
                            style: TextStyle(
                              color: AppColors.accentBlue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(
                            text: 'に基づき、提出された内容を審査します。\n不備がある場合、審査の再提出をお願いする場合があります。',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.accentBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '審査するポイント',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCheckItem('不適切な文字情報が入力されていないか'),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(left: 32),
                      child: Text(
                        '例：「あ」「　」「」などの適当な文字が入力されていると審査が否認されます。',
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: !(_step1Complete &&
                    _step2Complete &&
                    _step3Complete &&
                    _step4Complete)
                ? null
                : () {
                    // Publish service to main database
                    final providerDb = ProviderDatabaseService();
                    providerDb.publishServiceToMainDatabase(
                      _providerId ?? '',
                      _salonId ?? '',
                    );

                    // Show success dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('審査提出完了'),
                        content: const Text(
                          'サービスが正常に審査に提出されました。\n審査完了後、お客様に掲載されます。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Return to dashboard
                            },
                            child: const Text('確認'),
                          ),
                        ],
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: (_step1Complete &&
                      _step2Complete &&
                      _step3Complete &&
                      _step4Complete)
                  ? AppColors.primaryOrange
                  : Colors.grey[400],
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              '審査提出に進む',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String title,
    required bool isComplete,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentBlue : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? Colors.white : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: Center(
                child: isComplete
                    ? Icon(
                        Icons.check,
                        color: isActive ? Colors.white : Colors.grey[600],
                        size: 24,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isActive ? Colors.white : Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check,
          color: Colors.pink,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
