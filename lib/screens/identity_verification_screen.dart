import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/provider_database_service.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  String? _selectedIdType;
  String? _uploadedImagePath;
  String? _providerId;
  bool _isUploading = false;

  final Map<String, String> _idTypes = {
    'license': '運転免許証',
    'passport': 'パスポート',
    'mynumber': 'マイナンバーカード',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerId = ModalRoute.of(context)?.settings.arguments as String?;
  }

  void _uploadDocument() {
    // Simulate image upload
    setState(() {
      _isUploading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _uploadedImagePath = 'uploaded_document_${DateTime.now().millisecondsSinceEpoch}.jpg';
          _isUploading = false;
        });
      }
    });
  }

  void _submitVerification() {
    if (_selectedIdType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('本人確認書類の種類を選択してください')),
      );
      return;
    }

    if (_uploadedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('書類の画像をアップロードしてください')),
      );
      return;
    }

    final providerDb = ProviderDatabaseService();

    final verification = IdentityVerification(
      providerId: _providerId ?? '',
      idType: _selectedIdType!,
      idImageUrl: _uploadedImagePath!,
      submittedAt: DateTime.now(),
    );

    providerDb.submitVerification(verification);

    // Auto-approve the verification immediately
    providerDb.updateVerificationStatus(_providerId ?? '', 'approved');

    // Automatically publish all salon services to the main dashboard
    final salons = providerDb.getSalonsByProvider(_providerId ?? '');
    for (var salon in salons) {
      providerDb.publishServiceToMainDatabase(_providerId ?? '', salon.id);
    }

    // Navigate to provider dashboard to show registered view
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/provider-home-dashboard',
      (route) => false,
      arguments: _providerId,
    );

    // Show success message
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('登録完了！審査が承認されました。マイページから空き状況を設定してください。'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '本人確認書類アップロード',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.accentBlue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '本人確認について',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '安全なサービス提供のため、本人確認書類の提出が必要です。提出された情報は厳重に管理されます。',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ID type selection
            const Text(
              '本人確認書類の種類',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '必須',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            ..._idTypes.entries.map((entry) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIdType = entry.key;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedIdType == entry.key
                        ? AppColors.accentBlue.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedIdType == entry.key
                          ? AppColors.accentBlue
                          : AppColors.lightGray,
                      width: _selectedIdType == entry.key ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        entry.key == 'license'
                            ? Icons.credit_card
                            : entry.key == 'passport'
                                ? Icons.book
                                : Icons.badge,
                        color: _selectedIdType == entry.key
                            ? AppColors.accentBlue
                            : Colors.grey[600],
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: _selectedIdType == entry.key
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: _selectedIdType == entry.key
                                ? AppColors.accentBlue
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (_selectedIdType == entry.key)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.accentBlue,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 32),

            // Upload section
            const Text(
              '書類画像のアップロード',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '必須',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_uploadedImagePath == null)
              GestureDetector(
                onTap: _isUploading ? null : _uploadDocument,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.lightGray,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: _isUploading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              CircularProgressIndicator(color: AppColors.accentBlue),
                              SizedBox(height: 16),
                              Text(
                                'アップロード中...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'タップして画像を選択',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'JPG, PNG形式（最大10MB）',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'アップロード完了',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _uploadedImagePath!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _uploadedImagePath = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Guidelines
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppColors.primaryOrange, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '撮影時の注意点',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGuideline('書類全体が写るように撮影してください'),
                  _buildGuideline('文字がはっきり読めるようにしてください'),
                  _buildGuideline('反射や影がないように注意してください'),
                  _buildGuideline('有効期限内の書類を使用してください'),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: (_selectedIdType != null && _uploadedImagePath != null)
                ? _submitVerification
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_selectedIdType != null && _uploadedImagePath != null)
                  ? AppColors.primaryOrange
                  : Colors.grey[400],
              disabledBackgroundColor: Colors.grey[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              '審査に提出する',
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

  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
