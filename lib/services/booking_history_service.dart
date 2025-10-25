import 'database_service.dart';

class BookingHistory {
  final String bookingId;
  final ServiceModel service;
  final DateTime bookingDate;
  final String status; // 'upcoming', 'completed', 'cancelled'

  BookingHistory({
    required this.bookingId,
    required this.service,
    required this.bookingDate,
    required this.status,
  });
}

class BookingHistoryService {
  static final BookingHistoryService _instance = BookingHistoryService._internal();
  factory BookingHistoryService() => _instance;
  BookingHistoryService._internal();

  final List<BookingHistory> _bookings = [];

  // Add a new booking
  void addBooking(ServiceModel service) {
    final booking = BookingHistory(
      bookingId: 'BK${DateTime.now().millisecondsSinceEpoch}',
      service: service,
      bookingDate: DateTime.now(),
      status: 'upcoming',
    );
    _bookings.insert(0, booking); // Add to beginning of list
  }

  // Get all bookings
  List<BookingHistory> getAllBookings() {
    return List.from(_bookings);
  }

  // Get bookings by status
  List<BookingHistory> getBookingsByStatus(String status) {
    return _bookings.where((booking) => booking.status == status).toList();
  }

  // Get upcoming bookings
  List<BookingHistory> getUpcomingBookings() {
    return getBookingsByStatus('upcoming');
  }

  // Cancel a booking
  void cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
    if (index != -1) {
      final booking = _bookings[index];
      _bookings[index] = BookingHistory(
        bookingId: booking.bookingId,
        service: booking.service,
        bookingDate: booking.bookingDate,
        status: 'cancelled',
      );
    }
  }

  // Complete a booking
  void completeBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
    if (index != -1) {
      final booking = _bookings[index];
      _bookings[index] = BookingHistory(
        bookingId: booking.bookingId,
        service: booking.service,
        bookingDate: booking.bookingDate,
        status: 'completed',
      );
    }
  }
}
