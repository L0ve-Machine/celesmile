import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// チャットメッセージモデル
class ChatMessage {
  final String id;
  final String senderId; // ユーザー名 or プロバイダーID
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        senderId: json['senderId'],
        senderName: json['senderName'],
        message: json['message'],
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'] ?? false,
      );
}

// チャットルームモデル
class ChatRoom {
  final String id;
  final String userId; // 利用者のユーザー名
  final String providerId; // プロバイダーID
  final String providerName; // プロバイダー名
  final String serviceName; // サービス名
  final String bookingId; // 予約ID
  final DateTime createdAt;
  final ChatMessage? lastMessage;
  final int unreadCount; // 未読メッセージ数

  ChatRoom({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.providerName,
    required this.serviceName,
    required this.bookingId,
    required this.createdAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'providerId': providerId,
        'providerName': providerName,
        'serviceName': serviceName,
        'bookingId': bookingId,
        'createdAt': createdAt.toIso8601String(),
        'lastMessage': lastMessage?.toJson(),
        'unreadCount': unreadCount,
      };

  factory ChatRoom.fromJson(Map<String, dynamic> json) => ChatRoom(
        id: json['id'],
        userId: json['userId'],
        providerId: json['providerId'],
        providerName: json['providerName'],
        serviceName: json['serviceName'],
        bookingId: json['bookingId'],
        createdAt: DateTime.parse(json['createdAt']),
        lastMessage: json['lastMessage'] != null
            ? ChatMessage.fromJson(json['lastMessage'])
            : null,
        unreadCount: json['unreadCount'] ?? 0,
      );

  // 未読カウントを更新したコピーを返す
  ChatRoom copyWith({
    String? id,
    String? userId,
    String? providerId,
    String? providerName,
    String? serviceName,
    String? bookingId,
    DateTime? createdAt,
    ChatMessage? lastMessage,
    int? unreadCount,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      serviceName: serviceName ?? this.serviceName,
      bookingId: bookingId ?? this.bookingId,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// チャットサービス
///
/// 将来的にFirebaseに移行しやすいように、メソッド名とデータ構造を設計
/// 現在はSharedPreferencesを使用してローカルに保存
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // メモリ内キャッシュ
  final Map<String, List<ChatMessage>> _messagesCache = {};
  final List<ChatRoom> _chatRoomsCache = [];

  static const String _chatRoomsKey = 'chat_rooms';
  static const String _messagesKeyPrefix = 'chat_messages_';

  /// チャットルームを作成（予約完了時に呼び出す）
  Future<ChatRoom> createChatRoom({
    required String userId,
    required String providerId,
    required String providerName,
    required String serviceName,
    required String bookingId,
  }) async {
    print('🔵 [ChatService] チャットルーム作成開始');
    print('   - userId: $userId');
    print('   - providerId: $providerId');
    print('   - providerName: $providerName');
    print('   - serviceName: $serviceName');
    print('   - bookingId: $bookingId');

    final chatRoomId = 'chat_${userId}_${providerId}_${DateTime.now().millisecondsSinceEpoch}';
    print('   - chatRoomId: $chatRoomId');

    final chatRoom = ChatRoom(
      id: chatRoomId,
      userId: userId,
      providerId: providerId,
      providerName: providerName,
      serviceName: serviceName,
      bookingId: bookingId,
      createdAt: DateTime.now(),
    );

    // 全てのチャットルームを取得（全ユーザー分）
    final allRooms = await _getAllChatRooms();
    print('   - 既存チャットルーム数: ${allRooms.length}');

    allRooms.insert(0, chatRoom);
    print('   - 新しいチャットルーム数: ${allRooms.length}');

    // SharedPreferencesに保存
    await _saveChatRooms(allRooms);
    print('   - SharedPreferencesに保存完了');

    // キャッシュに追加
    _chatRoomsCache.insert(0, chatRoom);

    // 初期メッセージを送信（システムメッセージ）
    await sendMessage(
      chatRoomId: chatRoomId,
      senderId: 'system',
      senderName: 'システム',
      message: '予約が確定しました。$providerNameさんとチャットを開始できます。',
    );

    print('🟢 [ChatService] チャットルーム作成完了');
    return chatRoom;
  }

  /// 全てのチャットルームを取得（フィルタリングなし）
  Future<List<ChatRoom>> _getAllChatRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final roomsJson = prefs.getString(_chatRoomsKey);

    if (roomsJson == null) {
      return [];
    }

    final List<dynamic> decoded = json.decode(roomsJson);
    return decoded.map((r) => ChatRoom.fromJson(r)).toList();
  }

  /// チャットルーム一覧を取得
  Future<List<ChatRoom>> getChatRooms(String userId) async {
    print('🔵 [ChatService] チャットルーム一覧取得: userId=$userId');

    final prefs = await SharedPreferences.getInstance();
    final roomsJson = prefs.getString(_chatRoomsKey);

    if (roomsJson == null) {
      print('   - チャットルームなし（SharedPreferencesが空）');
      return [];
    }

    final List<dynamic> decoded = json.decode(roomsJson);
    final allRooms = decoded.map((r) => ChatRoom.fromJson(r)).toList();
    print('   - 全チャットルーム数: ${allRooms.length}');

    // 現在のユーザーに関連するチャットルームのみを返す
    final userRooms = allRooms.where((room) => room.userId == userId || room.providerId == userId).toList();
    print('   - ユーザー $userId のチャットルーム数: ${userRooms.length}');

    for (var room in userRooms) {
      print('     - ${room.id}: ${room.serviceName} (provider: ${room.providerName})');
    }

    return userRooms;
  }

  /// プロバイダー用：チャットルーム一覧を取得
  Future<List<ChatRoom>> getChatRoomsByProvider(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    final roomsJson = prefs.getString(_chatRoomsKey);

    if (roomsJson == null) {
      return [];
    }

    final List<dynamic> decoded = json.decode(roomsJson);
    final allRooms = decoded.map((r) => ChatRoom.fromJson(r)).toList();

    return allRooms.where((room) => room.providerId == providerId).toList();
  }

  /// チャットルームをIDで取得
  Future<ChatRoom?> getChatRoomById(String chatRoomId) async {
    final allRooms = await _getAllChatRooms();
    try {
      return allRooms.firstWhere((room) => room.id == chatRoomId);
    } catch (e) {
      return null;
    }
  }

  /// チャットルームを保存
  Future<void> _saveChatRooms(List<ChatRoom> rooms) async {
    final prefs = await SharedPreferences.getInstance();
    final roomsJson = json.encode(rooms.map((r) => r.toJson()).toList());
    await prefs.setString(_chatRoomsKey, roomsJson);
  }

  /// メッセージを送信
  Future<ChatMessage> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    final chatMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // メッセージをキャッシュに追加
    if (!_messagesCache.containsKey(chatRoomId)) {
      _messagesCache[chatRoomId] = [];
    }
    _messagesCache[chatRoomId]!.insert(0, chatMessage);

    // SharedPreferencesに保存
    await _saveMessages(chatRoomId, _messagesCache[chatRoomId]!);

    // チャットルームの最終メッセージと未読カウントを更新
    await _updateChatRoomLastMessage(chatRoomId, chatMessage, senderId);

    return chatMessage;
  }

  /// メッセージ一覧を取得
  Future<List<ChatMessage>> getMessages(String chatRoomId) async {
    // キャッシュにあればそれを返す
    if (_messagesCache.containsKey(chatRoomId)) {
      return List.from(_messagesCache[chatRoomId]!);
    }

    // SharedPreferencesから読み込み
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('$_messagesKeyPrefix$chatRoomId');

    if (messagesJson == null) {
      return [];
    }

    final List<dynamic> decoded = json.decode(messagesJson);
    final messages = decoded.map((m) => ChatMessage.fromJson(m)).toList();

    // キャッシュに保存
    _messagesCache[chatRoomId] = messages;

    return messages;
  }

  /// メッセージを保存
  Future<void> _saveMessages(String chatRoomId, List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = json.encode(messages.map((m) => m.toJson()).toList());
    await prefs.setString('$_messagesKeyPrefix$chatRoomId', messagesJson);
  }

  /// チャットルームの最終メッセージを更新
  Future<void> _updateChatRoomLastMessage(
    String chatRoomId,
    ChatMessage lastMessage,
    String senderId,
  ) async {
    print('🔵 [ChatService] チャットルーム最終メッセージ更新: $chatRoomId');

    final rooms = await _getAllChatRooms();

    final index = rooms.indexWhere((r) => r.id == chatRoomId);
    if (index == -1) {
      print('   ⚠️ チャットルームが見つかりません: $chatRoomId');
      return;
    }

    final room = rooms[index];

    // 未読カウントを増やす（送信者以外の場合）
    int newUnreadCount = room.unreadCount;

    // 更新されたチャットルーム
    final updatedRoom = room.copyWith(
      lastMessage: lastMessage,
      unreadCount: newUnreadCount,
    );

    rooms[index] = updatedRoom;

    // 最新メッセージがあるチャットルームを先頭に移動
    rooms.removeAt(index);
    rooms.insert(0, updatedRoom);

    await _saveChatRooms(rooms);
    print('   - 最終メッセージ更新完了');

    // キャッシュも更新
    final cacheIndex = _chatRoomsCache.indexWhere((r) => r.id == chatRoomId);
    if (cacheIndex != -1) {
      _chatRoomsCache.removeAt(cacheIndex);
      _chatRoomsCache.insert(0, updatedRoom);
    }
  }

  /// メッセージを既読にする
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    final messages = await getMessages(chatRoomId);

    bool hasUnread = false;
    final updatedMessages = messages.map((msg) {
      if (msg.senderId != userId && !msg.isRead) {
        hasUnread = true;
        return ChatMessage(
          id: msg.id,
          senderId: msg.senderId,
          senderName: msg.senderName,
          message: msg.message,
          timestamp: msg.timestamp,
          isRead: true,
        );
      }
      return msg;
    }).toList();

    if (hasUnread) {
      _messagesCache[chatRoomId] = updatedMessages;
      await _saveMessages(chatRoomId, updatedMessages);

      // チャットルームの未読カウントを0にする
      await _resetUnreadCount(chatRoomId);
    }
  }

