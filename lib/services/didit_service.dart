import 'dart:convert';
import 'package:http/http.dart' as http;

class DiditService {
  // スタンドアロンAPI用の設定（ガイド通り）
  static const String _baseUrl = 'http://localhost:8080'; // プロキシ経由
  static const String _apiKey = 'wpTfm090BVbZCUyLTmRn1SiuA7F-ru5kZ0i5YCJGWGAa';

  // Provider本人確認用のworkflow_id
  static const String _providerVerificationWorkflowId = 'cce0b449-5fc2-4cbe-b160-5825a1bb9d0d';

  // 電話番号を保存
  static String? _currentPhoneNumber;

  // Provider認証セッション情報
  static String? _providerSessionId;
  static String? _providerVerificationUrl;

  // SMS送信（認証コード送信）- ガイド通りの実装
  static Future<Map<String, dynamic>> sendPhoneCode(String phoneNumber) async {
    try {
      // 電話番号の正規化（日本の国番号を追加）
      String normalizedPhone = phoneNumber.startsWith('+')
          ? phoneNumber
          : '+81${phoneNumber.startsWith('0') ? phoneNumber.substring(1) : phoneNumber}';

      _currentPhoneNumber = normalizedPhone;

      final requestBody = {
        'phone_number': normalizedPhone,
        'options': {
          'code_size': 6,
          'locale': 'ja-JP',
          'preferred_channel': 'sms',
        },
      };

      print('📱 DIDIT API Request (Send Phone Code):');
      print('URL: $_baseUrl/phone/send/');
      print('Headers: x-api-key: ${_apiKey.substring(0, 10)}...');
      print('Body: $requestBody');

      final response = await http.post(
        Uri.parse('$_baseUrl/phone/send/'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: jsonEncode(requestBody),
      );

      print('📥 DIDIT API Response:');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];

        if (status == 'Success') {
          print('✅ SMS送信成功！');
          print('Request ID: ${data['request_id']}');

          return {
            'success': true,
            'message': 'SMSコードを送信しました',
            'request_id': data['request_id'],
          };
        } else if (status == 'Blocked') {
          return {
            'success': false,
            'error': 'この電話番号はブロックされています: ${data['reason']}',
          };
        }
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        if (data.containsKey('error') && data['error'].toString().contains('credits')) {
          return {
            'success': false,
            'error': 'クレジット残高が不足しています。https://business.didit.me でチャージしてください。',
          };
        }
        return {
          'success': false,
          'error': '権限がありません。DIdit Consoleでアカウント設定を確認してください。',
          'details': data['detail'],
        };
      } else if (response.statusCode == 429) {
        return {
          'success': false,
          'error': 'レート制限に達しました。しばらく待ってから再試行してください。',
        };
      }

      return {
        'success': false,
        'error': 'SMSの送信に失敗しました: ${response.statusCode}',
        'details': response.body,
      };
    } catch (e) {
      print('❌ DIDIT API Error: $e');
      return {
        'success': false,
        'error': 'エラーが発生しました: $e',
      };
    }
  }

  // コード確認（認証コード検証）- ガイド通りの実装
  static Future<Map<String, dynamic>> verifyPhoneCode(String code) async {
    if (_currentPhoneNumber == null) {
      return {
        'success': false,
        'error': '電話番号が見つかりません。もう一度SMSを送信してください。',
      };
    }

    try {
      final requestBody = {
        'phone_number': _currentPhoneNumber,
        'code': code,
        'disposable_number_action': 'DECLINE',
        'voip_number_action': 'DECLINE',
      };

      print('🔐 DIDIT API Request (Check Phone Code):');
      print('URL: $_baseUrl/phone/check/');
      print('Headers: x-api-key: ${_apiKey.substring(0, 10)}...');
      print('Body: $requestBody');

      final response = await http.post(
        Uri.parse('$_baseUrl/phone/check/'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: jsonEncode(requestBody),
      );

      print('📥 DIDIT Verify Response:');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];

        print('📊 Verification Status: $status');

        if (status == 'Approved') {
          print('✅ 認証成功！');
          return {
            'success': true,
            'message': '電話番号の認証が完了しました',
            'phone_number': _currentPhoneNumber,
            'phone_data': data['phone'],
          };
        } else if (status == 'Failed') {
          return {
            'success': false,
            'error': '認証コードが正しくありません',
          };
        } else if (status == 'Expired or Not Found') {
          return {
            'success': false,
            'error': '認証コードの有効期限が切れています。もう一度SMSを送信してください。',
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': '認証セッションが見つかりません（期限切れの可能性）',
        };
      }

      return {
        'success': false,
        'error': '認証に失敗しました: ${response.statusCode}',
        'details': response.body,
      };
    } catch (e) {
      print('❌ DIDIT Verify Error: $e');
      return {
        'success': false,
        'error': 'エラーが発生しました: $e',
      };
    }
  }

  // Provider本人確認セッションを作成（ワークフロー方式）
  static Future<Map<String, dynamic>> createProviderVerificationSession(String providerId) async {
    try {
      final requestBody = {
        'workflow_id': _providerVerificationWorkflowId,
        'vendor_data': providerId,
      };

      print('📱 DIDIT API Request (Create Provider Verification Session):');
      print('URL: $_baseUrl/session/');
      print('Headers: x-api-key: ${_apiKey.substring(0, 10)}...');
      print('Body: $requestBody');

      final response = await http.post(
        Uri.parse('$_baseUrl/session/'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: jsonEncode(requestBody),
      );

      print('📥 DIDIT API Response:');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _providerSessionId = data['id'];
        _providerVerificationUrl = data['verification_url'];

        print('✅ Provider認証セッション作成成功！');
        print('Session ID: $_providerSessionId');
        print('Verification URL: $_providerVerificationUrl');

        return {
          'success': true,
          'session_id': _providerSessionId,
          'verification_url': _providerVerificationUrl,
        };
      } else {
        return {
          'success': false,
          'error': 'セッション作成に失敗しました: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('❌ DIDIT API Error: $e');
      return {
        'success': false,
        'error': 'エラーが発生しました: $e',
      };
    }
  }

  // セッションをクリア
  static void clearSession() {
    _currentPhoneNumber = null;
    _providerSessionId = null;
    _providerVerificationUrl = null;
  }
}
