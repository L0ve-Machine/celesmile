import 'mysql_service.dart';
import 'auth_service.dart';

// チャットメッセージモデル
class ChatMessage {
  final String id;
  final String senderId; // ユーザー名 or プロバイダーID
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String senderType; // 'user' or 'provider'

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.senderType = 'user',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'senderType': senderType,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] ?? '',
        senderId: json['senderId'] ?? json['sender_id'] ?? json['user_id'] ?? '',
        senderName: json['senderName'] ?? json['sender_name'] ?? '',
        message: json['message'] ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
        isRead: json['isRead'] ?? json['is_read'] ?? false,
        senderType: json['senderType'] ?? json['sender_type'] ?? 'user',
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

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    // last_messageがある場合はChatMessageを作成
    ChatMessage? lastMsg;
    if (json['last_message'] != null && json['last_message'].toString().isNotEmpty) {
      lastMsg = ChatMessage(
        id: 'last',
        senderId: '',
        senderName: '',
        message: json['last_message'],
        timestamp: json['last_message_time'] != null
            ? DateTime.parse(json['last_message_time'])
            : DateTime.now(),
      );
    } else if (json['lastMessage'] != null) {
      lastMsg = ChatMessage.fromJson(json['lastMessage']);
    }

    return ChatRoom(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      providerId: json['providerId'] ?? json['provider_id'] ?? '',
      providerName: json['providerName'] ?? json['provider_name'] ?? '不明',
      serviceName: json['serviceName'] ?? json['service_name'] ?? '',
      bookingId: json['bookingId'] ?? json['booking_id'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now()),
      lastMessage: lastMsg,
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
    );
  }

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
/// MySQLデータベースを使用してチャットデータを管理
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

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

    final chatRoomId = 'room_${providerId}_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    print('   - chatRoomId: $chatRoomId');

    // APIでチャットルームを作成
    final result = await MySQLService.instance.createChatRoom(
      id: chatRoomId,
      providerId: providerId,
      userId: userId,
      bookingId: bookingId,
    );

    String finalRoomId = chatRoomId;
    if (result != null && result['existing'] == true) {
      // 既存のルームがある場合はそのIDを使用
      finalRoomId = result['id'];
      print('   - 既存のチャットルームを使用: $finalRoomId');
    }

    final chatRoom = ChatRoom(
      id: finalRoomId,
      userId: userId,
      providerId: providerId,
      providerName: providerName,
      serviceName: serviceName,
      bookingId: bookingId,
      createdAt: DateTime.now(),
    );

    // 初期メッセージを送信（システムメッセージ）
    await sendMessage(
      chatRoomId: finalRoomId,
      senderId: 'system',
      senderName: 'システム',
      message: '予約が確定しました。$providerNameさんとチャットを開始できます。',
    );

    print('🟢 [ChatService] チャットルーム作成完了');
    return chatRoom;
  }

  /// チャットルーム一覧を取得（購入者用）
  Future<List<ChatRoom>> getChatRooms(String userId) async {
    print('🔵 [ChatService] チャットルーム一覧取得: userId=$userId');

    final roomsData = await MySQLService.instance.getChatRoomsForUser(userId);
    print('   - 取得したチャットルーム数: ${roomsData.length}');

    final rooms = roomsData.map((r) => ChatRoom.fromJson(r)).toList();

    for (var room in rooms) {
      print('     - ${room.id}: ${room.providerName}');
    }

    return rooms;
  }

  /// プロバイダー用：チャットルーム一覧を取得
  Future<List<ChatRoom>> getChatRoomsByProvider(String providerId) async {
    print('🔵 [ChatService] プロバイダーのチャットルーム一覧取得: providerId=$providerId');

    final roomsData = await MySQLService.instance.getChatRoomsForProvider(providerId);
    print('   - 取得したチャットルーム数: ${roomsData.length}');

    final rooms = roomsData.map((r) => ChatRoom.fromJson(r)).toList();

    for (var room in rooms) {
      print('     - ${room.id}: ${room.userId}');
    }

    return rooms;
  }

  /// チャットルームをIDで取得
  Future<ChatRoom?> getChatRoomById(String chatRoomId) async {
    print('🔵 [ChatService] チャットルーム取得: roomId=$chatRoomId');

    final roomData = await MySQLService.instance.getChatRoomById(chatRoomId);
    if (roomData == null) {
      print('   - チャットルームが見つかりません');
      return null;
    }

    return ChatRoom.fromJson(roomData);
  }

  /// メッセージを送信
  Future<ChatMessage> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    print('🔵 [ChatService] メッセージ送信: roomId=$chatRoomId');

    // sender_typeを判定
    final currentProviderId = AuthService.currentUserProviderId;
    final isProvider = currentProviderId != null && senderId != 'system';
    final senderType = senderId == 'system' ? 'user' : (isProvider ? 'provider' : 'user');

    // APIでメッセージを送信
    final result = await MySQLService.instance.sendMessageToChatRoom(
      roomId: chatRoomId,
      senderType: senderType,
      message: message,
    );

    final messageId = result?['id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}';

    final chatMessage = ChatMessage(
      id: messageId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      senderType: senderType,
    );

    print('   - メッセージ送信完了: $messageId');
    return chatMessage;
  }

  /// メッセージ一覧を取得
  Future<List<ChatMessage>> getMessages(String chatRoomId) async {
    print('🔵 [ChatService] メッセージ一覧取得: roomId=$chatRoomId');

    final messagesData = await MySQLService.instance.getChatRoomMessages(chatRoomId);
    print('   - 取得したメッセージ数: ${messagesData.length}');

    final messages = messagesData.map((m) => ChatMessage.fromJson(m)).toList();

    // 最新が最初になるように逆順で返す
    return messages.reversed.toList();
  }

  /// メッセージを既読にする
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    // TODO: API側に既読機能を追加
    print('🔵 [ChatService] メッセージ既読処理: roomId=$chatRoomId');
  }

  /// 全体の未読メッセージ数を取得
  Future<int> getTotalUnreadCount(String userId) async {
    final rooms = await getChatRooms(userId);
    return rooms.fold<int>(0, (sum, room) => sum + room.unreadCount);
  }

  /// チャットルームを削除（現在は未実装）
  Future<void> deleteChatRoom(String chatRoomId) async {
    // TODO: API側に削除機能を追加
    print('🔵 [ChatService] チャットルーム削除（未実装）: roomId=$chatRoomId');
  }
}
