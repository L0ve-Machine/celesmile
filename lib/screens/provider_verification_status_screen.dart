import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ProviderVerificationStatusScreen extends StatefulWidget {
  const ProviderVerificationStatusScreen({super.key});

  @override
  State<ProviderVerificationStatusScreen> createState() => _ProviderVerificationStatusScreenState();
}

class _ProviderVerificationStatusScreenState extends State<ProviderVerificationStatusScreen> {
  @override
  Widget build(BuildContext context) {
    // Determine overall verification status
    String overallStatus = 'approved';  // Always approved

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

            const SizedBox(height: 40),
          ],
        ),
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

}
