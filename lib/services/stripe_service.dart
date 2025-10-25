import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';

class StripeService {
  // PaymentIntentを作成
  // 注意: 本番環境ではバックエンドAPIで実装すべきです
  // 現在はプロトタイプとしてクライアント側で実装しています
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    String currency = 'jpy',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final url = Uri.parse('${StripeConfig.stripeApiUrl}/payment_intents');

      final body = {
        'amount': amount.toString(),
        'currency': currency,
        'automatic_payment_methods[enabled]': 'true',
        'automatic_payment_methods[allow_redirects]': 'never',
      };

      // Add metadata if provided
      if (metadata != null) {
        metadata.forEach((key, value) {
          body['metadata[$key]'] = value.toString();
        });
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
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
  static Future<bool> processPayment({
    required int amountInCents,
    String currency = 'jpy',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 1. PaymentIntentを作成
      final paymentIntentData = await createPaymentIntent(
        amount: amountInCents,
        currency: currency,
        metadata: metadata,
      );

      final clientSecret = paymentIntentData['client_secret'] as String?;
      if (clientSecret == null) {
        throw Exception('Client secret not found in payment intent response');
      }

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
      return true;
    } on StripeException catch (e) {
      // ユーザーがキャンセルした場合
      if (e.error.code == FailureCode.Canceled) {
        print('Payment canceled by user');
        return false;
      }
      // その他のStripeエラー
      print('Stripe error: ${e.error.message}');
      throw Exception('Payment failed: ${e.error.message}');
    } catch (e) {
      print('Payment error: $e');
      throw Exception('Payment processing failed: $e');
    }
  }

  // 保存済みカードで決済を実行
  static Future<bool> processPaymentWithSavedCard({
    required int amountInCents,
    required String paymentMethodId,
    String currency = 'jpy',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 1. PaymentIntentを作成
      final paymentIntentData = await createPaymentIntent(
        amount: amountInCents,
        currency: currency,
        metadata: metadata,
      );

      final clientSecret = paymentIntentData['client_secret'] as String?;
      if (clientSecret == null) {
        throw Exception('Client secret not found in payment intent response');
      }

      // 2. PaymentMethodを使用してPaymentIntentを確認
      // 注: 本番環境ではバックエンドで実装すべきです
      final url = Uri.parse('${StripeConfig.stripeApiUrl}/payment_intents/${paymentIntentData['id']}/confirm');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_method': paymentMethodId,
        },
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
      final url = Uri.parse('${StripeConfig.stripeApiUrl}/setup_intents');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_method_types[]': 'card',
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
      // 注: 本番環境ではバックエンドで実装すべき
      final setupIntentId = setupIntent['id'] as String?;
      if (setupIntentId != null) {
        // SetupIntentからPaymentMethod IDを取得
        final url = Uri.parse('${StripeConfig.stripeApiUrl}/setup_intents/$setupIntentId');
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer ${StripeConfig.secretKey}',
          },
        );

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
    String currency = 'jpy',
  }) async {
    try {
      // 1. PaymentIntentを作成
      await createPaymentIntent(
        amount: amountInCents,
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
}
