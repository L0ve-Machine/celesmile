import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'dart:async';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _chatRoomId;
  ChatRoom? _chatRoom;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // 定期的にメッセージを更新（簡易的なリアルタイム更新）
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_chatRoomId != null) {
        _loadMessages(silent: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // チャットルームIDを取得
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is String && _chatRoomId == null) {
      _chatRoomId = arguments;
      _loadChatRoom();
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChatRoom() async {
    try {
      print('🔵 [ChatRoom] チャットルーム読み込み開始: $_chatRoomId');

      // IDでチャットルームを検索（ユーザー・プロバイダー両方に対応）
      final room = await _chatService.getChatRoomById(_chatRoomId!);

      if (room == null) {
        throw Exception('チャットルームが見つかりません');
      }

      print('   - チャットルーム見つかりました: ${room.serviceName}');

      setState(() {
        _chatRoom = room;
      });
    } catch (e) {
      print('   ⚠️ エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('チャットルームの読み込みに失敗しました: $e')),
        );
        // エラー時は前の画面に戻る
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (_chatRoomId != null) {
        final messages = await _chatService.getMessages(_chatRoomId!);

        if (mounted) {
          setState(() {
            _messages = messages;
            if (!silent) {
              _isLoading = false;
            }
          });
        }
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メッセージの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _chatRoomId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final currentUser = AuthService.currentUser;
      final currentUserProfile = AuthService.currentUserProfile;

      if (currentUser == null) {
        throw Exception('ログインが必要です');
      }

      final senderName = currentUserProfile?.name ?? currentUser;

      // チャットルームにおける自分の役割で sender_type を判定
      // チャットルームの user_id と現在のユーザーが一致すれば 'user'、そうでなければ 'provider'
      final senderType = _chatRoom?.userId == currentUser ? 'user' : 'provider';

      await _chatService.sendMessage(
        chatRoomId: _chatRoomId!,
        senderId: currentUser,
        senderName: senderName,
        message: messageText,
        senderType: senderType,
      );

      // メッセージ送信後、入力欄をクリア
      _messageController.clear();

      // メッセージ一覧を再読み込み
      await _loadMessages(silent: true);

      // 最新メッセージまでスクロール
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メッセージの送信に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '今日';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return '昨日';
    } else {
      return '${date.year}年${date.month}月${date.day}日';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chatRoom == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('チャット'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // プロバイダーの場合はユーザー名を、ユーザーの場合はプロバイダー名を表示
              AuthService.currentUserProviderId != null
                  ? _chatRoom!.userId
                  : _chatRoom!.providerName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _chatRoom!.serviceName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.grey[300], height: 1),
        ),
      ),
      body: Column(
        children: [
          // メッセージリスト
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true, // 最新メッセージが下
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final previousMessage =
                              index < _messages.length - 1
                                  ? _messages[index + 1]
                                  : null;

                          // 日付ヘッダーを表示するか判定
                          bool showDateHeader = false;
                          if (previousMessage == null) {
                            showDateHeader = true;
                          } else {
                            final prevDate = DateTime(
                              previousMessage.timestamp.year,
                              previousMessage.timestamp.month,
                              previousMessage.timestamp.day,
                            );
                            final currDate = DateTime(
                              message.timestamp.year,
                              message.timestamp.month,
                              message.timestamp.day,
                            );
                            showDateHeader = prevDate != currDate;
                          }

                          return Column(
                            children: [
                              if (showDateHeader)
                                _buildDateHeader(message.timestamp),
                              _buildMessageBubble(message),
                            ],
                          );
                        },
                      ),
          ),

          // メッセージ入力欄
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'メッセージを送信して\nチャットを開始しましょう',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatDateHeader(date),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // チャットルームにおける自分の役割で判定
    // チャットルームの user_id と現在のユーザーが一致すれば、自分は 'user' 側
    final currentUser = AuthService.currentUser;
    final isUserInThisRoom = _chatRoom?.userId == currentUser;

    // 自分の役割と message.senderType が一致すれば自分のメッセージ
    final isMyMessage = isUserInThisRoom
        ? message.senderType == 'user'
        : message.senderType == 'provider';
    final isSystemMessage = message.senderId == 'system' || message.senderType == 'system';

    // デバッグログ
    print('🔵 [ChatBubble] currentUser: $currentUser, chatRoom.userId: ${_chatRoom?.userId}');
    print('🔵 [ChatBubble] isUserInThisRoom: $isUserInThisRoom, senderType: ${message.senderType}, isMyMessage: $isMyMessage');

    if (isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              message.message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[900],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondaryOrange.withOpacity(0.3),
              child: const Icon(
                Icons.person,
                color: AppColors.primaryOrange,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMyMessage)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      // sender_typeに基づいて名前を表示
                      message.senderType == 'provider'
                          ? _chatRoom!.providerName
                          : _chatRoom!.userId,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMyMessage
                        ? AppColors.primaryOrange
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                      bottomRight: Radius.circular(isMyMessage ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMyMessage ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMyMessage) const SizedBox(width: 48),
          if (!isMyMessage) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'メッセージを入力...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSending
                      ? Colors.grey[400]
                      : AppColors.primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
