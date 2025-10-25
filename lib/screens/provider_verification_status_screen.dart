import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/provider_database_service.dart';

class ProviderVerificationStatusScreen extends StatefulWidget {
  const ProviderVerificationStatusScreen({super.key});

  @override
  State<ProviderVerificationStatusScreen> createState() => _ProviderVerificationStatusScreenState();
}

class _ProviderVerificationStatusScreenState extends State<ProviderVerificationStatusScreen> {
  String? _providerId;
  final providerDb = ProviderDatabaseService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerId = ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  Widget build(BuildContext context) {
    final provider = _providerId != null ? providerDb.getProvider(_providerId!) : null;
    final verification = _providerId != null ? providerDb.getVerification(_providerId!) : null;
    final bankAccount = _providerId != null ? providerDb.getBankAccount(_providerId!) : null;
    final salons = _providerId != null ? providerDb.getSalonsByProvider(_providerId!) : [];

    // Determine overall verification status
    String overallStatus = 'pending';
    if (verification != null && verification.verificationStatus == 'approved') {
      overallStatus = 'approved';
    } else if (verification != null && verification.verificationStatus == 'rejected') {
      overallStatus = 'rejected';
    }

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
          '審査状況',
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
            // Overall status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor(overallStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(overallStatus),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(overallStatus),
                    size: 64,
                    color: _getStatusColor(overallStatus),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getStatusTitle(overallStatus),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(overallStatus),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusMessage(overallStatus),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Verification details
            const Text(
              '審査項目',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Identity verification
            _buildVerificationItem(
              title: '本人確認書類',
              status: verification?.verificationStatus ?? 'not_submitted',
              details: verification != null
                  ? '${_getIdTypeName(verification.idType)} - ${_formatDate(verification.submittedAt)}'
                  : '未提出',
              rejectionReason: verification?.rejectionReason,
            ),

            const SizedBox(height: 12),

            // Bank account
            _buildVerificationItem(
              title: '銀行口座情報',
              status: bankAccount != null ? 'approved' : 'not_submitted',
              details: bankAccount != null
                  ? '${bankAccount.bankName} ${bankAccount.branchName}'
                  : '未登録',
            ),

            const SizedBox(height: 12),

            // Salon information
            _buildVerificationItem(
              title: 'サロン情報',
              status: salons.isNotEmpty ? 'approved' : 'not_submitted',
              details: salons.isNotEmpty
                  ? '${salons.length}件のサロン登録済み'
                  : '未登録',
            ),

            if (verification?.verificationStatus == 'rejected') ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '審査非承認の理由',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      verification?.rejectionReason ?? '理由が記載されていません',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationItem({
    required String title,
    required String status,
    required String details,
    String? rejectionReason,
  }) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = '承認済み';
        break;
      case 'pending':
        statusColor = AppColors.primaryOrange;
        statusIcon = Icons.pending;
        statusText = '審査中';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = '非承認';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.remove_circle_outline;
        statusText = '未提出';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return AppColors.primaryOrange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'approved':
        return '審査承認済み';
      case 'pending':
        return '審査中';
      case 'rejected':
        return '審査非承認';
      default:
        return '未申請';
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'approved':
        return 'おめでとうございます！審査が承認されました。\nサービスの掲載を開始できます。';
      case 'pending':
        return '現在審査中です。\n通常1〜2営業日以内に結果をお知らせします。';
      case 'rejected':
        return '審査が非承認となりました。\n下記の理由をご確認の上、再度申請してください。';
      default:
        return 'まだ審査申請が完了していません。';
    }
  }

  String _getIdTypeName(String idType) {
    switch (idType) {
      case 'license':
        return '運転免許証';
      case 'passport':
        return 'パスポート';
      case 'mynumber':
        return 'マイナンバーカード';
      default:
        return idType;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
