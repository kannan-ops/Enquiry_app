import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enquiry_app/services/storage_service.dart';
import 'package:enquiry_app/chartfile/chat_screen.dart';
import 'package:enquiry_app/main.dart';

class SharingIntentHandler {
  static const _channel = MethodChannel('com.circuitpoint.enquiry/share');
  static List<String>? pendingSharedFiles;
  static String? pendingSharedText;

  static void init() {
    // 1. Listen for warm starts / background sharing
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShareReceived') {
        _handleShareData(call.arguments);
      }
      return null;
    });

    // 2. Handle cold start sharing (app was terminated)
    _channel.invokeMethod('getInitialShare').then((data) {
      if (data != null) {
        _handleShareData(data);
      }
    });
  }

  static void _handleShareData(dynamic arguments) {
    if (arguments == null) return;
    try {
      final map = Map<String, dynamic>.from(arguments);
      final type = map['type'] as String?;
      if (type == 'text') {
        final text = map['text'] as String?;
        if (text != null && text.isNotEmpty) {
          _processSharing(text: text);
        }
      } else if (type == 'media') {
        final paths = List<String>.from(map['paths'] ?? []);
        if (paths.isNotEmpty) {
          _processSharing(filePaths: paths);
        }
      }
    } catch (e) {
      debugPrint("[SharingIntentHandler] Error parsing share data: $e");
    }
  }

  static void dispose() {
    _channel.setMethodCallHandler(null);
  }

  static Future<void> _processSharing({List<String>? filePaths, String? text}) async {
    final storage = await StorageService.getInstance();
    if (!storage.isLoggedIn) {
      pendingSharedFiles = filePaths;
      pendingSharedText = text;
      debugPrint("[SharingIntentHandler] User is not logged in. Shared content stored as pending.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String module = prefs.getString('last_chat_module') ?? 'enquiry';
    final int refId = prefs.getInt('last_chat_reference_id') ?? 1;
    final String userName = prefs.getString('last_chat_user_name') ?? 'Client';

    debugPrint("[SharingIntentHandler] Routing to ChatScreen: module=$module, refId=$refId, user=$userName");

    NavigationService.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          module: module,
          referenceId: refId,
          userName: userName,
          initialSharedFiles: filePaths,
          initialSharedText: text,
        ),
      ),
    );
  }

  static Future<void> checkAndProcessPending() async {
    if (pendingSharedFiles != null || pendingSharedText != null) {
      final files = pendingSharedFiles;
      final txt = pendingSharedText;
      pendingSharedFiles = null;
      pendingSharedText = null;
      await _processSharing(filePaths: files, text: txt);
    }
  }

  static Future<void> shareTextExternally(String text) async {
    try {
      await _channel.invokeMethod('shareText', {'text': text});
    } catch (e) {
      debugPrint("[SharingIntentHandler] Error launching native share: $e");
    }
  }
}
