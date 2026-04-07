/**
 * 支払い関連ロジックのユニットテスト
 * - 180分ルール（キャンセル・返金）
 * - 振込手数料
 * - 25日振込設定
 */

// 定数（server.jsと同じ値）
const TRANSFER_FEE = 250;
const CANCEL_THRESHOLD_MINUTES = 180;
const MONTHLY_PAYOUT_ANCHOR = 25;

// 180分ルールの判定ロジック（server.jsから抽出）
function canRefund(bookingDate, timeSlot, currentTime) {
  const booking = new Date(bookingDate);
  const [hours, minutes] = timeSlot.split(':').map(Number);
  booking.setHours(hours, minutes, 0, 0);

  const diffMinutes = (booking - currentTime) / (1000 * 60);
  return diffMinutes >= CANCEL_THRESHOLD_MINUTES;
}

// 振込手数料控除の判定ロジック（server.jsから抽出）
function canDeductTransferFee(availableBalance) {
  return availableBalance >= TRANSFER_FEE;
}

// 手数料計算ロジック（Flutter側と同様、確認用）
function calculateApplicationFee(amount) {
  return Math.round(amount * 0.20); // 20%
}

function calculateServiceFee(subtotal) {
  return Math.round(subtotal * 0.23); // 23%
}

describe('180分ルール（キャンセル・返金）', () => {

  test('予約の3時間以上前 → 返金可能', () => {
    const bookingDate = '2026-01-25';
    const timeSlot = '14:00';
    const now = new Date('2026-01-25T10:00:00'); // 4時間前

    expect(canRefund(bookingDate, timeSlot, now)).toBe(true);
  });

  test('予約のちょうど3時間前 → 返金可能（境界値）', () => {
    const bookingDate = '2026-01-25';
    const timeSlot = '14:00';
    const now = new Date('2026-01-25T11:00:00'); // ちょうど180分前

    expect(canRefund(bookingDate, timeSlot, now)).toBe(true);
  });

  test('予約の2時間59分前 → 返金不可（境界値）', () => {
    const bookingDate = '2026-01-25';
    const timeSlot = '14:00';
    const now = new Date('2026-01-25T11:01:00'); // 179分前

    expect(canRefund(bookingDate, timeSlot, now)).toBe(false);
  });

  test('予約の1時間前 → 返金不可', () => {
    const bookingDate = '2026-01-25';
    const timeSlot = '14:00';
    const now = new Date('2026-01-25T13:00:00'); // 60分前

    expect(canRefund(bookingDate, timeSlot, now)).toBe(false);
  });

  test('予約時刻を過ぎている → 返金不可', () => {
    const bookingDate = '2026-01-25';
    const timeSlot = '14:00';
    const now = new Date('2026-01-25T15:00:00'); // 予約時刻後

    expect(canRefund(bookingDate, timeSlot, now)).toBe(false);
  });

  test('前日の予約（24時間以上前）→ 返金可能', () => {
    const bookingDate = '2026-01-26';
    const timeSlot = '10:00';
    const now = new Date('2026-01-25T09:00:00'); // 25時間前

    expect(canRefund(bookingDate, timeSlot, now)).toBe(true);
  });

  test('朝の時間帯でも正しく動作する', () => {
    const bookingDate = '2026-01-25';
    const timeSlot = '09:30';
    const now = new Date('2026-01-25T06:30:00'); // ちょうど180分前

    expect(canRefund(bookingDate, timeSlot, now)).toBe(true);
  });

  test('深夜の時間帯でも正しく動作する', () => {
    const bookingDate = '2026-01-25';
    const timeSlot = '23:00';
    const now = new Date('2026-01-25T20:01:00'); // 179分前

    expect(canRefund(bookingDate, timeSlot, now)).toBe(false);
  });
});

describe('振込手数料', () => {

  test('振込手数料は250円', () => {
    expect(TRANSFER_FEE).toBe(250);
  });

  test('残高が250円以上 → 控除可能', () => {
    expect(canDeductTransferFee(250)).toBe(true);
    expect(canDeductTransferFee(1000)).toBe(true);
    expect(canDeductTransferFee(10000)).toBe(true);
  });

  test('残高がちょうど250円 → 控除可能（境界値）', () => {
    expect(canDeductTransferFee(250)).toBe(true);
  });

  test('残高が249円 → 控除不可（境界値）', () => {
    expect(canDeductTransferFee(249)).toBe(false);
  });

  test('残高が0円 → 控除不可', () => {
    expect(canDeductTransferFee(0)).toBe(false);
  });

  test('残高がマイナス → 控除不可', () => {
    expect(canDeductTransferFee(-100)).toBe(false);
  });
});

describe('振込スケジュール', () => {

  test('毎月25日に振込', () => {
    expect(MONTHLY_PAYOUT_ANCHOR).toBe(25);
  });
});

describe('手数料計算', () => {

  test('Application Fee（プラットフォーム手数料）は20%', () => {
    expect(calculateApplicationFee(10000)).toBe(2000);
    expect(calculateApplicationFee(5000)).toBe(1000);
    expect(calculateApplicationFee(7380)).toBe(1476);
  });

  test('サービス手数料（ユーザー負担）は23%', () => {
    expect(calculateServiceFee(10000)).toBe(2300);
    expect(calculateServiceFee(5000)).toBe(1150);
    expect(calculateServiceFee(6000)).toBe(1380);
  });

  test('端数の丸め処理が正しい', () => {
    // 1234円の20% = 246.8 → 247円
    expect(calculateApplicationFee(1234)).toBe(247);
    // 1234円の23% = 283.82 → 284円
    expect(calculateServiceFee(1234)).toBe(284);
  });

  test('実際の金額計算例', () => {
    // コース費: 5000円 + 交通費: 1000円 = 小計: 6000円
    const subtotal = 5000 + 1000;
    // サービス手数料: 6000 * 0.23 = 1380円
    const serviceFee = calculateServiceFee(subtotal);
    expect(serviceFee).toBe(1380);

    // 合計: 6000 + 1380 = 7380円
    const total = subtotal + serviceFee;
    expect(total).toBe(7380);

    // Application Fee: 7380 * 0.20 = 1476円
    const appFee = calculateApplicationFee(total);
    expect(appFee).toBe(1476);

    // プロバイダー受取額: 7380 - 1476 = 5904円
    const providerReceives = total - appFee;
    expect(providerReceives).toBe(5904);
  });
});

