import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../services/mysql_service.dart';
import '../services/provider_database_service.dart';

class BankRegistrationScreen extends StatefulWidget {
  const BankRegistrationScreen({super.key});

  @override
  State<BankRegistrationScreen> createState() => _BankRegistrationScreenState();
}

class _BankRegistrationScreenState extends State<BankRegistrationScreen> {
  String? _providerId;
  bool _isLoading = true;
  bool _hasStripeAccount = false;
  String? _stripeAccountId;
  Map<String, dynamic>? _accountStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerId = ModalRoute.of(context)?.settings.arguments as String?;
    _checkStripeAccountStatus();
  }

  Future<void> _checkStripeAccountStatus() async {
    if (_providerId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Get provider info to check if stripe_account_id exists
      final provider = await MySQLService.instance.getProviderById(_providerId!);

      if (provider != null && provider['stripe_account_id'] != null) {
        setState(() {
          _hasStripeAccount = true;
          _stripeAccountId = provider['stripe_account_id'];
        });

        // Get account status from Stripe
        final status = await MySQLService.instance.getStripeAccountStatus(_stripeAccountId!);
        setState(() {
          _accountStatus = status;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasStripeAccount = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking Stripe account status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startStripeOnboarding() async {
    if (_providerId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get provider info for email
      final provider = await MySQLService.instance.getProviderById(_providerId!);
      final email = provider?['email'] ?? '';

      String accountId;

      if (_stripeAccountId != null) {
        // Account already exists, create account link
        accountId = _stripeAccountId!;
      } else {
        // Create new Stripe Connect account
        final result = await MySQLService.instance.createStripeConnectAccount(email, _providerId!);
        accountId = result['accountId'];

        setState(() {
          _stripeAccountId = accountId;
          _hasStripeAccount = true;
        });
      }

      // Create account link for onboarding
      final onboardingUrl = await MySQLService.instance.createStripeAccountLink(accountId);

      // Launch Stripe onboarding in browser
      final uri = Uri.parse(onboardingUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stripeの登録画面を開きました。登録完了後、アプリに戻ってください。'),
              backgroundColor: AppColors.primaryOrange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception('Could not launch Stripe onboarding URL');
      }
    } catch (e) {
      print('Error starting Stripe onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '銀行口座情報',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stripeで安全に管理',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[900],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '報酬の振込先は、決済サービスStripeで安全に管理されます。本人確認と口座情報の登録が必要です。',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[800],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status section
                  if (_hasStripeAccount && _accountStatus != null) ...[
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                  ],

                  // Features section
                  const Text(
                    'Stripe登録で利用できる機能',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildFeatureItem(
                    Icons.account_balance,
                    '自動振込',
                    '毎月25日に前月の報酬を自動振込',
                  ),
                  _buildFeatureItem(
                    Icons.security,
                    'セキュアな管理',
                    '銀行口座情報はStripeで暗号化保存',
                  ),
                  _buildFeatureItem(
                    Icons.receipt_long,
                    '取引履歴の確認',
                    '全ての取引履歴をStripeで確認可能',
                  ),
                  _buildFeatureItem(
                    Icons.trending_up,
                    '売上レポート',
                    '詳細な売上分析とレポート機能',
                  ),

                  const SizedBox(height: 32),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _startStripeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _hasStripeAccount && _accountStatus?['details_submitted'] == true
                            ? '登録情報を更新'
                            : 'Stripeで口座登録を開始',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Help text
                  Center(
                    child: Text(
                      '登録は5〜10分程度で完了します',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final chargesEnabled = _accountStatus?['charges_enabled'] ?? false;
    final payoutsEnabled = _accountStatus?['payouts_enabled'] ?? false;
    final detailsSubmitted = _accountStatus?['details_submitted'] ?? false;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (chargesEnabled && payoutsEnabled && detailsSubmitted) {
      statusText = '登録完了';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (detailsSubmitted) {
      statusText = '審査中';
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
    } else {
      statusText = '登録未完了';
      statusColor = Colors.grey;
      statusIcon = Icons.warning_amber;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
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
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (!chargesEnabled || !payoutsEnabled)
                  Text(
                    detailsSubmitted ? '審査完了までお待ちください' : '登録を完了してください',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  )
                else
                  Text(
                    '報酬の受け取りが可能です',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
