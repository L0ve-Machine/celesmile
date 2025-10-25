import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedPaymentMethod {
  final String id; // PaymentMethod ID from Stripe
  final String last4;
  final String brand; // 'visa', 'mastercard', etc.
  final DateTime createdAt;

  SavedPaymentMethod({
    required this.id,
    required this.last4,
    required this.brand,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'last4': last4,
      'brand': brand,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: json['id'] as String,
      last4: json['last4'] as String,
      brand: json['brand'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get displayName {
    final brandUpper = brand.toUpperCase();
    return '$brandUpper •••• $last4';
  }
}

class PaymentMethodService {
  static const String _storageKey = 'saved_payment_methods';

  // 保存済みカードを全て取得
  static Future<List<SavedPaymentMethod>> getSavedCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cardsJson = prefs.getString(_storageKey);

      if (cardsJson == null || cardsJson.isEmpty) {
        return [];
      }

      final List<dynamic> cardsList = json.decode(cardsJson);
      return cardsList
          .map((cardJson) => SavedPaymentMethod.fromJson(cardJson))
          .toList();
    } catch (e) {
      print('Error loading saved cards: $e');
      return [];
    }
  }

  // カードを保存
  static Future<bool> saveCard(SavedPaymentMethod card) async {
    try {
      final cards = await getSavedCards();

      // 同じIDのカードが既に存在する場合は追加しない
      if (cards.any((c) => c.id == card.id)) {
        return false;
      }

      cards.add(card);

      final prefs = await SharedPreferences.getInstance();
      final cardsJson = json.encode(cards.map((c) => c.toJson()).toList());
      await prefs.setString(_storageKey, cardsJson);

      return true;
    } catch (e) {
      print('Error saving card: $e');
      return false;
    }
  }

  // カードを削除
  static Future<bool> deleteCard(String paymentMethodId) async {
    try {
      final cards = await getSavedCards();
      final updatedCards = cards.where((c) => c.id != paymentMethodId).toList();

      final prefs = await SharedPreferences.getInstance();
      final cardsJson = json.encode(updatedCards.map((c) => c.toJson()).toList());
      await prefs.setString(_storageKey, cardsJson);

      return true;
    } catch (e) {
      print('Error deleting card: $e');
      return false;
    }
  }

  // デフォルトカードのIDを取得
  static Future<String?> getDefaultCardId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('default_payment_method_id');
    } catch (e) {
      print('Error getting default card: $e');
      return null;
    }
  }

  // デフォルトカードを設定
  static Future<bool> setDefaultCard(String paymentMethodId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_payment_method_id', paymentMethodId);
      return true;
    } catch (e) {
      print('Error setting default card: $e');
      return false;
    }
  }

  // デフォルトカードを取得
  static Future<SavedPaymentMethod?> getDefaultCard() async {
    try {
      final defaultId = await getDefaultCardId();
      if (defaultId == null) {
        return null;
      }

      final cards = await getSavedCards();
      return cards.firstWhere(
        (card) => card.id == defaultId,
        orElse: () => cards.isNotEmpty ? cards.first : throw Exception('No cards found'),
      );
    } catch (e) {
      print('Error getting default card: $e');
      return null;
    }
  }

  // 全てのカードを削除
  static Future<bool> clearAllCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove('default_payment_method_id');
      return true;
    } catch (e) {
      print('Error clearing cards: $e');
      return false;
    }
  }
}
