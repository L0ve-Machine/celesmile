import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';

class StripeService {
  // Get base URL from environment
  static String get _baseUrl => '${dotenv.env['API_BASE_URL'] ?? 'https://celesmile-demo.duckdns.org'}/api';

  // PaymentIntentを作成（Direct Charge with Application Fee）
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    required String providerId,
    String currency = 'jpy',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Use backend API for Direct Charge
      final url = Uri.parse('$_baseUrl/stripe/payment-intent');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amount,
          'providerId': providerId,
          'currency': currency,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  // 決済処理を実行（Payment Sheetを使用）
  // 戻り値: {success: bool, paymentIntentId: String?, stripeAccountId: String?}
  static Future<Map<String, dynamic>> processPayment({
    required int amountInCents,
    required String providerId,
    String currency = 'jpy',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔵 [Booking] 決済処理開始');
      print('   - 最終金額: $amountInCents 円');
      print('   - Provider ID: $providerId');
      print('   - Stripe決済開始 (Direct Charge)');

      // 1. PaymentIntentを作成（Direct Charge with Application Fee）
      final paymentIntentData = await createPaymentIntent(
        amount: amountInCents,
        providerId: providerId,
        currency: currency,
        metadata: metadata,
      );

      final clientSecret = paymentIntentData['clientSecret'] as String?;
      final applicationFee = paymentIntentData['applicationFee'] as int?;
      final paymentIntentId = paymentIntentData['paymentIntentId'] as String?;
      final stripeAccountId = paymentIntentData['stripeAccountId'] as String?;

      if (clientSecret == null) {
        throw Exception('Client secret not found in payment intent response');
      }

      print('   - Application Fee (運営手数料): ${applicationFee ?? 0} 円');
      print('   - Provider受取額: ${amountInCents - (applicationFee ?? 0)} 円');
      print('   - Payment Intent ID: $paymentIntentId');

      // Web環境かどうかをチェック
      bool isWeb = identical(0, 0.0);

      if (isWeb) {
        // WEB: Payment Sheetはサポートされていないため、代替処理
        print('   ⚠️  Web環境: Payment Sheet非対応のため、テストモードで自動承認');

        // テスト環境では、Payment Intentが作成された時点で成功とみなす
        // 本番環境では、別の決済フローを実装する必要があります
        print('   ✅ 決済Intent作成成功（Web環境）');
        return {
          'success': true,
          'paymentIntentId': paymentIntentId,
          'stripeAccountId': stripeAccountId,
        };
      } else {
        // MOBILE: 通常のPayment Sheet処理
        // 2. Payment Sheetを初期化
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Celesmile',
            style: ThemeMode.system,
          ),
        );

        // 3. Payment Sheetを表示
        await Stripe.instance.presentPaymentSheet();

        // 決済成功
        print('   ✅ 決済成功');
        return {
          'success': true,
          'paymentIntentId': paymentIntentId,
          'stripeAccountId': stripeAccountId,
        };
      }
    } on StripeException catch (e) {
      // ユーザーがキャンセルした場合
      if (e.error.code == FailureCode.Canceled) {
        print('   ⚠️  決済キャンセル');
        return {'success': false};
      }
      // その他のStripeエラー
      print('   ❌ Stripe エラー: ${e.error.message}');
      throw Exception('Payment failed: ${e.error.message}');
    } catch (e) {
      print('Payment error: $e');
      print('   ❌ 決済エラー: $e');
      throw Exception('Payment processing failed: $e');
    }
  }

  // 保存済みカードで決済を実行
  static Future<bool> processPaymentWithSavedCard({
    required int amountInCents,
    required String providerId,
    required String paymentMethodId,
    String currency = 'jpy',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 1. PaymentIntentを作成（Direct Charge with Application Fee）
      final paymentIntentData = await createPaymentIntent(
        amount: amountInCents,
        providerId: providerId,
        currency: currency,
        metadata: metadata,
      );

      final clientSecret = paymentIntentData['clientSecret'] as String?;
      if (clientSecret == null) {
        throw Exception('Client secret not found in payment intent response');
      }

      // PaymentIntent IDをclientSecretから抽出 (pi_xxxxx_secret_yyyyyy -> pi_xxxxx)
      final paymentIntentId = clientSecret.split('_secret_')[0];

      // 2. PaymentMethodを使用してPaymentIntentを確認
      // Connected Account用にproviderIdも渡す
      final url = Uri.parse('$_baseUrl/stripe/confirm-payment-intent');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'paymentIntentId': paymentIntentId,
          'paymentMethodId': paymentMethodId,
          'providerId': providerId,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final status = result['status'] as String?;

        // 決済が成功したか確認
        if (status == 'succeeded' || status == 'processing') {
          return true;
        } else if (status == 'requires_action') {
          // 3Dセキュア認証が必要な場合
          // Payment Sheetを使用して認証を完了
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: 'Celesmile',
              style: ThemeMode.system,
            ),
          );
          await Stripe.instance.presentPaymentSheet();
          return true;
        } else {
          throw Exception('Payment failed with status: $status');
        }
      } else {
        throw Exception('Failed to confirm payment: ${response.body}');
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        print('Payment canceled by user');
        return false;
      }
      print('Stripe error: ${e.error.message}');
      throw Exception('Payment failed: ${e.error.message}');
    } catch (e) {
      print('Payment error: $e');
      throw Exception('Payment processing failed: $e');
    }
  }

  // SetupIntentを作成（カード情報を保存するため）
  static Future<Map<String, dynamic>> createSetupIntent() async {
    try {
      // Use backend API instead of calling Stripe directly
      final url = Uri.parse('$_baseUrl/stripe/setup-intent');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create setup intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating setup intent: $e');
    }
  }

  // カード情報を登録（SetupIntentを使用）
  static Future<String?> registerCard() async {
    try {
      // 1. SetupIntentを作成
      final setupIntent = await createSetupIntent();

      final clientSecret = setupIntent['client_secret'] as String?;
      if (clientSecret == null) {
        throw Exception('Client secret not found in setup intent response');
      }

      // 2. Payment Sheetを初期化（カード登録用）
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'Celesmile',
          style: ThemeMode.system,
        ),
      );

      // 3. Payment Sheetを表示してカード情報を入力
      await Stripe.instance.presentPaymentSheet();

      // 4. SetupIntentを取得してPaymentMethod IDを取得
      // Use backend API instead of calling Stripe directly
      final setupIntentId = setupIntent['id'] as String?;
      if (setupIntentId != null) {
        // SetupIntentからPaymentMethod IDを取得
        final url = Uri.parse('$_baseUrl/stripe/setup-intent/$setupIntentId');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          final paymentMethodId = result['payment_method'] as String?;

          if (paymentMethodId != null) {
            return paymentMethodId;
          }
        }
      }

      return null;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        print('Card registration canceled by user');
        return null;
      }
      print('Stripe error during card registration: ${e.error.message}');
      throw Exception('Card registration failed: ${e.error.message}');
    } catch (e) {
      print('Card registration error: $e');
      throw Exception('Card registration failed: $e');
    }
  }

  // テスト用：即座に決済を処理
  // 注意: モバイルアプリでのみ完全に動作します
  static Future<bool> processTestPayment({
    required int amountInCents,
    required String providerId,
    String currency = 'jpy',
  }) async {
    try {
      // 1. PaymentIntentを作成（Direct Charge with Application Fee）
      await createPaymentIntent(
        amount: amountInCents,
        providerId: providerId,
        currency: currency,
      );

      // Webではカードフィールドの情報を直接使用できないため、
      // モバイルアプリでの実装が必要です
      return true;
    } catch (e) {
      print('Payment processing error: $e');
      return false;
    }
  }

  // 予約キャンセル（180分ルール適用・返金処理）
  static Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/bookings/$bookingId/cancel');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      throw Exception('Error cancelling booking: $e');
    }
  }
}