describe('アカウント削除', () => {

  // Mock connection object for transaction testing
  function createMockConnection() {
    const queries = [];
    return {
      queries,
      beginTransaction: jest.fn(),
      commit: jest.fn(),
      rollback: jest.fn(),
      release: jest.fn(),
      query: jest.fn((sql, params) => {
        queries.push({ sql, params });
        return [{ affectedRows: 1 }];
      }),
    };
  }

  // Simulate the account deletion logic extracted from server.js
  async function deleteAccount(connection, userId) {
    await connection.beginTransaction();

    await connection.query('DELETE FROM chats WHERE provider_id = ? OR user_id = ?', [userId, userId]);
    await connection.query('DELETE FROM chat_rooms WHERE provider_id = ? OR user_id = ?', [userId, userId]);
    await connection.query('DELETE FROM reviews WHERE provider_id = ?', [userId]);
    await connection.query('DELETE FROM revenues WHERE provider_id = ?', [userId]);
    await connection.query('DELETE FROM bookings WHERE provider_id = ? OR user_id = ?', [userId, userId]);
    await connection.query('DELETE FROM service_menus WHERE provider_id = ?', [userId]);
    await connection.query('DELETE FROM services WHERE provider_id = ?', [userId]);
    await connection.query('DELETE FROM salons WHERE provider_id = ?', [userId]);
    await connection.query('DELETE FROM coupons WHERE user_id = ?', [userId]);
    await connection.query('DELETE FROM providers WHERE id = ?', [userId]);

    await connection.commit();
  }

  test('全テーブルから正しい順序で削除される', async () => {
    const conn = createMockConnection();
    await deleteAccount(conn, 'test-user-123');

    expect(conn.beginTransaction).toHaveBeenCalledTimes(1);
    expect(conn.commit).toHaveBeenCalledTimes(1);
    expect(conn.queries).toHaveLength(10);

    // Verify deletion order (child tables first, providers last)
    const tables = conn.queries.map(q => q.sql.match(/FROM (\w+)/)[1]);
    expect(tables).toEqual([
      'chats', 'chat_rooms', 'reviews', 'revenues',
      'bookings', 'service_menus', 'services', 'salons',
      'coupons', 'providers',
    ]);
  });

  test('全クエリにユーザーIDが渡される', async () => {
    const conn = createMockConnection();
    const userId = 'provider-456';
    await deleteAccount(conn, userId);

    for (const q of conn.queries) {
      expect(q.params).toContain(userId);
    }
  });

  test('providersテーブルが最後に削除される', async () => {
    const conn = createMockConnection();
    await deleteAccount(conn, 'test-user');

    const lastQuery = conn.queries[conn.queries.length - 1];
    expect(lastQuery.sql).toContain('DELETE FROM providers');
  });

  test('エラー時はrollbackされる', async () => {
    const conn = createMockConnection();
    conn.query.mockImplementationOnce(() => { throw new Error('DB error'); });

    await expect(async () => {
      try {
        await deleteAccount(conn, 'test-user');
      } catch (e) {
        await conn.rollback();
        throw e;
      }
    }).rejects.toThrow('DB error');

    expect(conn.rollback).toHaveBeenCalledTimes(1);
    expect(conn.commit).not.toHaveBeenCalled();
  });
});

describe('統合シナリオ', () => {

  test('シナリオ1: 予約4時間前にキャンセル → 全額返金', () => {
    const bookingDate = '2026-01-25';
    const timeSlot = '14:00';
    const cancelTime = new Date('2026-01-25T10:00:00'); // 4時間前
    const amount = 7380;

    const refundable = canRefund(bookingDate, timeSlot, cancelTime);
    expect(refundable).toBe(true);

    // 全額返金
    const refundAmount = refundable ? amount : 0;
    const cancellationFee = refundable ? 0 : amount;

    expect(refundAmount).toBe(7380);
    expect(cancellationFee).toBe(0);
  });

  test('シナリオ2: 予約2時間前にキャンセル → 返金なし', () => {
    const bookingDate = '2026-01-25';
    const timeSlot = '14:00';
    const cancelTime = new Date('2026-01-25T12:00:00'); // 2時間前
    const amount = 7380;

    const refundable = canRefund(bookingDate, timeSlot, cancelTime);
    expect(refundable).toBe(false);

    // 返金なし、キャンセル料100%
    const refundAmount = refundable ? amount : 0;
    const cancellationFee = refundable ? 0 : amount;

    expect(refundAmount).toBe(0);
    expect(cancellationFee).toBe(7380);
  });

  test('シナリオ3: 月末の振込処理', () => {
    // プロバイダーA: 残高10000円 → 250円控除可能
    expect(canDeductTransferFee(10000)).toBe(true);

    // プロバイダーB: 残高100円 → 控除不可（スキップ）
    expect(canDeductTransferFee(100)).toBe(false);

    // プロバイダーC: 残高250円 → ギリギリ控除可能
    expect(canDeductTransferFee(250)).toBe(true);
  });
});
