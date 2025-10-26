import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/mysql_service.dart';

/// プロバイダー用チャット一覧画面
class ProviderChatListScreen extends StatefulWidget {
  const ProviderChatListScreen({super.key});

  @override
  State<ProviderChatListScreen> createState() => _ProviderChatListScreenState();
}

class _ProviderChatListScreenState extends State<ProviderChatListScreen> {
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;
  String? _providerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerId = ModalRoute.of(context)?.settings.arguments as String?;
    if (_providerId == null) {
      _providerId = 'provider_test'; // デフォルトのテストプロバイダー
    }
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chats = await MySQLService.instance.getChats(_providerId!);

      // Group chats by user_id to create "rooms"
      final Map<String, Map<String, dynamic>> roomsMap = {};

      for (var chat in chats) {
        final userId = chat['user_id'] ?? '';
        final message = chat['message'] ?? '';
        final senderType = chat['sender_type'] ?? '';
        final createdAt = DateTime.parse(chat['created_at'] ?? DateTime.now().toString());

        if (!roomsMap.containsKey(userId)) {
          roomsMap[userId] = {
            'user_id': userId,
            'last_message': message,
            'last_message_time': createdAt,
            'unread_count': 0,
            'messages': <Map<String, dynamic>>[],
          };
        }

        // Update last message if this one is newer
        final currentLastTime = roomsMap[userId]!['last_message_time'] as DateTime;
        if (createdAt.isAfter(currentLastTime)) {
          roomsMap[userId]!['last_message'] = message;
          roomsMap[userId]!['last_message_time'] = createdAt;
        }

        // Count unread messages (messages from user that haven't been read)
        if (senderType == 'user') {
          roomsMap[userId]!['unread_count'] = (roomsMap[userId]!['unread_count'] as int) + 1;
        }

        // Add to messages list
        (roomsMap[userId]!['messages'] as List<Map<String, dynamic>>).add(chat);
      }

      // Convert to list and sort by last message time
      final rooms = roomsMap.values.toList();
      rooms.sort((a, b) {
        final aTime = a['last_message_time'] as DateTime;
        final bTime = b['last_message_time'] as DateTime;
        return bTime.compareTo(aTime);
      });

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

  Widget _buildChatRoomTile(Map<String, dynamic> chatRoom) {
    final userId = chatRoom['user_id'] ?? '';
    final lastMessageText = chatRoom['last_message'] ?? 'メッセージがありません';
    final lastMessageTime = chatRoom['last_message_time'] as DateTime? ?? DateTime.now();
    final unreadCount = chatRoom['unread_count'] ?? 0;
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: () {
        // For now, just show a message since we don't have a full chat room implementation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userId とのチャットを開く')),
        );
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
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryOrange.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primaryOrange,
                    size: 28,
                  ),
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
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
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
                          userId,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
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
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
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
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
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
