import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/provider_database_service.dart';

class ProviderAvailabilityCalendarScreen extends StatefulWidget {
  const ProviderAvailabilityCalendarScreen({super.key});

  @override
  State<ProviderAvailabilityCalendarScreen> createState() => _ProviderAvailabilityCalendarScreenState();
}

class _ProviderAvailabilityCalendarScreenState extends State<ProviderAvailabilityCalendarScreen> {
  String? _providerId;
  DateTime _selectedMonth = DateTime.now();
  Map<String, List<TimeSlot>> _availability = {};
  DateTime? _selectedDate;

  final List<TimeSlot> _timeSlots = [
    TimeSlot(startTime: '06:00', endTime: '07:00'),
    TimeSlot(startTime: '07:00', endTime: '08:00'),
    TimeSlot(startTime: '08:00', endTime: '09:00'),
    TimeSlot(startTime: '09:00', endTime: '10:00'),
    TimeSlot(startTime: '10:00', endTime: '11:00'),
    TimeSlot(startTime: '11:00', endTime: '12:00'),
    TimeSlot(startTime: '12:00', endTime: '13:00'),
    TimeSlot(startTime: '13:00', endTime: '14:00'),
    TimeSlot(startTime: '14:00', endTime: '15:00'),
    TimeSlot(startTime: '15:00', endTime: '16:00'),
    TimeSlot(startTime: '16:00', endTime: '17:00'),
    TimeSlot(startTime: '17:00', endTime: '18:00'),
    TimeSlot(startTime: '18:00', endTime: '19:00'),
    TimeSlot(startTime: '19:00', endTime: '20:00'),
    TimeSlot(startTime: '20:00', endTime: '21:00'),
    TimeSlot(startTime: '21:00', endTime: '22:00'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerId = ModalRoute.of(context)?.settings.arguments as String?;
  }

  void _toggleTimeSlot(DateTime date, TimeSlot slot) {
    final dateKey = _getDateKey(date);
    setState(() {
      if (!_availability.containsKey(dateKey)) {
        _availability[dateKey] = [];
      }

      final existingIndex = _availability[dateKey]!.indexWhere(
        (s) => s.startTime == slot.startTime && s.endTime == slot.endTime,
      );

      if (existingIndex >= 0) {
        _availability[dateKey]!.removeAt(existingIndex);
      } else {
        _availability[dateKey]!.add(slot);
      }

      // Sort time slots
      _availability[dateKey]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
  }

  bool _isTimeSlotAvailable(DateTime date, TimeSlot slot) {
    final dateKey = _getDateKey(date);
    if (!_availability.containsKey(dateKey)) return false;

    return _availability[dateKey]!.any(
      (s) => s.startTime == slot.startTime && s.endTime == slot.endTime,
    );
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          '空き状況カレンダー',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('空き状況を保存しました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              '保存',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.lightBeige,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.accentBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'カレンダーで日付を選択し、空いている時間帯をタップしてください',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Calendar header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  '${_selectedMonth.year}年${_selectedMonth.month}月',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Calendar grid
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCalendarGrid(),

                  if (_selectedDate != null) ...[
                    const SizedBox(height: 16),
                    _buildTimeSlotSelector(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;

    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Calendar days
          ...List.generate((daysInMonth + startingWeekday - 1) ~/ 7 + 1, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - startingWeekday + 2;

                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return Expanded(child: Container());
                  }

                  final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
                  final isToday = DateTime.now().year == date.year &&
                      DateTime.now().month == date.month &&
                      DateTime.now().day == date.day;
                  final isSelected = _selectedDate != null &&
                      _selectedDate!.year == date.year &&
                      _selectedDate!.month == date.month &&
                      _selectedDate!.day == date.day;
                  final hasAvailability = _availability.containsKey(_getDateKey(date)) &&
                      _availability[_getDateKey(date)]!.isNotEmpty;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      child: Container(
                        height: 50,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentBlue
                              : hasAvailability
                                  ? Colors.green[50]
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isToday
                                ? AppColors.primaryOrange
                                : isSelected
                                    ? AppColors.accentBlue
                                    : Colors.grey[300]!,
                            width: isToday ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                dayNumber.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (hasAvailability && !isSelected)
                              Positioned(
                                bottom: 4,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeSlotSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_selectedDate!.month}月${_selectedDate!.day}日の空き時間',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time slots grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeSlots.map((slot) {
              final isAvailable = _isTimeSlotAvailable(_selectedDate!, slot);
              return GestureDetector(
                onTap: () => _toggleTimeSlot(_selectedDate!, slot),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 56) / 3,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAvailable ? Colors.green : Colors.grey[300]!,
                      width: isAvailable ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${slot.startTime} -',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isAvailable ? FontWeight.w600 : FontWeight.normal,
                          color: isAvailable ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        slot.endTime,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isAvailable ? FontWeight.w600 : FontWeight.normal,
                          color: isAvailable ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      final dateKey = _getDateKey(_selectedDate!);
                      _availability[dateKey] = List.from(_timeSlots);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.accentBlue),
                  ),
                  child: const Text(
                    '全て選択',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      final dateKey = _getDateKey(_selectedDate!);
                      _availability[dateKey] = [];
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  child: Text(
                    '全て解除',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TimeSlot {
  final String startTime;
  final String endTime;

  TimeSlot({required this.startTime, required this.endTime});
}
