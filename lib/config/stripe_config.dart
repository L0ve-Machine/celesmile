import 'package:flutter_dotenv/flutter_dotenv.dart';

// Stripe API Keys Configuration
class StripeConfig {
  // Publishable key (公開可能キー - クライアント側で使用)
  static String get publishableKey =>
    dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? 'pk_test_dummy_key';

  // SECURITY NOTE: Secret key is ONLY stored on the backend server
  // Never include Stripe secret key in client-side code
  // All sensitive Stripe operations are handled via backend API endpoints
}