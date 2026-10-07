import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enquiry_app/services/storage_service.dart';
import 'package:enquiry_app/utils/api_debug_logger.dart';

class AuthService {
  final StorageService _storageService;
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  AuthService(this._storageService) {
    _dio.interceptors.add(ApiDebugLogger.dioInterceptor);
  }

  Future<List<String>> fetchAndStoreUserCategories(String userMainId) async {
    if (userMainId.isEmpty) return [];
    try {
      final String url = "https://user.jobes24x7.com/api/business-cre/main/$userMainId";
      final prefs = await SharedPreferences.getInstance();
      final String? savedCookies = prefs.getString('stored_cookies');
      final String token = _storageService.authToken;

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        if (savedCookies != null && savedCookies.isNotEmpty) 'Cookie': savedCookies,
      };

      final response = await _dio.get(
        url,
        options: Options(headers: headers),
      );

      debugPrint('================ BUSINESS API DEBUG ================');
      debugPrint('user_main_id: $userMainId');
      debugPrint('Request URL: $url');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('====================================================');

      if (response.statusCode == 200) {
        final data = response.data is Map
            ? response.data
            : (response.data is String ? jsonDecode(response.data.toString()) : response.data);

        final Set<String> primarySet = {};
        final Set<String> subSet = {};

        void findCategories(dynamic obj) {
          if (obj is Map) {
            if (obj.containsKey('primary_categories') && obj['primary_categories'] is List) {
              for (var p in obj['primary_categories']) {
                if (p is Map && p['name'] != null && p['name'].toString().trim().isNotEmpty) {
                  primarySet.add(p['name'].toString().trim());
                } else if (p is String && p.trim().isNotEmpty) {
                  primarySet.add(p.trim());
                }
              }
            }
            if (obj.containsKey('sub_categories') && obj['sub_categories'] is List) {
              for (var s in obj['sub_categories']) {
                if (s is Map && s['name'] != null && s['name'].toString().trim().isNotEmpty) {
                  subSet.add(s['name'].toString().trim());
                } else if (s is String && s.trim().isNotEmpty) {
                  subSet.add(s.trim());
                }
              }
            }
            for (var value in obj.values) {
              findCategories(value);
            }
          } else if (obj is List) {
            for (var elem in obj) {
              findCategories(elem);
            }
          }
        }

        findCategories(data);

        final List<String> primaryList = primarySet.toList();
        final List<String> subList = subSet.toList();

        await _storageService.setUserPrimaryCategories(primaryList);
        await _storageService.setUserSubCategories(subList);

        return [...primaryList, ...subList];
      }
    } catch (e) {
      debugPrint("Error fetching Business CRE categories for $userMainId: $e");
    }
    return [];
  }
}
