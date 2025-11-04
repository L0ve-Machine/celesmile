import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/didit_service.dart';
import '../services/provider_database_service.dart';
import '../services/auth_service.dart';

class ProviderVerificationWaitingScreen extends StatefulWidget {
  final String providerId;
  final String sessionId;

  const ProviderVerificationWaitingScreen({
    Key? key,
    required this.providerId,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<ProviderVerificationWaitingScreen> createState() =>
      _ProviderVerificationWaitingScreenState();
}

class _ProviderVerificationWaitingScreenState
    extends State<ProviderVerificationWaitingScreen> {
  late Timer _statusCheckTimer;
  bool _isChecking = false;
  String _statusMessage = '本人確認を処理中です...';
  bool _isApproved = false;
  bool _isRejected = false;
  String _rejectionReason = '';

  @override
  void initState() {
    super.initState();
    _startStatusChecking();
  }

  void _startStatusChecking() {
    // First, register session ID with provider ID to backend
    _registerSessionWithBackend();

    // URLパラメータをチェック（DID-ITからのリダイレクト）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = Uri.base;
      print('🔍 [CALLBACK] Current URI: $uri');
      print('🔍 [CALLBACK] Full URL: ${Uri.base.toString()}');

      // ハッシュ内のクエリパラメータを取得
      String fragment = uri.fragment;
      print('🔍 [CALLBACK] Fragment: $fragment');

      late String status;
      late String verificationSessionId;

      // fragment から ?xxx=yyy を抽出
      if (fragment.contains('?')) {
        final fragmentUri = Uri.parse('scheme://host/$fragment');
        status = fragmentUri.queryParameters['status'] ?? '';
        verificationSessionId = fragmentUri.queryParameters['verificationSessionId'] ?? '';
      } else {
        status = uri.queryParameters['status'] ?? '';
        verificationSessionId = uri.queryParameters['verificationSessionId'] ?? '';
      }

      print('🔍 [CALLBACK] Query params: ${uri.queryParameters}');
      print('✅ [CALLBACK] Extracted Status: $status');
      print('✅ [CALLBACK] Extracted Session ID: $verificationSessionId');

      if (status.isNotEmpty && verificationSessionId.isNotEmpty) {
        print('🎉 [CALLBACK] DID-IT callback received!');
        print('📊 [CALLBACK] Status: $status');
        print('📍 [CALLBACK] Session ID: $verificationSessionId');

        _handleVerificationResult(status);
      } else {
        print('⏳ [CALLBACK] No callback parameters yet, starting polling...');
        // Start polling backend for status updates
        _startPollingBackend();
      }
    });

    // フォールバック: タイムアウト（10分）
    _statusCheckTimer = Timer(Duration(minutes: 10), () {
      if (!_isApproved && !_isRejected && mounted) {
        print('⏰ [CALLBACK] TIMEOUT after 10 minutes');
        setState(() {
          _statusMessage = 'タイムアウトしました。もう一度お試しください。';
          _isRejected = true;
          _rejectionReason = 'セッションがタイムアウトしました';
        });
      }
    });
  }

  Future<void> _registerSessionWithBackend() async {
    try {
      final response = await http.post(
        Uri.parse('https://celesmile-demo.duckdns.org/register-session/${widget.sessionId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'providerId': widget.providerId}),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('✅ Session registered with backend');
      } else {
        print('❌ Failed to register session: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error registering session: $e');
    }
  }

  void _startPollingBackend() {
    // Poll backend every 2 seconds for status updates
    _statusCheckTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final response = await http.get(
          Uri.parse('https://celesmile-demo.duckdns.org/verification-status/${widget.sessionId}'),
        ).timeout(Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final status = data['status'] ?? '';

          print('🔄 [POLLING] Status from backend: $status');
          print('🔄 [POLLING] Full data from backend: ${json.encode(data)}');

          // Check if status is final (not initial or in progress states)
          final normalizedStatus = status.toLowerCase();
          if (status.isNotEmpty &&
              normalizedStatus != 'not_started' &&
              normalizedStatus != 'in_progress' &&
              normalizedStatus != 'not started' &&
              normalizedStatus != 'in progress') {
            print('✅ [POLLING] Final status detected, handling result: $status');
            timer.cancel();
            _handleVerificationResult(status);
          }
        }
      } catch (e) {
        print('⚠️ [POLLING] Error polling backend: $e');
      }
    });
  }

  void _handleVerificationResult(String status) {
    final normalizedStatus = status.toLowerCase().replaceAll('_', ' ').trim();

    print('🔍 [HANDLER] Original status: $status');
    print('🔍 [HANDLER] Normalized status: $normalizedStatus');

    if (normalizedStatus == 'approved') {
      _statusCheckTimer.cancel();
      setState(() {
        _isApproved = true;
        _statusMessage = '本人確認が承認されました！';
      });

      print('⏳ [CALLBACK] Waiting 2 seconds before navigation...');

      // ユーザーをproviderとして設定
      AuthService.setAsProvider(widget.providerId).then((_) {
        print('✅ User set as provider: ${widget.providerId}');
      });

      // 2秒後にProvider画面に遷移
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          print('📍 [CALLBACK] Navigating to provider-home-dashboard');
          _navigateToProviderHome();
        }
      });
    } else if (normalizedStatus == 'declined') {
      _statusCheckTimer.cancel();
      setState(() {
        _isRejected = true;
        _statusMessage = '申し訳ございません。本人確認が却下されました。';
        _rejectionReason = 'DID-IT で却下されました';
      });
    } else if (normalizedStatus == 'in review') {
      setState(() {
        _statusMessage = '本人確認をレビュー中です...';
      });
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'not_started':
        return '申請を処理中です...';
      case 'in_progress':
        return '本人確認を処理中です...';
      case 'approved':
        return '本人確認が承認されました！';
      case 'declined':
        return '本人確認が却下されました。';
      default:
        return '申請を処理中です...';
    }
  }

  void _navigateToProviderHome() {
    Navigator.pushReplacementNamed(
      context,
      '/provider-home-dashboard',
      arguments: widget.providerId,
    );
  }

  void _retryVerification() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _statusCheckTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本人確認申請'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // アイコン
                if (!_isRejected)
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: _isApproved
                            ? Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 50,
                              )
                            : Center(
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  )
                else
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                // メッセージ
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isRejected ? Colors.red : Colors.black,
                      ),
                ),
                const SizedBox(height: 16),

                // 詳細メッセージ
                if (!_isApproved && !_isRejected)
                  Text(
                    'ご申請ありがとうございます。\n本人確認を処理しています。\nお待ちください。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),

                if (_isApproved)
                  Text(
                    'Provider ページへ移動します。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),

                if (_isRejected)
                  Column(
                    children: [
                      Text(
                        '理由: $_rejectionReason',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.red[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'お手数ですが、もう一度お申し込みください。',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),

                const SizedBox(height: 48),

                // ボタン
                if (_isRejected)
                  ElevatedButton(
                    onPressed: _retryVerification,
                    child: const Text('再度申請'),
                  ),

                // 追加情報
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ℹ️ ご注意',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '本人確認プロセスには通常数分要します。\n'
                        'このページを閉じないでください。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
