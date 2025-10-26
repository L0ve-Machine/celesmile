import 'package:http/http.dart' as http;
import 'dart:convert';

class MySQLService {
  static MySQLService? _instance;
  final String baseUrl = '/api';

  MySQLService._();

  static MySQLService get instance {
    _instance ??= MySQLService._();
    return _instance!;
  }

  // Salon methods
  Future<List<Map<String, dynamic>>> getSalonsByProvider(String providerId) async {
    final response = await http.get(Uri.parse('$baseUrl/salons/$providerId'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
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

  // Login
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['provider'];
      }
    }
    return null;
  }
}
