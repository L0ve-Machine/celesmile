import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/chat_service.dart';
import '../services/profile_image_service.dart';

/// プロバイダー用チャット一覧画面
class ProviderChatListScreen extends StatefulWidget {
  const ProviderChatListScreen({super.key});

  @override
  State<ProviderChatListScreen> createState() => _ProviderChatListScreenState();
}

class _ProviderChatListScreenState extends State<ProviderChatListScreen> {
  final ChatService _chatService = ChatService();
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // プロバイダーIDでチャットルームを取得
      // TODO: 実際のプロバイダーIDを使用する
      const providerId = 'test_provider_001';
      final rooms = await _chatService.getChatRoomsByProvider(providerId);

      setState(() {
        _chatRooms = rooms;
        _isLoading = false;
      });

      print('🔵 [ProviderChatList] チャットルーム数: ${rooms.length}');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('チャット一覧の読み込みに失敗しました: $e')),
        );
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // 今日
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // 昨日
      return '昨日';
    } else if (difference.inDays < 7) {
      // 1週間以内
      final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
      return '${weekdays[timestamp.weekday - 1]}曜日';
    } else {
      // それ以前
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'チャット',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.grey[300], height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadChatRooms,
                  child: ListView.separated(
                    itemCount: _chatRooms.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.grey[300],
                      height: 1,
                      indent: 72,
                    ),
                    itemBuilder: (context, index) {
                      final chatRoom = _chatRooms[index];
                      return _buildChatRoomTile(chatRoom);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'チャットはまだありません',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'お客様からの予約が確定すると\nチャットが開始されます',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/provider-home-dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'ダッシュボードに戻る',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomTile(ChatRoom chatRoom) {
    final lastMessageText = chatRoom.lastMessage?.message ?? 'メッセージがありません';
    final lastMessageTime =
        chatRoom.lastMessage?.timestamp ?? chatRoom.createdAt;
    final hasUnread = chatRoom.unreadCount > 0;

    return InkWell(
      onTap: () async {
        // チャットルーム画面に遷移
        await Navigator.pushNamed(
          context,
          '/chat-room',
          arguments: chatRoom.id,
        );
        // チャット画面から戻ったら再読み込み
        _loadChatRooms();
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ユーザーアイコン
            Stack(
              children: [
                ProfileImageService().buildProfileAvatar(
                  userId: chatRoom.userId,
                  isProvider: false,
                  radius: 28,
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        chatRoom.unreadCount > 9
                            ? '9+'
                            : chatRoom.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // チャット情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ユーザー名と時刻
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chatRoom.userId, // お客様のユーザー名を表示
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                hasUnread ? FontWeight.bold : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread
                              ? AppColors.primaryOrange
                              : Colors.grey[600],
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // サービス名
                  Text(
                    chatRoom.serviceName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // 最終メッセージ
                  Text(
                    lastMessageText,
                    style: TextStyle(
                      fontSize: 14,
                      color: hasUnread
                          ? AppColors.textPrimary
                          : Colors.grey[700],
                      fontWeight:
                          hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
