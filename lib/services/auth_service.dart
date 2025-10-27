import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'mysql_service.dart';

class UserProfile {
  String? name;
  String? gender;
  String? birthDate;
  String? phone;
  String? email;
  String? inviteCode;
  String? postalCode;
  String? prefecture;
  String? city;
  String? address;
  String? building;

  UserProfile();

  bool get isComplete {
    return name != null &&
        gender != null &&
        birthDate != null &&
        phone != null &&
        email != null &&
        postalCode != null &&
        prefecture != null &&
        city != null &&
        address != null;
  }

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'birthDate': birthDate,
      'phone': phone,
      'email': email,
      'inviteCode': inviteCode,
      'postalCode': postalCode,
      'prefecture': prefecture,
      'city': city,
      'address': address,
      'building': building,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile()
      ..name = json['name']
      ..gender = json['gender']
      ..birthDate = json['birthDate']
      ..phone = json['phone']
      ..email = json['email']
      ..inviteCode = json['inviteCode']
      ..postalCode = json['postalCode']
      ..prefecture = json['prefecture']
      ..city = json['city']
      ..address = json['address']
      ..building = json['building'];
  }
}

class PaymentInfo {
  bool hasPaymentMethod = false;

  PaymentInfo();

  bool get isComplete => hasPaymentMethod;

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'hasPaymentMethod': hasPaymentMethod,
    };
  }

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo()..hasPaymentMethod = json['hasPaymentMethod'] ?? false;
  }
}

class AuthService {
  // 簡易的なインメモリユーザーデータベース
  static final Map<String, String> _users = {
    'admin': 'admin123',
    'test': 'test123',
    'user': 'test123',
  };

  // Provider ID mapping (only for provider users)
  static final Map<String, String> _userProviderIds = {
    'test': 'test_provider_001',
  };

  // ユーザープロフィール管理
  static final Map<String, UserProfile> _profiles = {};

  // 決済情報管理
  static final Map<String, PaymentInfo> _paymentInfos = {};

  // 現在ログイン中のユーザー
  static String? _currentUser;

  // 電話番号認証用の一時保存
  static String? currentUserPhone;

  // Initialize test user data
  static bool _initialized = false;

  static void _initializeTestUsers() {
    if (_initialized) return;
    _initialized = true;

    // Create complete profile for 'user' test account
    final userProfile = UserProfile()
      ..name = 'テスト ユーザー'
      ..gender = '男性'
      ..birthDate = '1990年1月1日'
      ..phone = '080-1234-5678'
      ..email = 'user@celesmile.com'
      ..inviteCode = ''
      ..postalCode = '150-0001'
      ..prefecture = '東京都'
      ..city = '渋谷区'
      ..address = '神宮前1-2-3'
      ..building = 'テストマンション101';

    _profiles['user'] = userProfile;

    // Create payment info for 'user' test account
    final userPayment = PaymentInfo()..hasPaymentMethod = true;
    _paymentInfos['user'] = userPayment;
  }

  // SharedPreferencesからデータを読み込み
  static Future<void> _loadUserData(String username) async {
    final prefs = await SharedPreferences.getInstance();

    // プロフィールを読み込み
    final profileJson = prefs.getString('profile_$username');
    print('Loading profile for $username: $profileJson'); // Debug
    if (profileJson != null) {
      final profile = UserProfile.fromJson(jsonDecode(profileJson));
      _profiles[username] = profile;
      print('Profile loaded - isComplete: ${profile.isComplete}, name: ${profile.name}'); // Debug
    } else {
      print('No profile found for $username'); // Debug
    }

    // 決済情報を読み込み
    final paymentJson = prefs.getString('payment_$username');
    print('Loading payment for $username: $paymentJson'); // Debug
    if (paymentJson != null) {
      final payment = PaymentInfo.fromJson(jsonDecode(paymentJson));
      _paymentInfos[username] = payment;
      print('Payment loaded - isComplete: ${payment.isComplete}'); // Debug
    } else {
      print('No payment found for $username'); // Debug
    }
  }

  // ログイン検証
  static Future<bool> login(String username, String password) async {
    // Initialize test users on first login attempt
    _initializeTestUsers();

    // For provider users (those with mapped provider IDs), use MySQL API
    if (_userProviderIds.containsKey(username)) {
      try {
        final providerId = _userProviderIds[username]!;
        // Get provider from database to verify credentials
        final provider = await MySQLService.instance.getProviderById(providerId);
        if (provider != null && provider['password'] == password) {
          _currentUser = username;
          // SharedPreferencesからデータを読み込み
          await _loadUserData(username);
          return true;
        }
        return false;
      } catch (e) {
        print('Provider login error: $e');
        return false;
      }
    }

    // For regular users, use hardcoded credentials
    if (_users.containsKey(username)) {
      if (_users[username] == password) {
        _currentUser = username;
        // SharedPreferencesからデータを読み込み
        await _loadUserData(username);
        return true;
      }
    }
    return false;
  }

  // ユーザー名の検証
  static bool userExists(String username) {
    return _users.containsKey(username);
  }

  // 現在のユーザー取得
  static String? get currentUser => _currentUser;

  // プロフィール取得
  static UserProfile? get currentUserProfile {
    if (_currentUser == null) return null;
    return _profiles[_currentUser];
  }

  // 決済情報取得
  static PaymentInfo? get currentUserPaymentInfo {
    if (_currentUser == null) return null;
    return _paymentInfos[_currentUser];
  }

  // プロフィール保存
  static Future<void> saveProfile(UserProfile profile) async {
    if (_currentUser != null) {
      _profiles[_currentUser!] = profile;
      // SharedPreferencesに保存
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'profile_$_currentUser', jsonEncode(profile.toJson()));
    }
  }

  // 決済情報保存
  static Future<void> savePaymentInfo(PaymentInfo paymentInfo) async {
    if (_currentUser != null) {
      _paymentInfos[_currentUser!] = paymentInfo;
      // SharedPreferencesに保存
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'payment_$_currentUser', jsonEncode(paymentInfo.toJson()));
    }
  }

  // ログアウト
  static void logout() {
    _currentUser = null;
  }

  // Get provider ID for current user
  static String? get currentUserProviderId {
    if (_currentUser == null) return null;
    return _userProviderIds[_currentUser];
  }

  // Check if current user is a provider
  static bool get isProvider {
    if (_currentUser == null) return false;
    return _userProviderIds.containsKey(_currentUser);
  }
}
