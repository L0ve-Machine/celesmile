import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class MySQLService {
  static MySQLService? _instance;
  String get baseUrl => '${dotenv.env['API_BASE_URL'] ?? 'https://celesmile-demo.duckdns.org'}/api';

  MySQLService._();

  static MySQLService get instance {
    _instance ??= MySQLService._();
    return _instance!;
  }

  // Helper to get headers with auth token
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth) {
      final token = AuthService.currentToken;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Salon methods
  Future<List<Map<String, dynamic>>> getSalonsByProvider(String providerId) async {
    final response = await http.get(Uri.parse('$baseUrl/salons/$providerId'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }

  Future<Map<String, dynamic>?> getSalonById(String salonId) async {
    final response = await http.get(Uri.parse('$baseUrl/salon/$salonId'));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    }
    return null;
  }

  // Booking methods
  Future<List<Map<String, dynamic>>> getBookingsByProvider(String providerId) async {
    final response = await http.get(Uri.parse('$baseUrl/bookings/$providerId'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }

  // Revenue methods
  Future<Map<String, dynamic>> getRevenueSummary(String providerId) async {
    final response = await http.get(Uri.parse('$baseUrl/revenue-summary/$providerId'));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    }
    return {'thisMonthTotal': 0, 'pendingTotal': 0, 'paidTotal': 0, 'totalRevenue': 0};
  }

  // Services methods
  Future<List<Map<String, dynamic>>> getServices({
    String? category,
    String? subcategory,
    String? location,
    String? search,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (subcategory != null) queryParams['subcategory'] = subcategory;
    if (location != null) queryParams['location'] = location;
    if (search != null) queryParams['search'] = search;
    if (limit != null) queryParams['limit'] = limit.toString();

    final uri = Uri.parse('$baseUrl/services').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }

  // Get single service by ID
  Future<Map<String, dynamic>?> getServiceById(String serviceId) async {
    final response = await http.get(Uri.parse('$baseUrl/service/$serviceId'));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    }
    return null;
  }

  // Create/Update salon
  Future<bool> saveSalon(Map<String, dynamic> salonData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/salons'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(salonData),
    );
    return response.statusCode == 200;
  }

  // Delete salon
  Future<bool> deleteSalon(String salonId) async {
    final response = await http.delete(Uri.parse('$baseUrl/salons/$salonId'));
    return response.statusCode == 200;
  }

  // Availability methods
  Future<List<Map<String, dynamic>>> getAvailability(String providerId, {String? date}) async {
    final queryParams = <String, String>{};
    if (date != null) queryParams['date'] = date;

    final uri = Uri.parse('$baseUrl/availability/$providerId').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }

  Future<bool> updateAvailability(Map<String, dynamic> availabilityData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/availability'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(availabilityData),
    );
    return response.statusCode == 200;
  }

  // Chat methods
  Future<List<Map<String, dynamic>>> getChats(String providerId) async {
    final response = await http.get(Uri.parse('$baseUrl/chats/$providerId'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }

  Future<bool> sendChatMessage(Map<String, dynamic> chatData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chats'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(chatData),
    );
    return response.statusCode == 200;
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/bookings/$bookingId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );
    return response.statusCode == 200;
  }

  // Menu methods
  Future<List<Map<String, dynamic>>> getMenusBySalon(String salonId) async {
    final response = await http.get(Uri.parse('$baseUrl/menus/$salonId'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }

  Future<bool> saveMenu(Map<String, dynamic> menuData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/menus'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(menuData),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteMenu(String menuId) async {
    final response = await http.delete(Uri.parse('$baseUrl/menus/$menuId'));
    return response.statusCode == 200;
  }

  // Get provider by ID
  Future<Map<String, dynamic>?> getProviderById(String providerId) async {
    final response = await http.get(Uri.parse('$baseUrl/providers/$providerId'));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    }
    return null;
  }

  // Login
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      // Handle success (200)
      if (response.statusCode == 200) {
        return data;
      }

      // Handle rate limiting (429)
      if (response.statusCode == 429) {
        print('⚠️ Rate limit exceeded: ${data['message'] ?? data['error']}');
        return data;
      }

      // Handle account locked (423)
      if (response.statusCode == 423) {
        print('🔒 Account locked: ${data['message'] ?? data['error']}');
        return data;
      }

      // Handle other errors (401, 400, etc.)
      if (response.statusCode >= 400) {
        print('❌ Login failed (${response.statusCode}): ${data['error']}');
        return data;
      }

      return null;
    } catch (e) {
      print('❌ Login request error: $e');
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  // Update provider profile
  Future<bool> updateProviderProfile(String providerId, Map<String, dynamic> profileData) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/providers/$providerId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(profileData),
    );
    return response.statusCode == 200;
  }

  // Change provider password
  Future<Map<String, dynamic>> changeProviderPassword(String providerId, String currentPassword, String newPassword) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/providers/$providerId/password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      final data = json.decode(response.body);
      return {'success': false, 'error': data['error'] ?? 'Password change failed'};
    }
  }

  // Check if review exists for a booking
  Future<Map<String, dynamic>> checkReviewExists(String bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/booking/$bookingId'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'exists': false, 'review': null};
    } catch (e) {
      print('Error checking review: $e');
      return {'exists': false, 'review': null};
    }
  }

  // Create a new review
  Future<bool> createReview({
    required String bookingId,
    required String providerId,
    required String serviceId,
    required String customerName,
    required double rating,
    required String comment,
  }) async {
    try {
      final reviewId = 'REV${DateTime.now().millisecondsSinceEpoch}';
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': reviewId,
          'booking_id': bookingId,
          'provider_id': providerId,
          'service_id': serviceId,
          'customer_name': customerName,
          'rating': rating,
          'comment': comment,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error creating review: $e');
      throw Exception('Failed to create review: $e');
    }
  }

  // Get reviews for a service
  Future<List<Map<String, dynamic>>> getServiceReviews(String serviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/service/$serviceId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting service reviews: $e');
      return [];
    }
  }

  // Get reviews for a provider
  Future<List<Map<String, dynamic>>> getProviderReviews(String providerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/provider/$providerId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting provider reviews: $e');
      return [];
    }
  }

  // Create booking in MySQL
  Future<bool> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bookingData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error creating booking: $e');
      return false;
    }
  }

  // Create revenue record in MySQL
  Future<bool> createRevenue(Map<String, dynamic> revenueData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/revenues'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(revenueData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error creating revenue: $e');
      return false;
    }
  }

  // ========================================
  // Stripe Connect Methods
  // ========================================

  // Create Stripe Connect Account
  Future<Map<String, dynamic>> createStripeConnectAccount(String email, String providerId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stripe/connect/account'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'providerId': providerId,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to create Stripe Connect account');
    } catch (e) {
      print('Error creating Stripe Connect account: $e');
      throw Exception('Failed to create Stripe Connect account: $e');
    }
  }

  // Create Account Link for onboarding
  Future<String> createStripeAccountLink(String accountId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stripe/connect/account-link'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accountId': accountId,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      }
      throw Exception('Failed to create account link');
    } catch (e) {
      print('Error creating account link: $e');
      throw Exception('Failed to create account link: $e');
    }
  }

  // Get Stripe Account status
  Future<Map<String, dynamic>> getStripeAccountStatus(String accountId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stripe/connect/account/$accountId'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get account status');
    } catch (e) {
      print('Error getting account status: $e');
      throw Exception('Failed to get account status: $e');
    }
  }

  // Create Payment Intent with Application Fee
  Future<Map<String, dynamic>> createPaymentIntent(int amount, String providerId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stripe/payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': amount,
          'providerId': providerId,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to create payment intent');
    } catch (e) {
      print('Error creating payment intent: $e');
      throw Exception('Failed to create payment intent: $e');
    }
  }
}