  /// 未読カウントをリセット
  Future<void> _resetUnreadCount(String chatRoomId) async {
    final rooms = await _getAllChatRooms();

    final index = rooms.indexWhere((r) => r.id == chatRoomId);
    if (index == -1) return;

    rooms[index] = rooms[index].copyWith(unreadCount: 0);
    await _saveChatRooms(rooms);

    // キャッシュも更新
    final cacheIndex = _chatRoomsCache.indexWhere((r) => r.id == chatRoomId);
    if (cacheIndex != -1) {
      _chatRoomsCache[cacheIndex] = _chatRoomsCache[cacheIndex].copyWith(unreadCount: 0);
    }
  }

  /// 全体の未読メッセージ数を取得
  Future<int> getTotalUnreadCount(String userId) async {
    final rooms = await getChatRooms(userId);
    return rooms.fold<int>(0, (sum, room) => sum + room.unreadCount);
  }

  /// チャットルームを削除
  Future<void> deleteChatRoom(String chatRoomId) async {
    final prefs = await SharedPreferences.getInstance();
    final rooms = await _getAllChatRooms();

    rooms.removeWhere((r) => r.id == chatRoomId);
    await _saveChatRooms(rooms);

    // メッセージも削除
    await prefs.remove('$_messagesKeyPrefix$chatRoomId');

    // キャッシュからも削除
    _chatRoomsCache.removeWhere((r) => r.id == chatRoomId);
    _messagesCache.remove(chatRoomId);
  }

  /// キャッシュをクリア（ログアウト時など）
  void clearCache() {
    _messagesCache.clear();
    _chatRoomsCache.clear();
  }
}
