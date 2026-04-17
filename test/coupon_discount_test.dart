import 'package:flutter_test/flutter_test.dart';

/// booking_confirmation_screen.dart の _calculateFinalAmountInCents() と
/// 同一ロジックを抽出してテストする
int calculateFinalAmount({
  required int subtotal,
  required int transportationFee,
  required int serviceFeePercent,
  required int usedPoints,
  required String? selectedCoupon,
  required List<Map<String, dynamic>> availableCoupons,
}) {
  int base = subtotal + transportationFee;
  int serviceFee = (base * serviceFeePercent / 100).round();
  int total = base + serviceFee;

  total = total - usedPoints;

  if (selectedCoupon != null) {
    final coupon = availableCoupons.firstWhere((c) => c['id'] == selectedCoupon);
    if (coupon['discount'] is double) {
      total = (total * (1 - coupon['discount'])).round();
    } else {
      total -= coupon['discount'] as int;
    }
  }

  if (total < 0) total = 0;

  return total;
}

void main() {
  group('招待クーポン500円割引テスト', () {
    final couponFromBackend = {
      'id': '3',
      'name': '招待クーポン ¥500 OFF',
      'discount': 500,
      'code': 'CPN-BUGEBD6W',
      'expires_at': '2026-07-17 03:50:50',
    };

    test('5000円のサービスにクーポン適用 → 4500円になる', () {
      final result = calculateFinalAmount(
        subtotal: 5000,
        transportationFee: 0,
        serviceFeePercent: 0,
        usedPoints: 0,
        selectedCoupon: '3',
        availableCoupons: [couponFromBackend],
      );
      expect(result, 4500);
    });

    test('5000円+交通費500円+手数料10%にクーポン適用 → 5550円になる', () {
      // base = 5000 + 500 = 5500, fee = 550, total = 6050, -500 = 5550
      final result = calculateFinalAmount(
        subtotal: 5000,
        transportationFee: 500,
        serviceFeePercent: 10,
        usedPoints: 0,
        selectedCoupon: '3',
        availableCoupons: [couponFromBackend],
      );
      expect(result, 5550);
    });

    test('クーポン未選択 → 割引なし', () {
      final result = calculateFinalAmount(
        subtotal: 5000,
        transportationFee: 0,
        serviceFeePercent: 0,
        usedPoints: 0,
        selectedCoupon: null,
        availableCoupons: [couponFromBackend],
      );
      expect(result, 5000);
    });

    test('300円のサービスに500円クーポン → 0円（マイナスにならない）', () {
      final result = calculateFinalAmount(
        subtotal: 300,
        transportationFee: 0,
        serviceFeePercent: 0,
        usedPoints: 0,
        selectedCoupon: '3',
        availableCoupons: [couponFromBackend],
      );
      expect(result, 0);
    });

    test('ポイント200円+クーポン500円の併用 → 4300円', () {
      final result = calculateFinalAmount(
        subtotal: 5000,
        transportationFee: 0,
        serviceFeePercent: 0,
        usedPoints: 200,
        selectedCoupon: '3',
        availableCoupons: [couponFromBackend],
      );
      expect(result, 4300);
    });

    test('バックエンド実レスポンスのデータ形式でマッピングが正しい', () {
      // バックエンドの実レスポンス
      final backendResponse = {
        'id': 3,
        'code': 'CPN-BUGEBD6W',
        'discount_amount': 500,
        'discount_type': 'fixed',
        'is_used': 0,
        'expires_at': '2026-07-17 03:50:50',
        'source': 'invite_received',
        'created_at': '2026-04-18 03:50:50',
      };

      // _loadCoupons() のマッピングロジック
      final amount = backendResponse['discount_amount'] as int? ?? 0;
      final source = backendResponse['source'] as String? ?? '';
      final label = source == 'invite_received'
          ? '招待クーポン ¥$amount OFF'
          : source == 'invite_given'
              ? '紹介クーポン ¥$amount OFF'
              : 'クーポン ¥$amount OFF';
      final mapped = {
        'id': backendResponse['id'].toString(),
        'name': label,
        'discount': amount,
        'code': backendResponse['code'],
        'expires_at': backendResponse['expires_at'],
      };

      expect(mapped['id'], '3');
      expect(mapped['name'], '招待クーポン ¥500 OFF');
      expect(mapped['discount'], 500);
      expect(mapped['discount'] is int, true);
      expect(mapped['discount'] is double, false);

      // このマッピング結果で割引計算
      final result = calculateFinalAmount(
        subtotal: 5000,
        transportationFee: 0,
        serviceFeePercent: 0,
        usedPoints: 0,
        selectedCoupon: '3',
        availableCoupons: [mapped],
      );
      expect(result, 4500);
    });
  });
}
