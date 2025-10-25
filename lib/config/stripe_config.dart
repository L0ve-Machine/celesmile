import 'package:flutter_dotenv/flutter_dotenv.dart';

// Stripe API Keys Configuration
class StripeConfig {
  // Publishable key (公開可能キー - クライアント側で使用)
  static String get publishableKey =>
    dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? 'pk_test_dummy_key';

  // Secret key (シークレットキー - サーバー側で使用)
  // 注意: 本番環境ではこのキーをクライアント側に含めないでください
  // バックエンドサーバーで管理するべきです
  static String get secretKey =>
    dotenv.env['STRIPE_SECRET_KEY'] ?? 'sk_test_dummy_key';

  // Stripe API base URL
  static const String stripeApiUrl = 'https://api.stripe.com/v1';
}