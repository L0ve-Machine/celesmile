import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../services/didit_service.dart';

class PosterRegistrationIntroScreen extends StatefulWidget {
  const PosterRegistrationIntroScreen({super.key});

  @override
  State<PosterRegistrationIntroScreen> createState() => _PosterRegistrationIntroScreenState();
}

class _PosterRegistrationIntroScreenState extends State<PosterRegistrationIntroScreen> {
  bool _isLoading = false;

  Future<void> _startVerification() async {
    setState(() {
      _isLoading = true;
    });

    // 仮のprovider IDを生成（実際には認証済みユーザーのIDを使用）
    final providerId = 'provider_${DateTime.now().millisecondsSinceEpoch}';

    // DIdit認証URL（手動生成済み）
    final verificationUrl = 'https://verify.didit.me/session/4bTr8NeJAylj';

    setState(() {
      _isLoading = false;
    });

    // DIdit認証URLを開く
    final url = Uri.parse(verificationUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);

      // 認証完了後の処理のため、provider-home-dashboardに遷移
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/provider-home-dashboard',
          arguments: providerId,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('認証URLを開けませんでした')),
        );
      }
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
          icon: Icon(Icons.close, color: AppColors.accentBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '掲載をはじめる前に',
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
              const SizedBox(height: 20),
              const Text(
                '掲載前に審査が行われます',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'ミニモではお客様に安心して利用していただくために、利用規約・ガイドラインに基づき掲載情報の審査を行っています。',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Image.asset(
                'assets/images/beingPosterImage.png',
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  // Navigate to details
                },
                child: Text(
                  '審査について詳しくはこちら',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.accentBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ミニモに掲載できる施術',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ミニモでは美容を目的とした施術を掲載の対象としています。\n掲載予定の施術が以下の掲載できない施術に該当していないかご確認の上、メニューの作成を行なってください。',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        // Navigate to details
                      },
                      child: Text(
                        '掲載できない情報・施術についてはこちら',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.accentBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _startVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
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
                    '新規掲載手続きに進む',
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
}
