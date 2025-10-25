import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/booking_history_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String _selectedTab = 'upcoming'; // 'upcoming', 'completed', 'cancelled'

  @override
  Widget build(BuildContext context) {
    final bookingService = BookingHistoryService();
    List<BookingHistory> bookings;

    if (_selectedTab == 'upcoming') {
      bookings = bookingService.getUpcomingBookings();
    } else {
      bookings = bookingService.getBookingsByStatus(_selectedTab);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '予約履歴',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('予約中', 'upcoming'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('完了', 'completed'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('キャンセル', 'cancelled'),
                ),
              ],
            ),
          ),

          // Bookings list
          Expanded(
            child: bookings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '予約がありません',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return _buildBookingCard(booking);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String value) {
    final isSelected = _selectedTab == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.lightGray,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingHistory booking) {
    Color statusColor;
    String statusText;

    switch (booking.status) {
      case 'upcoming':
        statusColor = AppColors.primaryOrange;
        statusText = '予約中';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = '完了';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'キャンセル';
        break;
      default:
        statusColor = Colors.grey;
        statusText = booking.status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '予約ID: ${booking.bookingId}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Service details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service title
                Text(
                  booking.service.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Provider
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          AppColors.secondaryOrange.withOpacity(0.3),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primaryOrange,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.service.provider,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            booking.service.providerTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.accentBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.service.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Date & Time
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppColors.accentBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${booking.service.date} ${booking.service.time}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '合計金額',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      booking.service.totalPrice,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),

                // Action buttons for upcoming bookings
                if (booking.status == 'upcoming') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _openChatForBooking(booking);
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('チャット'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryOrange,
                            side: const BorderSide(color: AppColors.primaryOrange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to booking details in view-only mode
                            Navigator.pushNamed(
                              context,
                              '/booking-confirmation',
                              arguments: {
                                'serviceId': booking.service.id,
                                'viewOnly': true,
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '詳細を見る',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatForBooking(BookingHistory booking) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です')),
      );
      return;
    }

    final chatService = ChatService();

    // 既存のチャットルームを検索
    final chatRooms = await chatService.getChatRooms(currentUser);
    ChatRoom? existingRoom;

    // サービスIDまたはプロバイダーIDで検索
    for (var room in chatRooms) {
      if (room.serviceName == booking.service.title &&
          room.providerName == booking.service.provider) {
        existingRoom = room;
        break;
      }
    }

    if (existingRoom != null) {
      // 既存のチャットルームを開く
      Navigator.pushNamed(
        context,
        '/chat-room',
        arguments: existingRoom.id,
      );
    } else {
      // チャットルームが見つからない場合、新規作成
      if (booking.service.providerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロバイダー情報が見つかりません')),
        );
        return;
      }

      try {
        final newRoom = await chatService.createChatRoom(
          userId: currentUser,
          providerId: booking.service.providerId!,
          providerName: booking.service.provider,
          serviceName: booking.service.title,
          bookingId: booking.bookingId,
        );

        if (mounted) {
          Navigator.pushNamed(
            context,
            '/chat-room',
            arguments: newRoom.id,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('チャットの作成に失敗しました: $e')),
          );
        }
      }
    }
  }

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予約キャンセル'),
        content: const Text(
          'この予約をキャンセルしますか？\nキャンセル料が発生する場合があります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('戻る'),
          ),
          TextButton(
            onPressed: () {
              final bookingService = BookingHistoryService();
              bookingService.cancelBooking(bookingId);
              Navigator.pop(context);
              setState(() {}); // Refresh the list
            },
            child: const Text(
              'キャンセルする',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
