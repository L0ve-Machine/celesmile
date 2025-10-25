import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import 'dart:convert';

/// デバッグ用：SharedPreferencesの内容を表示する画面
class DebugChatScreen extends StatefulWidget {
  const DebugChatScreen({super.key});

  @override
  State<DebugChatScreen> createState() => _DebugChatScreenState();
}

class _DebugChatScreenState extends State<DebugChatScreen> {
  String _debugInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final buffer = StringBuffer();

    buffer.writeln('=== SharedPreferences デバッグ情報 ===\n');

    // All keys
    final keys = prefs.getKeys();
    buffer.writeln('📋 保存されているキー数: ${keys.length}\n');

    for (var key in keys) {
      buffer.writeln('🔑 $key:');
      final value = prefs.get(key);

      if (key == 'chat_rooms') {
        // チャットルームの詳細を表示
        try {
          final roomsJson = prefs.getString(key);
          if (roomsJson != null) {
            final List<dynamic> rooms = json.decode(roomsJson);
            buffer.writeln('   チャットルーム数: ${rooms.length}');
            for (var i = 0; i < rooms.length; i++) {
              final room = rooms[i];
              buffer.writeln('   [$i] ${room['id']}');
              buffer.writeln('       - userId: ${room['userId']}');
              buffer.writeln('       - providerId: ${room['providerId']}');
              buffer.writeln('       - providerName: ${room['providerName']}');
              buffer.writeln('       - serviceName: ${room['serviceName']}');
              buffer.writeln('       - bookingId: ${room['bookingId']}');
              buffer.writeln('       - createdAt: ${room['createdAt']}');
              buffer.writeln('       - unreadCount: ${room['unreadCount']}');
            }
          }
        } catch (e) {
          buffer.writeln('   ⚠️ パースエラー: $e');
        }
      } else if (key.startsWith('chat_messages_')) {
        // メッセージの詳細を表示
        try {
          final messagesJson = prefs.getString(key);
          if (messagesJson != null) {
            final List<dynamic> messages = json.decode(messagesJson);
            buffer.writeln('   メッセージ数: ${messages.length}');
          }
        } catch (e) {
          buffer.writeln('   ⚠️ パースエラー: $e');
        }
      } else {
        // その他のキーは値をそのまま表示
        buffer.writeln('   $value');
      }
      buffer.writeln('');
    }

    setState(() {
      _debugInfo = buffer.toString();
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
          'チャットデバッグ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryOrange),
            onPressed: _loadDebugInfo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: _clearAllChatData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          _debugInfo,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Future<void> _clearAllChatData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('警告'),
        content: const Text('全てのチャットデータを削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_rooms');

      // 全てのメッセージも削除
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith('chat_messages_')) {
          await prefs.remove(key);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('全てのチャットデータを削除しました')),
        );
        _loadDebugInfo();
      }
    }
  }
}
