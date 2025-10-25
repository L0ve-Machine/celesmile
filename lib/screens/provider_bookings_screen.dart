import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/provider_database_service.dart';
import '../services/chat_service.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  String? _providerId;
  final providerDb = ProviderDatabaseService();
  String _filterStatus = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerId = ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _providerId != null
        ? providerDb.getBookingsByProvider(_providerId!)
        : [];

    // Filter bookings by status
    final filteredBookings = _filterStatus == 'all'
        ? bookings
        : bookings.where((b) => b.status == _filterStatus).toList();

    // Sort by booking date (newest first)
    filteredBookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

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
          '予約一覧',
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
          // Filter tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'すべて', bookings.length),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'pending',
                    '未対応',
                    bookings.where((b) => b.status == 'pending').length,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'confirmed',
                    '承認済み',
                    bookings.where((b) => b.status == 'confirmed').length,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'completed',
                    '完了',
                    bookings.where((b) => b.status == 'completed').length,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'cancelled',
                    'キャンセル',
                    bookings.where((b) => b.status == 'cancelled').length,
                  ),
                ],
              ),
            ),
          ),

          // Bookings list
          Expanded(
            child: filteredBookings.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      return _buildBookingCard(filteredBookings[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status, String label, int count) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = status;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primaryOrange.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryOrange : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryOrange : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _filterStatus == 'all' ? '予約がありません' : 'この状態の予約がありません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: _getStatusColor(booking.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(booking.status),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '¥${booking.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Booking details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service name
                Text(
                  booking.serviceName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Date and time
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(booking.bookingDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      booking.timeSlot,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Divider(),
                const SizedBox(height: 12),

                // Customer info
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      booking.customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      booking.customerPhone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.notes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action buttons
                if (booking.status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateBookingStatus(booking.id, 'cancelled'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('キャンセル'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateBookingStatus(booking.id, 'confirmed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            '承認',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (booking.status == 'confirmed') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openChat(booking),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('チャット'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryOrange,
                            side: const BorderSide(color: AppColors.primaryOrange),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateBookingStatus(booking.id, 'completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            '完了にする',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // チャットボタン（その他のステータスでも表示）
                if (booking.status != 'pending' && booking.status != 'confirmed') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openChat(booking),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('チャット'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryOrange,
                        side: const BorderSide(color: AppColors.primaryOrange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateBookingStatus(String bookingId, String newStatus) {
    if (_providerId == null) return;

    setState(() {
      providerDb.updateBookingStatus(_providerId!, bookingId, newStatus);
    });

    String message = '';
    switch (newStatus) {
      case 'confirmed':
        message = '予約を承認しました';
        break;
      case 'completed':
        message = '予約を完了にしました';
        break;
      case 'cancelled':
        message = '予約をキャンセルしました';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: newStatus == 'cancelled' ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return AppColors.primaryOrange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return '承認済み';
      case 'completed':
        return '完了';
      case 'cancelled':
        return 'キャンセル';
      case 'pending':
      default:
        return '未対応';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  Future<void> _openChat(Booking booking) async {
    if (_providerId == null) return;

    final chatService = ChatService();

    // 既存のチャットルームを検索
    final chatRooms = await chatService.getChatRoomsByProvider(_providerId!);
    ChatRoom? existingRoom;

    for (var room in chatRooms) {
      if (room.bookingId == booking.id) {
        existingRoom = room;
        break;
      }
    }

    // チャットルームが存在しない場合は作成
    if (existingRoom == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('この予約にはまだチャットが開設されていません')),
        );
      }
      return;
    }

    // チャットルーム画面に遷移
    if (mounted) {
      await Navigator.pushNamed(
        context,
        '/chat-room',
        arguments: existingRoom.id,
      );

      // 戻ったら画面を更新
      setState(() {});
    }
  }
}
