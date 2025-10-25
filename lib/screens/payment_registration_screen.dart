import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/stripe_service.dart';
import '../services/payment_method_service.dart';

class PaymentRegistrationScreen extends StatefulWidget {
  const PaymentRegistrationScreen({super.key});

  @override
  State<PaymentRegistrationScreen> createState() =>
      _PaymentRegistrationScreenState();
}

class _PaymentRegistrationScreenState
    extends State<PaymentRegistrationScreen> {
  bool _isLoading = false;
  List<SavedPaymentMethod> _savedCards = [];
  String? _defaultCardId;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
    _cleanupInvalidCards();
  }

  // 無効なカードデータ(SetupIntent ID)を削除
  Future<void> _cleanupInvalidCards() async {
    final cards = await PaymentMethodService.getSavedCards();
    bool needsCleanup = false;

    // SetupIntent IDで始まるカードを検出
    for (var card in cards) {
      if (card.id.startsWith('seti_')) {
        needsCleanup = true;
        break;
      }
    }

    if (needsCleanup) {
      // 全てクリアして再読み込み
      await PaymentMethodService.clearAllCards();
      await _loadSavedCards();
    }
  }

  Future<void> _loadSavedCards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cards = await PaymentMethodService.getSavedCards();
      final defaultId = await PaymentMethodService.getDefaultCardId();

      setState(() {
        _savedCards = cards;
        _defaultCardId = defaultId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 初回登録かどうかを判定（ルートから渡される引数を確認）
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isFirstRegistration = args?['isFirstRegistration'] ?? false;

    return Scaffold(
      backgroundColor: AppColors.lightBeige,
      appBar: AppBar(
        backgroundColor: AppColors.lightBeige,
        elevation: 0,
        title: const Text(
          'お支払い方法',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: isFirstRegistration
            ? [
                TextButton(
                  onPressed: _skipToNext,
                  child: const Text(
                    'あとで登録する',
                    style: TextStyle(
                      color: AppColors.primaryOrange,
                      fontSize: 14,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 保存済みカード一覧
                    if (_savedCards.isNotEmpty) ...[
                      const Text(
                        '保存済みカード',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._savedCards.map((card) => _buildCardItem(card)),
                      const SizedBox(height: 32),
                    ],

                    // 新しいカードを追加ボタン
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addNewCard,
                        icon: const Icon(Icons.add),
                        label: const Text('新しいカードを追加'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryOrange,
                          side: const BorderSide(color: AppColors.primaryOrange),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // セキュリティメッセージ
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'カード情報はStripeにより安全に暗号化・処理されます',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!kIsWeb) ...[
                      const SizedBox(height: 24),

                      // テストカード情報
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'テストモード',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'テスト用カード番号: 4242 4242 4242 4242\n有効期限: 任意の未来の日付\nCVC: 任意の3桁の数字',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCardItem(SavedPaymentMethod card) {
    final isDefault = card.id == _defaultCardId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDefault ? AppColors.primaryOrange : AppColors.lightGray,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // カードブランドアイコン
          Container(
            width: 48,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.secondaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.credit_card,
              color: AppColors.secondaryOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // カード情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isDefault)
                  const Text(
                    'デフォルト',
                    style: TextStyle(
                      color: AppColors.primaryOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // アクションボタン
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'set_default') {
                _setDefaultCard(card.id);
              } else if (value == 'delete') {
                _confirmDeleteCard(card);
              }
            },
            itemBuilder: (context) => [
              if (!isDefault)
                const PopupMenuItem(
                  value: 'set_default',
                  child: Text('デフォルトに設定'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  '削除',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
            icon: Icon(
              Icons.more_vert,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewCard() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Web版ではカード登録機能は利用できません。モバイルアプリをご利用ください。'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // StripeServiceを使ってカードを登録
      final paymentMethodId = await StripeService.registerCard();

      if (paymentMethodId != null) {
        // カード情報を保存（モックデータ）
        // 注: 本番環境ではバックエンドからPaymentMethodの詳細を取得すべき
        final newCard = SavedPaymentMethod(
          id: paymentMethodId,
          last4: '4242', // テストカードの下4桁
          brand: 'visa',
          createdAt: DateTime.now(),
        );

        await PaymentMethodService.saveCard(newCard);

        // 最初のカードの場合、デフォルトに設定
        if (_savedCards.isEmpty) {
          await PaymentMethodService.setDefaultCard(paymentMethodId);
        }

        // リロード
        await _loadSavedCards();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('カードを追加しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カード登録に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setDefaultCard(String cardId) async {
    await PaymentMethodService.setDefaultCard(cardId);
    await _loadSavedCards();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('デフォルトカードを設定しました'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDeleteCard(SavedPaymentMethod card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カードを削除'),
        content: Text('${card.displayName}を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteCard(card.id);
    }
  }

  Future<void> _deleteCard(String cardId) async {
    await PaymentMethodService.deleteCard(cardId);

    // 削除したカードがデフォルトだった場合、残りのカードの最初をデフォルトに設定
    if (cardId == _defaultCardId) {
      final remainingCards = await PaymentMethodService.getSavedCards();
      if (remainingCards.isNotEmpty) {
        await PaymentMethodService.setDefaultCard(remainingCards.first.id);
      }
    }

    await _loadSavedCards();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('カードを削除しました'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _skipToNext() {
    // スキップしてダッシュボードへ
    Navigator.pushReplacementNamed(context, '/dashboard');
  }
}
