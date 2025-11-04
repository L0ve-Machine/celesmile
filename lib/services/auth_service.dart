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

  // 新規登録用の一時保存されたアカウント情報
  static Map<String, String> _pendingAccounts = {};

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

  // Current JWT token
  static String? _currentToken;

  // Get current token
  static String? get currentToken => _currentToken;

  // Last login error message
  static String? _lastLoginError;

  // Get last login error
  static String? get lastLoginError => _lastLoginError;

  // ログイン検証
  static Future<bool> login(String username, String password) async {
    _lastLoginError = null;

    try {
      // Call real API for authentication
      final result = await MySQLService.instance.login(username, password);

      if (result != null && result['success'] == true) {
        // Store token
        _currentToken = result['token'];

        // Save token to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _currentToken!);

        // Get provider data
        final provider = result['provider'];
        if (provider != null) {
          _currentUser = provider['email'] ?? username;

          // If user has a provider ID, load additional data
          if (provider['id'] != null) {
            _userProviderIds[_currentUser!] = provider['id'];
            await prefs.setString('provider_id_$_currentUser', provider['id']);
          }
        }

        // Load user data
        await _loadUserData(_currentUser!);
        await loadProviderStatus();

        print('✅ Login successful: $_currentUser');
        return true;
      } else {
        // Handle various error types
        final errorType = result?['type'];
        final errorMessage = result?['message'] ?? result?['error'] ?? 'ログインに失敗しました';
        final remainingAttempts = result?['remainingAttempts'];
        final remainingMinutes = result?['remainingMinutes'];

        // Build user-friendly error message
        if (errorType == 'ACCOUNT_LOCKED') {
          _lastLoginError = 'アカウントが一時的にロックされています。\n${remainingMinutes}分後に再試行してください。';
        } else if (errorType == 'DEVICE_BLOCKED') {
          _lastLoginError = 'デバイスが一時的にブロックされています。\n${remainingMinutes}分後に再試行してください。';
        } else if (errorType == 'AUTH_RATE_LIMIT_EXCEEDED' || errorType == 'RATE_LIMIT_EXCEEDED') {
          _lastLoginError = 'リクエストが多すぎます。\nしばらく待ってから再試行してください。';
        } else if (remainingAttempts != null) {
          _lastLoginError = 'ログインに失敗しました。\n残り試行回数: $remainingAttempts';
        } else {
          _lastLoginError = errorMessage;
        }

        print('❌ Login failed: $_lastLoginError');
        return false;
      }
    } catch (e) {
      print('❌ Login error: $e');
      _lastLoginError = 'ネットワークエラーが発生しました。\nもう一度お試しください。';
      return false;
    }
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

  // Set user as provider (called after DIDIT approval)
  static Future<void> setAsProvider(String providerId) async {
    if (_currentUser != null) {
      _userProviderIds[_currentUser!] = providerId;
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('provider_id_$_currentUser', providerId);
      print('✅ User $_currentUser set as provider with ID: $providerId');
    }
  }

  // Load provider status from SharedPreferences
  static Future<void> loadProviderStatus() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      final providerId = prefs.getString('provider_id_$_currentUser');
      if (providerId != null) {
        _userProviderIds[_currentUser!] = providerId;
        print('✅ Loaded provider status for $_currentUser: $providerId');
      }
    }
  }

  // アカウント作成（SMS認証後）
  static Future<Map<String, dynamic>> createAccount(
      String username, String password) async {
    // ユーザー名が既に存在するかチェック
    if (_users.containsKey(username)) {
      return {
        'success': false,
        'error': 'このユーザー名は既に使用されています',
      };
    }

    // バリデーション
    if (username.length < 4) {
      return {
        'success': false,
        'error': 'ユーザー名は4文字以上で入力してください',
      };
    }

    if (password.length < 8) {
      return {
        'success': false,
        'error': 'パスワードは8文字以上で設定してください',
      };
    }

    try {
      // 新しいアカウントを作成
      _users[username] = password;

      // SharedPreferencesに保存
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username_$username', password);

      // 自動ログイン
      _currentUser = username;
      print('✅ Account created and logged in: $username');

      // 電話番号が認証されていれば、プロフィールに設定
      if (currentUserPhone != null) {
        final profile = UserProfile()..phone = currentUserPhone;
        _profiles[username] = profile;
        await prefs.setString('profile_$username', jsonEncode(profile.toJson()));
      }

      return {
        'success': true,
        'username': username,
      };
    } catch (e) {
      print('❌ Error creating account: $e');
      return {
        'success': false,
        'error': 'アカウント作成中にエラーが発生しました',
      };
    }
  }

  // アカウントを読み込み（アプリ起動時）
  static Future<void> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (var key in keys) {
      if (key.startsWith('username_')) {
        final username = key.substring('username_'.length);
        final password = prefs.getString(key);
        if (password != null) {
          _users[username] = password;
        }
      }
    }
    print('✅ Loaded ${_users.length} accounts from storage');
  }
}
